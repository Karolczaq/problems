defmodule Problems.Search do
  @moduledoc """
  Text normalization shared by indexing and querying (ADR-8).

  The importer stores `normalize(text)` in `problems.search_text`, and
  `Problems.list_problems(q: ...)` normalizes the user's phrase with the same
  function. Both sides must go through here, or Polish search silently breaks.
  """

  @doc """
  Lowercases, strips diacritics and collapses whitespace.

      iex> Problems.Search.normalize("  Dzielników   ŁÓDŹ ")
      "dzielnikow lodz"
  """
  def normalize(text) when is_binary(text) do
    text
    |> String.downcase()
    # "ł" is a separate letter in Unicode, not "l" + a combining mark, so NFD leaves it alone.
    |> String.replace("ł", "l")
    |> :unicode.characters_to_nfd_binary()
    |> String.replace(~r/\p{Mn}/u, "")
    |> String.split()
    |> Enum.join(" ")
  end
end
