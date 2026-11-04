class ReservationPolicy < ApplicationPolicy
  def show? = owner? || staff?

  # Гость бронирует без аккаунта (user пуст); вошедший — только за себя
  def create? = record.user.blank? || (user.present? && record.user_id == user.id)

  def cancel? = staff? && record.cancellable?
  def record_on_site? = staff? && record.payable?
  # Назначение времени заявке, пришедшей без слота
  def assign_time? = staff? && record.slotless?

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
