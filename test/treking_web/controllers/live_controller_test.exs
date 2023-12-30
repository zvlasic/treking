defmodule TrekingWeb.LiveControllerTest do
  use TrekingWeb.ConnCase, async: true

  alias Treking.Repo
  alias Elixlsx.{Sheet, Workbook}

  setup do
    on_exit(fn -> path("autogen*") |> Path.wildcard() |> Enum.each(&File.rm!(&1)) end)
  end

  describe "uploads" do
    test "don't work without all needed params", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      prepare_upload(view, "test1.xlsx")
      assert click_upload(view) =~ "Kornélia"
      assert click_insert(view, %{}) =~ "Missing params"
    end

    test "don't work without selecting file", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert click_upload(view) =~ "Select a file!"
    end

    test "don't work with selected column value out of range", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      prepare_upload(view, "test1.xlsx")
      assert click_upload(view) =~ "Kornélia"
      race = hd(Repo.all(Treking.Schemas.Race))

      params = %{
        "birth_year" => "5",
        "country" => "NO_COUNTRY",
        "fin" => "ALL_FIN",
        "first_name" => "8",
        "gender" => "F",
        "last_name" => "9",
        "race" => race.id,
        "position" => "0",
        "category" => "challenger"
      }

      params = Map.put(params, "birth_year", "-1")
      assert click_insert(view, params) =~ "Column out of range"

      params = Map.put(params, "birth_year", "100")
      assert click_insert(view, params) =~ "Column out of range"
    end

    test "work (existing file)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      prepare_upload(view, "test1.xlsx")
      assert click_upload(view) =~ "Kornélia"
      race = hd(Repo.all(Treking.Schemas.Race))

      assert click_insert(view, %{
               "birth_year" => "5",
               "country" => "NO_COUNTRY",
               "fin" => "ALL_FIN",
               "first_name" => "8",
               "gender" => "F",
               "last_name" => "9",
               "race" => race.id,
               "position" => "0",
               "category" => "challenger"
             }) =~ "Inserted 1 results!"
    end

    test "work (created file)", %{conn: conn} do
      file_name =
        create_file([
          ["First Name", "Last Name", "Position"],
          ["Marko", "Kos", 1],
          ["Ante", "Gelo", 2]
        ])

      {:ok, view, _html} = live(conn, ~p"/")
      prepare_upload(view, file_name)
      assert click_upload(view) =~ "Marko"
      race = hd(Repo.all(Treking.Schemas.Race))

      assert click_insert(view, %{
               "birth_year" => "NO_YEAR",
               "country" => "NO_COUNTRY",
               "fin" => "ALL_FIN",
               "first_name" => "0",
               "gender" => "M",
               "last_name" => "1",
               "race" => race.id,
               "position" => "2",
               "category" => "challenger"
             }) =~ "Inserted 2 results!"
    end
  end

  defp create_file(rows) do
    sheet = %Sheet{name: random_string(), rows: rows}
    filename = "autogen#{random_string()}.xlsx"
    path = path(filename)
    %Workbook{} |> Workbook.append_sheet(sheet) |> Elixlsx.write_to(path)
    filename
  end

  defp click_upload(view), do: render_click(view, "upload")
  defp click_insert(view, params), do: render_click(view, "insert-results", params)

  defp prepare_upload(view, filename) do
    view
    |> file_input("#upload-form", :results, [%{name: filename, content: open_file!(filename)}])
    |> render_upload(filename)
  end

  defp open_file!(file_name), do: file_name |> path() |> File.read!()
  defp path(file_name), do: Path.join([:code.priv_dir(:treking), "results", file_name])

  defp random_string(length \\ 10),
    do: :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
end
