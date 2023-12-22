defmodule Treking.Repo.Migrations.AddPointsToResult do
  use Ecto.Migration

  def change do
    alter table(:results) do
      add :points, :integer
    end
  end
end
