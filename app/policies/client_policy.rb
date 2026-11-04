class ClientPolicy < ApplicationPolicy
  # База клиентов — только персоналу
  def index? = staff?
end
