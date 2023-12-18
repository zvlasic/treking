defmodule Treking.Repo.Migrations.CreateResult do
  use Ecto.Migration
  import EctoEnum

  defenum Category, :race_category, [:active, :challenger, :marathon, :ultra]

  def change do
    Category.create_type()

    create table(:results) do
      add :runner_id, references(:runners, on_delete: :delete_all, null: false)
      add :race_id, references(:races, on_delete: :delete_all, null: false)
      add :position, :integer
      add :category, Category.type()
      add :dnf, :boolean, default: false

      timestamps()
    end

    create unique_index(:results, [:runner_id, :race_id])
  end
end
