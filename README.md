# Terminator
[![Coverage Status](https://img.shields.io/coveralls/github/MilosMosovsky/terminator.svg?style=flat-square)](https://coveralls.io/github/MilosMosovsky/terminator)
[![Build Status](https://img.shields.io/travis/MilosMosovsky/terminator.svg?style=flat-square)](https://travis-ci.org/MilosMosovsky/terminator)
[![Version](https://img.shields.io/hexpm/v/terminator.svg?style=flat-square)](https://hex.pm/packages/terminator)

Simple elixir library for managing abilities

**WIP: NOT INTENDED FOR PRODUCTION USE**

## Installation

```elixir
def deps do
  [
    {:terminator, "~> 0.1.3"}
  ]
end
```

## Usage

`config.exs`

```elixir
config :terminator,
  ecto_repo: Blog.Repo
```

`lib/blog/post.ex`

```elixir
defmodule Blog.Post do
  alias Blog.User
  alias Blog.Role

  use Ecto.Schema
  use Terminator.Guard, performer: User, role: Role

  ...

  def create() do
    load_and_authorize_performer(%User{id: 1000})

    preconditions do
      ability(:create_blog_post)
      role(:admin)
      ability(:create, %Post{id: 1})
    end  

    as_authorized do
      IO.inspect("Creating blog post")
    end
  do
  
```
