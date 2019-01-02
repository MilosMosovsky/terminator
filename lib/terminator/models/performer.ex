defmodule Terminator.Models.Performer do
  use Ecto.Schema

  embedded_schema do
    field(:username)
  end

  def table, do: :terminator_performers
end
