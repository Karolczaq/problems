defmodule Problems.Repo do
  use Ecto.Repo,
    otp_app: :problems,
    adapter: Ecto.Adapters.Postgres
end
