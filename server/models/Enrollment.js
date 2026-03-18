const mongoose = require('mongoose');

const enrollmentSchema = new mongoose.Schema(
  {
    user_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    course_id: { type: String, required: true, index: true },
    status: {
      type: String,
      enum: ['in_progress', 'completed', 'wishlist'],
      default: 'in_progress',
      index: true,
    },
    progress_percent: {
      type: Number,
      default: 0,
      min: 0,
      max: 1,
    },
    last_accessed_at: { type: Date, default: null },
    completed_at: { type: Date, default: null },
    certificate_url: { type: String, default: null },
  },
  { timestamps: true }
);

enrollmentSchema.index({ user_id: 1, course_id: 1 }, { unique: true });

module.exports = mongoose.model('Enrollment', enrollmentSchema);
