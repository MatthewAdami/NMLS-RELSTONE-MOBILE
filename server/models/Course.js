const mongoose = require('mongoose');

const courseModuleSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, trim: true },
    hours: { type: Number, default: 0, min: 0 },
  },
  { _id: false }
);

const courseSchema = new mongoose.Schema(
  {
    _id: { type: String, required: true, trim: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, default: '', trim: true },
    type: { type: String, enum: ['PE', 'CE', 'EXAM_PREP'], required: true },
    credit_hours: { type: Number, default: 0, min: 0 },
    price: { type: Number, default: 0, min: 0 },
    has_textbook: { type: Boolean, default: false },
    textbook_price: { type: Number, default: 0, min: 0 },
    states_approved: { type: [String], default: [] },
    modules: { type: [courseModuleSchema], default: [] },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Course', courseSchema);
