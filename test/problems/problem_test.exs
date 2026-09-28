defmodule Problems.ProblemTest do
  use Problems.DataCase, async: true

  alias Problems.Problem

  @valid_attrs %{
    slug: "om-1998-2-4",
    subject: "math",
    title: "Suma odwrotności dzielników",
    difficulty: 3,
    body_md: ~S"Znajdź wszystkie $n$ takie, że $\sum_{d \mid n} \frac{1}{d} = 2$.",
    search_text: "znajdz wszystkie n takie ze sum d mid n frac 1 d 2",
    origin_path: "content/math/om-1998-2-4.md",
    content_hash: "0f1e2d"
  }

  defp changeset(overrides), do: Problem.changeset(%Problem{}, Map.merge(@valid_attrs, overrides))

  test "valid attrs produce a valid changeset" do
    assert changeset(%{}).valid?
  end

  test "any lowercase dashed subject is accepted" do
    assert changeset(%{subject: "computer-science"}).valid?
  end

  test "subject must be URL-safe" do
    for subject <- ["Math", "fizyka jądrowa", "math/../x", "-math", ""] do
      assert %{subject: [_]} = errors_on(changeset(%{subject: subject})), subject
    end
  end

  test "difficulty must be within 1..5" do
    assert changeset(%{difficulty: 1}).valid?
    assert changeset(%{difficulty: 5}).valid?
    assert %{difficulty: [_]} = errors_on(changeset(%{difficulty: 0}))
    assert %{difficulty: [_]} = errors_on(changeset(%{difficulty: 6}))
  end

  test "whitespace-only body is rejected" do
    assert %{body_md: ["can't be blank"]} = errors_on(changeset(%{body_md: "  \n "}))
  end

  test "title is required once it reaches the database" do
    assert %{title: ["can't be blank"]} = errors_on(changeset(%{title: nil}))
  end

  test "duplicate slug returns an error changeset instead of raising" do
    assert {:ok, _} = Repo.insert(changeset(%{}))
    assert {:error, changeset} = Repo.insert(changeset(%{origin_path: "content/math/copy.md"}))
    assert %{slug: ["has already been taken"]} = errors_on(changeset)
  end
end
