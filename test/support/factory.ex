defmodule Terminator.Factory do
  use ExMachina.Ecto, repo: Terminator.Repo
  alias Terminator.Performer
  alias Terminator.Ability
  alias Terminator.Role

  def performer_factory do
    %Performer{}
  end

  def ability_factory do
    %Ability{}
  end

  def role_factory do
    %Role{}
  end
end
