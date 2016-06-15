# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  body             :text
#  user_id          :integer          not null
#  post_id          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  markdown         :text
#  aasm_state       :string
#  body_preview     :text
#  markdown_preview :text
#

class CommentsController < ApplicationController
  before_action :doorkeeper_authorize!, only: [:create, :update]

  def index
    comments = Comment.active.where(post: params[:post_id]).includes(:user, :post)
    authorize comments

    render json: comments
  end

  def show
    comment = Comment.find(params[:id])

    authorize comment

    render json: comment
  end

  def create
    comment = Comment.new(create_params)

    authorize comment

    if comment.update(publish?)
      if publish?
        track("Created Comment")
        GenerateCommentUserNotificationsWorker.perform_async(comment.id)
      else
        track("Previewed New Comment")
      end
      render json: comment
    else
      render_validation_errors comment.errors
    end
  end

  def update
    comment = Comment.find(params[:id])

    authorize comment

    comment.assign_attributes(update_params)

    if comment.update(publish?)
      if publish?
        track("Updated Comment")
        GenerateCommentUserNotificationsWorker.perform_async(comment.id)
      else
        track("Previewed Existing Comment")
      end
      render json: comment
    else
      render_validation_errors comment.errors
    end
  end

  private

    def publish?
      true unless parse_params(params).fetch(:preview, false)
    end

    def permitted_params
      parse_params(params, only: [:markdown_preview, :post])
    end

    def create_params
      params_for_user(permitted_params)
    end

    def update_params
      permitted_params
    end

    def track(event_name)
      analytics.track(
        user_id: current_user.id,
        event: event_name
      )
    end
end
