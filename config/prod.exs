use Mix.Config

config :fruit_picker, FruitPickerWeb.Endpoint,
  load_from_system_env: true,
  http: [:inet6, port: System.get_env("PORT") || 4000],
  static_url: [
    scheme: System.get_env("URL_SCHEME") || "https",
    host: System.get_env("URL_STATIC_HOST"),
    port: System.get_env("URL_PORT") || 443
  ],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: Map.fetch!(System.get_env(), "SECRET_KEY_BASE")

if System.get_env("DOMAIN_URL") do
  config :fruit_picker, FruitPickerWeb.Endpoint,
    url: [scheme: "https", host: System.get_env("DOMAIN_URL"), port: 443]
else
  config :fruit_picker, FruitPickerWeb.Endpoint,
    url: [scheme: "https", host: "#{System.get_env("HEROKU_APP_NAME")}.herokuapp.com", port: 443]
end

# Do not print debug messages in production
config :logger,
  level: :info

# Configure your database
config :fruit_picker, FruitPicker.Repo,
  adapter: Ecto.Adapters.Postgres,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
  ssl: true,
  url: System.get_env("DATABASE_URL")

# Configure Mailer
config :fruit_picker, FruitPicker.Mailer,
  adapter: Bamboo.MailgunAdapter,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN")

# Configure Sentry
config :sentry,
  environment_name: :prod

# Configure file uploads
config :arc,
  storage: Arc.Storage.S3,
  virtual_host: false,
  bucket: System.get_env("SPACES_BUCKET"),
  storage_dir: "/uploads",
  asset_host: "https://jj-apps.nyc3.digitaloceanspaces.com/#{System.get_env("SPACES_BUCKET")}"

config :ex_aws,
  access_key_id: System.get_env("SPACES_ACCESS_KEY_ID"),
  secret_access_key: System.get_env("SPACES_SECRET_ACCESS_KEY"),
  region: "nyc3",
  s3: [
    scheme: "https://",
    host: System.get_env("SPACES_HOST")
  ]

# Configure env keys
config :fruit_picker,
       :google_analytics_id,
       System.get_env("GOOGLE_ANALYTICS")
