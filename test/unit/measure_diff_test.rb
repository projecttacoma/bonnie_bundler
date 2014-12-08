require 'test_helper'

class MeasureDiffTest < ActiveSupport::TestCase

  test "loading previous measure" do
    @previous_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_DEMO.zip')
    dump_db
    Measures::MATLoader.load(@previous_measure, nil, {})
    Measure.all.count.must_equal 1
    measure = Measure.all.first
    measure.title.must_equal "Discharged on Antithrombotic Therapy"
    measure.hqmf_id.must_equal "40280381-3D27-5493-013D-4DCA4B826AE4"
    measure.populations.size.must_equal 1
    measure.population_criteria.keys.count.must_equal 5
  end

  test "loading updated measure" do
    @updated_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_FIXED.zip')
    dump_db
    Measures::MATLoader.load(@updated_measure, nil, {})
    Measure.all.count.must_equal 1
    measure = Measure.all.first
    measure.title.must_equal "Discharged on Antithrombotic Therapy"
    measure.hqmf_id.must_equal "40280381-3D27-5493-013D-4DCA4B826AE4"
    measure.populations.size.must_equal 1
    measure.population_criteria.keys.count.must_equal 5
  end

  test "loading w previous against updated" do
    dump_db
    @previous_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_DEMO.zip')
    Measures::MATLoader.load(@previous_measure, nil, {})
    Measure.all.count.must_equal 1
    previous = Measure.all.first
    @updated_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_FIXED.zip')
    Measures::MATLoader.load(@updated_measure, nil, {})
    Measure.all.count.must_equal 2
    updated = Measure.all.last
    assert !updated.latest_diff.blank?
  end

end