require 'test_helper'

class MeasureDiffTest < ActiveSupport::TestCase

  test "loading previous measure" do
    @previous_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_DEMO.zip')
    dump_db
    Measures::MATLoader.load(@previous_measure, nil, {})
    assert_equal 1, Measure.all.count
    measure = Measure.all.first
    assert_equal "Discharged on Antithrombotic Therapy", measure.title
    assert_equal "40280381-3D27-5493-013D-4DCA4B826AE4", measure.hqmf_id
    assert_equal 1, measure.populations.size
    assert_equal 5, measure.population_criteria.keys.count
  end

  test "loading updated measure" do
    @updated_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_FIXED.zip')
    dump_db
    Measures::MATLoader.load(@updated_measure, nil, {})
    assert_equal 1, Measure.all.count
    measure = Measure.all.first
    assert_equal "Discharged on Antithrombotic Therapy", measure.title
    assert_equal "40280381-3D27-5493-013D-4DCA4B826AE4", measure.hqmf_id
    assert_equal 1, measure.populations.size
    assert_equal 5, measure.population_criteria.keys.count
  end

  test "loading previous against updated" do
    dump_db
    @previous_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_DEMO.zip')
    Measures::MATLoader.load(@previous_measure, nil, {})
    assert_equal 1, Measure.all.count
    previous = Measure.all.first
    @updated_measure = File.new File.join('test','fixtures','05_DischargedonAntithromboticThe_Artifacts_FIXED.zip')
    Measures::MATLoader.load(@updated_measure, nil, {})
    assert_equal 2, Measure.all.count
    updated = Measure.all.last
    assert !previous.diff(updated).blank?
  end

end
