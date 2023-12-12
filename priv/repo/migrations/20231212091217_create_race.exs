defmodule Treking.Repo.Migrations.CreateRace do
  use Ecto.Migration

  def change do
    create table(:races) do
      add :name, :string, null: false
      add :date, :date, null: false

      timestamps()
    end
  end
end
