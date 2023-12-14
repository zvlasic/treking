defmodule Treking.Schemas.Result do
  use Ecto.Schema
  import Ecto.Changeset
  import EctoEnum

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  defenum Gender, :gender, [:m, :f]

  schema "results" do
    belongs_to :runner, Treking.Schemas.Runner, foreign_key: :runner_id, type: :id
    belongs_to :race, Treking.Schemas.Race, foreign_key: :race_id, type: :id

    field :position, :integer
    field :category, :string
    field :dnf, :boolean, default: false
    field :gender, Gender

    timestamps()
  end

  @doc false
  def changeset(result, attrs) do
    result
    |> cast(attrs, [:runner_id, :race_id, :position, :category, :dnf])
    |> validate_required([:runner_id, :race_id, :position, :category])
  end
end
