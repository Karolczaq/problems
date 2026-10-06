defmodule Problems.Repo.Migrations.RemoveBodyHtmlFromProblems do
  use Ecto.Migration

  def change do
    alter table(:problems) do
      remove :body_html, :text
    end
  end
end
