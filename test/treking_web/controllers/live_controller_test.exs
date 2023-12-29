defmodule TrekingWeb.LiveControllerTest do
  use TrekingWeb.ConnCase, async: true

  alias Treking.Repo

  test "upload without selecting file", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")
    assert render_click(view, "save") =~ "Select a file!"
  end

  test "upload with selecting file", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    results =
      file_input(view, "#upload-form", :results, [
        %{name: "challenger.xlsx", content: File.read!("challenger.xlsx")}
      ])

    render_upload(results, "challenger.xlsx")
    assert render_click(view, "save") =~ "Kornélia"
  end

  test "works", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/")

    results =
      file_input(view, "#upload-form", :results, [
        %{name: "challenger.xlsx", content: File.read!("challenger.xlsx")}
      ])

    render_upload(results, "challenger.xlsx")
    render_click(view, "save")

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
end
