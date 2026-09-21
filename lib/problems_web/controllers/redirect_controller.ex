defmodule ProblemsWeb.RedirectController do
  use ProblemsWeb, :controller

  def redirect_to_problems(conn, _params) do
    redirect(conn, to: ~p"/problems")
  end
end
