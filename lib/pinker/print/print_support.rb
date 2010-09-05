module Pinker
  module PrintSupport
    overridable do
      def inspect(indent="")
        indent + to_s
      end
    end
  end
  
  module ArrayPrintSupport
    def self.inspect_array(array, indent="", prefix="")
      str = indent + prefix + "[\n"
    
      array.each_with_index do |item, i|
        str << item.inspect(indent + "  ")
        str << "," unless i==array.length-1
        str << "\n"
      end
    
      str << indent + "]"
      str
    end

    def self.to_s_array(array)
      "[" + array.collect{|item|item.to_s}.join(",") + "]"
    end
    
    overridable do
      def inspect(indent="", prefix="")
        ArrayPrintSupport.inspect_array(self, indent, prefix)
      end
    end
    
    overridable do
      def to_s
        ArrayPrintSupport.to_s_array(self)
      end  
    end
  end
end