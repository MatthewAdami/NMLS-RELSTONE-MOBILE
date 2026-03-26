const express = require('express');
const mongoose = require('mongoose');
const { requireAuth } = require('../middleware/auth');
const User = require('../models/User');

const router = express.Router();

function normalizeQuestion(raw, meta) {
  if (!raw || typeof raw !== 'object') return null;

  const prompt = String(raw.question || raw.prompt || '').trim();
  const options = Array.isArray(raw.options)
    ? raw.options.map((entry) => String(entry).trim()).filter(Boolean)
    : [];

  let correctIndex = Number(raw.correct_index);
  if (!Number.isInteger(correctIndex)) {
    correctIndex = Number(raw.correctIndex);
  }

  if (!prompt || options.length < 2) return null;
  if (correctIndex < 0 || correctIndex >= options.length) {
    correctIndex = 0;
  }

  return {
    id: `${meta.courseId}:${meta.moduleOrder}:${raw.number || meta.itemOrder}`,
    courseId: meta.courseId,
    courseTitle: meta.courseTitle,
    topic: meta.topic,
    prompt,
    options,
    correctIndex,
  };
}

function buildFlashcards(questions) {
  const cards = [];
  const seen = new Set();

  for (const q of questions) {
    const answer = Array.isArray(q.options) ? q.options[q.correctIndex] : null;
    if (!answer) continue;

    const key = `${q.topic}::${q.prompt}`;
    if (seen.has(key)) continue;
    seen.add(key);

    const prompt = String(q.prompt || '').replace(/\s+/g, ' ').trim();
    const cleanPrompt = prompt.replace(/[?.!]+$/, '');
    const complexityScore =
      (q.options?.length || 0) * 0.2 +
      (cleanPrompt.length > 110 ? 0.6 : cleanPrompt.length > 80 ? 0.35 : 0) +
      (/except|least|not|primarily|best/i.test(cleanPrompt) ? 0.7 : 0);

    let difficulty = 'easy';
    if (complexityScore >= 1.5) difficulty = 'hard';
    else if (complexityScore >= 0.9) difficulty = 'medium';

    cards.push({
      topic: q.topic,
      term: String(answer),
      definition: `Applies to: ${cleanPrompt}`,
      difficulty,
    });

    if (cards.length >= 300) break;
  }

  if (cards.length <= 1) {
    return cards.slice(0, 80);
  }

  // Daily rotation: same order for everyone during a day, changes next day.
  const now = new Date();
  const daySeed = Number(
    `${now.getUTCFullYear()}${String(now.getUTCMonth() + 1).padStart(2, '0')}${String(now.getUTCDate()).padStart(2, '0')}`
  );

  const shuffled = cards.slice();

  // Deterministic PRNG (mulberry32-style) seeded by UTC date.
  let state = daySeed >>> 0;
  const nextRand = () => {
    state += 0x6D2B79F5;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };

  // Fisher-Yates shuffle with deterministic random.
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(nextRand() * (i + 1));
    const tmp = shuffled[i];
    shuffled[i] = shuffled[j];
    shuffled[j] = tmp;
  }

  return shuffled.slice(0, 80);
}

async function loadExamQuestions({ topic, assignedCourseIds, isAdmin, userState }) {
  const db = mongoose.connection.db;
  if (!db) throw new Error('Database connection is not initialized');

  // Admins can access all quiz-bearing courses.
  // Students are normally scoped by `assigned_course_ids`, but in practice some
  // student accounts may have none assigned yet. In that case, we fall back to
  // the student's state (if present) so Exam Prep still works.
  const courseQuery = (() => {
    if (isAdmin) return { 'modules.quiz.0': { $exists: true } };

    if (Array.isArray(assignedCourseIds) && assignedCourseIds.length > 0) {
      return {
        _id: { $in: assignedCourseIds },
        'modules.quiz.0': { $exists: true },
      };
    }

    const state = String(userState || '').trim().toUpperCase();
    if (state) {
      // No assignments: fallback to the student's state.
      return {
        states_approved: { $in: [state] },
        'modules.quiz.0': { $exists: true },
      };
    }

    // Last-resort fallback: any quiz-bearing course.
    return { 'modules.quiz.0': { $exists: true } };
  })();

  const courses = await db
    .collection('courses')
    .find(courseQuery)
    .project({ title: 1, modules: 1 })
    .toArray();

  const questions = [];

  for (const course of courses) {
    const modules = Array.isArray(course.modules) ? course.modules : [];

    for (let m = 0; m < modules.length; m++) {
      const module = modules[m] || {};
      const moduleQuiz = Array.isArray(module.quiz) ? module.quiz : [];
      if (moduleQuiz.length === 0) continue;

      const topicName = String(module.title || 'General').trim();
      if (topic && topicName.toLowerCase() != String(topic).trim().toLowerCase()) {
        continue;
      }

      for (let i = 0; i < moduleQuiz.length; i++) {
        const parsed = normalizeQuestion(moduleQuiz[i], {
          courseId: String(course._id),
          courseTitle: String(course.title || 'Untitled Course'),
          topic: topicName,
          moduleOrder: module.order || m + 1,
          itemOrder: i + 1,
        });

        if (parsed) questions.push(parsed);
      }
    }
  }

  const topics = [...new Set(questions.map((q) => q.topic))].sort((a, b) =>
    a.localeCompare(b)
  );

  return { questions, topics };
}

