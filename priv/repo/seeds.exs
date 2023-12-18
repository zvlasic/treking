# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Treking.Repo.insert!(%Treking.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

# Insert a race

alias Treking.Repo
alias Treking.Schemas.Race

Repo.insert(%Race{name: "Krk", date: ~D[2000-01-01]})
Repo.insert(%Race{name: "Rab", date: ~D[2000-02-02]})
