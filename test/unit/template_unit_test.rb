require 'test_helper'

class TemplateUnitTest < Minitest::Test
  include Liquid

  def test_with_cache_classes_tags_returns_the_same_class
    original_cache_setting = Liquid.cache_classes
    Liquid.cache_classes = true

    original_klass = Class.new
    Object.send(:const_set, :CustomTag, original_klass)
    Template.register_tag('custom', CustomTag)

    Object.send(:remove_const, :CustomTag)

    new_klass = Class.new
    Object.send(:const_set, :CustomTag, new_klass)

    assert Template.tags['custom'].equal?(original_klass)
  ensure
    Object.send(:remove_const, :CustomTag)
    Template.tags.delete('custom')
    Liquid.cache_classes = original_cache_setting
  end

  def test_without_cache_classes_tags_reloads_the_class
    original_cache_setting = Liquid.cache_classes
    Liquid.cache_classes = false

    original_klass = Class.new
    Object.send(:const_set, :CustomTag, original_klass)
    Template.register_tag('custom', CustomTag)

    Object.send(:remove_const, :CustomTag)

    new_klass = Class.new
    Object.send(:const_set, :CustomTag, new_klass)

    assert Template.tags['custom'].equal?(new_klass)
  ensure
    Object.send(:remove_const, :CustomTag)
    Template.tags.delete('custom')
    Liquid.cache_classes = original_cache_setting
  end

  class FakeTag; end

  def test_tags_delete
    Template.register_tag('fake', FakeTag)
    assert_equal FakeTag, Template.tags['fake']

    Template.tags.delete('fake')
    assert_nil Template.tags['fake']
  end

  def test_tags_can_be_looped_over
    Template.register_tag('fake', FakeTag)
    result = Template.tags.map { |name, klass| [name, klass] }
    assert result.include?(["fake", "TemplateUnitTest::FakeTag"])
  ensure
    Template.tags.delete('fake')
  end
end
