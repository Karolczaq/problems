defmodule Problems.Search do
  @moduledoc """
  Search text shared by indexing and querying (ADR-8).

  The importer stores `search_text/3` in `problems.search_text`, and
  `Problems.list_problems(q: ...)` runs the user's phrase through `normalize/1`.
  Both sides must go through here, or Polish search silently breaks.
  """

  @kept_commands ~w(
    alpha beta gamma delta epsilon varepsilon zeta eta theta vartheta iota kappa lambda mu nu
    xi pi varpi rho varrho sigma tau upsilon phi varphi chi psi omega
    Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega
    sin cos tan cot sec csc arcsin arccos arctan sinh cosh tanh log ln lg exp
    lim sup inf max min gcd lcm det
  )

  @doc """
  Builds the searchable text of a problem: title, source and body (ADR-8).

      iex> Problems.Search.search_text("Dzielniki", nil, ~S"Oblicz $\\sigma(n)/n$ dla $n = 6$.")
      "dzielniki oblicz sigma(n)/n dla n = 6 ."
  """
  def search_text(title, source, body_md) do
    [title, source, markdown_text(body_md)]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
    |> normalize()
  end

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

  @doc """
  Replaces TeX syntax with the words worth searching for.

      iex> Problems.Search.strip_tex(~S"\\frac{1}{2} + \\sigma(n)") |> Problems.Search.normalize()
      "1 2 + sigma(n)"
  """
  def strip_tex(latex) do
    ~r/\\([a-zA-Z]+)/
    |> Regex.replace(latex, fn _command, name ->
      if name in @kept_commands, do: " " <> name, else: " "
    end)
    |> String.replace(~r/[\\{}^_&$~]/, " ")
  end

  defp markdown_text(markdown) do
    markdown
    |> MDEx.parse_document!(extension: [math_dollars: true, table: true])
    |> Enum.flat_map(fn
      %MDEx.Math{literal: latex} -> [strip_tex(latex)]
      %MDEx.CodeBlock{info: "math", literal: latex} -> [strip_tex(latex)]
      %MDEx.Text{literal: text} -> [text]
      %MDEx.Code{literal: text} -> [text]
      %MDEx.CodeBlock{literal: text} -> [text]
      _node -> []
    end)
    |> Enum.join(" ")
  end
end
