module Measures
  # Utility class for loading CQL measure definitions into the database
  class CqlLoader

    def self.mat_cql_export?(zip_file)
      Zip::ZipFile.open(zip_file.path) do |zip_file|
        # Check for CQL and ELM
        cql_entry = zip_file.glob(File.join('**','**.cql')).select {|x| x.name.match(/.*CQL.cql/) && !x.name.starts_with?('__MACOSX') }.first
        hqmf_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*eMeasure.xml/) && !x.name.starts_with?('__MACOSX') }.first
        !(cql_entry.nil? && hqmf_entry.nil?)
      end
    end

    def self.load_mat_cql_exports(user, file, out_dir, measure_details, vsac_user, vsac_password, overwrite_valuesets=true, cache=false, effectiveDate=nil, includeDraft=false, ticket_granting_ticket=nil)
      measure = nil
      cql = nil
      hqmf_path = nil
      elm = ''

      # Open the zip and grab the
      Zip::ZipFile.open(file.path) do |zip_file|
        cql_entry = zip_file.glob(File.join('**','**.cql')).select {|x| x.name.match(/.*CQL.cql/) && !x.name.starts_with?('__MACOSX') }.first
        hqmf_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*eMeasure.xml/) && !x.name.starts_with?('__MACOSX') }.first
        xls_entry = zip_file.glob(File.join('**','**.xls')).select {|x| !x.name.starts_with?('__MACOSX') }.first

        begin
          cql_path = extract(zip_file, cql_entry, out_dir) if cql_entry && cql_entry.size > 0
          hqmf_path = extract(zip_file, hqmf_entry, out_dir) if hqmf_entry && hqmf_entry.size > 0
          xls_path = extract(zip_file, xls_entry, out_dir)

          cql = open(cql_path).read
        rescue Exception => e
          raise MeasureLoadingException.new "Error Parsing Measure Logic: #{e.message}"
        end
      end

      begin
        elm = RestClient.post('http://localhost:8080/cql/translator', cql, content_type: 'application/cql', accept: 'application/elm+json', timeout: 10)
        elm.gsub! 'urn:oid:', '' # Removes 'urn:oid:' from ELM for Bonnie
      rescue RestClient::BadRequest => e
        errors = JSON.parse(e.response)['library']['annotation'].map { |a| "Line #{a['startLine']}: #{a['message']}" }
        flash[:error] = {
          title: "Error Loading Measure",
          summary: "Error converting CQL measure into ELM.",
          body: errors.join("<br>")
        }
        return
      end

      # Load hqmf into HQMF Parser
      model = Measures::Loader.parse_hqmf_model(hqmf_path)

      # Get Value Sets
      begin
        value_set_models =  Measures::ValueSetLoader.load_value_sets_from_vsac(model.all_code_set_oids, vsac_user, vsac_password, user, overwrite_valuesets, effectiveDate, includeDraft, ticket_granting_ticket)
      rescue Exception => e
        raise VSACException.new "Error Loading Value Sets from VSAC: #{e.message}"
      end

      # Create CQL Measure
      model.backfill_patient_characteristics_with_codes(HQMF2JS::Generator::CodesToJson.from_value_sets(value_set_models))
      json = model.to_json
      json.convert_keys_to_strings
      measure = load_hqmf_cql_model_json(json, user, value_set_models.collect{|vs| vs.oid}, JSON.parse(elm), cql)

      puts "measure #{measure.cms_id || measure.measure_id} successfully loaded."
      measure
    end

    def self.load_hqmf_cql_model_json(json, user, measure_oids, elm, cql)
      measure = CqlMeasure.new
      measure.user = user if user
      measure.cql = cql
      measure.elm = elm

      # Add metadata
      measure.hqmf_id = json["hqmf_id"]
      measure.hqmf_set_id = json["hqmf_set_id"]
      measure.hqmf_version_number = json["hqmf_version_number"]
      measure.cms_id = json["cms_id"]
      measure.title = json["title"]
      measure.description = json["description"]
      measure.measure_attributes = json["attributes"]
      measure.value_set_oids = measure_oids

      measure.data_criteria = json["data_criteria"]
      measure.source_data_criteria = json["source_data_criteria"]
      measure.populations = json['populations']
    #  puts "\tCould not find episode ids #{measure.episode_ids} in measure #{measure.cms_id || measure.measure_id}" if (measure.episode_ids && measure.episode_of_care && (measure.episode_ids - measure.source_data_criteria.keys).length > 0)
      measure.measure_period = json["measure_period"]
      measure.population_criteria = json["population_criteria"]
      measure.populations_cql_map = json["populations_cql_map"]

      measure
    end

    #TODO Move to base class (Duplicate in hqmf_loader)
    def self.extract(zip_file, entry, out_dir)
      out_file = File.join(out_dir,Pathname.new(entry.name).basename.to_s)
      zip_file.extract(entry, out_file)
      out_file
    end
  end
end
