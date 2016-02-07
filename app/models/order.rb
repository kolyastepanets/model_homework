class Order < ActiveRecord::Base
  include AASM
  before_save :update_total_price

  validates :completed_date, :aasm_state, :user_id, presence: true

  belongs_to :user
  belongs_to :checkout
  # belongs_to :credit_card

  has_many :order_items, dependent: :destroy
  has_one :shipping_address, as: :addressable, class_name: "ShippingAddress"
  accepts_nested_attributes_for :shipping_address

  has_one :billing_address, as: :addressable, class_name: "BillingAddress"
  accepts_nested_attributes_for :billing_address

  aasm do
    state :in_progress, initial: true
    state :complited
    state :shipped

    event :complete do
      transitions :from => :in_progress, :to => :complited
    end

    event :ship do
      transitions :from => :complited, :to => :shipped
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

  def building_billing_address
    build_billing_address unless billing_address
  end

  def building_shipping_address
    build_shipping_address unless shipping_address
  end

  private

    def update_total_price
      self.total_price = total_price
    end

end
