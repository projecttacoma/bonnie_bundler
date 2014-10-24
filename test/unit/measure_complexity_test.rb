require 'test_helper'

class MeasureComplexityTest < ActiveSupport::TestCase

  setup do
    dump_db
    bundle = File.new File.join('test','fixtures','bundle-tiny.zip')
    Measures::BundleLoader.load(bundle, nil)
  end

  # Just a regression test
  test "calculate complexity" do
    Measure.count.must_equal 2
    Measure.first.complexity[:populations].must_equal({ "DENEX"=>2, "NUMER"=>2, "DENOM"=>1, "IPP"=>8})
    Measure.last.complexity[:populations].must_equal({ "DENEX"=>1, "NUMER"=>2, "NUMER_1"=>6, "DENOM"=>1, "IPP"=>10, "IPP_1"=>11, "IPP_2"=>10 })
  end

end
