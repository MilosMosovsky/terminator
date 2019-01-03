# 🛡 Terminator 🛡

[![Coverage Status](https://img.shields.io/coveralls/github/MilosMosovsky/terminator.svg?style=flat-square)](https://coveralls.io/github/MilosMosovsky/terminator)
[![Build Status](https://img.shields.io/travis/MilosMosovsky/terminator.svg?style=flat-square)](https://travis-ci.org/MilosMosovsky/terminator)
[![Version](https://img.shields.io/hexpm/v/terminator.svg?style=flat-square)](https://hex.pm/packages/terminator)

Terminator is toolkit for granular ability management for performers

**WIP: NOT INTENDED FOR PRODUCTION USE**

## Installation

```elixir
def deps do
  [
    {:terminator, "~> 0.1.5"}
  ]
end
```

```elixir
# In your config/config.exs file
config :terminator, Terminator.Repo,
  username: "postgres",
  password: "postgres",
  database: "terminator_dev",
  hostname: "localhost"
```

### Granting abilities

Let's assume we want to create new `Role` - _admin_ which is able to delete accounts inside our system. We want to have special `Performer` who is given this _role_ but also he is able to have `Ability` for banning users.

1. Create performer

```elixir
iex> {:ok, performer} = %Terminator.Performer{} |> Terminator.Repo.insert()
```

2. Create some abilities

```elixir
iex> {:ok, ability_delete} = Terminator.Ability.build("delete_accounts", "Delete accounts of users") |> Terminator.Repo.insert()
iex> {:ok, ability_ban} = Terminator.Ability.build("ban_accounts", "Ban users") |> Terminator.Repo.insert()
```

3. Create role

```elixir
iex> {:ok, role} = Terminator.Role.build("admin", [], "Site administrator") |> Terminator.Repo.insert()
```

4. Grant abilities to a role

```elixir
iex> Terminator.Role.grant(role, ability_delete)
```

5. Grant role to a performer

```elixir
iex> Terminator.Performer.grant(performer, role)
```

6. Grant abilities to a performer

```elixir
iex> Terminator.Performer.grant(performer, ability_ban)
```

```elixir
iex> performer |> Terminator.Repo.preload([:roles, :abilities])
%Terminator.Performer{
  abilities: [
    %Terminator.Ability{
      identifier: "ban_accounts"
    }
  ]
  roles: [
    %Terminator.Role{
      identifier: "admin"
      abilities: ["delete_accounts"]
    }
  ]
}
```

### Revoking abilities

Same as we can grant any abilities to models we can also revoke them.

```elixir
iex> Terminator.Performer.revoke(performer, role)
iex> performer |> Terminator.Repo.preload([:roles, :abilities])
%Terminator.Performer{
  abilities: [
    %Terminator.Ability{
      identifier: "ban_accounts"
    }
  ]
  roles: []
}
iex> Terminator.Performer.revoke(performer, ability_ban)
iex> performer |> Terminator.Repo.preload([:roles, :abilities])
%Terminator.Performer{
  abilities: []
  roles: []
}
```

## License

[MIT © Milos Mosovsky](mailto:milos@mosovsky.com)
