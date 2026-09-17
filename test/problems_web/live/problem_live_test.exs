defmodule ProblemsWeb.ProblemLiveTest do
  use ProblemsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  @marker %{
    "szufladkowa-51-liczb" => "z zasady szufladkowej",
    "oo-czy-or" => "zniszczyć sama siebie"
  }

  defp toggle(view, slug) do
    view
    |> element(~s(button[phx-value-slug="#{slug}"]))
    |> render_click()
  end

  test "lists all problems", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/problems")

    for problem <- Problems.Fixtures.list_problems() do
      assert html =~ problem.title
      assert html =~ problem.body
    end
  end

  test "hides every solution on first render", %{conn: conn} do
    {:ok, _view, html} = live(conn, ~p"/problems")

    for {_slug, marker} <- @marker do
      refute html =~ marker
    end
  end

  test "toggles a solution on and off", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/problems")
    marker = @marker["oo-czy-or"]

    assert toggle(view, "oo-czy-or") =~ marker
    refute toggle(view, "oo-czy-or") =~ marker
  end

  test "expands problems independently of each other", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/problems")

    toggle(view, "szufladkowa-51-liczb")
    toggle(view, "oo-czy-or")

    html = render(view)
    assert html =~ @marker["szufladkowa-51-liczb"]
    assert html =~ @marker["oo-czy-or"]

    refute toggle(view, "oo-czy-or") =~ @marker["oo-czy-or"]
    assert render(view) =~ @marker["szufladkowa-51-liczb"]
  end
end
