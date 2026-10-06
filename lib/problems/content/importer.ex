defmodule Problems.Content.Importer do
  @moduledoc """
  Imports every problem file under a content dir into the database.

  Two steps (ADR-10):

    1. Read and validate **all** files without touching the database.
       Any error → nothing is written, every error is returned.
    2. Write all changes in one transaction: create, update, and delete
       problems whose file is gone (ADR-11). Unchanged files are skipped by hash.

  Directory layout carries no meaning (ADR-9). `README.md` files are skipped,
  so a content repository can describe itself.
  """

  alias Problems.Content.Parser
  alias Problems.Repo

  @type summary :: %{
          created: non_neg_integer(),
          updated: non_neg_integer(),
          skipped: non_neg_integer(),
          deleted: non_neg_integer()
        }

  @doc """
  Options:

    * `:check` — only validate and report what would change; write nothing.
    * `:force` — rewrite unchanged files too (e.g. after changing `Problems.Search`).

  Returns `{:ok, summary}` or `{:error, ["path: field: message", ...]}`.
  """
  @spec run(Path.t(), keyword()) :: {:ok, summary()} | {:error, [String.t()]}
  def run(dir, opts \\ []) do
    with {:ok, parsed} <- parse_dir(dir) do
      plan = plan(parsed, Problems.content_hashes(), opts[:force] == true)

      if opts[:check] do
        {:ok, summary(plan)}
      else
        write(plan)
      end
    end
  end

  defp parse_dir(dir) do
    if File.dir?(dir) do
      paths =
        dir
        |> Path.join("**/*.md")
        |> Path.wildcard()
        |> Enum.reject(&(Path.basename(&1) |> String.downcase() == "readme.md"))
        |> Enum.map(&Path.relative_to(&1, dir))

      results = Enum.map(paths, &parse_file(dir, &1))
      parsed = for {:ok, attrs} <- results, do: attrs
      parse_errors = for {:error, messages} <- results, message <- messages, do: message

      case parse_errors ++ duplicate_slug_errors(dir, paths) do
        [] -> {:ok, parsed}
        errors -> {:error, errors}
      end
    else
      {:error, ["#{dir}: content directory does not exist"]}
    end
  end

  defp parse_file(dir, path) do
    full_path = Path.join(dir, path)

    case Parser.parse(path, File.read!(full_path)) do
      {:ok, attrs} -> {:ok, attrs}
      {:error, messages} -> {:error, Enum.map(messages, &"#{full_path}: #{&1}")}
    end
  end

  defp duplicate_slug_errors(dir, paths) do
    for {slug, [_, _ | _] = same} <- Enum.group_by(paths, &(Path.basename(&1) |> Path.rootname())),
        path <- same do
      others = same |> List.delete(path) |> Enum.join(", ")
      "#{Path.join(dir, path)}: file name: slug #{inspect(slug)} is also used by #{others}"
    end
  end

  defp plan(parsed, stored_hashes, force?) do
    {to_write, skipped} =
      Enum.split_with(parsed, fn attrs ->
        force? or stored_hashes[attrs.slug] != attrs.content_hash
      end)

    present = MapSet.new(parsed, & &1.slug)

    %{
      write: to_write,
      created: Enum.count(to_write, &(not Map.has_key?(stored_hashes, &1.slug))),
      skipped: length(skipped),
      delete: stored_hashes |> Map.keys() |> Enum.reject(&MapSet.member?(present, &1))
    }
  end

  defp write(plan) do
    Repo.transact(fn ->
      with :ok <- upsert_all(plan.write) do
        Problems.delete_problems_and_unused_tags(plan.delete)
        {:ok, summary(plan)}
      end
    end)
  end

  defp upsert_all(attrs_list) do
    Enum.reduce_while(attrs_list, :ok, fn attrs, :ok ->
      case Problems.upsert_problem_from_file_attrs(attrs) do
        {:ok, _problem} ->
          {:cont, :ok}

        {:error, changeset} ->
          {:halt, {:error, ["#{attrs.origin_path}: #{inspect(changeset.errors)}"]}}
      end
    end)
  end

  defp summary(plan) do
    %{
      created: plan.created,
      updated: length(plan.write) - plan.created,
      skipped: plan.skipped,
      deleted: length(plan.delete)
    }
  end
end
