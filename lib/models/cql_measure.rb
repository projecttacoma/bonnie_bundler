class CqlMeasure

  include Mongoid::Document
  include Mongoid::Timestamps

  # Metadata fields
  # TODO: Some of these are currently here for backwards compatibility, and may or not actually be available
  # once we're getting CQL packaged with HQMF
  field :cms_id, type: String
  field :title, type: String, default: ""
  field :description, type: String, default: ""
  field :hqmf_id, type: String
  field :hqmf_set_id, type: String
  field :populations, type: Array, default: []

  # Store the original CQL as a string
  field :cql, type: String

  # Store the derived ELM as a simple hash
  # TODO: some simple documentation on the formatting of ELM (or pointers to main doc)
  field :elm, type: Hash

  # TEMPORARY: store the XML for comparison
  field :xml, type: String

  # Store the data criteria found in the measure; these are extracted before save, and we store them in both
  # the data_criteria and source_data_criteria fields to enable some simple usage of CQL measures in the same
  # contexts as we've used QDM+HQMF measures
  # TODO: determine if both are needed
  field :source_data_criteria, type: Hash
  field :data_criteria, type: Hash

  # Store a list OIDS of all value sets referenced by the measure
  field :value_set_oids, type: Array, default: []

  # Store the calculated cyclomatic complexity as a simple Hash
  # TODO: some better documentation on the formatting
  field :complexity, type: Hash

  # A measure belongs to a user
  belongs_to :user

  # Allow selection of measures by user
  scope :by_user, ->(user) { where user_id: user.id }

  # When saving extract some metadata
  before_save :extract_metadata
  def extract_metadata
    if identifier = self.elm.try(:[], 'library').try(:[], 'identifier')
      self.cms_id = "#{identifier['id']}v#{identifier['version']}"
      # TODO: these are all placeholders, which may get filled in once we have real HQMF with our CQL
      self.title = self.cms_id
      self.description = self.cms_id
      self.hqmf_id = self.cms_id
      self.hqmf_set_id = identifier['id']
      self.populations << {} if self.populations.empty?
    end
  end

  # When saving the measure look at the ELM and extract data criteria; data criteria are basically QDM
  # elements (ie Diagnosis: Ischemic Stroke); this populates the data_criteria, source_data_criteria, and
  # value_set_oids fields
  before_save :extract_data_criteria
  def extract_data_criteria

    self.source_data_criteria = {}
    self.data_criteria = {}

    # To build data criteria we need the OIDs for the value sets, so we build a simple lookup table mapping
    # the name of the value set to the OID
    value_set_lookup = {}
    if value_sets = self.elm.try(:[], 'library').try(:[], 'valueSets').try(:[], 'def')
      # TODO: what happens if two value sets share a name? Given how references work, should be an error in CQL?
      value_sets.each { |vs| value_set_lookup[vs['name']] = vs['id'] }
    end

    # Populate the value_set_oids from the value sets OIDs we just extracted
    self.value_set_oids += value_set_lookup.values

    # To find the data critera we look through all the statements in the measure recursively and extract any
    # value set references using an internal function for the recursion; this returns an array of hashes, each
    # hash containing the name and datatype of a value set
    def extract_value_set_references(expression)
      references = []
      if expression['codes'] && expression['codes']['type'] == 'ValueSetRef'
        # TODO: expression has a dataType field that embeds QDM version info, is templateId a suitable substitute? If so, document
        references << { name: expression['codes']['name'], datatype: expression['templateId'] }
      end
      if expression['source']
        if expression['source'].is_a? Array
          expression['source'].each do |source|
            references += extract_value_set_references(source['expression'])
          end
        elsif expression['source'].is_a? Hash
          references += extract_value_set_references(expression['source'])
        end
      end
      # TODO: nesting likely occurs in other places other than source
      references
    end

    # Extract value set references from each statement
    value_set_references = []
    if statements = self.elm.try(:[], 'library').try(:[], 'statements').try(:[], 'def')
      statements.each do |statement|
        value_set_references += extract_value_set_references(statement['expression'])
      end
    end

    # Take each unique value set reference and create the appropriate data criteria
    value_set_references.uniq.each do |vsr|

      name = vsr[:name]
      datatype = vsr[:datatype]
      oid = value_set_lookup[name]
      data_criteria_key = "#{datatype}_#{name}".gsub(/\s+/, '_')

      # We lookup the datatype in HDS to retrieve information about how to map this reference to a data
      # criteria; this pulls data from HDS in lib/hqmf-model/data_criteria.json
      settings = HQMF::DataCriteria.get_settings_map[datatype.underscore]
      raise "No HDS settings found for datatype #{datatype}" unless settings

      description = "#{settings['title'].titleize}: #{name}"

      source_data_criteria[data_criteria_key] = { title: name, description: description, code_list_id: oid, type: settings['category'], definition: settings['definition'], status: settings['status'] }
      # TODO: Do we need both data_criteria and source_data_criteria? Look at what's actually needed (ie patient builder)
      data_criteria[data_criteria_key] = source_data_criteria[data_criteria_key]
    end

  end
  
  # When saving calculate the cyclomatic complexity of the measure
  # TODO: Do we want to consider a measure other than "cyclomatic complexity" for CQL?
  # TODO: THIS IS NOT CYCLOMATIC COMPLEXITY, ALL MULTIPLE ELEMENT EXPRESSIONS GET COUNTED AS HIGHER COMPLEXITY, NOT JUST LOGICAL
  before_save :calculate_complexity
  def calculate_complexity
    # We calculate the complexity for each statement, and (at least for now) store the result in the same way
    # we store the complexity for QDM variables
    # TODO: consider whether this is too much of a force fit
    self.complexity = { variables: [] }

    # Recursively look through an expression to count the logical branches
    def count_expression_logical_branches(expression)
      case expression
      when nil
        0
      when Array
        expression.map { |exp| count_expression_logical_branches(exp) }.sum
      when Hash
        case expression['type']
        when 'And', 'Or', 'Not'
          count_expression_logical_branches(expression['operand'])
        when 'Query'
          # TODO: Do we need to look into the source side of the query? Can there be logical operators there?
          count_expression_logical_branches(expression['where']) + count_expression_logical_branches(expression['relationship'])
        else
          1
        end
      else
        0
      end
    end

    # Determine the complexity of each statement
    if statements = self.elm.try(:[], 'library').try(:[], 'statements').try(:[], 'def')
      statements.each do |statement|
        self.complexity[:variables] << { name: statement['name'], complexity: count_expression_logical_branches(statement['expression']) }
      end
    end

    self.complexity

  end

end