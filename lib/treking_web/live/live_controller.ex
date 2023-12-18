defmodule TrekingWeb.LiveController do
  use TrekingWeb, :live_view

  def mount(_params, _session, socket) do
    socket = allow_upload(socket, :results, accept: ~w(.xls .xlsx), max_entries: 1)

    race_options =
      Treking.get_races() |> Enum.map(&{&1.name, to_string(&1.id)}) |> Keyword.to_list()

    {:ok,
     assign(socket,
       col: [],
       rows: [],
       gender_options: [],
       first_name_options: [],
       last_name_options: [],
       birth_year_options: [],
       fin_options: [],
       country_options: [],
       delete_column_options: [],
       race_options: race_options
     )}
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
          <.input label="Race" type="select" name="race" options={@race_options} value={nil} />
          <.input
            label="Category"
            type="select"
            name="category"
            options={Treking.Schemas.Result.Category.__enums__()}
            value={nil}
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
    all_column_options = Enum.map(-1..column_size, & &1)

    socket =
      assign(socket,
        col: col,
        rows: rows,
        first_name_options: all_column_options,
        last_name_options: all_column_options,
        gender_options: all_column_options ++ ["M", "F"],
        delete_column_options: all_column_options,
        birth_year_options: all_column_options,
        fin_options: all_column_options,
        country_options: all_column_options
      )

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
          "category" => category
        },
        socket
      ) do
    birth_year_column = String.to_integer(birth_year_column)
    country_column = String.to_integer(country_column)
    first_name_column = String.to_integer(first_name_column)
    gender_column = String.to_integer(gender_column)
    last_name_column = String.to_integer(last_name_column)
    fin_column = String.to_integer(fin_column)

    rows = socket.assigns.rows

    Enum.map(rows, fn row ->
      %{
        first_name: Enum.at(row, first_name_column),
        last_name: Enum.at(row, last_name_column),
        birth_year: Enum.at(row, birth_year_column),
        gender: Enum.at(row, gender_column),
        country: Enum.at(row, country_column)
      }
    end)

    {:noreply, socket}
  end
end
