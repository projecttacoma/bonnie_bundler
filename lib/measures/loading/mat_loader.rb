module Measures
  # Utility class for loading measure definitions into the database from the MAT export zip
  class MATLoader 

    def self.load(file, user, measure_details)
      measure = nil
      Dir.mktmpdir do |dir|
        measure = load_mat_exports(user, file, dir, measure_details)
      end
      measure
    end

    def self.mat_export?(zip_file)
      Zip::ZipFile.open(zip_file.path) do |zip_file|
        hqmf_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*eMeasure.xml/) && !x.name.starts_with?('__MACOSX') }.first
        simplexml_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*SimpleXML.xml/) && !x.name.starts_with?('__MACOSX') }.first
        xls_entry = zip_file.glob(File.join('**','**.xls')).select {|x| !x.name.starts_with?('__MACOSX') }.first
        (!hqmf_entry.nil? || !simplexml_entry.nil?) && !xls_entry.nil?
      end
    end

    def self.load_mat_exports(user, file, out_dir, measure_details)
      measure = nil
      Zip::ZipFile.open(file.path) do |zip_file|

        hqmf_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*eMeasure.xml/) && !x.name.starts_with?('__MACOSX') }.first
        simplexml_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*SimpleXML.xml/) && !x.name.starts_with?('__MACOSX') }.first
        html_entry = zip_file.glob(File.join('**','**.html')).select {|x| x.name.match(/.*HumanReadable.html/) && !x.name.starts_with?('__MACOSX') }.first
        xls_entry = zip_file.glob(File.join('**','**.xls')).select {|x| !x.name.starts_with?('__MACOSX') }.first

        begin

          xml_entry = hqmf_entry || simplexml_entry
          xml_entry = simplexml_entry if hqmf_entry && hqmf_entry.size == 0
          xml_path = extract(zip_file, xml_entry, out_dir)
          html_path = extract(zip_file, html_entry, out_dir)
          xls_path = extract(zip_file, xls_entry, out_dir)

          # handle value sets
          begin
            value_set_models = Measures::ValueSetLoader.load_value_sets_from_xls(xls_path)
          rescue Exception => e
            if e.is_a? Measures::ValueSetException
              raise e
            else
              raise ValueSetException.new "Error Parsing Value Sets: #{e.message}" unless e.is_a? Measures::ValueSetException
            end
          end

          Measures::ValueSetLoader.save_value_sets(value_set_models,user)
          model = Measures::Loader.parse_hqmf_model(xml_path)
          model.backfill_patient_characteristics_with_codes(HQMF2JS::Generator::CodesToJson.from_value_sets(value_set_models))

          json = model.to_json
          json.convert_keys_to_strings
          measure = Measures::Loader.load_hqmf_model_json(json, user,value_set_models.collect{|vs| vs.oid})
          measure.update_attributes(measure_details)

        rescue Exception => e
          if e.is_a? Measures::ValueSetException
            raise e
          else
            raise MeasureLoadingException.new "Error Parsing Measure Logic: #{e.message}" 
          end
        end

        puts "measure #{measure.cms_id || measure.measure_id} successfully loaded."
      end
      measure
    end

    def self.extract(zip_file, entry, out_dir) 
      out_file = File.join(out_dir,Pathname.new(entry.name).basename.to_s)
      zip_file.extract(entry, out_file)
      out_file
    end

  end

end
