class Game < ApplicationRecord
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

    update!(status: :completed, result: game_result, finished_at: Time.current)
  end

  def resign!(player)
    raise ArgumentError, "Player is not part of this game." unless participant?(player)

    finish!(player == white_player ? :black_won : :white_won)
  end

  def pass_turn!
    raise ActiveRecord::RecordInvalid.new(self), "Game is not active." unless active?

    update!(turn: turn == "white" ? :black : :white)
  end

  def participant?(player)
    player == white_player || player == black_player
  end

  def color_for(player)
    return :white if player == white_player
    return :black if player == black_player

    nil
  end

  STATUSES.each do |state|
    define_method("#{state}?") { status == state }
  end

  private

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
