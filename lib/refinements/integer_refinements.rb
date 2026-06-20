module Refinements
  module IntegerRefinements
    refine Integer do
      def to_sequence
        case self.to_i
        when 1
          "once"
        when 2
          "twice"
        else
          "#{self.to_i} times"
        end
      end
    end
  end
end
