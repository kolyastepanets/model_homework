class Order < ActiveRecord::Base
  include AASM
  before_save :update_total_price

  validates :completed_date, :aasm_state, :user_id, presence: true

  belongs_to :user
  belongs_to :delivery

  has_many :order_items, dependent: :destroy
  has_one :shipping_address, as: :addressable, class_name: "ShippingAddress"
  accepts_nested_attributes_for :shipping_address

  has_one :billing_address, as: :addressable, class_name: "BillingAddress"
  accepts_nested_attributes_for :billing_address

  has_one :credit_card
  accepts_nested_attributes_for :credit_card

  aasm do
    state :in_progress, initial: true
    state :in_processing
    state :in_delivery
    state :delivered
    state :canceled

    event :process do
      transitions :from => :in_progress, :to => :in_processing
    end

    event :deliver do
      transitions :from => :in_processing, :to => :in_delivery
    end

    event :ship do
      transitions :from => :in_delivery, :to => :delivered
    end

    event :cancel do
      transitions :from => [:in_processing, :in_delivery], :to => :canceled
    end
  end

  def add_book(book_id, quantity = 1, price)
    current_item = order_items.find_by(book_id: book_id)
    if current_item
      current_item.update_attributes(quantity: current_item.quantity + quantity.to_i)
    else
      current_item = order_items.build(book_id: book_id, quantity: quantity, price: price)
    end
    current_item
  end

  def total_price
    order_items.to_a.sum { |item| item.total_price }
  end

  def delivery_price
    delivery.nil? ? 0 : delivery.price
  end

  def total_price_with_delivery
    total_price + delivery_price
  end

  def building_billing_address
    build_billing_address unless billing_address
  end

  def building_shipping_address
    build_shipping_address unless shipping_address
  end

  def build_both_addresses
    building_billing_address
    building_shipping_address
  end

  def building_credit_card
    build_credit_card unless credit_card
  end

  def updating_both_addresses(params, coping)
    if coping
      params[:shipping_address_attributes] = params[:billing_address_attributes]
      update_attributes(params)
    else
      update_attributes(params)
    end
  end

  private

    def update_total_price
      self.total_price = total_price_with_delivery
    end

end
