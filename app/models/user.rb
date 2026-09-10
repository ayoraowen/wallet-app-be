class User < ApplicationRecord
    has_secure_password

    # Rails applies this on write AND to find_by(email:) lookups, so signup
    # casing can't create an account that login is then unable to find.
    normalizes :email, with: ->(email) { email.to_s.strip.downcase }

    validates :email, presence: true, uniqueness: true

end
