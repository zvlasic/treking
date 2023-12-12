defmodule TrekingWeb.LiveController do
  use TrekingWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :message, "Hello World")}
  end

  def render(assigns) do
    ~H"""
    <div class="container">
      <div class="row">
        <div class="col-12">
          <h1><%= @message %></h1>
        </div>
      </div>
    </div>
    """
  end
end
