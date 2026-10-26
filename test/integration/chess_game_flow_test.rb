require "test_helper"

class ChessGameFlowTest < ActionDispatch::IntegrationTest
  setup do
    @host = User.create!(
      username: "flow_host",
      email: "flow-host@example.com",
      password: "password123"
    )
    @guest = User.create!(
      username: "flow_guest",
      email: "flow-guest@example.com",
      password: "password123"
    )
    @outsider = User.create!(
      username: "flow_outsider",
      email: "flow-outsider@example.com",
      password: "password123"
    )
  end

  test "happy path creates a lobby, starts a game, records a move, and finishes by resignation" do
    host_session = open_session_as(@host)
    guest_session = open_session_as(@guest)

    host_session.post lobbies_path, params: { lobby: { time_control: "10+0" } }
    host_session.assert_response :redirect

    lobby = @host.hosted_lobbies.order(:created_at).last
    assert_not_nil lobby.code
    assert_equal "waiting", lobby.status

    guest_session.post join_lobbies_path, params: { code: lobby.code }
    guest_session.assert_response :redirect

    game = lobby.reload.game
    assert_not_nil game
    assert_equal "active", game.status
    assert_equal @host, game.white_player
    assert_equal @guest, game.black_player

    host_session.get lobby_path(lobby)
    host_session.assert_redirected_to game_path(game)

    host_session.get game_state_path(game), as: :json
    host_session.assert_response :success
    assert_equal Game::STARTING_FEN, host_session.response.parsed_body["fen"]
    assert_equal "white", host_session.response.parsed_body["turn"]

    host_session.post game_move_path(game), params: {
      from: "e2",
      to: "e4",
      promotion: nil
    }, as: :json
    host_session.assert_response :success
    assert_equal 1, host_session.response.parsed_body["version"]

    game.reload
    assert_equal "e4", game.last_move
    assert_equal "black", game.turn
    assert_includes game.pgn, "e4"
    assert_includes game.board_state["fen"], "4P3"

    guest_session.post game_resign_path(game), as: :json
    guest_session.assert_response :success
    assert_equal "white_won", guest_session.response.parsed_body["result"]

    assert game.reload.completed?
    assert_equal "white_won", game.result
  end

  test "rejects an illegal move and leaves the game unchanged" do
    game = started_game
    host_session = open_session_as(@host)

    host_session.post game_move_path(game), params: {
      from: "e2",
      to: "e5",
      promotion: nil
    }, as: :json

    host_session.assert_response :unprocessable_entity
    assert_includes host_session.response.parsed_body["error"], "Illegal chess move"
    assert_equal 0, game.reload.version
    assert_equal "white", game.turn
  end

  test "forbids a user who is not a participant from reading or changing the game" do
    game = started_game
    outsider_session = open_session_as(@outsider)

    outsider_session.get game_path(game)
    outsider_session.assert_response :forbidden

    outsider_session.get game_state_path(game), as: :json
    outsider_session.assert_response :forbidden

    outsider_session.post game_move_path(game), params: {
      from: "e2",
      to: "e4"
    }, as: :json
    outsider_session.assert_response :forbidden
  end

  test "rejects an unknown lobby code without creating a game" do
    guest_session = open_session_as(@guest)

    guest_session.post join_lobbies_path, params: { code: "XXXXXX" }

    guest_session.assert_redirected_to root_path
    assert_equal "Lobby code was not found.", guest_session.flash[:alert]
    assert_empty Game.where(black_player: @guest)
  end

  private

  def open_session_as(user)
    session = open_session
    session.post login_path, params: { email: user.email, password: "password123" }
    assert_equal 302, session.response.status
    session
  end

  def started_game
    lobby = Lobby.create!(host: @host)
    lobby.join!(@guest)
    lobby.start_game!
  end
end
