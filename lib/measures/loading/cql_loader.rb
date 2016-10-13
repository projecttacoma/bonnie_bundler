module Measures
  # Utility class for loading CQL measure definitions into the database
  class CqlLoader
    
    def self.mat_cql_export?(zip_file)
      Zip::ZipFile.open(zip_file.path) do |zip_file|
        # Check for CQL and ELM
        cql_entry = zip_file.glob(File.join('**','**.cql')).select {|x| x.name.match(/.*eMeasure.cql/) && !x.name.starts_with?('__MACOSX') }.first
        elm_entry = zip_file.glob(File.join('**','**.elm')).select {|x| x.name.match(/.*eMeasure.elm/) && !x.name.starts_with?('__MACOSX') }.first

        !(cql_entry.nil? || elm_entry.nil?)
      end
    end
    
    def self.load(file, user, measure_details)
      measure = nil
      Dir.mktmpdir do |dir|
        measure = load_mat_cql_exports(file, user, dir, measure_details)
      end
      measure
    end
    
    def self.load_mat_cql_exports(file, user, dir, measure_details)
      measure = nil
      
      Zip::ZipFile.open(file.path) do |zip_file|
        elm_entry = zip_file.glob(File.join('**','**.elm')).select {|x| x.name.match(/.*eMeasure.elm/) && !x.name.starts_with?('__MACOSX') }.first
        cql_entry = zip_file.glob(File.join('**','**.cql')).select {|x| x.name.match(/.*eMeasure.cql/) && !x.name.starts_with?('__MACOSX') }.first

        begin
          elm_path = extract(zip_file, elm_entry, dir) if elm_entry && elm_entry.size > 0
          cql_path = extract(zip_file, cql_entry, dir) if cql_entry && cql_entry.size > 0

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

    def self.extract(zip_file, entry, out_dir) 
      out_file = File.join(out_dir, Pathname.new(entry.name).basename.to_s)
      zip_file.extract(entry, out_file)
      out_file
    end
    
  end
end