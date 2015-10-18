require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  test "full title helper" do
    assert_equal full_title,         "Sample Rails App"
    assert_equal full_title("Help"), "Help | Sample Rails App"
  end
end