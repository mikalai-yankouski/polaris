# Переключение публичной темы: «атлас» (светлая) / «ночное небо» (v1)
class ThemeSwitchesController < ApplicationController
  allow_unauthenticated_access only: :create

  def create
    theme = params[:theme]
    if %w[atlas night].include?(theme)
      cookies.permanent[:design_theme] = theme
    end
    redirect_back_or_to root_path
  end
end
