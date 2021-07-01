# frozen_string_literal: true

class Developer < ApplicationRecord
  devise :database_authenticatable, :registerable, :confirmable, :lockable,
         :recoverable, :rememberable, :validatable, :timeoutable,
         authentication_keys: [:login]

  extend FriendlyId
  friendly_id :username, use: :slugged # username as friendly_id

  # Mount uploaders
  mount_uploader :avatar, AvatarUploader
  mount_uploader :cover, CoverUploader

  # Validate uploaded files size
  validates :avatar, file_size: { less_than_or_equal_to: 2.megabytes }
  validates :cover, file_size: { less_than_or_equal_to: 2.megabytes }

  # validates cover image sizes
  validate :validate_minimum_cover_image_size
  validate :validate_maximum_cover_image_size

  # validates avatar image size
  validate :validate_maximum_avatar_image_size
  validate :validate_minimum_avatar_image_size

  attr_writer :login

  extend UsernamesBlocklist
  validates :friendly_id, exclusion: { in: blocklist }

  validate :validate_username, if: :username_changed?

  # validate checkbox guidelines
  validates :accept_terms, acceptance: true

  # regex to assure username doesn't have a @
  validates_format_of :username, with: /\A[a-zA-Z0-9_-]*\z/
  validates_length_of :username, minimum: 4, maximum: 32
  before_save :downcase_username

  # validates name to ensure it doesn't contain numbers nor symbols
  validates :name, format: { with: /\A[^0-9`!@#$%^&*+_=]+\z/ }
  validates_length_of :name, minimum: 4, maximum: 64

  # validate password strength
  validates :password, password_strength: { min_entropy: 25, use_dictionary: true, min_word_length: 6 },
                       if: :encrypted_password_changed?

  has_many :bots, dependent: :destroy
  has_many :likes, dependent: :destroy

  # validates length of developer's bio
  validates_length_of :bio, maximum: 512

  acts_as_follower

  # Save browser's locale as default user's preference locale
  before_create do |dev|
    dev.locale = I18n.locale
  end

  # remove all capitals from usernames
  def downcase_username
    username.downcase!
  end

  def login
    @login or username or email
  end

  # Update user's friendly_id when username is changed
  def should_generate_new_friendly_id?
    username_changed?
  end

  # override auth method to allow login with different params
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
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

  def validate_minimum_cover_image_size
    if cover.path
      image = MiniMagick::Image.open(cover.path)
      errors.add(:cover, :minimum_image_size) unless image[:width] >= 640 && image[:height] >= 180
    end
  end

  def validate_maximum_cover_image_size
    if cover.path
      image = MiniMagick::Image.open(cover.path)
      errors.add(:cover, :maximum_image_size) unless image[:width] <= 1280 && image[:height] <= 360
    end
  end

  def validate_minimum_avatar_image_size
    if avatar.path
      image = MiniMagick::Image.open(avatar.path)
      unless image[:width].to_i >= image[:height].to_i / 2 && image[:height].to_i >= image[:width].to_i / 2
        errors.add(:avatar, :invalid_image_size)
      end
    end
  end

  def validate_maximum_avatar_image_size
    if avatar.path
      image = MiniMagick::Image.open(avatar.path)
      unless image[:width].to_i <= image[:height].to_i * 2 && image[:height].to_i <= image[:width].to_i * 2
        errors.add(:avatar, :invalid_image_size)
      end
    end
  end

  # send emails in background
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
