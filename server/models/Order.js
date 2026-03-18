const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    course_id: {
      _id: { type: String, required: true },
      title: { type: String, required: true },
      type: { type: String, required: true },
      credit_hours: { type: Number, required: true },
    },
    price: { type: Number, required: true },
    include_textbook: { type: Boolean, default: false },
    textbook_price: { type: Number, default: 0 },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    status: {
      type: String,
      enum: ['pending', 'paid', 'completed', 'cancelled'],
      default: 'pending',
      index: true,
    },
    total_amount: { type: Number, required: true },
    items: { type: [orderItemSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema);
