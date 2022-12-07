defmodule Mix.Tasks.Picks.PickersDailyEmail do
  @moduledoc """
  Send out an email with available pick info to active fruit pickers.
  """

  @shortdoc "Send pickers available picks email"

  use Mix.Task

  import Ecto.Query, warn: false
  import Logger

  alias FruitPicker.{Mailer, Repo}
  alias FruitPicker.Accounts.Person
  alias FruitPicker.Activities.{Pick, PickPerson}
  alias FruitPickerWeb.Email

  def run(_args) do
    Mix.Task.run("app.start")
    send_out_email()
  end

  def send_out_email do
    picks = find_all_available_picks

    if length(picks) > 0 do
      pick_ids = Enum.map(picks, fn p -> p.id end) |> Enum.join(", ")
      pickers = find_all_active_pickers

      Enum.each(pickers, fn person ->
        person
        |> Email.daily_picks_available_email(picks)
        |> Mailer.deliver_later()
      end)
    else
      Logger.info("Not sending out the daily pickers email. No picks with spots available.")
    end
  end

  defp find_all_available_picks do
    today = Date.utc_today()

    picks = Pick
    |> where(status: "claimed")
    |> where([p], p.scheduled_date >= ^today)
    |> where([p], not p.is_private == true)
    |> limit(10)
    |> order_by(asc: :scheduled_date)
    |> Pick.preload_all()
    |> Repo.all()

    # TODO: can this be done as a query?
    Enum.reject(picks, fn pick ->
      length(pick.pickers) >= pick.volunteers_max
    end)
  end

  defp find_all_active_pickers do
    Person
    |> where(accepts_portal_communications: true)
    |> where(accepts_consent_picker: true)
    |> where(membership_is_active: true)
    |> where(is_picker: true)
    |> Repo.all()
  end
end
