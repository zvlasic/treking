defmodule TrekingWeb.LiveControllerTest do
  use TrekingWeb.ConnCase, async: true

  alias Treking.Repo
  alias Treking.Schemas.Result
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

      params = default_params()

      params = Map.put(params, "birth_year", "-1")
      assert click_insert(view, params) =~ "Column out of range"

      params = Map.put(params, "birth_year", "100")
      assert click_insert(view, params) =~ "Column out of range"
    end

    test "don't work with unselected race or category", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      prepare_upload(view, "test1.xlsx")
      assert click_upload(view) =~ "Kornélia"

      params = default_params()

      params = Map.put(params, "race", "")
      assert click_insert(view, params) =~ "Select race!"

      params = Map.put(params, "race", "uuid")
      params = Map.put(params, "category", "")
      assert click_insert(view, params) =~ "Select category!"
    end

    test "work (existing file)", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")
      prepare_upload(view, "test1.xlsx")
      assert click_upload(view) =~ "Kornélia"

      params = default_params()

      assert click_insert(view, params) =~ "Inserted 1 results!"
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

      params = default_generated_params()
      assert click_insert(view, params) =~ "Inserted 2 results!"
    end
  end

  test "handle invalid integer", %{conn: conn} do
    file_name =
      create_file([
        ["First Name", "Last Name", "Position"],
        ["Marko", "Kos", "s"]
      ])

    {:ok, view, _html} = live(conn, ~p"/")
    prepare_upload(view, file_name)
    assert click_upload(view) =~ "Marko"

    params = default_generated_params()
    assert click_insert(view, params) =~ "Invalid integer"
  end

  test "handle empty cell", %{conn: conn} do
    file_name =
      create_file([
        ["First Name", "Last Name", "Position"],
        ["", "Kos", "1"]
      ])

    {:ok, view, _html} = live(conn, ~p"/")
    prepare_upload(view, file_name)
    assert click_upload(view) =~ "Kos"

    params = default_generated_params()

    assert click_insert(view, params) =~ "Empty string"
  end

  test "handle invalid gender marker", %{conn: conn} do
    file_name =
      create_file([
        ["First Name", "Last Name", "Position", "Gender"],
        ["Marko", "Kos", 1, "G"]
      ])

    {:ok, view, _html} = live(conn, ~p"/")
    prepare_upload(view, file_name)
    assert click_upload(view) =~ "Marko"

    params = default_generated_params()
    params = Map.put(params, "gender", "3")

    assert click_insert(view, params) =~ "G not in gender markers"
  end

  test "handle invalid dnf marker", %{conn: conn} do
    file_name =
      create_file([
        ["First Name", "Last Name", "Position", "DNF"],
        ["Marko", "Kos", 1, "X"]
      ])

    {:ok, view, _html} = live(conn, ~p"/")
    prepare_upload(view, file_name)
    assert click_upload(view) =~ "Marko"

    params = default_generated_params()
    params = Map.put(params, "fin", "3")

    assert click_insert(view, params) =~ "X not in dnf markers"
  end

  test "handle invalid country", %{conn: conn} do
    file_name =
      create_file([
        ["First Name", "Last Name", "Position", "Country"],
        ["Marko", "Kos", 1, "M", "Ooga"]
      ])

    {:ok, view, _html} = live(conn, ~p"/")
    prepare_upload(view, file_name)
    assert click_upload(view) =~ "Marko"

    params = default_generated_params()
    params = Map.put(params, "country", "4")

    assert click_insert(view, params) =~ "Ooga is an unknown country"
  end

  test "gives zero points to sub 50 result", %{conn: conn} do
    file_name =
      create_file([
        ["First Name", "Last Name", "Position"],
        ["Marko", "Kos", 51]
      ])

    {:ok, view, _html} = live(conn, ~p"/")
    prepare_upload(view, file_name)
    assert click_upload(view) =~ "Marko"

    params = default_generated_params()

    assert click_insert(view, params) =~ "Inserted 1 results"

    assert Repo.all(Result) |> hd |> Map.get(:points) == 0
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

  defp default_params do
    %{
      "birth_year" => "5",
      "country" => "NO_COUNTRY",
      "fin" => "ALL_FIN",
      "first_name" => "8",
      "gender" => "F",
      "last_name" => "9",
      "race" => hd(Repo.all(Treking.Schemas.Race)).id,
      "position" => "0",
      "category" => "challenger"
    }
  end

  defp default_generated_params do
    %{
      "birth_year" => "NO_YEAR",
      "country" => "NO_COUNTRY",
      "fin" => "ALL_FIN",
      "first_name" => "0",
      "gender" => "M",
      "last_name" => "1",
      "race" => hd(Repo.all(Treking.Schemas.Race)).id,
      "position" => "2",
      "category" => "challenger"
    }
  end
end
