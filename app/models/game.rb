class Game < ApplicationRecord
  STARTING_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
  STATUSES = %w[waiting active completed abandoned].freeze
  TURNS = %w[white black].freeze
  RESULTS = %w[white_won black_won draw].freeze

  belongs_to :user
  belongs_to :lobby, optional: true
  belongs_to :white_player, class_name: "User"
  belongs_to :black_player, class_name: "User"

  validates :status, inclusion: { in: STATUSES }
  validates :turn, inclusion: { in: TURNS }
  validates :result, inclusion: { in: RESULTS }, allow_nil: true
  validates :last_move, length: { maximum: 20 }, allow_nil: true
  validate :players_must_be_different
  validate :board_state_must_be_hash
  validate :result_matches_status

  def start!
    raise ActiveRecord::RecordInvalid.new(self), "Game is not waiting." unless waiting?

    update!(status: :active, started_at: Time.current)
  end

  def finish!(game_result)
    raise ArgumentError, "Unknown game result." unless RESULTS.include?(game_result.to_s)
    raise ActiveRecord::RecordInvalid.new(self), "Game is not active." unless active?

    update!(
      status: :completed,
      result: game_result,
      finished_at: Time.current,
      version: version + 1
    )
  end

  def resign!(player)
    raise ArgumentError, "Player is not part of this game." unless participant?(player)

    finish!(player == white_player ? :black_won : :white_won)
  end

  def pass_turn!
    raise ActiveRecord::RecordInvalid.new(self), "Game is not active." unless active?

    update!(turn: turn == "white" ? :black : :white)
  end

  def record_move!(player, from:, to:, promotion: nil)
    raise ActiveRecord::RecordInvalid.new(self), "Game is not active." unless active?
    raise ArgumentError, "Player is not part of this game." unless participant?(player)
    raise ActiveRecord::RecordInvalid.new(self), "It is not this player's turn." unless color_for(player).to_s == turn

    chess_game = Chess::Game.new(board_state.fetch("moves", []))
    notation = "#{from}#{to}#{promotion}"
    san = chess_game.move(notation)
    moves = board_state.fetch("moves", []) + [notation]
    next_state = board_state.merge(
      "fen" => chess_game.board.to_fen,
      "moves" => moves,
      "pgn" => chess_game.pgn.to_s
    )

    completion = completion_attributes(chess_game)
    update!(
      board_state: next_state,
      pgn: chess_game.pgn.to_s,
      last_move: san,
      turn: chess_game.active_player.to_s,
      version: version + 1,
      **completion
    )
    broadcast_state!
    san
  rescue Chess::IllegalMoveError, Chess::BadNotationError => error
    raise ArgumentError, "Illegal chess move: #{error.message}"
  end

  def participant?(player)
    player == white_player || player == black_player
  end

  def color_for(player)
    return :white if player == white_player
    return :black if player == black_player

    nil
  end

  def broadcast_state!
    GameChannel.broadcast_to(self, state_payload)
  end

  def state_payload
    {
      type: "state",
      status: status,
      result: result,
      turn: turn,
      fen: board_state.fetch("fen", STARTING_FEN),
      pgn: pgn.to_s,
      last_move: last_move,
      version: version
    }
  end

  STATUSES.each do |state|
    define_method("#{state}?") { status == state }
  end

  private

  def completion_attributes(chess_game)
    return {} unless chess_game.over?

    result = case chess_game.status
             when :white_won, :white_won_resign then "white_won"
             when :black_won, :black_won_resign then "black_won"
             else "draw"
             end

    { status: :completed, result: result, finished_at: Time.current }
  end

  def players_must_be_different
    errors.add(:black_player, "must be different from white player") if white_player.present? && white_player == black_player
  end

  def result_matches_status
    errors.add(:result, "must be present when the game is completed") if completed? && result.blank?
    errors.add(:result, "must be blank while the game is not completed") if !completed? && result.present?
  end

  def board_state_must_be_hash
    errors.add(:board_state, "must be a JSON object") unless board_state.is_a?(Hash)
  end
end
