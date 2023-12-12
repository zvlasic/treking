defmodule TrekingWeb.LiveController do
  use TrekingWeb, :live_view

  def mount(_params, _session, socket) do
    socket = allow_upload(socket, :results, accept: ~w(.xls .xlsx), max_entries: 1)
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div id="result-upload">
      <form id="upload-form" phx-submit="save" phx-change="validate">
        <.live_file_input upload={@uploads.results} />
        <.button phx-disable-with="Uploading...">Upload</.button>
      </form>
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

    XlsxReader.open(file)

    {:noreply, socket}
  end

  def handle_event("validate", _params, socket), do: {:noreply, socket}
end
