defmodule Problems.ProblemsTest do
  use Problems.DataCase, async: true

  import Problems.ProblemsFixtures

  alias Problems.{Problem, Tag}

  defp slugs(problems), do: Enum.map(problems, & &1.slug)
  defp tag_slugs(problem), do: Enum.map(problem.tags, &{&1.kind, &1.slug})

  describe "upsert_problem_from_file_attrs/1" do
    test "upserting the same slug twice keeps one record and replaces its tags" do
      problem_fixture(%{slug: "same", topics: ["algebra", "geometria"], labels: ["klasyka"]})
      problem_fixture(%{slug: "same", title: "Nowy tytuł", topics: ["algebra"], labels: []})

      assert [problem] = Repo.all(Problem)
      assert problem.title == "Nowy tytuł"
      assert tag_slugs(Problems.get_problem_by_slug!("same")) == [{:topic, "algebra"}]
    end

    test "the same slug under topics and labels is two different tags" do
      problem = problem_fixture(%{topics: ["klasyka"], labels: ["klasyka"]})

      assert Enum.sort(tag_slugs(problem)) == [label: "klasyka", topic: "klasyka"]
    end

    test "problems share existing tags instead of duplicating them" do
      problem_fixture(%{topics: ["algebra"]})
      problem_fixture(%{topics: ["algebra"]})

      assert Repo.aggregate(Tag, :count) == 1
    end

    test "a subject in the wrong format returns an error changeset" do
      attrs = %{slug: "zle", subject: "Math", topics: ["algebra"]}

      assert {:error, changeset} =
               Problems.upsert_problem_from_file_attrs(Map.merge(valid_attrs(), attrs))

      assert %{subject: [_]} = errors_on(changeset)
    end

    test "an invalid problem rolls back the tags created for it" do
      attrs = Map.merge(valid_attrs(), %{difficulty: 9, topics: ["nowy-temat"]})

      assert {:error, _} = Problems.upsert_problem_from_file_attrs(attrs)
      assert Repo.aggregate(Tag, :count) == 0
    end

    test "an invalid tag slug returns the tag's error changeset" do
      attrs = Map.merge(valid_attrs(), %{topics: ["Teoria Liczb"]})

      assert {:error, changeset} = Problems.upsert_problem_from_file_attrs(attrs)
      assert %{slug: [_]} = errors_on(changeset)
      assert Repo.aggregate(Problem, :count) == 0
    end
  end

  describe "list_problems/1" do
    test "subject filter returns only that subject" do
      problem_fixture(%{slug: "m", subject: "math"})
      problem_fixture(%{slug: "p", subject: "physics"})

      assert slugs(Problems.list_problems(subject: "physics")) == ["p"]
    end

    test "difficulty range is inclusive on both ends" do
      for d <- 1..5, do: problem_fixture(%{slug: "d#{d}", difficulty: d})

      assert slugs(Problems.list_problems(difficulty_range: 2..4)) == ["d2", "d3", "d4"]
    end

    test "topics filter requires every given topic" do
      problem_fixture(%{slug: "both", topics: ["algebra", "geometria"]})
      problem_fixture(%{slug: "only-algebra", topics: ["algebra"]})
      problem_fixture(%{slug: "label-only", topics: ["algebra"], labels: ["geometria"]})

      assert slugs(Problems.list_problems(topics: ["algebra", "geometria"])) == ["both"]
    end

    test "q matches inflected Polish words without diacritics" do
      problem_fixture(%{slug: "hit", body_md: "Suma odwrotności dzielników liczby."})
      problem_fixture(%{slug: "miss", body_md: "Pręt się przewraca."})

      assert slugs(Problems.list_problems(q: "DZIELNIKÓW")) == ["hit"]
    end

    test "q with many words requires all of them" do
      problem_fixture(%{slug: "both", body_md: "suma dzielników"})
      problem_fixture(%{slug: "one", body_md: "suma kątów"})

      assert slugs(Problems.list_problems(q: "suma dzielnikow")) == ["both"]
    end

    test "q treats LIKE wildcards literally" do
      problem_fixture(%{slug: "percent", body_md: "Zysk 50% w rok."})
      problem_fixture(%{slug: "plain", body_md: "Zysk 500 w rok."})

      assert slugs(Problems.list_problems(q: "50%")) == ["percent"]
    end

    test "preloads tags in a fixed number of queries" do
      for n <- 1..3, do: problem_fixture(%{slug: "p#{n}", topics: ["t#{n}", "wspolny"]})

      {problems, query_count} = count_queries(fn -> Problems.list_problems() end)

      assert Enum.all?(problems, &(length(&1.tags) == 2))
      assert query_count == 2
    end
  end

  defp valid_attrs do
    %{
      slug: "valid",
      subject: "math",
      title: "Zadanie",
      difficulty: 3,
      body_md: "Treść.",
      search_text: "tresc.",
      origin_path: "content/math/valid.md",
      content_hash: "abc"
    }
  end

  # Telemetry handlers run in the process that executed the query,
  # so filtering by pid ignores queries from concurrently running async tests.
  defp count_queries(fun) do
    test_pid = self()
    handler_id = {__MODULE__, make_ref()}

    :telemetry.attach(
      handler_id,
      [:problems, :repo, :query],
      fn _event, _measurements, _metadata, _config ->
        if self() == test_pid, do: send(test_pid, :query)
      end,
      nil
    )

    result = fun.()
    :telemetry.detach(handler_id)

    {result, count_messages(:query, 0)}
  end

  defp count_messages(message, count) do
    receive do
      ^message -> count_messages(message, count + 1)
    after
      0 -> count
    end
  end
end
