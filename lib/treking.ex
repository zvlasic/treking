defmodule Treking do
  import Ecto.Query
  alias Treking.Repo
  alias Treking.Schemas.{Race, Result, Runner}

  @valid_races 8
  @dnf_points 1
  @break_off_points 5

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

    runners
    |> Enum.map(fn %{results: results} = runner ->
      results = results |> Enum.sort_by(& &1.points, :desc) |> Enum.take(@valid_races)
      total_points = Enum.reduce(results, 0, fn result, acc -> acc + result.points end)
      per_race = results |> Enum.map(&{&1.race_id, &1.points}) |> Map.new()

      %{runner: runner, total_points: total_points, per_race: per_race}
    end)
    |> Enum.sort(&(&1.total_points > &2.total_points))
  end

  def get_races, do: Repo.all(from race in Race, order_by: race.date)

  def get_points(_, true), do: @dnf_points

  def get_points(position, _) do
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
        50 => 5
      },
      position,
      @break_off_points
    )
  end

  def fetch_country(input) do
    country =
      Map.get(
        %{
          "AUS - Australia" => "AUSTRALIJA",
          "Austria" => "AUSTRIJA",
          "AUT - Austria" => "AUSTRIJA",
          "AUT" => "AUSTRIJA",
          "BEL - Belgium" => "BELGIJA",
          "BEL" => "BELGIJA",
          "Belgium" => "BELGIJA",
          "BIH - Bosnia and Herzegovina" => "BIH",
          "B i H" => "BIH",
          "Bosnia and Herzegovina" => "BIH",
          "BIH" => "BIH",
          "BRA - Brazil" => "BRAZIL",
          "CAN - Canada" => "KANADA",
          "CRO - Croatia" => "HRVATSKA",
          "CRO" => "HRVATSKA",
          "Croatia (Hrvatska)" => "HRVATSKA",
          "Hrvatska" => "HRVATSKA",
          "CZE - Czech Republic" => "ČEŠKA",
          "CZE" => "ČEŠKA",
          "Ceska Republika" => "ČEŠKA",
          "DEN - Denmark" => "DANSKA",
          "ESP - Spain" => "Španjolska",
          "España" => "Španjolska",
          "FIN - Finland" => "FINSKA",
          "FIN" => "FINSKA",
          "FRA - France" => "FRANCUSKA",
          "FRA" => "FRANCUSKA",
          "GBR - Great Britain" => "VELIKA BRITANIJA",
          "GBR" => "VELIKA BRITANIJA",
          "GER - Germany" => "NJEMAČKA",
          "GER" => "NJEMAČKA",
          "GRE - Greece" => "GRČKA",
          "Germany" => "NJEMAČKA",
          "Deutschland" => "NJEMAČKA",
          "HUN - Hungary" => "MAĐARSKA",
          "HUN" => "MAĐARSKA",
          "Magyarorszag" => "MAĐARSKA",
          "IND - India" => "INDIJA",
          "IRL - Ireland" => "IRSKA",
          "Irska" => "IRSKA",
          "ISR - Israel" => "IZRAEL",
          "Italy" => "ITALIJA",
          "Italia" => "ITALIJA",
          "ITA - Italy" => "ITALIJA",
          "ITA" => "ITALIJA",
          "MEX" => "MEKSIKO",
          "Japan" => "JAPAN",
          "LUX - Luxembourg" => "Luksemburg",
          "MKD - Macedonia" => "MAKEDONIJA",
          "North Macedonia" => "MAKEDONIJA",
          "MNE - Montenegro" => "CRNA GORA",
          "Montenegro" => "CRNA GORA",
          "NED - Netherlands" => "NIZOZEMSKA",
          "NED" => "NIZOZEMSKA",
          "ROU - Romania" => "RUMUNJSKA",
          "Nizozemska" => "NIZOZEMSKA",
          "NOR - Norway" => "NORVEŠKA",
          "NZL - New Zealand" => "NOVI ZELAND",
          "Österreich" => "AUSTRIJA",
          "POL - Poland" => "POLJSKA",
          "POL" => "POLJSKA",
          "POR - Portugal" => "PORTUGAL",
          "Portugal" => "PORTUGAL",
          "Polska" => "POLJSKA",
          "QAT - Qatar" => "KATAR",
          "Qatar" => "KATAR",
          "Russian Federation" => "RUSKA FEDERACIJA",
          "SAD" => "SAD",
          "SLO - Slovenia" => "SLOVENIJA",
          "SRB - Serbia" => "SRBIJA",
          "SUI - Switzerland" => "ŠVICARSKA",
          "SVK - Slovakia" => "SLOVAČKA",
          "SVK" => "SLOVAČKA",
          "SWE - Sweden" => "ŠVEDSKA",
          "United Kingdom" => "VELIKA BRITANIJA",
          "USA - United States" => "SAD",
          "USA" => "SAD",
          "United States of America" => "SAD",
          "Srbija" => "SRBIJA",
          "Serbia" => "SRBIJA",
          "Slovenia" => "SLOVENIJA",
          "Slovenija" => "SLOVENIJA",
          "SLO" => "SLOVENIJA"
        },
        input
      )

    case country do
      nil -> {:error, "#{input} is an unknown country"}
      value -> {:ok, value}
    end
  end
end
