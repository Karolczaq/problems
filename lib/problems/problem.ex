defmodule Problems.Problem do
  @moduledoc """
  A single problem, indexed from a markdown file (ADR-1).

  Every field is derived from the file by the importer, so the changeset
  guards the data contract from `docs/PLAN.md` §2.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @slug_format ~r/^[a-z0-9]+(-[a-z0-9]+)*$/

  def validate_slug_format(changeset, field) do
    validate_format(changeset, field, @slug_format,
      message: "must be lowercase letters, digits and dashes"
    )
  end

  schema "problems" do
    field :slug, :string
    field :subject, :string
    field :title, :string
    field :difficulty, :integer
    field :source, :string
    field :year, :integer
    field :answer, :string
    field :body_md, :string
    field :hint_md, :string
    field :solution_md, :string
    field :search_text, :string
    field :origin_path, :string
    field :content_hash, :string

    many_to_many :tags, Problems.Tag, join_through: "problems_tags", on_replace: :delete

    timestamps(type: :utc_datetime)
  end

  @required [
    :slug,
    :subject,
    :title,
    :difficulty,
    :body_md,
    :search_text,
    :origin_path,
    :content_hash
  ]
  @optional [:source, :year, :answer, :hint_md, :solution_md]

  def changeset(problem, attrs) do
    problem
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_number(:difficulty, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_slug_format(:slug)
    |> validate_slug_format(:subject)
    |> unique_constraint(:slug)
    |> check_constraint(:difficulty, name: :difficulty_range)
  end
end
