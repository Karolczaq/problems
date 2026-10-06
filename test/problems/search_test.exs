defmodule Problems.SearchTest do
  use ExUnit.Case, async: true

  alias Problems.Search

  doctest Search

  test "inflected Polish word matches its ASCII spelling" do
    assert Search.normalize("Dzielników") == Search.normalize("dzielnikow")
  end

  test "strips every Polish diacritic, including ł which NFD does not decompose" do
    assert Search.normalize("ĄĆĘŁŃÓŚŹŻ ąćęłńóśźż") == "acelnoszz acelnoszz"
  end

  test "collapses newlines and repeated spaces into single spaces" do
    assert Search.normalize(" a\n\n b\t c ") == "a b c"
  end

  describe "search_text/3" do
    test "keeps meaningful TeX commands and drops layout ones" do
      text = Search.search_text("T", nil, ~S"Niech $\sigma(n)$ oraz $\frac{1}{2}\cdot x$.")

      assert text =~ "sigma(n)"
      refute text =~ "frac"
      refute text =~ "cdot"
    end

    test "reads math in display blocks, lists and tables" do
      body = ~S"""
      $$\alpha^2$$

      - element **listy**

      | kolumna |
      |---|
      | $\omega$ |
      """

      text = Search.search_text("T", nil, body)

      for word <- ["alpha", "listy", "kolumna", "omega"], do: assert(text =~ word)
    end

    test "includes title and source, normalized" do
      assert Search.search_text("Łódź", "OM 1998", "treść") == "lodz om 1998 tresc"
    end
  end
end
