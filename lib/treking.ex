defmodule Treking do
  import Ecto.Query
  alias Treking.Repo
  alias Treking.Schemas.{Race, Result, Runner}
  alias Elixlsx.{Sheet, Workbook}

  @valid_races 8
  @dnf_points 1
  @break_off_points 5

  def create_all do
    sheets =
      Enum.map(
        [
          {"CHALLENGER MUŠKI", :challenger, :m},
          {"CHALLENGER ŽENSKI", :challenger, :f},
          {"ACTIVE MUŠKI", :active, :m},
          {"ACTIVE ŽENSKI", :active, :f}
        ],
        fn {sheet_name, category, gender} ->
          points_data = calculate_points(category, gender)
          create_sheet(sheet_name, points_data)
        end
      )

    workbook = %Workbook{sheets: sheets}
    Elixlsx.write_to(workbook, "results.xlsx")
  end

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
    |> Enum.filter(&(&1.results != []))
    |> Enum.map(fn %{results: results} = runner ->
      results = results |> Enum.sort_by(& &1.points, :desc) |> Enum.take(@valid_races)
      total_points = Enum.reduce(results, 0, fn result, acc -> acc + result.points end)
      per_race = results |> Enum.map(&{&1.race_id, &1.points}) |> Map.new()

      %{runner: runner, total_points: total_points, per_race: per_race}
    end)
    |> Enum.sort(&(&1.total_points > &2.total_points))
  end

  def create_sheet(sheet_name, results) do
    races = get_races()

    headers = ["#", "Ime", "Prezime", "Godina", "Država", "Ukupno"]
    headers = Enum.reduce(races, headers, fn race, acc -> acc ++ [race.name] end)

    {_, _, rows} =
      Enum.reduce(results, {1, nil, []}, fn %{
                                              runner: runner,
                                              total_points: total_points,
                                              per_race: per_race
                                            },
                                            {position, last_points, rows} ->
        printed_position = if total_points == last_points, do: "", else: position
        last_points = if total_points == last_points, do: last_points, else: total_points

        row =
          [
            printed_position,
            runner.first_name,
            runner.last_name,
            to_string(runner.birth_year),
            runner.country || "",
            total_points
          ]

        row =
          Enum.reduce(races, row, fn race, acc ->
            points = Map.get(per_race, race.id, "")
            acc ++ [points]
          end)

        {position + 1, last_points, rows ++ [row]}
      end)

    %Sheet{name: sheet_name, rows: [headers | rows]}
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
          "AFG - Afghanistan" => "AFGANISTAN",
          "BEL - Belgium" => "BELGIJA",
          "BEL" => "BELGIJA",
          "Belgium" => "BELGIJA",
          "BIH - Bosnia and Herzegovina" => "BIH",
          "B i H" => "BIH",
          "Bosnia and Herzegovina" => "BIH",
          "BIH" => "BIH",
          "BRA - Brazil" => "BRAZIL",
          "CAN - Canada" => "KANADA",
          "CAN" => "KANADA",
          "CRO - Croatia" => "HRVATSKA",
          "CRO" => "HRVATSKA",
          "Croatia (Hrvatska)" => "HRVATSKA",
          "Hrvatska" => "HRVATSKA",
          "CZE - Czech Republic" => "ČEŠKA",
          "CZE" => "ČEŠKA",
          "Ceska Republika" => "ČEŠKA",
          "DEN - Denmark" => "DANSKA",
          "ESP - Spain" => "Španjolska",
          "ESP" => "Španjolska",
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
          "MKD" => "MAKEDONIJA",
          "North Macedonia" => "MAKEDONIJA",
          "MNE - Montenegro" => "CRNA GORA",
          "MLT" => "MALTA",
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
          "SRB" => "SRBIJA",
          "Polska" => "POLJSKA",
          "QAT - Qatar" => "KATAR",
          "Qatar" => "KATAR",
          "Russian Federation" => "RUSIJA",
          "RUS" => "RUSIJA",
          "SAD" => "SAD",
          "SLO - Slovenia" => "SLOVENIJA",
          "SRB - Serbia" => "SRBIJA",
          "SUI - Switzerland" => "ŠVICARSKA",
          "SVK - Slovakia" => "SLOVAČKA",
          "SVK" => "SLOVAČKA",
          "SWE - Sweden" => "ŠVEDSKA",
          "SWE" => "ŠVEDSKA",
          "EST" => "ESTONIJA",
          "LUX" => "LUKSEMBURG",
          "United Kingdom" => "VELIKA BRITANIJA",
          "USA - United States" => "SAD",
          "USA" => "SAD",
          "United States of America" => "SAD",
          "Srbija" => "SRBIJA",
          "Serbia" => "SRBIJA",
          "Slovenia" => "SLOVENIJA",
          "Slovenija" => "SLOVENIJA",
          "SLO" => "SLOVENIJA",
          "CZE - Czechia" => "ČEŠKA",
          "KGZ - Kyrgyzstan" => "KIRGISTAN",
          "UKR - Ukraine" => "UKRAJINA",
          "MHL - Marshall Islands" => "MARŠALSKI OTOCI",
          "CHN - China" => "KINA",
          "RUS - Russia" => "RUSIJA",
          "HAI - Haiti" => "HAITI"
        },
        input
      )

    case country do
      nil -> {:error, "#{input} is an unknown country"}
      value -> {:ok, value}
    end
  end
end
