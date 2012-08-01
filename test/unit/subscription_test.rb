require File.expand_path(File.dirname(__FILE__)) + '/../test_helper'

require 'google4r/checkout'

require 'test/frontend_configuration'

# Test for the Subscription class.
class Google4R::Checkout::ItemTest < Test::Unit::TestCase
  include Google4R::Checkout

  def setup
    @frontend = Frontend.new(FRONTEND_CONFIGURATION)
    @frontend.tax_table_factory = TestTaxTableFactory.new

    @xml_str = %q{<?xml version="1.0" encoding="UTF-8"?>
      <item>
        <subscription type="google" period="MONTHLY">
          <payments>
            <subscription-payment is-exact="true">
              <maximum-charge currency="USD">1.0</maximum-charge>
            </subscription-payment>
          </payments>
          <recurrent-item>
            <item-name>An interesting subscription</item-name>
            <item-description>A flat rate monthly charge</item-description>
            <unit-price currency="USD">1.0</unit-price>
            <quantity>1</quantity>
          </recurrent-item>
        </subscription>
        <item-name>Interesting Subscription</item-name>
        <item-description>Keep up-to-date with that thing you like</item-description>
        <unit-price currency="USD">0.0</unit-price>
        <quantity>1</quantity>
        <merchant-private-item-data>
          <item-note>Text 1</item-note>
          <item-note>Text 2</item-note>
          <nested>
            <tags>value</tags>
          </nested>
        </merchant-private-item-data>
        <tax-table-selector>Some Table</tax-table-selector>
      </item>
    }
    
    @optional_tags = [ 'merchant-item-id', 'merchant-private-item-data', 'tax-table-selector' ]

    @command = @frontend.create_checkout_command
    @shopping_cart = @command.shopping_cart
    @item = @shopping_cart.create_item
    @digital_content = @item.digital_content
  end
  
  def test_item_behaves_correctly
    [ :shopping_cart,  :name, :name=, :description, :description=, :unit_price, :unit_price=,
      :quantity, :quantity=, :id, :id=, :private_data, :private_data=,
      :tax_table, :tax_table=, :digital_content, :weight, :weight=
    ].each do |symbol|
      assert_respond_to @item, symbol
    end
  end
  
  def test_item_gets_initialized_correctly
    assert_equal @shopping_cart, @item.shopping_cart
    assert_nil @item.name
    assert_nil @item.description
    assert_nil @item.unit_price
    assert_nil @item.quantity
    assert_nil @item.private_data
    assert_nil @item.id
    assert_nil @item.tax_table
    assert_nil @item.digital_content
  end
  
  def test_item_setters_work
    @item.name = "name"
    assert_equal "name", @item.name
    
    @item.description = "description"
    assert_equal "description", @item.description
    
    @item.unit_price = Money.new(100, "EUR")
    assert_equal Money.new(100, "EUR"), @item.unit_price
    
    @item.quantity = 10
    assert_equal 10, @item.quantity
    
    @item.id = "id"
    assert_equal "id", @item.id
    
    @item.private_data = Hash.new
    assert_equal Hash.new, @item.private_data
    
    @item.weight = Weight.new(2.2)
    assert_equal Weight, @item.weight.class
  end
  
  def test_set_tax_table_works
    table = @command.tax_tables.first
    @item.tax_table = table
    assert_equal table, @item.tax_table
  end
  
  def test_set_tax_table_raises_if_table_is_unknown_in_command
    assert_raises(RuntimeError) { @item.tax_table = TaxTable.new(false) }
  end
  
  def test_set_private_data_only_works_with_hashes
    assert_raises(RuntimeError) { @shopping_cart.private_data = 1 }
    assert_raises(RuntimeError) { @shopping_cart.private_data = nil }
    assert_raises(RuntimeError) { @shopping_cart.private_data = 'Foobar' }
    assert_raises(RuntimeError) { @shopping_cart.private_data = [] }
  end
  
  def test_item_price_must_be_money_instance
    assert_raises(RuntimeError) { @item.unit_price = nil }
    assert_raises(RuntimeError) { @item.unit_price = "String" }
    assert_raises(RuntimeError) { @item.unit_price = 10 }
  end

  def test_create_from_element_works
    @optional_tags.power.each do |optional_tag_names|
      xml_str = @xml_str

      optional_tag_names.each { |name| xml_str = xml_str.gsub(%r{<#{name}.*?</#{name}>}, '') }

      command = @frontend.create_checkout_command
      tax_table = TaxTable.new(false)
      tax_table.name = 'Some Table'
      command.tax_tables << tax_table
      item = Item.create_from_element(REXML::Document.new(xml_str).root, command.shopping_cart)
      
      assert_equal command.shopping_cart, item.shopping_cart
      
      assert_equal 'Interesting Subscription', item.name
      assert_equal 'Keep up-to-date with that thing you like', item.description
      assert_equal Money.new(0, 'USD'), item.unit_price
      assert_equal 1, item.quantity

      hash = 
        {
          'item-note' => [ 'Text 1', 'Text 2' ],
          'nested' => { 'tags' => 'value' }
        }
      assert_equal hash, item.private_data unless optional_tag_names.include?('merchant-private-item-data')
      assert_equal 'Some Table', item.tax_table.name unless optional_tag_names.include?('tax-table-selector')

      subscription = item.subscription
      assert_equal 1, subscription.recurrent_items.count
      assert_equal Google4R::Checkout::Item::Subscription::MONTHLY, subscription.period
      assert_equal Google4R::Checkout::Item::Subscription::GOOGLE, subscription.type

      recurrent_item = subscription.recurrent_items.first
      assert_equal 'An interesting subscription', recurrent_item.name
      assert_equal 'A flat rate monthly charge', recurrent_item.description
      assert_equal 1, recurrent_item.quantity
      assert_equal Money.new(100, 'USD'), recurrent_item.unit_price
    end
  end
end
