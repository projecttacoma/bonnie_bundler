require 'test_helper'

class MeasureComplexityTest < ActiveSupport::TestCase

  setup do
    dump_db
    bundle = File.new File.join('test','fixtures','bundle-tiny.zip')
    Measures::BundleLoader.load(bundle, nil)
  end

  # Just a regression test
  test "calculate complexity" do
    assert_equal 2, Measure.count
    assert_equal Measure.first.complexity[:populations], [{"name"=>"DENEX", "complexity"=>2}, {"name"=>"NUMER", "complexity"=>2}, {"name"=>"DENOM", "complexity"=>1}, {"name"=>"IPP", "complexity"=>8}]
    assert_equal Measure.last.complexity[:populations], [{"name"=>"DENEX", "complexity"=>1}, {"name"=>"NUMER", "complexity"=>2}, {"name"=>"NUMER_1", "complexity"=>6}, {"name"=>"DENOM", "complexity"=>1}, {"name"=>"IPP", "complexity"=>10}, {"name"=>"IPP_1", "complexity"=>11}, {"name"=>"IPP_2", "complexity"=>10}]
  end

end
