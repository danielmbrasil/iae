class Guest < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable, :lockable,
         :recoverable, :rememberable, :validatable, :timeoutable,
         authentication_keys: [:login]

  attr_writer :login

  acts_as_follower

  has_many :likes, dependent: :destroy

  extend UsernamesBlocklist
  validates :username, exclusion: { in: blocklist }, if: :username_changed?

  validate :validate_username, if: :username_changed?

  # regex to assure username doesn't have a @
  validates_format_of :username, with: /\A[a-zA-Z0-9_-]*\z/
  validates_length_of :username, minimum: 4, maximum: 32
  before_save :downcase_username

  # validates to guidelines
  validates :accept_terms, acceptance: true

  # validate password strength
  validates :password, password_strength: { min_entropy: 25, use_dictionary: true, min_word_length: 6 },
                       if: :encrypted_password_changed?

  # Save browser's locale as default user's preference locale
  before_create do |guest|
    guest.locale = I18n.locale
  end

  # remove all capitals from usernames
  def downcase_username
    username.downcase!
  end

  def login
    @login or username or email
  end

  # override auth method to allow login with different params
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(['lower(username) = :value OR lower(email) = :value ',
                                    { value: login.downcase }]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end

  # validates if username is not taken
  def validate_username
    if Guest.where(email: username.downcase).exists? || Developer.where(email: username.downcase).exists?
      errors.add(:username, :already_taken)
    elsif Guest.where(username: username.downcase).exists? || Developer.where(username: username.downcase).exists?
      errors.add(:username, :already_taken)
    elsif Bot.where(username: username.downcase).exists?
      errors.add(:username, :already_taken)
    end
  end

  # send emails in background
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
