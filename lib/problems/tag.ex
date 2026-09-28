defmodule Problems.Tag do
  @moduledoc """
  A topic or a label attached to problems (ADR-4).

  `kind` mirrors the two frontmatter keys (`topics`, `labels`), so it is a closed
  set defined by the file format. `slug` is open: every author picks their own.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :kind, Ecto.Enum, values: [:topic, :label]
    field :slug, :string
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:kind, :slug])
    |> validate_required([:kind, :slug])
    |> Problems.Problem.validate_slug_format(:slug)
  end
end
