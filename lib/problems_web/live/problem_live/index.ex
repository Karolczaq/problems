defmodule ProblemsWeb.ProblemLive.Index do
  use ProblemsWeb, :live_view

  alias Problems.Fixtures

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, problems: Fixtures.list_problems(), expanded: MapSet.new())}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <h1 class="text-2xl font-semibold mb-6">Problems</h1>
      <div class="space-y-4">
        <%= for problem <- @problems do %>
          <.problem_card problem={problem} expanded?={MapSet.member?(@expanded, problem.slug)} />
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :problem, :map, required: true
  attr :expanded?, :boolean, default: false

  def problem_card(assigns) do
    ~H"""
    <div id={"problem-#{@problem.slug}"} class="card bg-base-100 border border-base-300 shadow-sm">
      <div class="card-body gap-3">
        <h2 class="card-title">{@problem.title}</h2>
        <div class="flex flex-wrap items-center gap-2 text-sm">
          <span class="badge badge-outline">{@problem.subject}</span>
          <span class="badge badge-outline">Difficulty: {@problem.difficulty}</span>
          <span class="text-base-content/60">{@problem.source}</span>
          <span class="text-base-content/60">{Enum.join(@problem.topics, ", ")}</span>
        </div>
        <p class="whitespace-pre-line">{@problem.body}</p>
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
          <div class="rounded-box bg-base-200 p-4 space-y-2 text-sm">
            <p><span class="font-semibold">Hint:</span> {@problem.hint}</p>
            <p><span class="font-semibold">Solution:</span> {@problem.solution}</p>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

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
