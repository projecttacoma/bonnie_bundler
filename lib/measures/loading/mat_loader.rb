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
      Measures::CqlLoader.mat_cql_export?(zip_file) || Measures::HQMFLoader.mat_hqmf_export?(zip_file)
    end

    def self.load_mat_exports(user, file, out_dir, measure_details)
      measure = nil
      cql_entry = nil
      hqmf_entry = nil
      simplexml_entry = nil
      xls_entry = nil
      Zip::ZipFile.open(file.path) do |zip_file|
        # Check for CQL file
        cql_entry = zip_file.glob(File.join('**','**.cql')).select {|x| x.name.match(/.*CQL.cql/) && !x.name.starts_with?('__MACOSX') }.first
        # Check for HQMF file
        hqmf_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*eMeasure.xml/) && !x.name.starts_with?('__MACOSX') }.first
        # Check for SimpleXML file
        simplexml_entry = zip_file.glob(File.join('**','**.xml')).select {|x| x.name.match(/.*SimpleXML.xml/) && !x.name.starts_with?('__MACOSX') }.first
        # Check for excel value set file
        xls_entry = zip_file.glob(File.join('**','**.xls')).select {|x| !x.name.starts_with?('__MACOSX') }.first
      end
      if cql_entry.nil?
        measure = Measures::CqlLoader.load_mat_cql_exports(user, file, out_dir, measure_details)
      elsif (hqmf_entry.nil? || simplexml_entry.nil?) && xls_entry.nil?
        measure = Measures::HqmfLoader.load_mat_hqmf_exports(user, file, out_dir, measure_details)

      measure
    end

    def self.extract(zip_file, entry, out_dir)
      out_file = File.join(out_dir,Pathname.new(entry.name).basename.to_s)
      zip_file.extract(entry, out_file)
      out_file
    end

  end

end
