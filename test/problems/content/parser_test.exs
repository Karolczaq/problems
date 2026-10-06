defmodule Problems.Content.ParserTest do
  use ExUnit.Case, async: true

  alias Problems.Content.Parser

  @valid ~S"""
  ---
  title: "Suma odwrotności dzielników"
  subject: math
  topics: [teoria-liczb, dzielniki]
  labels: [olimpiada]
  difficulty: 3
  source: "OM 1998, etap II, zadanie 4"
  year: 1998
  answer: "n = 6"
  ---

  Znajdź wszystkie $n$ takie, że $\sum_{d \mid n} \frac{1}{d} = 2$.

  <!-- hint -->
  Zauważ, że $\sum_{d \mid n} 1/d = \sigma(n)/n$.

  <!-- solution -->
  Funkcja $\sigma(n)/n$ jest multiplikatywna.
  """

  defp file(frontmatter, body \\ "Treść zadania."), do: "---\n#{frontmatter}\n---\n\n#{body}\n"

  defp errors(raw, path \\ "math/zadanie.md") do
    assert {:error, errors} = Parser.parse(path, raw)
    errors
  end

  test "a complete file becomes upsert attrs" do
    assert {:ok, attrs} = Parser.parse("olimpiady/1998/om-1998-2-4.md", @valid)

    assert %{
             slug: "om-1998-2-4",
             subject: "math",
             title: "Suma odwrotności dzielników",
             difficulty: 3,
             year: 1998,
             answer: "n = 6",
             topics: ["teoria-liczb", "dzielniki"],
             labels: ["olimpiada"],
             origin_path: "olimpiady/1998/om-1998-2-4.md"
           } = attrs

    assert attrs.body_md =~ ~r/^Znajdź.*= 2\$\.$/
    assert attrs.hint_md =~ "Zauważ"
    assert attrs.solution_md =~ "multiplikatywna"
  end

  describe "invariant 1: frontmatter with subject and difficulty" do
    test "a file without frontmatter is rejected" do
      assert ["frontmatter: " <> _] = errors("Tylko treść.")
    end

    test "an unclosed frontmatter is rejected" do
      assert ["frontmatter: " <> _] = errors("---\nsubject: math\n\nTreść.")
    end

    test "missing subject and difficulty are both reported" do
      assert errors(file("title: X")) |> Enum.sort() == [
               "difficulty: can't be blank",
               "subject: can't be blank"
             ]
    end

    test "an unknown key is reported, so typos do not pass silently" do
      assert "dificulty: unknown frontmatter key" in errors(file("subject: math\ndificulty: 3"))
    end

    test "invalid YAML is reported" do
      assert ["frontmatter: invalid YAML" <> _] = errors(file("topics: [a, b"))
    end
  end

  describe "invariant 2: subject format and difficulty range" do
    test "subject outside the slug format is rejected" do
      assert ["subject: " <> _] = errors(file("subject: Math\ndifficulty: 3"))
    end

    test "difficulty outside 1..5 is rejected" do
      assert ["difficulty: " <> _] = errors(file("subject: math\ndifficulty: 6"))
    end
  end

  describe "invariant 3: title is always resolved" do
    test "explicit title wins" do
      assert {:ok, %{title: "Tytuł"}} =
               Parser.parse(
                 "a/x.md",
                 file("title: Tytuł\nsource: Źródło\nsubject: m\ndifficulty: 1")
               )
    end

    test "falls back to source" do
      assert {:ok, %{title: "Źródło"}} =
               Parser.parse("a/x.md", file("source: Źródło\nsubject: m\ndifficulty: 1"))
    end

    test "falls back to the humanized slug, also for a blank title" do
      assert {:ok, %{title: "Om 1998 2 4"}} =
               Parser.parse("om-1998-2-4.md", file("title: \"\"\nsubject: m\ndifficulty: 1"))
    end
  end

  test "invariant 4: body before the first marker cannot be empty" do
    raw = file("subject: m\ndifficulty: 1", "<!-- solution -->\nRozwiązanie.")

    assert ["body (text before the first section marker): can't be blank"] = errors(raw)
  end

  describe "invariant 5: sections in any order, each at most once" do
    test "solution may come before hint" do
      raw = file("subject: m\ndifficulty: 1", "Treść.\n<!-- solution -->\nR.\n<!-- hint -->\nW.")

      assert {:ok, %{hint_md: "W.", solution_md: "R."}} = Parser.parse("x.md", raw)
    end

    test "a repeated section is rejected" do
      raw = file("subject: m\ndifficulty: 1", "T.\n<!-- hint -->\nA.\n<!-- hint -->\nB.")

      assert ["hint: section appears more than once"] = errors(raw)
    end

    test "a horizontal rule in the body is not a frontmatter separator" do
      raw = file("subject: m\ndifficulty: 1", "Część pierwsza.\n\n---\n\nCzęść druga.")

      assert {:ok, %{body_md: body}} = Parser.parse("x.md", raw)
      assert body =~ "Część druga."
    end
  end

  test "invariant 6: slug comes from the file name and must be URL-safe" do
    assert ["file name: " <> _] = errors(file("subject: m\ndifficulty: 1"), "math/Zadanie 1.md")
  end

  test "invariant 7: content hash depends on every byte of the file" do
    {:ok, %{content_hash: a}} = Parser.parse("x.md", @valid)
    {:ok, %{content_hash: b}} = Parser.parse("x.md", @valid <> " ")

    assert a != b
  end

  test "invariant 8: search text is derived from title, source and body, not hint or solution" do
    {:ok, %{search_text: text}} = Parser.parse("x.md", @valid)

    assert text =~ "suma odwrotnosci dzielnikow om 1998"
    refute text =~ "frac"
    refute text =~ "multiplikatywna"
  end

  describe "tags" do
    test "a tag that is not a list is rejected" do
      assert ["topics: must be a list" <> _] =
               errors(file("subject: m\ndifficulty: 1\ntopics: algebra"))
    end

    test "a tag in the wrong format names the offending tag" do
      assert [~s(labels: "Klasyka" must be) <> _] =
               errors(file("subject: m\ndifficulty: 1\nlabels: [Klasyka]"))
    end
  end

  test "numbers in text fields stay text" do
    assert {:ok, %{answer: "6", source: "2019"}} =
             Parser.parse("x.md", file("subject: m\ndifficulty: 1\nanswer: 6\nsource: 2019"))
  end

  test "Windows line endings and a BOM are accepted" do
    raw = "\uFEFF" <> String.replace(@valid, "\n", "\r\n")

    assert {:ok, %{subject: "math", hint_md: hint}} = Parser.parse("x.md", raw)
    refute hint =~ "\r"
  end
end
