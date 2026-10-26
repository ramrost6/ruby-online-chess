class Lobby < ApplicationRecord
  STATUSES = %w[waiting ready started closed].freeze
  TIME_CONTROLS = %w[3+0 5+0 10+0 15+10].freeze

  belongs_to :host, class_name: "User"
  belongs_to :guest, class_name: "User", optional: true
  has_one :game, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }
  validates :time_control, inclusion: { in: TIME_CONTROLS }
  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z0-9]{6}\z/ }
  validate :guest_cannot_be_host
  before_validation :generate_code, on: :create

  def join!(player)
    raise ArgumentError, "A lobby cannot be joined by its host." if player == host
    raise ActiveRecord::RecordInvalid.new(self), "Lobby is not waiting." unless waiting?

    update!(guest: player, status: :ready)
  end

  def start_game!
    raise ActiveRecord::RecordInvalid.new(self), "Lobby is not ready." unless ready?

    transaction do
      update!(status: :started)
      create_game!(
        user: host,
        white_player: host,
        black_player: guest,
        board_state: { "fen" => Game::STARTING_FEN, "pgn" => "", "moves" => [] }
      ).tap(&:start!)
    end
  end

  STATUSES.each do |state|
    define_method("#{state}?") { status == state }
  end

  private

  def guest_cannot_be_host
    errors.add(:guest, "cannot be the host") if guest.present? && guest == host
  end

  def generate_code
    self.code ||= loop do
      candidate = SecureRandom.alphanumeric(6).upcase
      break candidate unless Lobby.exists?(code: candidate)
    end
  end
end
