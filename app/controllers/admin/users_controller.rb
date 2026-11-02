module Admin
  class UsersController < BaseController
    def index
      @users = policy_scope(User).left_outer_joins(:reservations)
                                  .select("users.*, COUNT(reservations.id) AS reservations_count")
                                  .group("users.id")
      authorize User
    end

    def update
      user = User.find(params[:id])
      authorize user
      if user.update(role_params)
        redirect_to admin_users_path, notice: t(".updated", name: user)
      else
        redirect_to admin_users_path, alert: user.errors.full_messages.to_sentence
      end
    end

    private

    def role_params
      params.require(:user).permit(:role)
    end
  end
end
