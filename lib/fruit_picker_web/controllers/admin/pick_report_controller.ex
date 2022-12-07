defmodule FruitPickerWeb.Admin.PickReportController do
  @moduledoc false

  use FruitPickerWeb, :controller

  alias FruitPicker.Accounts
  alias FruitPicker.Accounts.{
    Person,
    Tree,
    TreeSnapshot
  }
  alias FruitPicker.Activities
  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickFruit,
    PickReport
  }
  alias FruitPicker.{
    Inventory,
    Repo,
    Partners,
    Mailer,
  }
  alias FruitPickerWeb.{Email, Resources}
  alias Ecto.Multi

  def new(conn, %{"pick_id" => pick_id}) do
    me = conn.assigns.current_person
    pick = Activities.get_pick!(pick_id)
    changeset = PickReport.changeset(%PickReport{}, %{})

    cond do
      is_map(pick.report) and pick.report.is_complete ->
        conn
        |> put_flash(:error, "This pick already has a completed report.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
      is_map(pick.report) ->
        conn
        |> redirect(to: Routes.admin_pick_report_path(conn, :fruit, pick))
      is_nil(pick.lead_picker) ->
        conn
        |> put_flash(:error, "You don't have permission to create this report")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
      pick.lead_picker.id == me.id ->
        render(conn, "new.html",
          pick: pick,
          changeset: changeset
        )
      true ->
        conn
        |> put_flash(:error, "You don't have permission to create this report")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    end
  end

  def create(conn, %{"pick_report" => report_params, "pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person
    attendees = Map.get(report_params, "attendees") || [] |> Enum.to_list()

    if pick.lead_picker.id == me.id do
      case Activities.create_report(report_params, pick, me, attendees) do
        {:ok, %{pick_report: report}} ->
          conn
          |> put_flash(:success, "Pick report attendance was successfully submitted. Please fill out fruit info next.")
          |> redirect(to: Routes.admin_pick_report_path(conn, :fruit, pick))
        {:error, :pick_report, %Ecto.Changeset{} = changeset, _} ->
          conn
          |> put_flash(:error, "There was an error submitting the report.")
          |> render("new.html",
            pick: pick,
            changeset: changeset
          )
      end
    else
      conn
      |> put_flash(:error, "You don't have permission to create this report")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    end
  end

  def fruit(conn, %{"pick_id" => pick_id}) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    cond do
      is_map(pick.report) and pick.report.is_complete ->
        conn
        |> put_flash(:error, "The pick report is already complete.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))

      is_map(pick.report) and pick.lead_picker.id == me.id ->
        case Activities.get_pick_report_by_pick_id(pick_id) do
          %PickReport{} = pick_report ->
            fruit_changesets = setup_fruit_changesets(pick)
            changeset = PickReport.changeset(pick_report, %{}) |> Ecto.Changeset.put_assoc(:fruits, fruit_changesets)

            render(conn, "fruit.html",
              pick: pick,
              changeset: changeset
            )
          nil ->
            conn
            |> put_flash(:error, "You must submit the attendance for the report first.")
            |> redirect(to: Routes.admin_pick_report_path(conn, :new, pick))
        end
      true ->
        conn
        |> put_flash(:error, "You must submit the attendance for the report first.")
        |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    end
  end

  def report_fruit(conn, %{"pick_report" => report_params, "pick_id" => pick_id} = params) do
    pick = Activities.get_pick!(pick_id)
    me = conn.assigns.current_person

    if is_map(pick.report) and pick.lead_picker.id == me.id do
      pick_report = Activities.get_pick_report_by_pick_id(pick_id)

      case Activities.complete_report(pick_report, report_params) do
        {:ok, report} ->
          if has_issue?(report) do
            email_admin_report_issue(pick)
          end

          conn
          |> put_flash(:info, "Pick report was successfully completed.")
          |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_flash(:error, "There was an error completing the report.")
          |> render("fruit.html",
            pick: pick,
            changeset: changeset
          )
      end
    else
      conn
      |> put_flash(:error, "You don't have permission to finish this report")
      |> redirect(to: Routes.admin_pick_path(conn, :show, pick))
    end
  end

  defp setup_fruit_changesets(%Pick{} = pick) do
    pick.trees
    |> Enum.map(fn tree -> tree.type end)
    |> Enum.sort()
    |> Enum.chunk_by(fn type -> type end)
    |> Enum.map(fn tree_type_list -> (if length(tree_type_list) > 1 do "#{hd(tree_type_list)} x#{length(tree_type_list)}" else hd(tree_type_list) end) end)
    |> Enum.map(fn tt ->
      PickFruit.changeset(%PickFruit{}, %{fruit_category: tt, pick_id: pick.id, pick_report_id: pick.report.id})
    end)
  end

  defp has_issue?(%PickReport{} = report) do
    report.has_equipment_set_issue or
    not report.has_fruit_delivered_to_agency or
    report.has_issues_on_site
  end

  defp email_admin_report_issue(%Pick{} = pick) do
    admins = Repo.all(Person.admins())

    Enum.each(admins, fn a ->
      a
      |> Email.admin_report_issue(pick)
      |> Mailer.deliver_later()
    end)
  end
end
