class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :admin_section?, :night_design?, :admin_dark?
  before_action :set_current_user
  before_action :require_site_access

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

    # Админка остаётся на классическом светлом chrome
    def admin_section?
      is_a?(Admin::BaseController)
    end

    # Тестовый режим: публичный сайт открывается только после пина на /enter.
    # Админка и bePaid-webhook ходят своими дверями — им пин не нужен.
    def require_site_access
      return if admin_section? || is_a?(SiteAccessController)
      return if cookies.signed[:site_access] == "granted"

      session[:return_to] = request.path if request.get? && !request.xhr?
      redirect_to enter_path, allow_other_host: false
    end

    # Две темы публичного сайта: «атлас» (светлая) и «ночное небо» (v1)
    def night_design?
      cookies[:design_theme] == "night"
    end

    # Тема едина для сайта и админки: ночь → тёмная админка, атлас → светлая
    def admin_dark?
      night_design?
    end

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
