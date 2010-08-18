#see http://yehudakatz.com/2009/01/18/other-ways-to-wrap-a-method/
class Module
  def overridable(&blk)
    mod = Module.new(&blk)
    include mod
  end
end

module Pinker
  module ValueEquality
    def ==(other)
      self.instance_variables.sort == other.instance_variables.sort &&
      self.instance_variables.inject({}) {|h, sym| h[sym]=self.instance_variable_get(sym);h} ==
        other.instance_variables.inject({}) {|h, sym| h[sym]=other.instance_variable_get(sym);h}
    end
  end
end