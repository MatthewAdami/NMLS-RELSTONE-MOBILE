const express = require('express');
const mongoose = require('mongoose');
const { requireAuth } = require('../middleware/auth');
const Enrollment = require('../models/Enrollment');
const User = require('../models/User');

const router = express.Router();

const DAY_MS = 24 * 60 * 60 * 1000;

function asDate(value) {
  const d = value ? new Date(value) : null;
  return d && !Number.isNaN(d.getTime()) ? d : null;
}

function daysUntil(target) {
  const now = new Date();
  return Math.ceil((target.getTime() - now.getTime()) / DAY_MS);
}

function makeItem({ id, type, title, message, createdAt, severity = 'info' }) {
  return {
    id,
    type,
    title,
    message,
    severity,
    createdAt: createdAt.toISOString(),
  };
}

function objectIdOrRaw(id) {
  if (mongoose.Types.ObjectId.isValid(id)) {
    return new mongoose.Types.ObjectId(id);
  }
  return id;
}

router.get('/', requireAuth, async (req, res) => {
  try {
    const db = mongoose.connection.db;
    if (!db) throw new Error('Database connection is not initialized');

    const user = await User.findById(req.user.id).lean();
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const userIdRaw = req.user.id;
    const userId = objectIdOrRaw(req.user.id);
    const userFilters = [{ user_id: userIdRaw }];
    if (userId !== userIdRaw) userFilters.push({ user_id: userId });

    const [enrollments, quizAttempts, stateCourses, dbNotifications] = await Promise.all([
      Enrollment.find({ user_id: req.user.id }).sort({ updatedAt: -1 }).lean(),
      db
        .collection('quizattempts')
        .find({ $or: userFilters })
        .sort({ createdAt: -1 })
        .limit(10)
        .toArray(),
      user.state
        ? db
            .collection('courses')
            .find({
              is_active: { $ne: false },
              states_approved: { $in: [String(user.state).toUpperCase()] },
            })
            .sort({ createdAt: -1 })
            .limit(10)
            .toArray()
        : [],
      db
        .collection('notifications')
        .find({
          $or: [
            { audience: 'all' },
            { user_id: userIdRaw },
            { user_id: userId },
            ...(user.state ? [{ states: { $in: [String(user.state).toUpperCase()] } }] : []),
          ],
        })
        .sort({ createdAt: -1 })
        .limit(15)
        .toArray()
        .catch(() => []),
    ]);

    const items = [];

    // Course completion milestones
    for (const enrollment of enrollments) {
      const progress = Number(enrollment.progress_percent || 0);
      const titleBase = `Course ${enrollment.course_id}`;
      const updatedAt = asDate(enrollment.updatedAt) || new Date();

      if (enrollment.status === 'completed') {
        items.push(
          makeItem({
            id: `completion-${enrollment._id}`,
            type: 'course_completion_milestone',
            title: 'Course Completed',
            message: `${titleBase}: Great job, you completed this course.`,
            createdAt: asDate(enrollment.completed_at) || updatedAt,
            severity: 'success',
          })
        );
        continue;
      }

      const milestone = progress >= 0.75 ? 75 : progress >= 0.5 ? 50 : progress >= 0.25 ? 25 : 0;
      if (milestone > 0) {
        items.push(
          makeItem({
            id: `milestone-${enrollment._id}-${milestone}`,
            type: 'course_completion_milestone',
            title: `${milestone}% Milestone Reached`,
            message: `${titleBase}: You reached ${milestone}% progress. Keep going.`,
            createdAt: updatedAt,
            severity: 'info',
          })
        );
      }
    }

    // Quiz results and retake eligibility
    for (const attempt of quizAttempts.slice(0, 6)) {
      const scorePct = Number(attempt.score_pct || 0);
      const passed = attempt.passed === true;
      const title = String(attempt.quiz_title || 'Quiz').trim();
      const when = asDate(attempt.submitted_at || attempt.createdAt) || new Date();

      items.push(
        makeItem({
          id: `quiz-result-${attempt._id}`,
          type: 'quiz_result',
          title: `Quiz Result: ${title}`,
          message: passed
            ? `You passed with ${scorePct.toFixed(1)}%.`
            : `You scored ${scorePct.toFixed(1)}%. Retake is available now.`,
          createdAt: when,
          severity: passed ? 'success' : 'warning',
        })
      );

      if (!passed) {
        items.push(
          makeItem({
            id: `quiz-retake-${attempt._id}`,
            type: 'retake_eligibility',
            title: `Retake Eligible: ${title}`,
            message: 'You can retake this quiz to improve your score.',
            createdAt: when,
            severity: 'warning',
          })
        );
      }
    }

    // CE renewal reminders (30/60/90 day windows)
    const ceCompletion = enrollments
      .filter((e) => e.status === 'completed' && e.course_id && String(e.course_id).toLowerCase().includes('ce'))
      .sort((a, b) => {
        const da = asDate(a.completed_at || a.updatedAt)?.getTime() || 0;
        const dbv = asDate(b.completed_at || b.updatedAt)?.getTime() || 0;
        return dbv - da;
      })[0];

    const renewalAnchor = asDate(ceCompletion?.completed_at || ceCompletion?.updatedAt || user.createdAt) || new Date();
    const renewalDeadline = new Date(renewalAnchor.getTime());
    renewalDeadline.setFullYear(renewalDeadline.getFullYear() + 1);
    const daysLeft = daysUntil(renewalDeadline);

    let windowLabel = null;
    if (daysLeft >= 61 && daysLeft <= 90) windowLabel = 90;
    if (daysLeft >= 31 && daysLeft <= 60) windowLabel = 60;
    if (daysLeft >= 0 && daysLeft <= 30) windowLabel = 30;

    if (windowLabel) {
      items.push(
        makeItem({
          id: `ce-renewal-${windowLabel}`,
          type: 'ce_renewal_reminder',
          title: `CE Renewal Reminder (${windowLabel}-Day)`,
          message: `Your CE renewal deadline is in ${daysLeft} day(s). Complete required CE before ${renewalDeadline.toDateString()}.`,
          createdAt: new Date(),
          severity: windowLabel === 30 ? 'warning' : 'info',
        })
      );
    }

    // New courses in student's state
    const recentStateCourses = stateCourses.filter((course) => {
      const createdAt = asDate(course.createdAt);
      if (!createdAt) return false;
      const ageDays = Math.floor((Date.now() - createdAt.getTime()) / DAY_MS);
      return ageDays <= 45;
    });

    for (const course of recentStateCourses.slice(0, 4)) {
      items.push(
        makeItem({
          id: `new-course-${course._id}`,
          type: 'new_course_state',
          title: 'New Course In Your State',
          message: `${course.title} is now available for ${String(user.state || '').toUpperCase()}.`,
          createdAt: asDate(course.createdAt) || new Date(),
          severity: 'info',
        })
      );
    }

    // Promotional offers + system announcements
    const now = new Date();
    const systemDefaults = [
      makeItem({
        id: 'promo-default-1',
        type: 'promotional_offer',
        title: 'Limited-Time Offer',
        message: 'Save 15% on selected CE bundles this week at Relstone.',
        createdAt: now,
        severity: 'info',
      }),
      makeItem({
        id: 'announcement-default-1',
        type: 'system_announcement',
        title: 'Relstone System Announcement',
        message: 'New student portal improvements are now live for faster quiz feedback.',
        createdAt: now,
        severity: 'info',
      }),
    ];

    for (const notice of dbNotifications.slice(0, 6)) {
      const nType = String(notice.type || '').toLowerCase();
      let type = 'system_announcement';
      if (nType.includes('promo') || nType.includes('offer')) type = 'promotional_offer';
      if (nType.includes('announcement')) type = 'system_announcement';

      items.push(
        makeItem({
          id: `db-notice-${notice._id}`,
          type,
          title: String(notice.title || 'Relstone Notice'),
          message: String(notice.message || notice.body || 'You have a new update from Relstone.'),
          createdAt: asDate(notice.createdAt || notice.updatedAt) || new Date(),
          severity: 'info',
        })
      );
    }

    if (!dbNotifications.length) {
      items.push(...systemDefaults);
    }

    items.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    return res.status(200).json({
      total: items.length,
      notifications: items.slice(0, 40),
    });
  } catch (error) {
    console.error('Notifications load error:', error);
    return res.status(500).json({ message: 'Server error loading notifications' });
  }
});

module.exports = router;
