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
end
