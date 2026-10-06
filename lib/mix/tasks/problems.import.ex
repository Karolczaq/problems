defmodule Mix.Tasks.Problems.Import do
  @shortdoc "Imports problem files from the content dir into the database"

  @moduledoc """
  Imports every `*.md` problem file under the content dir (ADR-1, ADR-10, ADR-11).

      mix problems.import            # validate everything, then write in one transaction
      mix problems.import --check    # validate and report planned changes, write nothing
      mix problems.import --force    # rewrite unchanged files too

  The directory comes from `config :problems, :content_dir` (default `content`)
  and can be overridden with `CONTENT_DIR=priv/content_example mix problems.import`.

  Exits with status 1 when any file is invalid; nothing is written in that case.
  """
  use Mix.Task

  alias Problems.Content.Importer

  @requirements ["app.start"]
  @switches [check: :boolean, force: :boolean]

  @impl Mix.Task
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: @switches)
    dir = Application.fetch_env!(:problems, :content_dir)

    case Importer.run(dir, opts) do
      {:ok, summary} ->
        prefix = if opts[:check], do: "check passed, would import", else: "imported"

        Mix.shell().info(
          "#{prefix} #{dir}: created #{summary.created}, updated #{summary.updated}, " <>
            "skipped #{summary.skipped}, deleted #{summary.deleted}"
        )

      {:error, errors} ->
        shell = Mix.shell()
        Enum.each(errors, &shell.error/1)
        shell.error("#{length(errors)} error(s), nothing was written")
        exit({:shutdown, 1})
    end
  end
end
