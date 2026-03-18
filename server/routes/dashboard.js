const express = require('express');
const User = require('../models/User');
const { requireAuth } = require('../middleware/auth');
const Order = require('../models/Order');
const Enrollment = require('../models/Enrollment');
const { findCourseById } = require('../data/courses');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).lean();
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const [orders, completedEnrollments] = await Promise.all([
      Order.find({ user_id: req.user.id }).sort({ createdAt: -1 }).lean(),
      Enrollment.find({ user_id: req.user.id, status: 'completed' })
        .sort({ completed_at: -1 })
        .lean(),
    ]);

    const completions = { PE: [], CE: [] };
    for (const enrollment of completedEnrollments) {
      const course = findCourseById(enrollment.course_id);
      const courseSnapshot = {
        _id: enrollment.course_id,
        title: course?.title || enrollment.course_id,
        type: course?.type || 'PE',
        credit_hours: course?.credit_hours || 0,
      };

      const completionEntry = {
        course_id: courseSnapshot,
        completed_at:
          enrollment.completed_at?.toISOString?.() ||
          enrollment.completed_at ||
          enrollment.updatedAt,
        certificate_url: enrollment.certificate_url || null,
      };

      if (String(courseSnapshot.type).toUpperCase() === 'CE') {
        completions.CE.push(completionEntry);
      } else {
        completions.PE.push(completionEntry);
      }
    }

    return res.status(200).json({
      profile: {
        id: user._id,
        name: user.name,
        email: user.email,
        nmls_id: user.nmls_id,
        state: user.state,
        role: user.role,
      },
      completions,
      orders,
    });
  } catch (error) {
    console.error('Dashboard error:', error);
    return res.status(500).json({ message: 'Server error loading dashboard' });
  }
});

module.exports = router;
