require 'test_helper'

class RenderProfilingTest < Minitest::Test
  include Liquid

  def test_template_allows_flagging_profiling
    t = Template.parse("{{ 'a string' | upcase }}")
    t.render!

    assert_nil t.profiler
  end

  def test_parse_makes_available_simple_profiling
    t = Template.parse("{{ 'a string' | upcase }}", profile: true)
    t.render!

    assert_equal 1, t.profiler.length

    node = t.profiler[0]
    assert_equal " 'a string' | upcase ", node.code
  end

  def test_render_ignores_raw_strings_when_profiling
    t = Template.parse("This is raw string\nstuff\nNewline", profile: true)
    t.render!

    assert_equal 0, t.profiler.length
  end

  def test_profiling_includes_line_numbers_of_liquid_nodes
    t = Template.parse("{{ 'a string' | upcase }}\n{% increment test %}", profile: true)
    t.render!
    assert_equal 2, t.profiler.length

    # {{ 'a string' | upcase }}
    assert_equal 1, t.profiler[0].line_number
    # {{ increment test }}
    assert_equal 2, t.profiler[1].line_number
  end

  def test_can_iterate_over_each_profiling_entry
    t = Template.parse("{{ 'a string' | upcase }}\n{% increment test %}", profile: true)
    t.render!

    timing_count = 0
    t.profiler.each do |timing|
      timing_count += 1
    end

    assert_equal 2, timing_count
  end

  def test_profiling_marks_children_of_if_blocks
    t = Template.parse("{% if true %} {% increment test %} {{ test }} {% endif %}", profile: true)
    t.render!

    assert_equal 1, t.profiler.length
    assert_equal 2, t.profiler[0].children.length
  end

  def test_profiling_marks_children_of_for_blocks
    t = Template.parse("{% for item in collection %} {{ item }} {% endfor %}", profile: true)
    t.render!({ "collection" => ["one", "two"] })

    assert_equal 1, t.profiler.length
    # Will profile each invocation of the for block
    assert_equal 2, t.profiler[0].children.length
  end
end
