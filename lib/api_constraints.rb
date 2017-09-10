class ApiConstraints
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end

  def matches?(req)
    return true if req.headers['Accept'].include?("application/vnd.contacts.v#{@version}") # a match
    return false if req.headers['Accept'].include?("application/vnd.contacts.v") # specifies a different version
    @default # no version Accept header found
  end
end
