defmodule ProblemsWeb.ProblemLiveTest do
  use ProblemsWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Problems.ProblemsFixtures

  @marker %{
    "szufladkowa-51-liczb" => "z zasady szufladkowej",
    "oo-czy-or" => "zniszczyć sama siebie"
  }

  setup do
    problems = [
      problem_fixture(%{
        slug: "szufladkowa-51-liczb",
        body_md: "Wybieramy 51 liczb ze zbioru od 1 do 100.",
        solution_md: "Dwie liczby mają tę samą część nieparzystą z zasady szufladkowej."
      }),
      problem_fixture(%{
        slug: "przewracajacy-sie-pret",
        subject: "physics",
        body_md: "Pręt o długości L przewraca się bez poślizgu.",
        solution_md: "Energia potencjalna środka masy przechodzi w energię obrotu."
      }),
      problem_fixture(%{
        slug: "oo-czy-or",
        subject: "quant",
        body_md: "Ile rzutów monetą średnio czekamy na dwa orły pod rząd?",
        solution_md: "Sekwencja OO może zniszczyć sama siebie, dlatego czekamy dłużej."
      })
    ]

    %{problems: problems}
  end

  defp toggle(view, slug) do
    view
    |> element(~s(button[phx-value-slug="#{slug}"]))
    |> render_click()
  end

  test "lists all problems", %{conn: conn, problems: problems} do
    {:ok, _view, html} = live(conn, ~p"/problems")

    for problem <- problems do
      assert html =~ problem.title
      assert html =~ problem.body_md
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
