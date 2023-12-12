defmodule Treking.Repo.Migrations.CreateResult do
  use Ecto.Migration

  def change do
    execute "CREATE TYPE race_category AS ENUM ('ACTIVE', 'CHALLENGER', 'MARATHON', 'ULTRA')"

    create table(:results) do
      add :runner_id, references(:runners, on_delete: :delete_all, null: false)
      add :race_id, references(:races, on_delete: :delete_all, null: false)
      add :position, :integer
      add :category, :race_category
      add :dnf, :boolean, default: false

      timestamps()
    end

    create unique_index(:results, [:runner_id, :race_id])
  end
end
