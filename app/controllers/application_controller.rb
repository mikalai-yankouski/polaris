class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user
  before_action :set_current_user

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

    def current_user
      Current.user
    end

    def set_current_user
      Current.session ||= find_session_by_cookie
    end

    def user_not_authorized(exception)
      policy_name = exception.policy.class.to_s.underscore
      flash[:alert] = t("#{policy_name}.error", scope: "pundit", default: :default)
      redirect_back_or_to(root_path)
    end

    def not_found
      flash[:alert] = t("errors.not_found")
      redirect_back_or_to(root_path)
    end
end
