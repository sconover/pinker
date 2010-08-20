#see http://yehudakatz.com/2009/01/18/other-ways-to-wrap-a-method/
class Module
  def overridable(&blk)
    mod = Module.new(&blk)
    include mod
  end
end


unless Object.new.respond_to?(:instance_exec) #true for 1.8.7, 1.9.  false for 1.8.6
  #see http://eigenclass.org/hiki.rb?instance_exec
  class Object
    module InstanceExecHelper; end
    include InstanceExecHelper
    def instance_exec(*args, &block) # !> method redefined; discarding old instance_exec
      mname = "__instance_exec_#{Thread.current.object_id.abs}_#{object_id.abs}"
      InstanceExecHelper.module_eval{ define_method(mname, &block) }
      begin
        ret = send(mname, *args)
      ensure
        InstanceExecHelper.module_eval{ undef_method(mname) } rescue nil
      end
      ret
    end
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