require "test_helper"

class LobbyTest < ActiveSupport::TestCase
  setup do
    @host = User.create!(username: "lobby_host", email: "host@example.com", password: "password123")
    @guest = User.create!(username: "lobby_guest", email: "guest@example.com", password: "password123")
    @lobby = Lobby.create!(host: @host)
  end

  test "joining a waiting lobby makes it ready" do
    @lobby.join!(@guest)

    assert @lobby.ready?
    assert_equal @guest, @lobby.guest
  end

  test "starting a ready lobby creates and starts a game" do
    @lobby.join!(@guest)

    game = @lobby.start_game!

    assert @lobby.started?
    assert game.persisted?
    assert game.active?
    assert_equal @host, game.white_player
    assert_equal @guest, game.black_player
  end

  test "host cannot join their own lobby" do
    assert_raises(ArgumentError) { @lobby.join!(@host) }
    assert @lobby.waiting?
  end
end
