module Admin
  class ScheduleController < BaseController
    def show
      @date = parsed_date
      @zones = Zone.active.ordered.includes(:building)
      @grid = ::Schedule::Grid.new(date: @date, zones: @zones)
    end

    private

    def parsed_date
      Date.parse(params[:date])
    rescue ArgumentError, TypeError
      Date.current
    end
  end
end
