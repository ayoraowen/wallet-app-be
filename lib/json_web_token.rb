# Encodes and decodes the JWTs used for API authentication.
#
# The signing secret is Rails' own secret_key_base, which lives in
# config/credentials.yml.enc (and is overridable via SECRET_KEY_BASE).
# Note: Rails.application.secrets was removed in Rails 7.2 — use this instead.
class JsonWebToken
  ALGORITHM = "HS256".freeze
  DEFAULT_EXPIRY = 24.hours

  class << self
    def encode(payload, exp: DEFAULT_EXPIRY.from_now)
      raise ArgumentError, "payload must be a Hash, got #{payload.class}" unless payload.is_a?(Hash)

      payload = payload.dup
      payload[:exp] = exp.to_i
      JWT.encode(payload, secret, ALGORITHM)
    end

    # Returns the claims as a HashWithIndifferentAccess.
    # Raises JWT::DecodeError (or JWT::ExpiredSignature) when the token is
    # missing, tampered with, or past its exp — callers rescue and 401.
    def decode(token)
      decoded, _header = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      ActiveSupport::HashWithIndifferentAccess.new(decoded)
    end

    private

    def secret
      Rails.application.secret_key_base
    end
  end
end
