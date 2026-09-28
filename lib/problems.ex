defmodule Problems do
  @moduledoc """
  The problems context: the only public entry point to problems and tags.

  Problems are written by the importer (`upsert_problem_from_file_attrs/1`)
  and read by the web layer (`list_problems/1`, `get_problem_by_slug!/1`).
  """

  import Ecto.Query

  alias Problems.{Problem, Repo, Search, Tag}

  @doc """
  Inserts or updates a problem by `slug` and replaces its tags.

  `attrs` is a map with atom keys: the `Problems.Problem` fields plus
  `:topics` and `:labels` (lists of tag slugs). Missing tags are created.
  Runs in one transaction: an invalid problem leaves no new tags behind.
  """
  def upsert_problem_from_file_attrs(attrs) do
    {topics, attrs} = Map.pop(attrs, :topics, [])
    {labels, attrs} = Map.pop(attrs, :labels, [])

    Repo.transact(fn ->
      with {:ok, tags} <- ensure_tags(topic: topics, label: labels) do
        attrs[:slug]
        |> problem_for_upsert()
        |> Problem.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:tags, tags)
        |> Repo.insert_or_update()
      end
    end)
  end

  defp problem_for_upsert(slug) when is_binary(slug) do
    case Repo.get_by(Problem, slug: slug) do
      nil -> %Problem{}
      problem -> Repo.preload(problem, :tags)
    end
  end

  defp problem_for_upsert(_slug), do: %Problem{}

  defp ensure_tags(slugs_by_kind) do
    rows =
      for {kind, slugs} <- slugs_by_kind, slug <- Enum.uniq(slugs) do
        %{kind: kind, slug: slug}
      end

    case Enum.find(rows, &(not Tag.changeset(%Tag{}, &1).valid?)) do
      nil ->
        Repo.insert_all(Tag, rows, on_conflict: :nothing, conflict_target: [:kind, :slug])
        {:ok, fetch_tags(slugs_by_kind)}

      invalid_row ->
        {:error, Tag.changeset(%Tag{}, invalid_row)}
    end
  end

  defp fetch_tags(topic: topics, label: labels) do
    Repo.all(
      from t in Tag,
        where:
          (t.kind == :topic and t.slug in ^topics) or
            (t.kind == :label and t.slug in ^labels),
        order_by: [t.kind, t.slug]
    )
  end

  @doc """
  Fetches a problem with its tags. Raises `Ecto.NoResultsError` when missing.
  """
  def get_problem_by_slug!(slug) do
    Problem
    |> Repo.get_by!(slug: slug)
    |> Repo.preload(tags: tags_query())
  end

  @doc """
  Lists problems with their tags, filtered by a keyword list:

    * `subject: "math"`
    * `difficulty_range: 3..5` (inclusive)
    * `topics: ["a", "b"]` — problems tagged with **all** given topics
    * `q: "dzielników"` — every word must occur in `search_text` (ADR-8)

  Unknown filters raise `FunctionClauseError`.
  """
  def list_problems(filters \\ []) do
    filters
    |> Enum.reduce(Problem, &filter/2)
    |> order_by([p], [p.subject, p.difficulty, p.slug])
    |> preload(tags: ^tags_query())
    |> Repo.all()
  end

  defp filter({:subject, subject}, query), do: where(query, [p], p.subject == ^subject)

  defp filter({:difficulty_range, low..high//1}, query) do
    where(query, [p], p.difficulty >= ^low and p.difficulty <= ^high)
  end

  defp filter({:topics, []}, query), do: query

  defp filter({:topics, slugs}, query) do
    slugs = Enum.uniq(slugs)

    tagged_with_all =
      from pt in "problems_tags",
        join: t in Tag,
        on: t.id == pt.tag_id,
        where: t.kind == :topic and t.slug in ^slugs,
        group_by: pt.problem_id,
        having: count(t.id, :distinct) == ^length(slugs),
        select: pt.problem_id

    where(query, [p], p.id in subquery(tagged_with_all))
  end

  defp filter({:q, phrase}, query) do
    phrase
    |> Search.normalize()
    |> String.split()
    |> Enum.reduce(query, fn word, query ->
      where(query, [p], like(p.search_text, ^"%#{escape_like(word)}%"))
    end)
  end

  # `%` and `_` are LIKE wildcards and `\` is its escape character;
  # a user typing "50%" means the literal text.
  defp escape_like(word), do: String.replace(word, ["\\", "%", "_"], &("\\" <> &1))

  defp tags_query, do: from(t in Tag, order_by: [t.kind, t.slug])
end
