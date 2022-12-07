defmodule FruitPicker.Factory do
  use ExMachina.Ecto, repo: FruitPicker.Repo

  alias FruitPicker.Accounts

  def person_factory do
    %Accounts.Person{
      first_name: sequence(:first_name, &"Bob #{&1}"),
      last_name: sequence(:last_name, &"Smith #{&1}"),
      email: sequence(:email, &"bobsmith-#{&1}@email.com"),
      profile: %Accounts.Profile{},
    }
  end
end
