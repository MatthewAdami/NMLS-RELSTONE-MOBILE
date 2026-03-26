const mongoose = require('mongoose');

const orderItemSchema = new mongoose.Schema(
  {
    // In your web app this is populated from a Course model.
    // Here we keep a snapshot object to avoid needing a Course model.
    course_id: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    price: { type: Number, default: 0 },
    include_textbook: { type: Boolean, default: false },
    textbook_price: { type: Number, default: 0 },
  },
  { _id: false }
);

const orderSchema = new mongoose.Schema(
  {
    user_id: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    items: { type: [orderItemSchema], default: [] },
    total_amount: { type: Number, default: 0 },
    status: {
      type: String,
      enum: ['pending', 'paid', 'completed', 'cancelled', 'refunded'],
      default: 'completed',
    },
    payment_reference: { type: String, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Order', orderSchema);

