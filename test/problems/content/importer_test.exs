defmodule Problems.Content.ImporterTest do
  use Problems.DataCase, async: true

  alias Problems.Content.Importer
  alias Problems.{Problem, Tag}

  @moduletag :tmp_dir

  defp put_file(dir, path, frontmatter, body \\ "Treść zadania.") do
    full = Path.join(dir, path)
    File.mkdir_p!(Path.dirname(full))
    File.write!(full, "---\n#{frontmatter}\n---\n\n#{body}\n")
  end

  defp valid(extra \\ ""), do: "subject: math\ndifficulty: 3\n#{extra}"

  defp slugs, do: Repo.all(from p in Problem, select: p.slug, order_by: p.slug)

  test "imports files from any directory depth", %{tmp_dir: dir} do
    put_file(dir, "a.md", valid())
    put_file(dir, "olimpiady/1998/b.md", valid("topics: [algebra]"))

    assert {:ok, %{created: 2, updated: 0, skipped: 0, deleted: 0}} = Importer.run(dir)
    assert slugs() == ["a", "b"]
  end

  test "a second run with no changes skips everything", %{tmp_dir: dir} do
    put_file(dir, "a.md", valid())
    {:ok, _} = Importer.run(dir)

    assert {:ok, %{created: 0, updated: 0, skipped: 1}} = Importer.run(dir)
  end

  test "changing one character updates only that file", %{tmp_dir: dir} do
    put_file(dir, "a.md", valid())
    put_file(dir, "b.md", valid())
    {:ok, _} = Importer.run(dir)

    put_file(dir, "a.md", valid(), "Treść zadania!")

    assert {:ok, %{updated: 1, skipped: 1}} = Importer.run(dir)
    assert Problems.get_problem_by_slug!("a").body_md == "Treść zadania!"
  end

  test "force rewrites unchanged files", %{tmp_dir: dir} do
    put_file(dir, "a.md", valid())
    {:ok, _} = Importer.run(dir)

    assert {:ok, %{updated: 1, skipped: 0}} = Importer.run(dir, force: true)
  end

  test "moving a file between directories changes nothing", %{tmp_dir: dir} do
    put_file(dir, "math/a.md", valid())
    {:ok, _} = Importer.run(dir)

    File.rename!(Path.join(dir, "math"), Path.join(dir, "inne"))

    assert {:ok, %{created: 0, deleted: 0}} = Importer.run(dir)
  end

  test "one invalid file blocks the whole import and every error is reported", %{tmp_dir: dir} do
    put_file(dir, "good.md", valid())
    put_file(dir, "bad-subject.md", "subject: Math\ndifficulty: 3")
    put_file(dir, "bad-difficulty.md", valid() |> String.replace("3", "9"))

    assert {:error, errors} = Importer.run(dir)
    assert Enum.any?(errors, &(&1 =~ ~r"bad-subject\.md: subject: "))
    assert Enum.any?(errors, &(&1 =~ ~r"bad-difficulty\.md: difficulty: "))
    assert slugs() == []
  end

  test "the same file name in two directories is an error naming both", %{tmp_dir: dir} do
    put_file(dir, "a/x.md", valid())
    put_file(dir, "b/x.md", "subject: Math\ndifficulty: 3")

    assert {:error, errors} = Importer.run(dir)
    duplicates = Enum.filter(errors, &(&1 =~ "is also used by"))
    assert length(duplicates) == 2
    assert Enum.all?(duplicates, &(&1 =~ "a/x.md" and &1 =~ "b/x.md"))
    assert Enum.any?(errors, &(&1 =~ "b/x.md: subject: "))
  end

  test "a deleted file deletes its problem and tags nobody uses", %{tmp_dir: dir} do
    put_file(dir, "a.md", valid("topics: [wspolny, tylko-a]"))
    put_file(dir, "b.md", valid("topics: [wspolny]"))
    {:ok, _} = Importer.run(dir)

    File.rm!(Path.join(dir, "a.md"))

    assert {:ok, %{deleted: 1, skipped: 1}} = Importer.run(dir)
    assert slugs() == ["b"]
    assert Repo.all(from t in Tag, select: t.slug) == ["wspolny"]
  end

  test "an invalid file never deletes the problem it used to describe", %{tmp_dir: dir} do
    put_file(dir, "a.md", valid())
    {:ok, _} = Importer.run(dir)

    put_file(dir, "a.md", "subject: math")

    assert {:error, _} = Importer.run(dir)
    assert slugs() == ["a"]
  end

  test "check reports planned changes without writing", %{tmp_dir: dir} do
    put_file(dir, "a.md", valid())

    assert {:ok, %{created: 1}} = Importer.run(dir, check: true)
    assert slugs() == []
  end

  test "README files are not problems", %{tmp_dir: dir} do
    File.write!(Path.join(dir, "README.md"), "# Moje zadania\n")

    assert {:ok, %{created: 0}} = Importer.run(dir)
  end

  test "a missing directory is an error" do
    assert {:error, ["/nonexistent/dir: " <> _]} = Importer.run("/nonexistent/dir")
  end
end
