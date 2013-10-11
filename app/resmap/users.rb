class Users
  def initialize(api)
    @api = api
  end

  attr_reader :api

  def valid?(email, password)
    begin
      res = api.json("/users/validate_credentials", {user: email, password: password})

      return res['message'] == 'Valid credentials'
    rescue
      false
    end
  end
end
