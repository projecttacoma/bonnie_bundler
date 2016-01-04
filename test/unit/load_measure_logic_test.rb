require 'test_helper'

class LoadMeasureLogicTest < ActiveSupport::TestCase

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

end
