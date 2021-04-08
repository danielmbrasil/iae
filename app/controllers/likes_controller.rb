class LikesController < ApplicationController
  before_action :authenticate!
  before_action :find_post
  before_action :find_like, only: %i[destroy]

  # like post or unlike it if it's already liked
  def create
    if !already_liked?
      @post.likes.create(liker_id: current_user.id, liker_type: current_user.class.name)
    end
    redirect_back fallback_location: root_path
  end

  # deletes like
  def destroy
    @like.destroy if already_liked?
    redirect_back fallback_location: root_path
  end

  private

  def find_post
    @post = Post.find(params[:post_id])
  end

  def find_like
    @like = @post.likes.find_by(liker_id: current_user.id, liker_type: current_user.class.name)
  end

  def already_liked?
    Like.where(liker_id: current_user.id, post_id: params[:post_id], 
        liker_type: current_user.class.name).exists?
  end

  # check if there is a current user
  def authenticate!
    if !current_developer && !current_guest
      flash[:notice] = 'You must be logged in to like'
      redirect_back fallback_location: root_path
    end
  end
end
