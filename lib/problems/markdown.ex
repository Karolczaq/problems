defmodule Problems.Markdown do
  @moduledoc """
  Renders problem markdown to safe HTML (ADR-12, ADR-13).

  Math becomes empty `<span>`/`<div>` elements carrying `data-latex`; KaTeX fills
  them in the browser. Raw HTML from the file is dropped and the output is
  sanitized, so `raw/1` on the result is safe even for someone else's content.
  """

  @extension [math_dollars: true, table: true, strikethrough: true]

  @math_attributes ["id", "phx-update", "data-latex", "data-math-style"]

  @sanitize Keyword.merge(MDEx.Document.default_sanitize_options(),
              add_tag_attributes: %{"span" => @math_attributes, "div" => @math_attributes}
            )

  @doc "Markdown extensions shared by rendering and search indexing."
  def extension, do: @extension

  @doc """
  Renders `markdown` to HTML. `id_prefix` must be unique on the page: every formula
  gets an `id` derived from it, which LiveView requires for `phx-update="ignore"`.

      iex> Problems.Markdown.to_html("$x^2$", "p")
      ~s(<p><span id="p-math-1" phx-update="ignore" data-math-style="inline" data-latex="x^2"></span></p>)
  """
  def to_html(markdown, id_prefix) do
    math_attrs = fn seq -> ~s(id="#{id_prefix}-math-#{seq}" phx-update="ignore") end

    [markdown: markdown, extension: @extension, sanitize: @sanitize]
    |> MDEx.new()
    |> MDExKatex.attach(
      katex_init: "",
      katex_block_attrs: math_attrs,
      katex_inline_attrs: math_attrs
    )
    |> MDEx.to_html!()
    |> String.trim()
  end
end
