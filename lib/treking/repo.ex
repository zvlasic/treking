defmodule Treking.Repo do
  use Ecto.Repo,
    otp_app: :treking,
    adapter: Ecto.Adapters.Postgres
end
