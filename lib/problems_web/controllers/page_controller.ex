defmodule ProblemsWeb.PageController do
  use ProblemsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
