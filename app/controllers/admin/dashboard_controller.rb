module Admin
  class DashboardController < BaseController
    def show
      @dashboard = ::Analytics::Dashboard.new(period: 30.days.ago.beginning_of_day..Time.current)
      @active_reservations = Reservation.active_now.includes(:zone, :user)
    end
  end
end