router.get('/questions', requireAuth, async (req, res) => {
  try {
    const { topic } = req.query;
    const isAdmin = req.user.role === 'admin';

    // Students should only access their assigned courses.
    const user = isAdmin
      ? null
      : await User.findById(req.user.id)
          .select('assigned_course_ids state')
          .lean();
    const assignedCourseIds = isAdmin
      ? null
      : (user?.assigned_course_ids || []).map((id) => String(id).trim()).filter(Boolean);
    const userState = isAdmin ? null : String(user?.state || '').trim();

    const { questions, topics } = await loadExamQuestions({
      topic,
      assignedCourseIds,
      isAdmin,
      userState,
    });
    const flashcards = buildFlashcards(questions);

    return res.status(200).json({
      total: questions.length,
      topics,
      questions,
      flashcards,
    });
  } catch (error) {
    console.error('Exam prep questions error:', error);
    return res.status(500).json({ message: 'Server error loading exam questions' });
  }
});

router.post('/attempt', requireAuth, async (req, res) => {
  try {
    const total = Number(req.body?.total || 0);
    const correct = Number(req.body?.correct || 0);
    const mode = String(req.body?.mode || 'Exam Prep Session').trim();
    const timeSpentSeconds = Number(req.body?.timeSpentSeconds || 0);
    const topicStats = req.body?.topicStats && typeof req.body.topicStats === 'object'
      ? req.body.topicStats
      : {};

    if (!Number.isInteger(total) || total <= 0) {
      return res.status(400).json({ message: 'Invalid total question count' });
    }

    if (!Number.isInteger(correct) || correct < 0 || correct > total) {
      return res.status(400).json({ message: 'Invalid correct answer count' });
    }

    const db = mongoose.connection.db;
    if (!db) throw new Error('Database connection is not initialized');

    const userId = mongoose.Types.ObjectId.isValid(req.user.id)
      ? new mongoose.Types.ObjectId(req.user.id)
      : req.user.id;

    const scorePct = Number(((correct / total) * 100).toFixed(2));
    const now = new Date();

    const payload = {
      user_id: userId,
      course_id: null,
      quiz_id: 'exam-prep-center',
      quiz_title: mode,
      quiz_type: 'exam_prep',
      module_order: null,
      score_pct: scorePct,
      correct,
      total,
      passed: scorePct >= 70,
      passing_score: 70,
      submitted_at: now,
      time_spent_seconds: Number.isFinite(timeSpentSeconds) ? timeSpentSeconds : 0,
      unlocked_by_instructor: false,
      topic_stats: topicStats,
      createdAt: now,
      updatedAt: now,
    };

    const result = await db.collection('quizattempts').insertOne(payload);
    return res.status(201).json({
      id: String(result.insertedId),
      message: 'Exam prep attempt saved',
      score_pct: scorePct,
    });
  } catch (error) {
    console.error('Exam prep attempt save error:', error);
    return res.status(500).json({ message: 'Server error saving exam prep attempt' });
  }
});

router.get('/analytics', requireAuth, async (req, res) => {
  try {
    const db = mongoose.connection.db;
    if (!db) throw new Error('Database connection is not initialized');

    const userFilters = [{ user_id: req.user.id }];
    if (mongoose.Types.ObjectId.isValid(req.user.id)) {
      userFilters.push({ user_id: new mongoose.Types.ObjectId(req.user.id) });
    }

    const attempts = await db
      .collection('quizattempts')
      .find({
        $and: [
          { $or: userFilters },
          { quiz_type: { $in: ['exam_prep', 'module_quiz', 'final_exam', 'quiz'] } },
        ],
      })
      .sort({ createdAt: -1 })
      .limit(50)
      .project({
        _id: 0,
        quiz_title: 1,
        score_pct: 1,
        correct: 1,
        total: 1,
        submitted_at: 1,
        createdAt: 1,
      })
      .toArray();

    const normalized = attempts
      .map((entry) => {
        const scoreRaw = Number(entry.score_pct);
        const score = scoreRaw > 1 ? scoreRaw / 100 : scoreRaw;
        const title = String(entry.quiz_title || 'General').trim();

        return {
          title,
          score: Number.isFinite(score) ? score : 0,
          completedAt: entry.submitted_at || entry.createdAt || null,
        };
      })
      .filter((entry) => entry.score >= 0 && entry.score <= 1);

    const topicBuckets = {};
    for (const item of normalized) {
      const key = item.title;
      if (!topicBuckets[key]) topicBuckets[key] = [];
      topicBuckets[key].push(item.score);
    }

    const topicScores = Object.entries(topicBuckets).map(([title, scores]) => ({
      title,
      average: scores.reduce((a, b) => a + b, 0) / scores.length,
      attempts: scores.length,
    }));

    const recent = normalized.slice(0, 10).reverse().map((entry) => entry.score);
    const readiness = normalized.length
      ? normalized
          .slice(0, 6)
          .map((entry) => entry.score)
          .reduce((a, b) => a + b, 0) / Math.min(6, normalized.length)
      : 0;

    return res.status(200).json({
      readiness,
      trend: recent,
      topicScores,
      attempts: normalized.length,
    });
  } catch (error) {
    console.error('Exam prep analytics error:', error);
    return res.status(500).json({ message: 'Server error loading exam prep analytics' });
  }
});

module.exports = router;
