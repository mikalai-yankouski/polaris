# Вход на сайт по пину: проект в тестовом режиме, реальных клиентов не пускаем.
# Пин живёт только в зашифрованных credentials — проверка на сервере, в браузер
# уходит лишь форма, так что в консоли разработчика его не увидеть.
class SiteAccessController < ApplicationController
  skip_before_action :require_site_access
  # Гость, вводящий пин, ещё не персонал — аутентификация админки здесь не нужна
  allow_unauthenticated_access

  layout false

  MAX_FAILS = 8
  LOCK_SECONDS = 600

  def new
    redirect_to root_path, allow_other_host: false if site_access_granted?
    @locked = locked?
  end

  def create
    if locked?
      @locked = true
      return render :new, status: :too_many_requests
    end

    if params[:pin].to_s.strip == Rails.application.credentials.dig(:site, :pin)
      session.delete(:gate_fails)
      session.delete(:gate_locked_at)
      cookies.permanent.signed[:site_access] = "granted"
      redirect_to session.delete(:return_to) || root_path, allow_other_host: false
    else
      session[:gate_fails] = fails + 1
      sleep 1 # мягкое торможение перебора
      @failed = true
      @locked = locked?
      render :new, status: :unprocessable_entity
    end
  end

  private

    def site_access_granted?
      cookies.signed[:site_access] == "granted"
    end

    def fails
      session[:gate_fails].to_i
    end

    # После MAX_FAILS провальных попыток форма закрыта на LOCK_SECONDS
    def locked?
      return false unless fails >= MAX_FAILS

      locked_at = session[:gate_locked_at] ||= Time.current.to_i
      if Time.current.to_i - locked_at >= LOCK_SECONDS
        session.delete(:gate_fails)
        session.delete(:gate_locked_at)
        false
      else
        true
      end
    end
end
