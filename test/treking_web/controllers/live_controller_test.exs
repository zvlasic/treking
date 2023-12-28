defmodule TrekingWeb.LiveControllerTest do
  use TrekingWeb.ConnCase, async: true

  test "upload", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/")

    assert html =~ "Upload"

    results =
      file_input(view, "#upload-form", :results, [
        %{name: "challenger.xlsx", content: File.read!("challenger.xlsx")}
      ])

    render_upload(results, "challenger.xlsx")

    render_click(view, "save")

    element =
      view |> element("select#category") |> render() |> IO.inspect(label: "")
  end
end
