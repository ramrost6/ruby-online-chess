class GameChannel < ApplicationCable::Channel
  def subscribed
    game = Game.find_by(id: params[:game_id])
    reject unless game && game.participant?(current_user)

    stream_for game
    transmit(game.state_payload)
  end
end
