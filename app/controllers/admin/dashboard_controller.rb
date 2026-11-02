module Admin
  class DashboardController < BaseController
    def show
      @dashboard = ::Analytics::Dashboard.new(period: 30.days.ago.beginning_of_day..Time.current)
    end
  end
end
