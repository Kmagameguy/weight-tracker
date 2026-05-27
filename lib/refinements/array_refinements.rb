module Refinements
  module ArrayRefinements
    refine Array do
      def median
        return nil if compact_blank.blank?
        return nil unless compact_blank.all? { |entry| entry.is_a?(Numeric) }

        sorted = sort
        (sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0
      end
    end
  end
end
