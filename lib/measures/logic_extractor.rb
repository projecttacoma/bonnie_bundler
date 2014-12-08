module HQMF
  module Measure
    class LogicExtractor

      POPULATION_MAP = {
        'STRAT' => 'Stratification',
        'IPP' => 'Initial Patient Population',
        'DENOM' => 'Denominator',
        'NUMER' => 'Numerator',
        'DENEXCEP' => 'Denominator Exceptions',
        'DENEX' => 'Denominator Exclusions',
        'MSRPOPL' => 'Measure Population',
        'OBSERV' => 'Measure Observations'
      }
      AGGREGATOR_MAP = {
        'MEAN' => 'Mean of',
        'MEDIAN' => 'Median of'
      }
      LOGIC_OPERATOR_MAP = { 'XPRODUCT' => 'AND' }
      SET_OPERATOR_MAP = {
        'INTERSECT' => 'Intersection of',
        'UNION' => 'Union of'
      }
      SUBSET_MAP = {
        'COUNT' => 'COUNT',
        'FIRST' => 'FIRST',
        'SECOND' => 'SECOND',
        'THIRD' => 'THIRD',
        'FOURTH' => 'FOURTH',
        'FIFTH' => 'FIFTH',
        'RECENT' => 'MOST RECENT',
        'LAST' => 'LAST',
        'MIN' => 'MIN',
        'MAX' => 'MAX',
        'MEAN' => 'MEAN',
        'MEDIAN' => 'MEDIAN',
        'TIMEDIFF' => 'Difference between times',
        'DATEDIFF' => 'Difference between dates',
        'DATETIMEDIFF' => 'Difference between date/times'
      }
      OPERATOR_MAP = {
        'satisfies_all' => 'SATISFIES ALL',
        'satisfies_any' => 'SATISFIES ANY'
      }
      TIMING_MAP = {
        'DURING' => 'During',
        'OVERLAP' => 'Overlaps',
        'SBS' => 'Starts Before Start of',
        'SAS' => 'Starts After Start of',
        'SBE' => 'Starts Before End of',
        'SAE' => 'Starts After End of',
        'EBS' => 'Ends Before Start of',
        'EAS' => 'Ends After Start of',
        'EBE' => 'Ends Before End of',
        'EAE' => 'Ends After End of',
        'SDU' => 'Starts During',
        'EDU' => 'Ends During',
        'ECW' => 'Ends Concurrent with',
        'SCW' => 'Starts Concurrent with',
        'ECWS' => 'Ends Concurrent with Start of',
        'SCWE' => 'Starts Concurrent with End of',
        'SBCW' => 'Starts Before or Concurrent with',
        'SBCWE' => 'Starts Before or Concurrent with End of',
        'SACW' => 'Starts After or Concurrent with',
        'SACWE' => 'Starts After or Concurrent with End of',
        'SBDU' => 'Starts Before or During',
        'EBCW' => 'Ends Before or Concurrent with',
        'EBCWS' => 'Ends Before or Concurrent with Start of',
        'EACW' => 'Ends After or Concurrent with',
        'EACWS' => 'Ends After or Concurrent with Start of',
        'EADU' => 'Ends After or During',
        'CONCURRENT' => 'Concurrent with'
      }
      UNIT_MAP = {
        'a' => 'year',
        'mo' => 'month',
        'wk' => 'week',
        'd' => 'day',
        'h' => 'hour',
        'min' => 'minute',
        's' => 'second'
      }
      CONJUNCTION_MAP = {
        'allTrue' => 'AND',
        'atLeastOneTrue' => 'OR'
      }
      FLIP_CONJUNCTION_MAP = {
        'AND' => 'OR',
        'OR' => 'AND'
      }
      SATISFIES_DEFINITIONS = ['satisfies_all','satisfies_any']
      INTERVAL_DEFINITIONS = ['IVL_PQ', 'IVL_TS']
      INTERVAL_TYPES_DEFINITIONS = ['PQ', 'TS']

      def precondition_logic(precondition, parent_precondition=nil, parent_negation=false, indent=nil)
        results = []
        precondition_key = "precondition_#{precondition['id']}"
        parent_preocondition_key = "precondition_#{parent_precondition['id']}"
        conjunction = translate_conjunction(parent_precondition['conjunction_code'])
        suppress = true if precondition['negation'] && precondition['preconditions'] && precondition['preconditions'].length == 1
        conjunction = FLIP_CONJUNCTION_MAP[conjunction] if parent_negation
        comments = precondition['comments'] || []
        if precondition['reference']
          data_criteria = @measure['data_criteria'][precondition['reference']]
          comments.concat data_criteria['comments'] || []
        end
        indent ||= ""
        indent += "\t"

        line = ""
        unless suppress
          if comments
            results.concat comments
          end
          line << "#{indent}#{conjunction}"
          line << " NOT" if parent_negation
          line << ":"
          results << line
        end
        if precondition['preconditions']
          results.last << "\n" unless results.blank?
          precondition['preconditions'].each do |p|
            results.concat precondition_logic(p, precondition, precondition['negation'], indent)
          end
        else
          results.last << " "
          results.concat data_criteria_logic(precondition['reference'])
        end

        results
      end

      def subset_operator_logic(subset_operator)
        results = []
        line = "#{translate_subset(subset_operator['type'])}"
        if subset_operator['value']
          unless subset_operator['value']['type'].to_s == 'ANYNonNull'
            line << "#{value_logic(subset_operator['value'])[0]}"
          end
        end
        line << ": "
        results << line
      end

      def value_logic(value, range_comparison=nil)
        results = []

        is_range = INTERVAL_DEFINITIONS.include?(value['type'])
        is_equivalent = is_range && value['high'] && value['low'] && (value['high']['value'] == value['low']['value']) && value['high']['inclusive?'] && value['low']['inclusive?']
        is_value = INTERVAL_TYPES_DEFINITIONS.include?(value['type'])
        is_any_non_null = value['type'].to_s == 'ANYNonNull'
        is_ts = value['type'].to_s == 'TS'

        line = ""
        unless is_any_non_null
          if is_value
            line << "#{range_comparison || ''}"
            line << "=" if value['inclusive?']
            if is_ts
              line << translate_date(value['value'])
            else
              line << " #{value['value']}"
            end
            line << " #{translate_unit(value['unit'], value['value'])}"
          else
            if is_range
              if value['high'] && value['low']
                if is_equivalent
                  line = value_logic(value['low'])[0]
                else
                  line = "#{value_logic(value['low'], '>')[0]} and #{value_logic(value['high'], '<')[0]}"
                end
              else
                if value['high']
                  line = " #{value_logic(value['high'], '<')[0]}"
                else
                  if value['low']
                    line = " #{value_logic(value['low'], '>')[0]}"
                  end
                end
              end
            else
              line << ": #{translate_oid(value['code_list_id'])}" if value['type'].to_s == 'CD'
            end
          end
        end
        results << line
      end

      def satisfies_logic(reference, indent=nil)
        results = []
        indent ||= ""

        data_criteria = @measure.data_criteria[reference]
        root_criteria = @measure.data_criteria[data_criteria['children_criteria'][0]]

        line = ""
        line << "Occurrence #{root_criteria['specific_occurrence']}:" if root_criteria['specific_occurrence']
        line << "$" if root_criteria['variable']

        line << "#{root_criteria['description']} #{translate_operator(data_criteria['definition'])}\n"
        results << line
        data_criteria['children_criteria'].each do |cc|
          results << "#{data_criteria_logic(cc, false, true, indent+"\t").join('')}"
        end
        if data_criteria['temporal_references']
          data_criteria['temporal_references'].each do |tr|
            results << "#{indent+"\t"}#{temporal_reference_logic(tr).join()}"
          end
        end

        results
      end

      def temporal_reference_logic(temporal_reference)
        results = []

        line = ""
        line << "#{value_logic(temporal_reference['range'])[0]}" if temporal_reference['range']
        line << " #{translate_timing(temporal_reference['type'])} "
        if temporal_reference['reference'].to_s == "MeasurePeriod"
          line << "\"Measurement Period\""
        else
          line << "#{data_criteria_logic(temporal_reference['reference']).join()}"
        end

        results << line
      end

      def data_criteria_logic(reference, expand_variable=false, hide_title=nil, indent=nil)
        results = []
        indent ||= ""

        data_criteria = @measure.data_criteria[reference]
        unless data_criteria
          data_criteria = @measure.source_data_criteria[reference]
        end
        data_criteria['key'] ||= reference


        if !data_criteria['field_values'].blank?
          data_criteria['field_values'].each do |key, field|
            if field.blank?
              field = {}
              data_criteria['field_values'][key] = field
            end
            field['key'] = key
            field['key_title'] = translate_field(key)
          end
        end
        # handle field values on data_criteria
        is_satisfies = SATISFIES_DEFINITIONS.include?(data_criteria['definition'])
        is_derived = data_criteria['type'].to_s == 'derived'
        has_children = is_derived && (!data_criteria['variable'] || expand_variable)
        is_set_op = SET_OPERATOR_MAP.keys.include?(data_criteria['derivation_operator'])

        if data_criteria['subset_operators']
          data_criteria['subset_operators'].each do |so|
            results.concat subset_operator_logic(so)
          end
        end

        if has_children
          if is_satisfies
            results.concat satisfies_logic(data_criteria['key'], indent+"\t")
          else
            if data_criteria['children_criteria']
              if is_set_op
                unless expand_variable
                  results << "\n#{indent+"\t\t"}#{translate_set_operator(data_criteria['derivation_operator'])}:"
                end
              end
              line = "#{indent}"
              data_criteria['children_criteria'].each_with_index do |cc, cc_ind|
                unless is_set_op
                  line << "#{translate_logic_operator(data_criteria['derivation_operator'])} : "
                end
                data_criteria_logic(cc, false, nil, indent+"\t").each_with_index do |dc, dc_ind|
                  results << "#{line}\t#{dc}"
                end
              end
              if data_criteria['temporal_references']
                data_criteria['temporal_references'].each do |tr|
                  results << "#{indent+"\t\t"}#{temporal_reference_logic(tr).first}"
                end
              end
            end
          end
        else
          line = "#{indent}"
          line = "" if hide_title && !results.blank?
          unless hide_title
            if data_criteria['specific_occurrence']
              line << "Occurrence #{data_criteria['specific_occurrence']}: "
            end
            line << "$" if data_criteria['variable']
            line << data_criteria['description']
          end
          if data_criteria['value']
            unless data_criteria['type'].to_s == 'characteristic'
              line << "(result#{value_logic(data_criteria['value'])[0]})"
            end
          end
          if data_criteria['field_values']
            line << " ( "
            data_criteria['field_values'].each do |field, fv|
              line << fv['key_title']
              line << "#{value_logic(fv)[0]}" if fv['type'] != 'ANYNonNull'
            end
            line << " )"
          end
          if data_criteria['negation']
            line << " ( Not Done : #{translate_oid(data_criteria['negation_code_list_id'])} )"
          end

          results << line
          if data_criteria['temporal_references']
            if data_criteria['temporal_references'].length > 1
              data_criteria['temporal_references'].each do |tr|
                results << "#{indent}#{temporal_reference_logic(tr)}"
              end
            else
              data_criteria['temporal_references'].each do |tr|
                results << temporal_reference_logic(tr).first
              end
            end
          end
        end
        results.last << "\n" unless results.last.end_with?("\n")

        results
      end

      def population_criteria_logic(population)
        results = []

        root_precondition = population['preconditions'][0] if population['preconditions']
        aggregator = population['aggregator']
        ( comments = root_precondition.try(:[],'comments') || [] ) | ( population['comments'] || [] )
        comments ||= []

        comments.each {|c| results.concat c}
        unless root_precondition.blank?
          if root_precondition['preconditions']
            root_precondition['preconditions'].each do |precondition|
              results.concat precondition_logic(precondition, root_precondition, root_precondition['negation'] || false)
            end
          else
            unless aggregator.blank?
              results << "\t#{translate_aggregator(aggregator)}\n"
            end
            results.concat data_criteria_logic(root_precondition['reference'])
          end
        else
          results << "\tNone\n"
        end

        results
      end

      def population_logic(measure)
        results = []
        @measure = measure
        populations = HQMF::PopulationCriteria::ALL_POPULATION_CODES & @measure.population_criteria.keys

        populations.each do |population|
          population_results = {:code => population, :lines => []}
          population_results[:lines] << "\n#{translate_population(population)}\n"
          population_results[:lines].concat population_criteria_logic(@measure.population_criteria[population])
          results << population_results
        end
        variables_text = variables_logic
        unless variables_text.blank?
          variable_results = {:code => "VARIABLES", :lines => variables_text }
          results << variable_results
        end

        results
      end

      def variables_logic
        results = []

        variables = @measure['source_data_criteria'].select{ |key, attrs| attrs['variable'] == true }
        has_variables = variables.length > 0

        if has_variables
          results << "\nVariables\n"
          variables.each do |title, v|
            results << "\t$#{v['description']} = \n"
            results.concat data_criteria_logic(v['source_data_criteria'], true, nil, "\t")
          end
        end

        results
      end

      def translate_population(code)
        POPULATION_MAP[code]
      end

      def translate_aggregator(code)
        AGGREGATOR_MAP[code]
      end

      def translate_logic_operator(conjunction)
        LOGIC_OPERATOR_MAP[conjunction]
      end

      def translate_set_operator(conjunction)
        SET_OPERATOR_MAP[conjunction]
      end

      def translate_field(field_key)
        HQMF::DataCriteria::FIELDS[field_key][:title]
      end

      def translate_subset(subset)
        SUBSET_MAP[subset]
      end

      def translate_operator(definition)
        OPERATOR_MAP[definition]
      end

      def translate_timing(code)
        TIMING_MAP[code].downcase
      end

      def translate_unit(unit, value)
        if UNIT_MAP[unit]
          UNIT_MAP[unit] + ( value.to_i > 1 ? 's' : '' )
        else
          unit
        end
      end

      def translate_oid(oid)
        begin
          @measure.value_sets.where({:oid => oid}).first.display_name
        rescue
          oid
        end
      end

      def translate_date(date)
        date
      end

      def translate_conjunction(conjunction)
        CONJUNCTION_MAP[conjunction]
      end

      ### Diff methods ###

      def self.get_measure_logic_text(measure, by_population=false)
        return '' if measure.measure_logic.blank?
        unless by_population
          lines = ''
          measure.measure_logic.each do |population|
            population[:lines].each do |line|
              lines << "#{line}#{"\n" unless line.ends_with?("\n")||''}"
            end
          end
          lines
        else
          measure_logic_text = []
          measure.measure_logic.each do |population|
            measure_logic = {:code => population[:code], :lines => []}
            lines = ''
            population[:lines].each do |line|
              lines << "#{line}#{"\n" unless line.ends_with?("\n")||''}"
            end
            measure_logic[:lines] = lines
            measure_logic_text << measure_logic
          end
          measure_logic_text
        end
      end

      def self.get_measure_logic_diff(measure, other, by_population=false)
        return if other.nil?
        measure_totals = {:total => 0, :deletions => 0, :insertions => 0, :unchanged => 0}
        unless by_population
          compute_diff(get_measure_logic_text(measure), get_measure_logic_text(other), measure_totals)
        else
          measure_text = get_measure_logic_text(measure, by_population)
          other_text = get_measure_logic_text(other, by_population)
          verify_populations(measure_text, other_text)
          diff = {:cms_id => measure.cms_id, :populations => [], :totals => {}}
          measure_text.each_with_index do |population, index|
            population_totals = {:total => 0, :deletions => 0, :insertions => 0, :unchanged => 0}
            first = population[:lines] rescue binding.pry
            second = other_text.at(index)[:lines] rescue binding.pry
            diff[:populations] << compute_diff(first, second, population_totals, population[:code])
            measure_totals[:total] += population_totals[:total]
            measure_totals[:deletions] += population_totals[:deletions]
            measure_totals[:insertions] += population_totals[:insertions]
            measure_totals[:unchanged] += population_totals[:unchanged]
          end
          diff[:totals] = measure_totals
          diff
        end
      end

      private

      def self.compute_diff(text1, text2, totals, code='test')
        diffs = Diffy::Diff.new(text1, text2, :include_plus_and_minus_in_html => true, :allow_empty_diff => false)
        # File.write("#{code}.html", "<html>\n<style>#{Diffy::CSS}</style>\n#{diffs.to_s(:html)}\n</html>")
        results = {:code => code, :lines => []}
        diffs.each_with_index do |line, ind|
          case line
          when /^\+/
            totals[:insertions] += 1
            results[:lines] << :ins
          when /^-/
            totals[:deletions] += 1
            results[:lines] << :del
          else
            totals[:unchanged] += 1
            results[:lines] << :unchanged
          end
          totals[:total] += 1
        end
        results.merge! totals
      end

      def self.verify_populations(measure_text, other_text)
        measure_codes = measure_text.map { |p| p[:code] }
        other_codes = other_text.map { |p| p[:code] }
        index = 0
        HQMF::PopulationCriteria::ALL_POPULATION_CODES.each do |code|
          overlap = measure_codes | other_codes
          next if !overlap.include?(code)
          if !measure_codes.include?(code)
            measure_text.insert(index, {:code => code, :lines => []})
          elsif !other_codes.include?(code)
            other_text.insert(index, {:code => code, :lines => []})
          end
          index += 1
        end
      end

    end
  end
end
