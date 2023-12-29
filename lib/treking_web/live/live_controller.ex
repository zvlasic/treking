defmodule TrekingWeb.LiveController do
  use TrekingWeb, :live_view

  import Ecto.Query

  alias Treking.Repo
  alias Treking.Schemas.{Result, Runner}

  @male_markers ["Muški", "M"]
  @female_markers ["Ženski", "Ž", "F"]

  @dnf_markers ["DNF"]
  @fin_markers ["FIN"]

  def mount(_params, _session, socket) do
    socket = allow_upload(socket, :results, accept: ~w(.xls .xlsx), max_entries: 1)

    race_options =
      Treking.get_races()
      |> Enum.map(&{&1.name, to_string(&1.id)})
      |> Keyword.to_list()
      |> Kernel.++([{"Select race", ""}])

    category_options = Result.Category.__enums__() ++ [""]

    {:ok,
     socket
     |> assign(
       col: [],
       rows: [],
       gender_options: [],
       first_name_options: [],
       last_name_options: [],
       birth_year_options: [],
       fin_options: [],
       country_options: [],
       delete_column_options: [],
       position_options: [],
       race_options: race_options,
       category_options: category_options
     )
     |> clear_flash()}
  end

  def render(assigns) do
    ~H"""
    <div id="uploads">
      <form id="upload-form" phx-submit="save" phx-change="validate">
        <.live_file_input upload={@uploads.results} />
        <.button phx-disable-with="Uploading...">Upload</.button>
      </form>
    </div>
    <div class="flex h-screen bg-gray-100">
      <div class="w-64 bg-white p-4 shadow-lg flex-shrink-0">
        <form phx-submit="persist">
          <.input
            label="Delete column"
            type="select"
            name="delete_column"
            options={@delete_column_options}
            value="-1"
            phx-change="delete_column"
          />
          <.input
            label="First name"
            type="select"
            name="first_name"
            options={@first_name_options}
            value="-1"
          />
          <.input
            label="Last name"
            type="select"
            name="last_name"
            options={@last_name_options}
            value="-1"
          />
          <.input label="Gender" type="select" name="gender" options={@gender_options} value="-1" />
          <.input label="Country" type="select" name="country" options={@country_options} value="-1" />
          <.input
            label="Birth year"
            type="select"
            name="birth_year"
            options={@birth_year_options}
            value="-1"
          />
          <.input label="FIN" type="select" name="fin" options={@fin_options} value="-1" />
          <.input
            label="Position"
            type="select"
            name="position"
            options={@position_options}
            value="-1"
          />
          <.input label="Race" type="select" name="race" options={@race_options} value="" />
          <.input
            id="category"
            label="Category"
            type="select"
            name="category"
            options={@category_options}
            value=""
          />
          <.button>Persist</.button>
        </form>
      </div>

      <div class="flex-1 p-10 overflow-auto">
        <table id="results-table" class="min-w-full border-separate border-spacing-0">
          <thead>
            <tr>
              <%= for i  <- 0..length(@col) - 1 do %>
                <th
                  scope="col"
                  class="sticky top-0 z-10 border-b border-gray-300 bg-white bg-opacity-75 py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 backdrop-blur backdrop-filter sm:pl-6 lg:pl-8"
                >
                  <%= "#{i} #{Enum.at(@col, i)}" %>
                </th>
              <% end %>
            </tr>
          </thead>
          <tbody>
            <%= for row <- @rows do %>
              <tr>
                <%= for data <- row do %>
                  <td class="whitespace-nowrap border-b border-gray-200 py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-6 lg:pl-8">
                    <%= data %>
                  </td>
                <% end %>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def handle_event("save", _, %{assigns: %{uploads: %{results: %{entries: []}}}} = socket),
    do: {:noreply, put_flash(socket, :error, "Select a file!")}

  def handle_event("save", _params, socket) do
    [file] =
      consume_uploaded_entries(socket, :results, fn %{path: path}, entry ->
        dest =
          Path.join([
            :code.priv_dir(:treking),
            "static",
            "uploads",
            "#{entry.uuid}-#{entry.client_name}"
          ])

        File.cp!(path, dest)
        {:ok, static_path(socket, dest)}
      end)

    {:ok, package} = XlsxReader.open(file)
    [sheet_name] = XlsxReader.sheet_names(package)
    {:ok, [col | rows]} = XlsxReader.sheet(package, sheet_name)

    column_size = Enum.count(col)
    all_column_options = Enum.map(-1..(column_size - 1), & &1)

    socket =
      socket
      |> assign(
        col: col,
        rows: rows,
        first_name_options: all_column_options,
        last_name_options: all_column_options,
        gender_options: all_column_options ++ ["M", "F"],
        delete_column_options: all_column_options,
        birth_year_options: all_column_options ++ ["NO_YEAR"],
        fin_options: all_column_options ++ ["ALL_FIN"],
        country_options: all_column_options ++ ["NO_COUNTRY"],
        position_options: all_column_options
      )
      |> clear_flash()

    File.rm(file)

    {:noreply, socket}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}

  def handle_event("delete_column", %{"delete_column" => delete_column}, socket) do
    delete_column = String.to_integer(delete_column)
    rows = Enum.filter(socket.assigns.rows, &(Enum.at(&1, delete_column) != ""))
    {:noreply, assign(socket, :rows, rows)}
  end

  def handle_event(
        "persist",
        %{
          "birth_year" => birth_year_column,
          "country" => country_column,
          "fin" => fin_column,
          "first_name" => first_name_column,
          "gender" => gender_column,
          "last_name" => last_name_column,
          "race" => race_id,
          "position" => position_column,
          "category" => category
        },
        socket
      ) do
    birth_year_column = parse_column_value(birth_year_column)
    country_column = parse_column_value(country_column)
    first_name_column = parse_column_value(first_name_column)
    gender_column = parse_column_value(gender_column)
    last_name_column = parse_column_value(last_name_column)
    fin_column = parse_column_value(fin_column)
    position_column = parse_column_value(position_column)

    prepared_data =
      Enum.reduce_while(socket.assigns.rows, {:ok, []}, fn row, {:ok, acc} ->
        with {:ok, first_name} <- parse_name(row, first_name_column),
             {:ok, last_name} <- parse_name(row, last_name_column),
             {:ok, gender} <- parse_gender(row, gender_column),
             {:ok, birth_year} <- parse_birth_year(row, birth_year_column),
             {:ok, dnf} <- parse_dnf(row, fin_column),
             {:ok, position} <- parse_position(row, position_column, dnf),
             {:ok, country} <- parse_country(row, country_column),
             {:ok, race_id} <- validate_race_id(race_id),
             {:ok, category} <- validate_category(category),
             {:ok, points} <- Treking.fetch_points(position, dnf) do
          {:cont,
           {:ok,
            [
              %{
                first_name: first_name,
                last_name: last_name,
                gender: gender,
                birth_year: birth_year,
                dnf: dnf,
                position: position,
                country: country,
                race_id: race_id,
                category: category,
                points: points
              }
            ] ++ acc}}
        else
          error -> {:halt, error}
        end
      end)

    with {:ok, prepared_data} <- prepared_data,
         prepared_data <- Enum.filter(prepared_data, & &1.points),
         {:ok, inserted_results} <- insert(prepared_data) do
      {:noreply, put_flash(socket, :info, "Inserted #{length(inserted_results)} results!")}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, put_flash(socket, :error, inspect(changeset))}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, reason)}
    end
  end

  defp parse_column_value(column) do
    case Integer.parse(column) do
      :error -> column
      {value, _} -> value
    end
  end

  defp parse_name(row, column) do
    with {:ok, value} <- get_column_value(row, column),
         :ok <- check_empty(value),
         do: {:ok, value |> String.trim() |> String.upcase()}
  end

  defp parse_gender(_, "M"), do: {:ok, :m}
  defp parse_gender(_, "F"), do: {:ok, :f}

  defp parse_gender(row, column) do
    with {:ok, value} <- get_column_value(row, column),
         :ok <- check_empty(value),
         do: extract_gender(value)
  end

  defp parse_birth_year(_, "NO_YEAR"), do: {:ok, nil}

  defp parse_birth_year(row, column) do
    with {:ok, value} <- get_column_value(row, column),
         do: parse_integer(value)
  end

  def parse_dnf(_row, "ALL_FIN"), do: {:ok, false}

  def parse_dnf(row, column) do
    with {:ok, value} <- get_column_value(row, column),
         :ok <- check_empty(value),
         do: extract_dnf(value)
  end

  defp parse_position(_, _, true), do: {:ok, nil}

  defp parse_position(row, column, _) do
    with {:ok, value} <- get_column_value(row, column),
         do: parse_integer(value)
  end

  defp parse_country(_, "NO_COUNTRY"), do: {:ok, nil}

  defp parse_country(row, column) do
    with {:ok, value} <- get_column_value(row, column),
         :ok <- check_empty(value),
         do: Treking.fetch_country(value)
  end

  defp validate_race_id(""), do: {:error, "Select race!"}
  defp validate_race_id(race_id), do: {:ok, race_id}

  defp validate_category(""), do: {:error, "Select category!"}
  defp validate_category(category_id), do: {:ok, category_id}

  defp get_column_value(row, column) do
    if column < 0 || column > Enum.count(row) - 1,
      do: {:error, "Column out of range"},
      else: {:ok, Enum.at(row, column)}
  end

  defp check_empty(value),
    do: if(String.length(value) > 0, do: :ok, else: {:error, "Empty string"})

  defp insert(data) do
    Repo.transaction(fn ->
      response =
        Enum.reduce_while(data, [], fn row, acc ->
          with {:ok, runner} <- fetch_or_insert_runner(row),
               {:ok, result} <- insert_result(runner, row) do
            {:cont, [result | acc]}
          else
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

      case response do
        {:error, reason} -> Repo.rollback(reason)
        results -> results
      end
    end)
  end

  defp fetch_or_insert_runner(data) do
    query =
      from(r in Runner,
        where: r.first_name == ^data.first_name,
        where: r.last_name == ^data.last_name,
        where: r.gender == ^data.gender,
        select: r
      )
      |> filter_by_birth_year(data.birth_year)
      |> filter_by_country(data.country)

    case Repo.one(query) do
      nil -> insert_runner(data)
      runner -> {:ok, runner}
    end
  end

  defp insert_runner(data), do: %Runner{} |> Runner.changeset(data) |> Repo.insert()

  defp insert_result(runner, data),
    do: %Result{} |> Result.changeset(Map.put(data, :runner_id, runner.id)) |> Repo.insert()

  defp filter_by_birth_year(query, nil), do: query
  defp filter_by_birth_year(query, birth_year), do: where(query, [r], r.birth_year == ^birth_year)
  defp filter_by_country(query, nil), do: query
  defp filter_by_country(query, country), do: where(query, [r], r.country == ^country)

  defp extract_gender(value) when value in @male_markers, do: {:ok, :m}
  defp extract_gender(value) when value in @female_markers, do: {:ok, :f}
  defp extract_gender(value), do: {:error, "#{value} not in gender markers"}

  defp parse_integer(nil), do: {:ok, nil}
  defp parse_integer(""), do: {:ok, nil}
  defp parse_integer(value) when is_binary(value), do: {:ok, String.to_integer(value)}
  defp parse_integer(value) when is_float(value), do: {:ok, trunc(value)}
  defp parse_integer(value) when is_integer(value), do: {:ok, value}
  defp parse_integer(_), do: {:error, "Invalid integer"}

  defp extract_dnf(value) when value in @dnf_markers, do: {:ok, true}
  defp extract_dnf(value) when value in @fin_markers, do: {:ok, false}
  defp extract_dnf(value), do: {:error, "#{value} not in dnf markers"}
end
