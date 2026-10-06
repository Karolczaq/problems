defmodule ProblemsWeb.ProblemLive.Index do
  use ProblemsWeb, :live_view

  alias Problems.Markdown

  @impl true
  def mount(_params, _session, socket) do
    problems = Enum.map(Problems.list_problems(), &with_html/1)

    {:ok, assign(socket, problems: problems, expanded: MapSet.new())}
  end

  defp with_html(problem) do
    prefix = "problem-#{problem.slug}"

    %{
      problem: problem,
      html: %{
        body: Markdown.to_html(problem.body_md, "#{prefix}-body"),
        hint: problem.hint_md && Markdown.to_html(problem.hint_md, "#{prefix}-hint"),
        solution:
          problem.solution_md && Markdown.to_html(problem.solution_md, "#{prefix}-solution")
      }
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-2xl font-semibold mb-6">Problems</h1>
      <div class="space-y-4">
        <%= for %{problem: problem, html: html} <- @problems do %>
          <.problem_card
            problem={problem}
            html={html}
            expanded?={MapSet.member?(@expanded, problem.slug)}
          />
        <% end %>
      </div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".Katex">
        import katex from "@/vendor/katex/katex.mjs"

        // Formula elements are `phx-update="ignore"`, so LiveView keeps what KaTeX drew;
        // an element with children is already rendered and is skipped.
        export default {
          mounted() { this.render() },
          updated() { this.render() },
          render() {
            for (const el of this.el.querySelectorAll("[data-latex]")) {
              if (el.firstChild) continue
              katex.render(el.dataset.latex, el, {
                displayMode: el.dataset.mathStyle === "display",
                throwOnError: false,
                trust: false
              })
            }
          }
        }
      </script>
    </Layouts.app>
    """
  end

  attr :problem, Problems.Problem, required: true
  attr :html, :map, required: true, doc: "rendered `body`, `hint` and `solution`"
  attr :expanded?, :boolean, default: false

  def problem_card(assigns) do
    ~H"""
    <div
      id={"problem-#{@problem.slug}"}
      phx-hook=".Katex"
      class="card bg-base-100 border border-base-300 shadow-sm"
    >
      <div class="card-body gap-3">
        <h2 class="card-title">{@problem.title}</h2>
        <div class="flex flex-wrap items-center gap-2 text-sm">
          <span class="badge badge-outline">{@problem.subject}</span>
          <span class="badge badge-outline">Difficulty: {@problem.difficulty}</span>
          <span class="text-base-content/60">{@problem.source}</span>
          <span class="text-base-content/60">{Enum.join(topics(@problem), ", ")}</span>
        </div>
        <.markdown html={@html.body} />
        <div class="card-actions">
          <button
            type="button"
            phx-click="toggle_solution"
            phx-value-slug={@problem.slug}
            class="btn btn-sm btn-soft"
          >
            <%= if @expanded? do %>
              Hide Solution
            <% else %>
              Show Solution
            <% end %>
          </button>
        </div>
        <%= if @expanded? do %>
          <div class="rounded-box bg-base-200 p-4 space-y-3 text-sm">
            <div :if={@html.hint}>
              <p class="font-semibold">Hint</p>
              <.markdown html={@html.hint} />
            </div>
            <div :if={@html.solution}>
              <p class="font-semibold">Solution</p>
              <.markdown html={@html.solution} />
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :html, :string, required: true

  defp markdown(assigns) do
    ~H"""
    <div class={[
      "space-y-2 leading-relaxed",
      "[&_ul]:list-disc [&_ol]:list-decimal [&_ul]:pl-6 [&_ol]:pl-6",
      "[&_table]:my-2 [&_td]:border [&_th]:border [&_td]:border-base-300 [&_th]:border-base-300",
      "[&_td]:px-2 [&_th]:px-2 [&_a]:link [&_code]:font-mono",
      "[&_.katex-display]:my-3 [&_.katex-display]:overflow-x-auto"
    ]}>
      {raw(@html)}
    </div>
    """
  end

  defp topics(problem), do: for(%{kind: :topic, slug: slug} <- problem.tags, do: slug)

  @impl true
  def handle_event("toggle_solution", %{"slug" => slug}, socket) do
    {:noreply, update(socket, :expanded, &toggle(&1, slug))}
  end

  defp toggle(expanded, slug) do
    if MapSet.member?(expanded, slug) do
      MapSet.delete(expanded, slug)
    else
      MapSet.put(expanded, slug)
    end
  end
end
