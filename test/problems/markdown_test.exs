defmodule Problems.MarkdownTest do
  use ExUnit.Case, async: true

  alias Problems.Markdown

  doctest Markdown

  defp math_elements(html) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query("[data-latex]")
    |> Enum.map(fn el ->
      %{
        id: el |> LazyHTML.attribute("id") |> hd(),
        latex: el |> LazyHTML.attribute("data-latex") |> hd(),
        style: el |> LazyHTML.attribute("data-math-style") |> hd(),
        ignored?: LazyHTML.attribute(el, "phx-update") == ["ignore"]
      }
    end)
  end

  test "inline and display math survive sanitizing with their LaTeX intact" do
    html = Markdown.to_html(~S"Niech $\frac{1}{2}$.\n\n$$\sum_{d \mid n} d$$", "p")

    assert [
             %{latex: ~S"\frac{1}{2}", style: "inline", ignored?: true},
             %{latex: ~S"\sum_{d \mid n} d", style: "display", ignored?: true}
           ] = math_elements(html)
  end

  test "a matrix keeps its row separators and ampersands" do
    html = Markdown.to_html(~S"$$\begin{pmatrix} 1 & 2 \\ 3 & 4 \end{pmatrix}$$", "p")

    assert [%{latex: ~S"\begin{pmatrix} 1 & 2 \\ 3 & 4 \end{pmatrix}"}] = math_elements(html)
  end

  test "formula ids are unique per prefix, so two problems on one page do not collide" do
    ids =
      for prefix <- ["a", "b"],
          %{id: id} <- math_elements(Markdown.to_html("$x$ $y$", prefix)),
          do: id

    assert ids == Enum.uniq(ids)
    assert length(ids) == 4
  end

  test "raw HTML and javascript links from the file never reach the page" do
    html =
      Markdown.to_html(
        ~S|<script>alert(1)</script> <img src=x onerror=alert(1)> [x](javascript:alert(1))|,
        "p"
      )

    refute html =~ "<script"
    refute html =~ "onerror"
    refute html =~ "javascript:"
  end

  test "LaTeX cannot break out of its attribute" do
    html = Markdown.to_html(~S|$x" onmouseover="alert(1)$|, "p")

    refute html =~ ~s(onmouseover=")
    assert [%{latex: ~S|x" onmouseover="alert(1)|}] = math_elements(html)
  end
end
