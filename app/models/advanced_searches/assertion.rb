module AdvancedSearches
  class Assertion
    include Base

    def initialize(params)
      @params = params
      @presentation_class = AssertionWithStateParamsPresenter
    end

    def model_class
      ::Assertion
    end

    private
    def handler_for_field(field)
      default_handler = method(:default_handler).to_proc
      @handlers ||= {
        'id' => default_handler.curry['assertions.id'],
        'description' => default_handler.curry['assertions.description'],
        'disease_name' => default_handler.curry['diseases.name'],
        'disease_doid' => default_handler.curry['diseases.doid'],
        'phenotype_hpo_class' => default_handler.curry['phenotypes.hpo_class'],
        'phenotype_hpo_id' => default_handler.curry['phenotypes.hpo_id'],
        'drug_name' => default_handler.curry['drugs.name'],
        'drug_id' => default_handler.curry['drugs.pubchem_id'],
        'gene_name' => default_handler.curry['genes.name'],
        'variant_name' => default_handler.curry['variants.name'],
        'variant_alias' => default_handler.curry['variant_aliases.name'],
        'status' => default_handler.curry['assertions.status'],
        'submitter' => default_handler.curry[['users.email', 'users.name', 'users.username']],
        'submitter_id' => default_handler.curry['users.id'],
        'summary' => default_handler.curry['assertions.summary'],
        'clinical_significance' => method(:handle_clinical_significance),
        'assertion_direction' => method(:handle_assertion_direction),
        'assertion_type' => method(:handle_assertion_type),
        'suggested_changes_count' => method(:handle_suggested_changes_count),
        'interaction_type' => method(:handle_drug_combination_type),
        'organization' => default_handler.curry['organizations.name'],
        'organization_id' => default_handler.curry['organizations.id'],
      }
      @handlers[field]
    end

    def handle_clinical_significance(operation_type, parameters)
      [
        [comparison(operation_type, 'assertions.clinical_significance')],
        ::Assertion.clinical_significances[parameters.first]
      ]
    end

    def handle_assertion_type(operation_type, parameters)
      [
        [comparison(operation_type, 'assertions.evidence_type')],
        ::Assertion.evidence_types[parameters.first]
      ]
    end

    def handle_assertion_direction(operation_type, parameters)
      [
        [comparison(operation_type, 'assertions.evidence_direction')],
        ::Assertion.evidence_directions[parameters.first]
      ]
    end

    def handle_drug_combination_type(operation_type, parameters)
      val = parameters.first
      if val == 'none'
        query = ::Assertion.select('assertions.id')
          .joins('LEFT OUTER JOIN assertions_drugs on assertions.id = assertions_drugs.assertion_id')
          .group('assertions.id')
          .having('COUNT(assertions_drugs.drug_id) <= 1')
          .to_sql
        [
          ["assertions.id IN (#{query})"],
          []
        ]
      else
        [
          [comparison(operation_type, 'assertions.drug_interaction_type')],
          ::Assertion.drug_interaction_types[parameters.first]
        ]
      end
    end

    def handle_suggested_changes_count(operation_type, parameters)
      sanitized_status = ActiveRecord::Base.sanitize(parameters.shift)
      having_clause = comparison(operation_type, 'COUNT(DISTINCT(suggested_changes.id))')

      condition = ::EvidenceItem.select('evidence_items.id')
        .joins("LEFT OUTER JOIN suggested_changes ON suggested_changes.moderated_id = evidence_items.id AND suggested_changes.status = #{sanitized_status} AND suggested_changes.moderated_type = 'EvidenceItem'")
        .group('evidence_items.id')
        .having(having_clause, *parameters.map(&:to_i)).to_sql

      [
        ["evidence_items.id IN (#{condition})"],
        []
      ]
    end
  end
end