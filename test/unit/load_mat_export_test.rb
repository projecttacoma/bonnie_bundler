require 'test_helper'

class LoadMATExportTest < ActiveSupport::TestCase

  setup do
    @mat_export = File.new File.join('test','fixtures','07_ExclusiveBreastMilkFeeding_Artifacts.zip')
  end

  test "Loading a MAT export zip file" do
    dump_db
    Measures::MATLoader.load(@mat_export, nil, {})
    assert_equal 1, Measure.all.count
    measure = Measure.all.first
    assert_equal "Exclusive Breast Milk Feeding", measure.title 
    assert_equal "40280381-3D27-5493-013D-4DC3477E6961", measure.hqmf_id
    assert_equal 2, measure.populations.size
    assert_equal 10, measure.population_criteria.keys.count
  end

  test "Scoping by user" do
    dump_db
    u = User.new
    u.save
    # make sure that we can load a package and that the meause and valuesets are scoped to the user
    measure = Measures::MATLoader.load(@mat_export, u, {})
    assert_equal 1, Measure.by_user(u).count
    vs_count = HealthDataStandards::SVS::ValueSet.count()
    assert_equal vs_count, HealthDataStandards::SVS::ValueSet.by_user(u).count()
    vs = HealthDataStandards::SVS::ValueSet.by_user(u).first
    vsets = HealthDataStandards::SVS::ValueSet.by_user(u).to_a
   
    # Add the same measure not associated with a user, there should be 2 measures and 
    # and twice as many value sets in the db after loading 
    Measures::MATLoader.load(@mat_export, nil, {})
    assert_equal 1, Measure.by_user(u).count
    assert_equal 2, Measure.count
    assert_equal vs_count, HealthDataStandards::SVS::ValueSet.by_user(u).count()
    assert_equal vs_count * 2, HealthDataStandards::SVS::ValueSet.count
    
    u_count = Measures::ValueSetLoader.get_value_set_models(measure.value_set_oids,u).count()
    assert_equal u_count, Measures::ValueSetLoader.get_value_set_models(measure.value_set_oids,nil).count
    

  end


end
