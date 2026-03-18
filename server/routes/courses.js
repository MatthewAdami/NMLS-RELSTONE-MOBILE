const express = require('express');
const { requireAuth } = require('../middleware/auth');
const User = require('../models/User');
const Enrollment = require('../models/Enrollment');
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

    const courseIds = result.map((course) => course._id);
    const enrollments = await Enrollment.find({
      user_id: req.user.id,
      course_id: { $in: courseIds },
    }).lean();

    const enrollmentByCourseId = new Map(
      enrollments.map((enrollment) => [enrollment.course_id, enrollment])
    );

    const enriched = result.map((course) => {
      const enrollment = enrollmentByCourseId.get(course._id);
      if (!enrollment) {
        return {
          ...course,
          enrollment_status: 'in_progress',
          progress_percent: 0,
          last_accessed_at: null,
          completed_at: null,
          certificate_url: null,
        };
      }

      return {
        ...course,
        enrollment_status: enrollment.status || 'in_progress',
        progress_percent:
          typeof enrollment.progress_percent === 'number'
            ? enrollment.progress_percent
            : 0,
        last_accessed_at: enrollment.last_accessed_at || null,
        completed_at: enrollment.completed_at || null,
        certificate_url: enrollment.certificate_url || null,
      };
    });

    return res.status(200).json(enriched);
  } catch (error) {
    console.error('Courses route error:', error);
    return res.status(500).json({ message: 'Server error loading courses' });
  }
});

module.exports = router;
