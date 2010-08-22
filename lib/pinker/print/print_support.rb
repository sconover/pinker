module Pinker
  module PrintSupport
    overridable do
      def inspect(indent="")
        indent + to_s
      end
    end
  end
  
  module ArrayPrintSupport
    overridable do
      def inspect(indent="", prefix="")
        str = indent + prefix + "[\n"
      
        each_with_index do |item, i|
          str << item.inspect(indent + "  ")
          str << "," unless i==length-1
          str << "\n"
        end
      
        str << indent + "]"
        str
      end
    end
    
    overridable do
      def to_s
        "[" + collect{|item|item.to_s}.join(",") + "]"
      end  
    end
  end
end