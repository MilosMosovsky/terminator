defprotocol Terminator.Permissions do
  @doc "Evaluates permissions"
  def collect_permissions(subject)
end
