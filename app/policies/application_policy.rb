class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?   = false
  def show?    = false
  def create?  = false
  def new?     = create?
  def update?  = false
  def edit?    = update?
  def destroy? = false

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end

    private
      attr_reader :user, :scope
  end

  private

    def staff?    = user&.manager? || user&.admin?
    def admin?    = user&.admin?
    def owner?    = user && record.user_id == user.id
end
