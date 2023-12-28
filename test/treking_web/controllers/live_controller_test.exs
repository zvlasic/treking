defmodule TrekingWeb.LiveControllerTest do
  use TrekingWeb.ConnCase, async: true

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
end
