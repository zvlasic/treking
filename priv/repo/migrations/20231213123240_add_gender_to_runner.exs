defmodule Treking.Repo.Migrations.AddGenderToRunner do
  use Ecto.Migration
  import EctoEnum

  defenum Gender, :gender, [:m, :f]

  def change do
    Gender.create_type()

    alter table(:runners) do
      add :gender, Gender.type()
    end
  end
end
