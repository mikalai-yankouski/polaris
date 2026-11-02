class ReservationPolicy < ApplicationPolicy
  def index? = user.present?

  def show? = owner? || staff?

  def create? = user.present? && record.user_id == user.id

  def cancel? = (owner? || staff?) && record.cancellable?

  def confirm?  = staff? && record.confirmable?
  def decline?  = staff? && record.declinable?
  def complete? = staff? && record.completable?
  def extend?   = staff? && record.extendable?

  def destroy? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.manager? || user&.admin?
        scope.order(starts_at: :desc)
      else
        scope.where(user: user).order(starts_at: :desc)
      end
    end
  end
end
