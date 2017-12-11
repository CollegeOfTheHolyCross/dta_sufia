class User < ActiveRecord::Base
  # Connects this user object to Hydra behaviors.
  include Hydra::User
  # Connects this user object to Role-management behaviors.
  include Hydra::RoleManagement::UserRoles

# Connects this user object to Sufia behaviors. 
 include Sufia::User
  include Sufia::UserUsageStats



  if Blacklight::Utils.needs_attr_accessible?

    attr_accessible :email, :password, :password_confirmation
  end
# Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def admin?
    roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end
  
  def superuser?
  	roles.where(name: 'superuser').exists?
  end

  def contributor?
    roles.where(name: 'contributor').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  def homosaurus?
    roles.where(name: 'homosaurus').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
  end

  #FIXME: Cache this...
  def groups
    groups = []
    groups += ['admin'] if roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
    groups += ['superuser'] if roles.where(name: 'superuser').exists?
    groups += ['contributor'] if roles.where(name: 'contributor').exists? || roles.where(name: 'admin').exists? || roles.where(name: 'superuser').exists?
    return groups
  end
end
