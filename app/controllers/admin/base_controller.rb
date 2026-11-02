module Admin
  class BaseController < ApplicationController
    before_action :require_authentication
    before_action :require_staff!

    private

    def require_staff!
      return if current_user&.staff?

      redirect_to root_path, alert: t("admin.access_denied")
    end
  end
end
