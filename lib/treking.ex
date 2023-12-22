defmodule Treking do
  import Ecto.Query
  alias Treking.Repo
  alias Treking.Schemas.{Race, Result, Runner}

  @valid_races 8

  def calculate_points(category, gender) do
    category =
      case category do
        :challenger -> [:challenger, :ultra, :marathon]
        :active -> [:active]
      end

    runners =
      Repo.all(
        from runner in Runner,
          where: runner.gender == ^gender,
          preload: [results: ^from(result in Result, where: result.category in ^category)]
      )

    Enum.map(runners, fn %{results: results} = runner ->
      results = results |> Enum.sort_by(& &1.points, :desc) |> Enum.take(@valid_races)
      total_points = Enum.reduce(results, 0, fn result, acc -> acc + result.points end)
      per_race = results |> Enum.map(&{&1.race_id, &1.points}) |> Map.new()

      %{runner: runner, total_points: total_points, per_race: per_race}
    end)
  end

  def get_races, do: Repo.all(from race in Race, order_by: race.date)

  def points(position) do
    Map.get(
      %{
        1 => 100,
        2 => 85,
        3 => 75,
        4 => 70,
        5 => 65,
        6 => 62,
        7 => 59,
        8 => 56,
        9 => 53,
        10 => 50,
        11 => 48,
        12 => 46,
        13 => 44,
        14 => 42,
        15 => 40,
        16 => 39,
        17 => 38,
        18 => 37,
        19 => 36,
        20 => 35,
        21 => 34,
        22 => 33,
        23 => 32,
        24 => 31,
        25 => 30,
        26 => 29,
        27 => 28,
        28 => 27,
        29 => 26,
        30 => 25,
        31 => 24,
        32 => 23,
        33 => 22,
        34 => 21,
        35 => 20,
        36 => 19,
        37 => 18,
        38 => 17,
        39 => 16,
        40 => 15,
        41 => 14,
        42 => 13,
        43 => 12,
        44 => 11,
        45 => 10,
        46 => 9,
        47 => 8,
        48 => 7,
        49 => 6,
        50 => 5,
        nil => 1
      },
      position
    )
  end
end
