defmodule Mix.Tasks.Picks.Complete do
  @moduledoc """
  Update the status of picks to completed.

  Queries all of the picks to find "claimed" picks which have a scheduled
  date older than today. Also finds picks that have a scheduled date of
  today, but then confirms that the scheduled end time as already passed.
  """

  @shortdoc "Marks appropriate picks as completed"

  use Mix.Task

  import Ecto.Query, warn: false

  alias FruitPicker.Repo
  alias FruitPicker.Activities
  alias FruitPicker.Activities.Pick

  def run(_args) do
    Mix.Task.run("app.start")
    complete_picks()
  end

  def complete_picks do
    picks = find_all_claimed_picks_past_end_time()

    if picks == [] do
      Mix.shell.info("No picks require updating their status to completed.")
    end

    Enum.each(picks, fn pk ->
      update_pick_status_to_complete(pk)
      Mix.shell.info("Updated pick with id #{pk.id} to completed.")
    end)
  end

  defp update_pick_status_to_complete(%Pick{} = pick) do
    Repo.update!(Pick.complete_changeset(pick))
  end

  defp find_all_claimed_picks_past_end_time do
    today = Timex.now("America/Toronto") |> Timex.to_date()
    now = Time.utc_now() |> Time.add(-14_400, :second)

    picks = Pick
    |> where([p], p.status == "claimed" and p.scheduled_date < ^today)
    |> or_where([p], p.status == "claimed" and p.scheduled_date == ^today and p.scheduled_end_time < ^now)
    |> Repo.all()
  end
end
