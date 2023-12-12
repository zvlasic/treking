defmodule Treking.Schemas.Runner do
  use Ecto.Schema
  import Ecto.Changeset

  schema "runners" do
    field :first_name, :string
    field :last_name, :string
    field :birth_year, :integer
    field :country, :string

    timestamps()
  end

  @doc false
  def changeset(runner, attrs) do
    runner
    |> cast(attrs, [:first_name, :last_name, :birth_year, :country])
    |> validate_required([:first_name, :last_name, :birth_year, :country])
  end
end
