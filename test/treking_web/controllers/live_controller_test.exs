defmodule TrekingWeb.LiveControllerTest do
  use TrekingWeb.ConnCase, async: true

  alias Treking.Repo

  alias Elixlsx.{Workbook, Sheet}

  setup do
    on_exit(fn -> File.rm_rf!(path()) end)
  end

  describe "uploads" do
    test "don't work without all needed params", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      results =
        file_input(view, "#upload-form", :results, [
          %{name: "test1.xlsx", content: open_file!("test1.xlsx")}
        ])

      render_upload(results, "test1.xlsx")

      assert render_click(view, "save") =~ "Kornélia"

      assert render_click(view, "persist", %{}) =~ "Missing params"
    end

    test "don't work without selecting file", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      assert render_click(view, "save") =~ "Select a file!"
    end

    test "work", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      results =
        file_input(view, "#upload-form", :results, [
          %{name: "test1.xlsx", content: open_file!("test1.xlsx")}
        ])

      render_upload(results, "test1.xlsx")

      assert render_click(view, "save") =~ "Kornélia"

      race = Repo.all(Treking.Schemas.Race) |> hd()

      assert render_click(view, "persist", %{
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
      |> Elixlsx.write_to(path("hello.xlsx"))

      {:ok, view, _html} = live(conn, ~p"/")

      results =
        file_input(view, "#upload-form", :results, [
          %{name: "hello.xlsx", content: open_file!("hello.xlsx")}
        ])

      render_upload(results, "hello.xlsx")

      assert render_click(view, "save") =~ "Marko"

      race = Repo.all(Treking.Schemas.Race) |> hd()

      assert render_click(view, "persist", %{
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

  defp open_file!(file_name) do
    path = Path.join([:code.priv_dir(:treking), "results", file_name])
    File.read!(path)
  end

  defp path(file_name \\ ""), do: Path.join([:code.priv_dir(:treking), "results/test", file_name])
end
