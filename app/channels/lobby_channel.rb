class LobbyChannel < ApplicationCable::Channel
  def subscribed
    lobby = Lobby.find_by(id: params[:lobby_id])
    reject unless lobby && [lobby.host_id, lobby.guest_id].include?(current_user.id)

    stream_for lobby
  end
end
