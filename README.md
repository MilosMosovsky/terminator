# 🛡 Terminator 🛡

[![Coverage Status](https://img.shields.io/coveralls/github/MilosMosovsky/terminator.svg?style=flat-square)](https://coveralls.io/github/MilosMosovsky/terminator)
[![Build Status](https://img.shields.io/travis/MilosMosovsky/terminator.svg?style=flat-square)](https://travis-ci.org/MilosMosovsky/terminator)
[![Version](https://img.shields.io/hexpm/v/terminator.svg?style=flat-square)](https://hex.pm/packages/terminator)

Terminator is toolkit for granular ability management for performers. It allows you to define granular abilities such as:

- `Performer -> Ability`
- `Performer -> [Ability, Ability, ...]`
- `Role -> [Ability, Ability, ...]`
- `Performer -> Role -> [Ability, Ability, Ability]`
- `Performer -> [Role -> [Ability], Role -> [Ability, ...]]`
- `Performer -> AnyEntity -> [Ability, ...]`

Here is a small example:

```elixir
defmodule Sample.Post
  use Terminator

  def delete_post(id) do
    performer = Sample.Repo.get(Terminator.Performer, 1)
    load_and_authorize_performer(performer)
    post = %Post{id: 1}

    permissions do
      has_role(:admin) # or
      has_role(:editor) # or
      has_ability(:delete_posts) # or
      has_ability(:delete, post) # Entity related abilities
      calculated(fn performer ->
        performer.email_confirmed?
      end)
    end

    as_authorized do
      Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
    end

    # Notice that you can use both macros or functions

    case is_authorized? do
      :ok -> Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
      {:error, message} -> "Raise error"
      _ -> "Raise error"
    end
  end

```

## Installation

```elixir
def deps do
  [
    {:terminator, "~> 0.5.1"}
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

```elixir
iex> mix terminator.setup
```

### Usage with ecto

Terminator is originally designed to be used with Ecto. Usually you will want to have your own table for `Accounts`/`Users` living in your application. To do so you can link performer with `belongs_to` association within your schema.

```elixir
# In your migrations add performer_id field
defmodule Sample.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :performer_id, references(Terminator.Performer.table())

      timestamps()
    end

    create unique_index(:users, [:username])
  end
end

```

This will allow you link any internal entity with 1-1 association to performers. Please note that you need to create performer on each user creation (e.g with `Terminator.Performer.changeset/2`) and call `put_assoc` inside your changeset

```elixir
# In schema defintion
defmodule Sample.User do
  use Ecto.Schema

  schema "users" do
    field :username, :String

    belongs_to :performer, Terminator.Performer

    timestamps()
  end
end
```

```elixir
# In your model
defmodule Sample.Post
  use Terminator

  def delete_post(id) do
    user = Sample.Repo.get(Sample.User, 1)
    load_and_authorize_performer(user)
    # Function allows multiple signatues of performer it can
    # be either:
    #  * %Terminator.Performer{}
    #  * %AnyStruct{performer: %Terminator.Performer{}}
    #  * %AnyStruct{performer_id: id} (this will perform database preload)


    permissions do
      has_role(:admin) # or
      has_role(:editor) # or
      has_ability(:delete_posts) # or
    end

    as_authorized do
      Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
    end

    # Notice that you can use both macros or functions

    case is_authorized? do
      :ok -> Sample.Repo.get(Sample.Post, id) |> Sample.repo.delete()
      {:error, message} -> "Raise error"
      _ -> "Raise error"
    end
  end

```

Terminator tries to infer the performer, so it is easy to pass any struct (could be for example `User` in your application) which has set up `belongs_to` association for performer. If the performer was already preloaded from database Terminator will take it as loaded performer. If you didn't do preload and just loaded `User` -> `Repo.get(User, 1)` Terminator will fetch the performer on each authorization try.

### Calculated permissions

Often you will come to case when `static` permissions are not enough. For example allow only users who confirmed their email address.

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    load_and_authorize_performer(user)

    permissions do
      calculated(fn performer -> do
        performer.email_confirmed?
      end)
    end
  end
end
```

We can also use DSL form of `calculated` keyword

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    load_and_authorize_performer(user)

    permissions do
      calculated(:confirmed_email)
    end
  end

  def confirmed_email(performer) do
    performer.email_confirmed?
  end
end
```

### Composing calculations

When we need to performer calculation based on external data we can invoke bindings to `calculated/2`

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}
    load_and_authorize_performer(user)

    permissions do
      calculated(:confirmed_email)
      calculated(:is_owner, [post])
    end
  end

  def confirmed_email(performer) do
    performer.email_confirmed?
  end

  def is_owner(performer, [post]) do
    performer.id == post.owner_id
  end
end
```

To perform exclusive abilities such as `when User is owner of post AND is in editor role` we can do so as in following example

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}
    load_and_authorize_performer(user)

    permissions do
      has_role(:editor)
    end

    as_authorized do
      case is_owner(performer, post) do
        :ok -> ...
        {:error, message} -> ...
      end
    end
  end

  def is_owner(performer, post) do
    load_and_authorize_performer(performer)

    permissions do
      calculated(fn p, [post] ->
        p.id == post.owner_id
      end)
    end

    is_authorized?
  end
end
```

We can simplify example in this case by excluding DSL for permissions

```elixir
defmodule Sample.Post do
  def create() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{owner_id: 1}

    # We can also use has_ability?/2
    if has_role?(user, :admin) and is_owner(user, post) do
      ...
    end
  end

  def is_owner(performer, post) do
    performer.id == post.owner_id
  end
end
```

### Entity related abilities

Terminator allows you to grant abilities on any particular struct. Struct needs to have signature of `%{__struct__: entity_name, id: entity_id}` to infer correct relations. Lets assume that we want to grant `:delete` ability on particular `Post` for our performer:

```elixir
iex> {:ok, performer} = %Terminator.Performer{} |> Terminator.Repo.insert()
iex> post = %Post{id: 1}
iex> ability = %Ability{identifier: "delete"}
iex> Terminator.Performer.grant(performer, :delete, post)
iex> Terminator.has_ability?(performer, :delete, post)
true
```

```elixir
defmodule Sample.Post do
  def delete() do
    user = Sample.Repo.get(Sample.User, 1)
    post = %Post{id: 1}
    load_and_authorize_performer(user)

    permissions do
      has_ability(:delete, post)
    end

    as_authorized do
      :ok
    end
  end
end
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
