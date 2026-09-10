# Cross-origin access for the browser frontend.
#
# Origins come from CORS_ORIGINS, a comma-separated list, e.g.
#   CORS_ORIGINS=https://localhost:8080,https://192.168.100.5:8080
#
# When it is unset we fall back to "*". That is deliberate rather than lazy:
# this API authenticates with a bearer token in a header, not with cookies, so
# credentials are false and a browser will never attach ambient authority to a
# cross-origin request. CORS is not what protects the token -- the same-origin
# policy around localStorage is. Locking the list down by default would break
# the deployed frontend the moment this shipped without the env var set.
#
# Set CORS_ORIGINS in production anyway: it costs nothing and keeps casual
# cross-origin probing off the API.
allowed_origins = ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if allowed_origins.any?
      origins(*allowed_origins)
    else
      origins "*"
    end

    resource "*",
      headers: :any,
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: false
  end
end
