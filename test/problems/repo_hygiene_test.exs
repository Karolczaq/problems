defmodule Problems.RepoHygieneTest do
  use ExUnit.Case, async: true

  test "repo doesnt track problem contents" do
    assert System.cmd("git", ["ls-files", "content"]) == {"", 0}
  end
end
