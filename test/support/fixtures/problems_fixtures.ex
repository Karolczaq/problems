defmodule Problems.ProblemsFixtures do
  @moduledoc """
  Test helpers that insert problems through the context, the same way the importer will.
  """

  def problem_fixture(attrs \\ %{}) do
    slug = Map.get_lazy(attrs, :slug, fn -> "problem-#{System.unique_integer([:positive])}" end)
    subject = Map.get(attrs, :subject, "math")
    body = Map.get(attrs, :body_md, "Treść zadania #{slug}.")

    {:ok, problem} =
      %{
        slug: slug,
        subject: subject,
        title: "Zadanie #{slug}",
        difficulty: 3,
        body_md: body,
        search_text: Problems.Search.normalize(body),
        origin_path: "content/#{subject}/#{slug}.md",
        content_hash: :crypto.hash(:sha256, body) |> Base.encode16(case: :lower)
      }
      |> Map.merge(attrs)
      |> Problems.upsert_problem_from_file_attrs()

    problem
  end
end
