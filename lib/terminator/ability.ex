defmodule Terminator.Ability do
  @moduledoc """
  Ability is main representation of a single permission
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @typedoc "An ability struct"
  @type t :: %Ability{}

  schema "terminator_abilities" do
    field(:identifier, :string)
    field(:name, :string)

    timestamps()
  end

  def changeset(%Ability{} = struct, params \\ %{}) do
    struct
    |> cast(params, [:identifier, :name])
    |> validate_required([:identifier, :name])
    |> unique_constraint(:identifier, message: "Ability already exists")
  end

  def build(identifier, name) do
    changeset(%Ability{}, %{
      identifier: identifier,
      name: name
    })
  end
end
