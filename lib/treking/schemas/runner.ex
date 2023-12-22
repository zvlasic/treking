defmodule Treking.Schemas.Runner do
  use Treking.Schemas.Base

  defenum Gender, :gender, [:m, :f]

  schema "runners" do
    field :first_name, :string
    field :last_name, :string
    field :birth_year, :integer
    field :country, :string
    field :gender, Gender

    has_many :results, Treking.Schemas.Result

    timestamps()
  end

  @doc false
  def changeset(runner, attrs) do
    runner
    |> cast(attrs, [:first_name, :last_name, :birth_year, :country, :gender])
    |> validate_required([:first_name, :last_name])
  end
end
