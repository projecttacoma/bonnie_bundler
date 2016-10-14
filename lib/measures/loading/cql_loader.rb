module Measures
  # Utility class for loading CQL measure definitions into the database
  class CqlLoader

    def self.mat_cql_export?(zip_file)
      Zip::ZipFile.open(zip_file.path) do |zip_file|
        # Check for CQL and ELM
        cql_entry = zip_file.glob(File.join('**','**.cql')).select {|x| x.name.match(/.*CQL.cql/) && !x.name.starts_with?('__MACOSX') }.first

        !cql_entry.nil?
      end
    end

    def self.load_mat_cql_exports(user, file, out_dir, measure_details)
      measure = nil

      Zip::ZipFile.open(file.path) do |zip_file|
        cql_entry = zip_file.glob(File.join('**','**.cql')).select {|x| x.name.match(/.*CQL.cql/) && !x.name.starts_with?('__MACOSX') }.first

        begin
          cql_path = extract(zip_file, cql_entry, out_dir) if cql_entry && cql_entry.size > 0

          model = Measures::Loader.parse_hqmf_model(hqmf_path)
          json = model.to_json
          json.convert_keys_to_strings
          measure = load_hqmf_cql_model_json(json, user)
          measure.update_attributes(measure_details)

        rescue Exception => e
          raise MeasureLoadingException.new "Error Parsing Measure Logic: #{e.message}"
        end

        puts "measure #{measure.cms_id || measure.measure_id} successfully loaded."
      end

      measure
    end

    def load_hqmf_cql_model_json(json, user)
      measure = CqlMeasure.new

      # TODO



      measure
    end

  end
end
