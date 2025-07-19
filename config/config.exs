import Config

config_env() in [:test, :dev] or raise "configuration only for test environtment"
Application.put_env(:mishras, :repo, MishrasTest.Repo)
