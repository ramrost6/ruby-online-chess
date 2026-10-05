require "test_helper"

class GameTest < ActiveSupport::TestCase
  setup do
    @white = User.create!(username: "white_player", email: "white@example.com", password: "password123")
    @black = User.create!(username: "black_player", email: "black@example.com", password: "password123")
    @game = Game.create!(user: @white, white_player: @white, black_player: @black)
  end

  test "starts a waiting game and records the start time" do
    assert @game.waiting?

    @game.start!

    assert @game.active?
    assert_not_nil @game.started_at
    assert_equal "white", @game.turn
  end

  test "passes the turn only for an active game" do
    @game.start!

    @game.pass_turn!

    assert_equal "black", @game.turn
    @game.pass_turn!
    assert_equal "white", @game.turn
  end

  test "resigning finishes the game for the other player" do
    @game.start!

    @game.resign!(@white)

    assert @game.completed?
    assert_equal "black_won", @game.result
    assert_not_nil @game.finished_at
  end
end
