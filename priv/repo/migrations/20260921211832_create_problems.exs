defmodule Problems.Repo.Migrations.CreateProblems do
  use Ecto.Migration

  def change do
    create table(:problems) do
      add :slug, :string, null: false
      add :title, :string, null: false
      add :difficulty, :integer, null: false
      add :source, :string
      add :year, :integer
      add :answer, :string
      add :body_md, :text, null: false
      add :hint_md, :text
      add :solution_md, :text
      add :search_text, :text, null: false
      add :content_hash, :string, null: false
      add :origin_path, :string, null: false
      add :body_html, :text

      timestamps()
    end

    create unique_index(:problems, [:slug])
    create constraint(:problems, :difficulty_range, check: "difficulty BETWEEN 1 and 5")
  end
end
