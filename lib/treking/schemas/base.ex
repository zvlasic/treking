defmodule Treking.Schemas.Base do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset
      import EctoEnum

      alias Treking.Repo

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id

      @type t :: %__MODULE__{}
    end
  end
end
