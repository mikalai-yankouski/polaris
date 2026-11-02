module SessionHelpers
  # Вход через стандартную форму сессии (cookie устанавливается автоматически)
  def sign_in(user)
    post session_path, params: { email_address: user.email_address, password: user.password }
  end
end

RSpec.configure do |config|
  config.include SessionHelpers, type: :request
end
