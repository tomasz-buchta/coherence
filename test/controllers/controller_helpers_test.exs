defmodule CoherenceTest.ControllerHelpers do
  use TestCoherence.ConnCase
  alias Coherence.{InvitationController, Config}
  alias TestCoherence.{User, Repo, Config}
  alias Coherence.ControllerHelpers, as: Helpers
  import TestCoherence.TestHelpers

  test "confirm!" do
    user = insert_user
    refute User.confirmed?(user)
    {:ok, user} = Helpers.confirm!(user)
    assert User.confirmed?(user)

    {:error, changeset} = Helpers.confirm!(user)
    refute changeset.valid?
    assert changeset.errors == [confirmed_at: {"already confirmed", []}]
  end

  test "lock!" do
    user = insert_user
    refute User.locked?(user)
    {:ok, user} = Helpers.lock!(user)
    assert User.locked?(user)
    {:error, changeset} = Helpers.lock!(user)
    refute changeset.valid?
    assert changeset.errors == [locked_at: {"already locked", []}]
  end

  test "unlock!" do
    user = insert_user(%{locked_at: Timex.now})
    assert User.locked?(user)
    {:ok, user} = Helpers.unlock!(user)
    refute User.locked?(user)
    {:error, changeset} = Helpers.unlock!(user)
    refute changeset.valid?
    assert changeset.errors == [locked_at: {"not locked", []}]
  end
end
