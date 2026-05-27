module Refinements
  module ArrayRefinements
    refine Array do
      def median
        return 0 if compact_blank.blank?
        return 0 unless compact_blank.all? { |entry| entry.is_a?(Numeric) }

        sorted = sort
        (sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0
      end
    end
  end
end
