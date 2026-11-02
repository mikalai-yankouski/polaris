class ZonePolicy < ApplicationPolicy
  def index? = true
  def show?  = record.active? || staff?

  def create?  = staff?
  def update?  = staff?
  def destroy? = admin? && record.reservations.none?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.manager? || user&.admin?
        scope.ordered
      else
        scope.active.ordered
      end
    end
  end
end
