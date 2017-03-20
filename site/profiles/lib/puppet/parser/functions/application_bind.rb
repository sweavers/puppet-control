module Puppet::Parser::Functions
  newfunction(:application_bind, :type => :rvalue) do |args|
    input = args[0]

    # Error if argument is not a hash
    raise Puppet::ParseError, "A hash must be provided" unless input.is_a?(Hash)

    # Create an empty hash to output
    output = {}

    input.each do |name,data|
      output[name] = { bind: data['bind'] }
    end

    return output
  end
end
