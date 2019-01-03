# defmodule Mix.Tasks.Terminator.Create.Role do
#   use Mix.Task
#   alias Terminator.Role
#   alias Terminator.Repo

#   @shortdoc "Create new role"
#   # @opts [strict: [name: :string, abilities: [:string, :keep]], aliases: [n: :name]]
#   def run(argv) do
#     Application.ensure_all_started(:terminator)

#     %{args: args} =
#       Optimus.new!(
#         name: "terminator.create.role",
#         args: [
#           role: [
#             value_name: "role_identifier",
#             help: "Role identifier (:atom)",
#             required: true,
#             parser: :string
#           ],
#           name: [
#             value_name: "role_name",
#             help: "Role human name (:string)",
#             required: true,
#             parser: :string
#           ],
#           abilities: [
#             value_name: "abilities",
#             help: "Role abilities (:string,:string)",
#             required: true,
#             parser: :string
#           ]
#         ]
#       )
#       |> Optimus.parse!(argv)

#     args = Map.put(args, :abilities, String.split(args.abilities, ","))

#     create_role(args)
#   end

#   defp create_role(%{abilities: abilities, name: name, role: role}) do
#     changeset =
#       Role.changeset(%Role{}, %{
#         identifier: role,
#         name: name,
#         abilities: abilities
#       })

#     result = Repo.insert(changeset)

#     case result do
#       {:ok, _} ->
#         IO.puts("Role created")

#       {:error, error} ->
#         IO.puts("Error while creating role")
#         IO.inspect(error.errors)
#     end
#   end
# end
