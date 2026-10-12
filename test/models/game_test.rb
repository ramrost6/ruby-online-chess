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

  test "records a legal client-validated move and changes the turn" do
    @game.start!

    @game.record_move!(
      @white,
      fen: "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1",
      pgn: "1. e4",
      san: "e4"
    )

    assert_equal "e4", @game.last_move
    assert_equal "black", @game.turn
    assert_equal "1. e4", @game.pgn
    assert_equal 1, @game.version
  end

  test "rejects a move from the player whose turn has not started" do
    @game.start!

    assert_raises(ActiveRecord::RecordInvalid) do
      @game.record_move!(
        @black,
        fen: Game::STARTING_FEN,
        pgn: "",
        san: "e5"
      )
    end
  end

  test "resigning finishes the game for the other player" do
    @game.start!

    @game.resign!(@white)

    assert @game.completed?
    assert_equal "black_won", @game.result
    assert_not_nil @game.finished_at
    assert_equal 1, @game.version
  end
end
