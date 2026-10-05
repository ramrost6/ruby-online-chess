require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(username: "chess_user", email: "chess@example.com", password: "password123")
    @opponent = User.create!(username: "chess_opponent", email: "opponent@example.com", password: "password123")
  end

  test "exposes hosted and joined lobbies" do
    hosted = Lobby.create!(host: @user)
    joined = Lobby.create!(host: @opponent)
    joined.join!(@user)

    assert_includes @user.hosted_lobbies, hosted
    assert_includes @user.joined_lobbies, joined
  end

  test "exposes games by color" do
    game = Game.create!(user: @user, white_player: @user, black_player: @opponent)

    assert_includes @user.white_games, game
    assert_includes @opponent.black_games, game
  end
end
