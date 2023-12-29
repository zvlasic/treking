defmodule Treking.TrekingTest do
  use Treking.DataCase, async: true

  alias Treking.Repo
  alias Treking.Schemas.{Race, Result, Runner}

  setup do
    races =
      for i <- 1..12 do
        Repo.insert!(%Race{name: "#{i}", date: Date.add(~D[2018-01-01], i)})
      end

    runner =
      Repo.insert!(%Runner{
        first_name: "male",
        last_name: "male surname",
        birth_year: 1980,
        gender: :m
      })

    {:ok, %{races: races, runner: runner}}
  end

  describe "point calculator" do
    test "works", %{runner: runner, races: races} do
      [race1, race2, race3 | _] = races
      insert_result(runner, race1, 10, :challenger)
      insert_result(runner, race2, 20, :challenger)

      [result] = Treking.calculate_points(:challenger, :m)

      assert result.runner.id == runner.id
      assert result.total_points == 85
      assert Map.get(result.per_race, race1.id) == 50
      assert Map.get(result.per_race, race2.id) == 35
      refute Map.get(result.per_race, race3.id)
    end

    test "takes only 8 races into account", %{races: races, runner: runner} do
      [race1, race2, race3, race4, race5, race6, race7, race8, race9 | _] = races
      insert_result(runner, race1, 1, :challenger)
      insert_result(runner, race2, 1, :challenger)
      insert_result(runner, race3, 1, :challenger)
      insert_result(runner, race4, 1, :challenger)
      insert_result(runner, race5, 1, :challenger)
      insert_result(runner, race6, 1, :challenger)
      insert_result(runner, race7, 1, :challenger)
      insert_result(runner, race8, 1, :challenger)
      insert_result(runner, race9, 10, :challenger)

      [result] = Treking.calculate_points(:challenger, :m)

      assert result.runner.id == runner.id
      assert result.total_points == 800
      assert Map.get(result.per_race, race1.id) == 100
      assert Map.get(result.per_race, race2.id) == 100
      assert Map.get(result.per_race, race3.id) == 100
      assert Map.get(result.per_race, race4.id) == 100
      assert Map.get(result.per_race, race5.id) == 100
      assert Map.get(result.per_race, race6.id) == 100
      assert Map.get(result.per_race, race7.id) == 100
      assert Map.get(result.per_race, race8.id) == 100
      refute Map.get(result.per_race, race9.id)
    end

    test "takes category into account" do
    end

    test "takes gender into account" do
    end
  end

  defp insert_result(runner, race, position, category, dnf \\ false) do
    Repo.insert!(%Result{
      race_id: race.id,
      runner_id: runner.id,
      position: position,
      category: category,
      points: Treking.get_points(position, dnf)
    })
  end
end
