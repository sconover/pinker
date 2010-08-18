module Pinker
  module ValueEquality
    def ==(other)
      self.instance_variables.sort == other.instance_variables.sort &&
      self.instance_variables.inject({}) {|h, sym| h[sym]=self.instance_variable_get(sym);h} ==
        other.instance_variables.inject({}) {|h, sym| h[sym]=other.instance_variable_get(sym);h}
    end
  end
end