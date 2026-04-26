Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # or 'http://localhost:5173' for Vite

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: false
  end
end
