class GamesController < ApplicationController
  before_action :require_login

  def show
    @game = Game.find(params[:id])
    @player_color = @game.color_for(current_user)
    return head :forbidden unless @player_color
  end

  def state
    game = Game.find(params[:id])
    return head :forbidden unless game.participant?(current_user)

    render json: {
      status: game.status,
      result: game.result,
      turn: game.turn,
      fen: game.board_state.fetch("fen", Game::STARTING_FEN),
      pgn: game.pgn.to_s,
      last_move: game.last_move,
      version: game.version
    }
  end

  def move
    game = Game.find(params[:id])
    return head :forbidden unless game.participant?(current_user)

    game.record_move!(
      current_user,
      fen: params.require(:fen),
      pgn: params[:pgn],
      san: params.require(:san)
    )
    render json: { ok: true, version: game.version }
  rescue ActionController::ParameterMissing, ArgumentError, ActiveRecord::RecordInvalid => error
    render json: { error: error.message }, status: :unprocessable_entity
  end

  def resign
    game = Game.find(params[:id])
    return head :forbidden unless game.participant?(current_user)

    game.resign!(current_user)
    game.broadcast_state!
    render json: { ok: true, result: game.result }
  end
end
