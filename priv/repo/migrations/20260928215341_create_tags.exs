defmodule Problems.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :kind, :string, null: false
      add :slug, :string, null: false
    end

    create unique_index(:tags, [:kind, :slug])

    create table(:problems_tags, primary_key: false) do
      add :problem_id, references(:problems, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false
    end

    create unique_index(:problems_tags, [:problem_id, :tag_id])
    create index(:problems_tags, [:tag_id])
  end
end
