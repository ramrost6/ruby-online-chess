class LobbiesController < ApplicationController
  before_action :require_login

  def create
    lobby = current_user.hosted_lobbies.create!(time_control: lobby_params[:time_control])
    redirect_to lobby_path(lobby), notice: "Share this lobby code with your opponent."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to root_path, alert: error.record.errors.full_messages.to_sentence
  end

  def show
    @lobby = Lobby.find(params[:id])
    redirect_to game_path(@lobby.game) if @lobby.game
  end

  def join
    lobby = Lobby.find_by!(code: params[:code].to_s.strip.upcase)
    lobby.join!(current_user)
    game = lobby.start_game!
    LobbyChannel.broadcast_to(lobby, { type: "game_started", game_id: game.id })
    redirect_to game_path(game), notice: "Game started."
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Lobby code was not found."
  rescue ArgumentError, ActiveRecord::RecordInvalid => error
    redirect_to root_path, alert: error.message
  end

  private

  def lobby_params
    params.require(:lobby).permit(:time_control)
  end
end
