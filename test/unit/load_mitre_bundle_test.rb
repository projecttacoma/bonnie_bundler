require 'test_helper'

class LoadMiteBundleTest < ActiveSupport::TestCase

  setup do
    @tiny_bundle = File.new File.join('test','fixtures','bundle-tiny.zip')
  end

  test "Loading a MITRE bundle from JSON" do
    dump_db
    Measures::BundleLoader.load(@tiny_bundle, nil)
    Measure.all.count.must_equal 2
    m0002 = Measure.where(hqmf_id: '40280381-3D61-56A7-013E-5D1EF9B76A48').first
    m0004 = Measure.where(hqmf_id: '40280381-3D61-56A7-013E-5B2AA3493C42').first
    assert !m0002.nil?
    assert !m0004.nil?
    m0002.title.must_equal "Appropriate Testing for Children with Pharyngitis"
    m0002.populations.size.must_equal 1
    m0002.population_criteria.keys.count.must_equal 4
    m0004.title.must_equal "Initiation and Engagement of Alcohol and Other Drug Dependence Treatment"
    m0004.populations.size.must_equal 6
    m0004.population_criteria.keys.count.must_equal 7
  end

  test "Loading a MITRE bundle from HQMF" do
    dump_db
    HealthDataStandards::Import::Bundle::Importer.import(@tiny_bundle)
    Measures::BundleLoader.load(@tiny_bundle, nil, nil, true)
    Measure.all.count.must_equal 2
    m0002 = Measure.where(hqmf_id: '40280381-3D61-56A7-013E-5D1EF9B76A48').first
    m0004 = Measure.where(hqmf_id: '40280381-3D61-56A7-013E-5B2AA3493C42').first
    assert !m0002.nil?
    assert !m0004.nil?
    m0002.title.must_equal "Appropriate Testing for Children with Pharyngitis"
    m0002.populations.size.must_equal 1
    m0002.population_criteria.keys.count.must_equal 4
    m0004.title.must_equal "Initiation and Engagement of Alcohol and Other Drug Dependence Treatment"
    m0004.populations.size.must_equal 6
    m0004.population_criteria.keys.count.must_equal 7
  end

end