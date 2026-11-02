class AmenityPolicy < ApplicationPolicy
  def index? = staff?

  def create?  = staff?
  def update?  = staff?
  def destroy? = staff? && record.zones.none?

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.ordered
    end
  end
end
