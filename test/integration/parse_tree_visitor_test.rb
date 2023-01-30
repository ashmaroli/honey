# frozen_string_literal: true

require 'test_helper'

class ParseTreeVisitorTest < Minitest::Test
  include Liquid

  def test_variable
    assert_equal(
      ["test"],
      visit(%({{ test }}))
    )
  end

  def test_varible_with_filter
    assert_equal(
      ["test", "infilter"],
      visit(%({{ test | split: infilter }}))
    )
  end

  def test_dynamic_variable
    assert_equal(
      ["test", "inlookup"],
      visit(%({{ test[inlookup] }}))
    )
  end

  def test_if_condition
    assert_equal(
      ["test"],
      visit(%({% if test %}{% endif %}))
    )
  end

  def test_complex_if_condition
    assert_equal(
      ["test"],
      visit(%({% if 1 == 1 and 2 == test %}{% endif %}))
    )
  end

  def test_if_body
    assert_equal(
      ["test"],
      visit(%({% if 1 == 1 %}{{ test }}{% endif %}))
    )
  end

  def test_unless_condition
    assert_equal(
      ["test"],
      visit(%({% unless test %}{% endunless %}))
    )
  end

  def test_complex_unless_condition
    assert_equal(
      ["test"],
      visit(%({% unless 1 == 1 and 2 == test %}{% endunless %}))
    )
  end

  def test_unless_body
    assert_equal(
      ["test"],
      visit(%({% unless 1 == 1 %}{{ test }}{% endunless %}))
    )
  end

  def test_elsif_condition
    assert_equal(
      ["test"],
      visit(%({% if 1 == 1 %}{% elsif test %}{% endif %}))
    )
  end

  def test_complex_elsif_condition
    assert_equal(
      ["test"],
      visit(%({% if 1 == 1 %}{% elsif 1 == 1 and 2 == test %}{% endif %}))
    )
  end

  def test_elsif_body
    assert_equal(
      ["test"],
      visit(%({% if 1 == 1 %}{% elsif 2 == 2 %}{{ test }}{% endif %}))
    )
  end

  def test_else_body
    assert_equal(
      ["test"],
      visit(%({% if 1 == 1 %}{% else %}{{ test }}{% endif %}))
    )
  end

  def test_case_left
    assert_equal(
      ["test"],
      visit(%({% case test %}{% endcase %}))
    )
  end

  def test_case_condition
    assert_equal(
      ["test"],
      visit(%({% case 1 %}{% when test %}{% endcase %}))
    )
  end

  def test_case_when_body
    assert_equal(
      ["test"],
      visit(%({% case 1 %}{% when 2 %}{{ test }}{% endcase %}))
    )
  end

  def test_case_else_body
    assert_equal(
      ["test"],
      visit(%({% case 1 %}{% else %}{{ test }}{% endcase %}))
    )
  end

  def test_for_in
    assert_equal(
      ["test"],
      visit(%({% for x in test %}{% endfor %}))
    )
  end

  def test_for_limit
    assert_equal(
      ["test"],
      visit(%({% for x in (1..5) limit: test %}{% endfor %}))
    )
  end

  def test_for_offset
    assert_equal(
      ["test"],
      visit(%({% for x in (1..5) offset: test %}{% endfor %}))
    )
  end

  def test_for_body
    assert_equal(
      ["test"],
      visit(%({% for x in (1..5) %}{{ test }}{% endfor %}))
    )
  end

  def test_tablerow_in
    assert_equal(
      ["test"],
      visit(%({% tablerow x in test %}{% endtablerow %}))
    )
  end

  def test_tablerow_limit
    assert_equal(
      ["test"],
      visit(%({% tablerow x in (1..5) limit: test %}{% endtablerow %}))
    )
  end

  def test_tablerow_offset
    assert_equal(
      ["test"],
      visit(%({% tablerow x in (1..5) offset: test %}{% endtablerow %}))
    )
  end

  def test_tablerow_body
    assert_equal(
      ["test"],
      visit(%({% tablerow x in (1..5) %}{{ test }}{% endtablerow %}))
    )
  end

  def test_cycle
    assert_equal(
      ["test"],
      visit(%({% cycle test %}))
    )
  end

  def test_assign
    assert_equal(
      ["test"],
      visit(%({% assign x = test %}))
    )
  end

  def test_capture
    assert_equal(
      ["test"],
      visit(%({% capture x %}{{ test }}{% endcapture %}))
    )
  end

  def test_preserve_tree_structure
    assert_equal(
      [[nil, [
        [nil, [[nil, [["other", []]]]]],
        ["test", []],
        ["xs", []]
      ]]],
      traversal(%({% for x in xs offset: test %}{{ other }}{% endfor %})).visit
    )
  end

  private

  # rubocop:disable Style/SymbolProc
  def traversal(template)
    ParseTreeVisitor
      .for(Template.parse(template).root)
      .add_callback_for(VariableLookup) { |node| node.name }
  end
  # rubocop:enable Style/SymbolProc

  def visit(template)
    traversal(template).visit.flatten.compact
  end
end
