module Importer
  module EntityMaps
    class GeneProteinMotif < Base
      def self.tsv_to_entity_properties_map
        {
          'motifs_citation' => [:citation, default_processor],
        }
      end

      def self.mapped_entity_class
        ::GeneProteinMotif
      end
    end
  end
end