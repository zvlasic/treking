defmodule TrekingWeb.LiveControllerTest do
  use TrekingWeb.ConnCase, async: true

  alias Treking.Repo
  alias Elixlsx.{Workbook, Sheet}

  setup do
    on_exit(fn -> path("autogen*") |> Path.wildcard() |> Enum.each(&File.rm!(&1)) end)
  end

  describe "uploads" do
    test "don't work without all needed params", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      prepare_upload(view, "test1.xlsx")

      assert render_click(view, "upload") =~ "Kornélia"

      assert render_click(view, "insert-results", %{}) =~ "Missing params"
    end

    test "don't work without selecting file", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert render_click(view, "upload") =~ "Select a file!"
    end

    test "work", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      prepare_upload(view, "test1.xlsx")

      assert render_click(view, "upload") =~ "Kornélia"

      race = Repo.all(Treking.Schemas.Race) |> hd()

      assert render_click(view, "insert-results", %{
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

    test "work 2", %{conn: conn} do
      sheet = %Sheet{
        name: "Sheet1",
        rows: [["First Name", "Last Name", "Position"], ["Marko", "Kos", 1], ["Ante", "Gelo", 2]]
      }

      Workbook.append_sheet(%Workbook{}, sheet)
      |> Elixlsx.write_to(path("autogen1.xlsx"))

      {:ok, view, _html} = live(conn, ~p"/")

      prepare_upload(view, "autogen1.xlsx")

      assert render_click(view, "upload") =~ "Marko"

      race = Repo.all(Treking.Schemas.Race) |> hd()

      assert render_click(view, "insert-results", %{
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

  defp prepare_upload(view, filename) do
    view
    |> file_input("#upload-form", :results, [%{name: filename, content: open_file!(filename)}])
    |> render_upload(filename)
  end

  defp open_file!(file_name), do: file_name |> path() |> File.read!()
  defp path(file_name), do: Path.join([:code.priv_dir(:treking), "results", file_name])
end
