defmodule Problems.Repo.Migrations.AddSubjectToProblems do
  use Ecto.Migration

  def change do
    alter table(:problems) do
      add :subject, :string, null: false
    end
  end
end
