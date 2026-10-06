defmodule Problems.Content.Parser do
  @moduledoc """
  Turns one problem file into attrs for `Problems.upsert_problem_from_file_attrs/1`.

  Pure: no database, no file system. The data contract lives in `docs/PLAN.md` §2;
  field validation reuses `Problems.Problem` and `Problems.Tag` changesets, so the
  importer can reject a file before anything touches the database (ADR-10).
  """

  alias Problems.{Problem, Search, Tag}

  @keys %{
    "title" => :title,
    "subject" => :subject,
    "topics" => :topics,
    "labels" => :labels,
    "difficulty" => :difficulty,
    "source" => :source,
    "year" => :year,
    "answer" => :answer
  }

  @text_keys [:title, :source, :answer]

  @section_marker ~r/^<!--\s*(hint|solution)\s*-->[ \t]*$/m

  @field_names %{
    body_md: "body (text before the first section marker)",
    slug: "file name"
  }

  @doc """
  Parses `raw` file content. `path` is relative to the content dir and gives the slug.

  Returns `{:ok, attrs}` or `{:error, messages}` with every problem found in the file.
  """
  def parse(path, raw) do
    text = raw |> String.replace_prefix("\uFEFF", "") |> String.replace("\r\n", "\n")

    with {:ok, yaml, body} <- split_frontmatter(text),
         {:ok, frontmatter} <- decode_yaml(yaml),
         {:ok, sections} <- split_sections(body) do
      build(path, raw, frontmatter, sections)
    end
  end

  defp split_frontmatter(text) do
    with ["---", rest] <- String.split(text, "\n", parts: 2) |> trim_first(),
         [yaml, body] <- String.split(rest, ~r/^---[ \t]*$/m, parts: 2) do
      {:ok, yaml, body}
    else
      _ -> {:error, ["frontmatter: file must start with a `---` block closed by `---`"]}
    end
  end

  defp trim_first([first | rest]), do: [String.trim_trailing(first) | rest]

  defp decode_yaml(yaml) do
    case YamlElixir.read_from_string(yaml) do
      {:ok, map} when is_map(map) -> {:ok, map}
      {:ok, _other} -> {:error, ["frontmatter: must be a set of `key: value` lines"]}
      {:error, %{message: message}} -> {:error, ["frontmatter: invalid YAML (#{message})"]}
    end
  end

  defp split_sections(body) do
    [problem | rest] = Regex.split(@section_marker, body, include_captures: true)

    sections =
      rest
      |> Enum.chunk_every(2)
      |> Enum.map(fn [marker, content] ->
        [name] = Regex.run(@section_marker, marker, capture: :all_but_first)
        {name, content}
      end)

    case sections |> Enum.frequencies_by(&elem(&1, 0)) |> Enum.filter(&(elem(&1, 1) > 1)) do
      [] ->
        {:ok, Map.new([{"body", problem} | sections], fn {k, v} -> {k, blank_to_nil(v)} end)}

      duplicated ->
        {:error, for({name, _} <- duplicated, do: "#{name}: section appears more than once")}
    end
  end

  defp build(path, raw, frontmatter, sections) do
    {known, unknown} = Map.split(frontmatter, Map.keys(@keys))
    fields = Map.new(known, fn {key, value} -> {@keys[key], text_value(@keys[key], value)} end)
    {topics, topic_errors} = tag_list(fields, :topics)
    {labels, label_errors} = tag_list(fields, :labels)
    slug = path |> Path.basename() |> Path.rootname()
    title = resolve_title(fields, slug)

    attrs =
      fields
      |> Map.drop([:topics, :labels])
      |> Map.merge(%{
        slug: slug,
        title: title,
        body_md: sections["body"],
        hint_md: sections["hint"],
        solution_md: sections["solution"],
        search_text: search_text(title, fields[:source], sections["body"]),
        origin_path: path,
        content_hash: :crypto.hash(:sha256, raw) |> Base.encode16(case: :lower)
      })

    errors =
      Enum.map(unknown, fn {key, _} -> "#{key}: unknown frontmatter key" end) ++
        topic_errors ++
        label_errors ++
        for(
          {field, message} <- changeset_errors(Problem.changeset(%Problem{}, attrs)),
          field != :search_text,
          do: "#{Map.get(@field_names, field, field)}: #{message}"
        ) ++
        tag_errors(:topics, :topic, topics) ++
        tag_errors(:labels, :label, labels)

    case errors do
      [] -> {:ok, Map.merge(attrs, %{topics: topics, labels: labels})}
      errors -> {:error, errors}
    end
  end

  defp resolve_title(%{title: title}, _slug) when not is_binary(title) and not is_nil(title),
    do: title

  defp resolve_title(fields, slug) do
    present(fields[:title]) || present(fields[:source]) || humanize(slug)
  end

  defp search_text(title, source, body)
       when is_binary(title) and is_binary(body) and (is_binary(source) or is_nil(source)) do
    Search.search_text(title, source, body)
  end

  defp search_text(_title, _source, _body), do: nil

  defp text_value(key, value) when key in @text_keys and is_number(value), do: to_string(value)
  defp text_value(_key, value), do: value

  defp tag_list(fields, key) do
    case Map.get(fields, key) do
      nil -> {[], []}
      list when is_list(list) -> if Enum.all?(list, &is_binary/1), do: {list, []}, else: bad(key)
      _other -> bad(key)
    end
  end

  defp bad(key), do: {[], ["#{key}: must be a list of tags, e.g. [algebra, geometria]"]}

  defp tag_errors(key, kind, slugs) do
    for slug <- slugs,
        {_field, message} <- changeset_errors(Tag.changeset(%Tag{}, %{kind: kind, slug: slug})),
        do: "#{key}: #{inspect(slug)} #{message}"
  end

  defp changeset_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.flat_map(fn {field, messages} -> Enum.map(messages, &{field, &1}) end)
  end

  defp humanize(slug), do: slug |> String.replace("-", " ") |> String.capitalize()

  defp present(value) when is_binary(value),
    do: if(String.trim(value) == "", do: nil, else: value)

  defp present(_value), do: nil

  defp blank_to_nil(text), do: present(String.trim(text))
end
