const express = require('express');
const { requireAuth } = require('../middleware/auth');
const User = require('../models/User');
const { listCoursesForUser } = require('../data/courses');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  try {
    const { type, state } = req.query;

    const user = await User.findById(req.user.id)
      .select('assigned_course_ids')
      .lean();

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const result = listCoursesForUser({
      assignedCourseIds: user.assigned_course_ids || [],
      type,
      state,
    });

    return res.status(200).json(result);
  } catch (error) {
    console.error('Courses route error:', error);
    return res.status(500).json({ message: 'Server error loading courses' });
  }
});

module.exports = router;
