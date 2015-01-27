require 'test_helper'

class LoadMeasureLogicTest < ActiveSupport::TestCase

  setup do
    @mat_export = File.new File.join('test','fixtures','07_ExclusiveBreastMilkFeeding_Artifacts.zip')
  end

  test "Loading a MAT export zip file" do
    dump_db
    Measures::MATLoader.load(@mat_export, nil, {})
    Measure.all.count.must_equal 1
    measure = Measure.all.first
    measure.title.must_equal "Exclusive Breast Milk Feeding"
    measure.hqmf_id.must_equal "40280381-3D27-5493-013D-4DC3477E6961"
    measure.populations.size.must_equal 2
    measure.population_criteria.keys.count.must_equal 10
  end

end