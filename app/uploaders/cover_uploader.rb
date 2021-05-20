class CoverUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file

  before :process, :validate

  # Override the directory where uploaded files will be stored.
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url(*args)
    ActionController::Base.helpers.asset_path("fallback/" + ["default_cover.png"].compact.join('_'))
  end

  # Process files as they are uploaded:
  # process resize_to_fit: [780, 180]

  # Add an allowlist of extensions which are allowed to be uploaded.
  def extension_allowlist
    %w(jpg jpeg gif png)
  end

  def content_type_allowlist
    [%r{image/}]
  end

  # Override the filename of the uploaded files:
  def filename
    "#{model.username.to_s.underscore}-cover.#{file.extension}" if original_filename
  end

  # validate content type of image before processing it
  def validate(file)
    image = MiniMagick::Image.open(file.path)
  rescue StandardError
    raise CarrierWave::IntegrityError, I18n.translate(:"errors.messages.content_type_whitelist_error", content_type: content_type,
                                                                                                       allowed_types: Array(content_type_allowlist).join(', '), default: :"errors.messages.content_type_allowlist_error")
  end
end
