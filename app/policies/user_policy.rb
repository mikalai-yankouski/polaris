class UserPolicy < ApplicationPolicy
  def index? = staff?

  # Смена роли и блокировка — только администратору
  def update? = admin? && record != user

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.ordered
    end
  end
end
