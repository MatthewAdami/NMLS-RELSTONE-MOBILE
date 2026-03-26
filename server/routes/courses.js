const express = require('express');
const { requireAuth } = require('../middleware/auth');
const User = require('../models/User');
const Enrollment = require('../models/Enrollment');
const Course = require('../models/Course');
const { findCourseById } = require('../data/courses');

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

    const assignedCourseIds = (user.assigned_course_ids || [])
      .map((entry) => String(entry).trim())
      .filter(Boolean);
    const assignedSet = new Set(assignedCourseIds);

    // Primary source: MongoDB courses collection.
    // Fallback: in-memory seed list for any assigned IDs not yet migrated.
    const dbCourses = assignedCourseIds.length
      ? await Course.find({ _id: { $in: assignedCourseIds } }).lean()
      : [];
    const dbById = new Map(dbCourses.map((course) => [course._id, course]));

    const scopedAssignedCourses = assignedCourseIds
      .map((courseId) => dbById.get(courseId) || findCourseById(courseId))
      .filter(Boolean)
      .filter((course) => assignedSet.has(String(course._id)));

    const normalizedType = type ? String(type).toUpperCase() : null;
    const normalizedState = state ? String(state).toUpperCase() : null;

    const result = scopedAssignedCourses.filter((course) => {
      const matchesType =
        !normalizedType ||
        String(course.type || '').toUpperCase() === normalizedType;
      const statesApproved = Array.isArray(course.states_approved)
        ? course.states_approved.map((entry) => String(entry).toUpperCase())
        : [];
      const matchesState =
        !normalizedState || statesApproved.includes(normalizedState);
      return matchesType && matchesState;
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

// ─── GET /api/courses/available ─────────────────────────────────────────────
// Used by the Course Catalog to browse courses by the user's state (and optional type).
// Unlike `GET /api/courses`, this does NOT depend on `assigned_course_ids`.
router.get('/available', requireAuth, async (req, res) => {
  try {
    const { type, state } = req.query;

    // Prefer the authenticated user's state to prevent users from browsing
    // courses outside their allowed state.
    const user = await User.findById(req.user.id).select('state').lean();
    if (!user) return res.status(404).json({ message: 'User not found' });

    const userState = String(user.state || state || '').toUpperCase().trim();
    if (!userState || userState === 'NOT SET') {
      return res
        .status(400)
        .json({ message: 'User state is required to browse courses' });
    }

    const normalizedType = type ? String(type).toUpperCase().trim() : null;
    const filter = {
      states_approved: { $in: [userState] },
    };

    // Many course docs include `is_active`; if missing, Mongo will treat it as null,
    // and `$ne: false` will still match (so we don't accidentally hide courses).
    filter.is_active = { $ne: false };

    if (normalizedType && normalizedType !== 'ALL') {
      filter.type = normalizedType;
    }

    const courses = await Course.find(filter).lean();
    return res.status(200).json(courses);
  } catch (error) {
    console.error('Courses available route error:', error);
    return res.status(500).json({ message: 'Server error loading available courses' });
  }
});

// ─── GET /api/courses/:id ───────────────────────────────────────────────────
// Used by the Course Details screen. We enforce that the course matches the
// user's state.
router.get('/:id', requireAuth, async (req, res) => {
  try {
    const { id } = req.params;

    const user = await User.findById(req.user.id).select('state').lean();
    if (!user) return res.status(404).json({ message: 'User not found' });

    const userState = String(user.state || '').toUpperCase().trim();
    if (!userState || userState === 'NOT SET') {
      return res.status(400).json({ message: 'User state is required' });
    }

    const course = await Course.findOne({
      _id: id,
      is_active: { $ne: false },
      states_approved: { $in: [userState] },
    }).lean();

    if (!course) return res.status(404).json({ message: 'Course not found' });
    return res.status(200).json(course);
  } catch (error) {
    console.error('Course details route error:', error);
    return res.status(500).json({ message: 'Server error loading course details' });
  }
});

module.exports = router;
