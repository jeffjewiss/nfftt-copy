defmodule FruitPicker.Stats do
  @moduledoc """
  The Activities context.
  """

  import Ecto.Query, warn: false

  alias FruitPicker.Repo
  alias FruitPicker.Accounts.Person
  alias FruitPicker.Partners.Agency

  alias FruitPicker.Activities.{
    Pick,
    PickAttendance,
    PickFruit,
    PickPerson,
    PickReport
  }

  def tree_owner_season_stats(%Person{} = person) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> where(requester_id: ^person.id)
    |> where(status: "completed")
    |> where([pick], pick.scheduled_date > ^season_start)
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, fruit], %{
      "picks" => count(pick.id),
      "pounds_picked" => sum(fruit.total_pounds_picked),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def tree_owner_total_stats(%Person{} = person) do
    Pick
    |> where(requester_id: ^person.id)
    |> where(status: "completed")
    |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, fruit], %{
      "picks" => count(pick.id),
      "pounds_picked" => sum(fruit.total_pounds_picked),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def lead_picker_season_stats(%Person{} = person) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    lead_stats =
      Pick
      |> where(lead_picker_id: ^person.id)
      |> where(status: "completed")
      |> where([pick], pick.scheduled_date > ^season_start)
      |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
      |> select([pick, fruit], %{
        "picks" => count(pick.id),
        "pounds_picked" => sum(fruit.total_pounds_picked),
        "pounds_donated" => sum(fruit.total_pounds_donated)
      })
      |> Repo.one()

    attended_stats =
      Pick
      |> join(:inner, [pick], report in PickReport, on: report.pick_id == pick.id)
      |> where([pick, report], pick.status == "completed" and pick.scheduled_date > ^season_start)
      |> join(:left, [pick, report], attendance in PickAttendance,
        on: attendance.pick_report_id == report.id and attendance.person_id == ^person.id
      )
      |> where([pick, report, attendance], attendance.did_attend == true)
      |> join(:left, [pick, report, attendance], fruit in PickFruit, on: fruit.pick_id == pick.id)
      |> select([pick, report, attendance, fruit], %{
        "picks" => count(pick.id),
        "pounds_picked" => sum(fruit.total_pounds_picked),
        "pounds_donated" => sum(fruit.total_pounds_donated)
      })
      |> Repo.one()

    %{
      "picks_lead" => lead_stats["picks"],
      "picks_attended" => attended_stats["picks"],
      "pounds_picked" =>
        (lead_stats["pounds_picked"] || 0) + (attended_stats["pounds_picked"] || 0),
      "pounds_donated" =>
        (lead_stats["pounds_donated"] || 0) + (attended_stats["pounds_donated"] || 0)
    }
  end

  def lead_picker_total_stats(%Person{} = person) do
    lead_stats =
      Pick
      |> where(lead_picker_id: ^person.id)
      |> where(status: "completed")
      |> join(:left, [pick], fruit in PickFruit, on: fruit.pick_id == pick.id)
      |> select([pick, fruit], %{
        "picks" => count(pick.id),
        "pounds_picked" => sum(fruit.total_pounds_picked),
        "pounds_donated" => sum(fruit.total_pounds_donated)
      })
      |> Repo.one()

    attended_stats =
      Pick
      |> join(:inner, [pick], report in PickReport, on: report.pick_id == pick.id)
      |> where([pick, report], pick.status == "completed")
      |> join(:left, [pick, report], attendance in PickAttendance,
        on: attendance.pick_report_id == report.id and attendance.person_id == ^person.id
      )
      |> where([pick, report, attendance], attendance.did_attend == true)
      |> join(:left, [pick, report, attendance], fruit in PickFruit, on: fruit.pick_id == pick.id)
      |> select([pick, report, attendance, fruit], %{
        "picks" => count(pick.id),
        "pounds_picked" => sum(fruit.total_pounds_picked),
        "pounds_donated" => sum(fruit.total_pounds_donated)
      })
      |> Repo.one()

    %{
      "picks_lead" => lead_stats["picks"],
      "picks_attended" => attended_stats["picks"],
      "pounds_picked" =>
        (lead_stats["pounds_picked"] || 0) + (attended_stats["pounds_picked"] || 0),
      "pounds_donated" =>
        (lead_stats["pounds_donated"] || 0) + (attended_stats["pounds_donated"] || 0)
    }
  end

  def picker_season_stats(%Person{} = person) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> join(:inner, [pick], report in PickReport, on: report.pick_id == pick.id)
    |> where([pick, report], pick.status == "completed" and pick.scheduled_date > ^season_start)
    |> join(:left, [pick, report], attendance in PickAttendance,
      on: attendance.pick_report_id == report.id and attendance.person_id == ^person.id
    )
    |> where([pick, report, attendance], attendance.did_attend == true)
    |> join(:left, [pick, report, attendance], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, report, attendance, fruit], %{
      "picks" => count(pick.id),
      "pounds_picked" => sum(fruit.total_pounds_picked),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def picker_total_stats(%Person{} = person) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> join(:inner, [pick], report in PickReport, on: report.pick_id == pick.id)
    |> where([pick, report], pick.status == "completed")
    |> join(:left, [pick, report], attendance in PickAttendance,
      on: attendance.pick_report_id == report.id and attendance.person_id == ^person.id
    )
    |> where([pick, report, attendance], attendance.did_attend == true)
    |> join(:left, [pick, report, attendance], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, report, attendance, fruit], %{
      "picks" => count(pick.id),
      "pounds_picked" => sum(fruit.total_pounds_picked),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def agency_season_stats(%Person{} = person) do
    today = Date.utc_today()
    {:ok, season_start} = Date.new(today.year, 5, 1)

    Pick
    |> join(:left, [pick], agency in Agency, on: agency.id == pick.agency_id)
    |> where([pick, agency], agency.partner_id == ^person.id and pick.status == "completed")
    |> where([pick, _], pick.scheduled_date > ^season_start)
    |> join(:left, [pick, _], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, _, fruit], %{
      "picks" => count(pick.id),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def agency_total_stats(%Person{} = person) do
    Pick
    |> join(:left, [pick], agency in Agency, on: agency.id == pick.agency_id)
    |> where([pick, agency], agency.partner_id == ^person.id and pick.status == "completed")
    |> join(:left, [pick, _], fruit in PickFruit, on: fruit.pick_id == pick.id)
    |> select([pick, _, fruit], %{
      "picks" => count(pick.id),
      "pounds_donated" => sum(fruit.total_pounds_donated)
    })
    |> Repo.one()
  end

  def get_missed_picks_count(%Person{} = person) do
    year = Date.utc_today().year

    beginning = Date.from_erl!({year, 1, 1})
    ending = Date.from_erl!({year, 12, 31})

    PickAttendance
    |> where([pa], did_attend: false)
    |> join(:inner, [pa], pr in PickReport, on: pa.pick_report_id == pr.id)
    |> join(:inner, [pa, pr], p in Pick, on: pr.pick_id == p.id)
    |> where([pa, pr, p], pa.person_id == ^person.id)
    |> where([pa, pr, p], p.scheduled_date >= ^beginning)
    |> where([pa, pr, p], p.scheduled_date <= ^ending)
    |> Repo.aggregate(:count, :id)
  end
end
