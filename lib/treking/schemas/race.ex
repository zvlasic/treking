defmodule Treking.Schemas.Race do
  use Ecto.Schema
  import Ecto.Changeset

  schema "races" do
    field :name, :string
    field :date, :date

    timestamps()
  end

  @doc false
  def changeset(race, attrs) do
    race
    |> cast(attrs, [:name, :date])
    |> validate_required([:name, :date])
  end
end
