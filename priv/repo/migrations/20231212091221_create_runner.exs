defmodule Treking.Repo.Migrations.CreateRunner do
  use Ecto.Migration

  def change do
    create table(:runners) do
      add :first_name, :string, null: false
      add :last_name, :string, null: false
      add :birth_year, :integer
      add :country, :string

      timestamps()
    end
  end
end
