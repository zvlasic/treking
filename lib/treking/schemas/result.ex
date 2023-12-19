defmodule Treking.Schemas.Result do
  use Treking.Schemas.Base

  defenum Category, :category, [:active, :challenger, :marathon, :ultra]
  @attributes [:runner_id, :race_id, :position, :category, :dnf]
  @mandatory [:runner_id, :race_id, :category]

  schema "results" do
    belongs_to :runner, Treking.Schemas.Runner
    belongs_to :race, Treking.Schemas.Race

    field :position, :integer
    field :category, Category
    field :dnf, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(result, attrs) do
    result
    |> cast(attrs, @attributes)
    |> unique_constraint(:race_id, name: "results_runner_id_race_id_index")
    |> validate_required(@mandatory)
  end
end
