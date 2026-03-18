const express = require('express');
const { requireAuth } = require('../middleware/auth');
const { findCourseById } = require('../data/courses');
const User = require('../models/User');
const Order = require('../models/Order');
const Enrollment = require('../models/Enrollment');

const router = express.Router();

router.post('/', requireAuth, async (req, res) => {
  const items = Array.isArray(req.body?.items) ? req.body.items : [];

  if (items.length === 0) {
    return res.status(400).json({ message: 'At least one course is required' });
  }

  const normalizedItems = [];

  for (const rawItem of items) {
    const courseId = rawItem?.course_id;
    const includeTextbook = rawItem?.include_textbook === true;
    const course = findCourseById(courseId);

    if (!course) {
      return res.status(400).json({ message: `Invalid course: ${courseId}` });
    }

    normalizedItems.push({
      course_id: {
        _id: course._id,
        title: course.title,
        type: course.type,
        credit_hours: course.credit_hours,
      },
      price: course.price,
      include_textbook: includeTextbook,
      textbook_price: includeTextbook ? course.textbook_price : 0,
    });
  }

  const totalAmount = normalizedItems.reduce((sum, item) => {
    return sum + Number(item.price || 0) + Number(item.textbook_price || 0);
  }, 0);

  try {
    const user = await User.findById(req.user.id).select('_id assigned_course_ids');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const order = await Order.create({
      user_id: user._id,
      status: 'pending',
      total_amount: Number(totalAmount.toFixed(2)),
      items: normalizedItems,
    });

    const purchasedCourseIds = normalizedItems
      .map((item) => item.course_id?._id)
      .filter(Boolean);

    if (purchasedCourseIds.length > 0) {
      await User.updateOne(
        { _id: user._id },
        { $addToSet: { assigned_course_ids: { $each: purchasedCourseIds } } }
      );

      await Promise.all(
        purchasedCourseIds.map((courseId) =>
          Enrollment.updateOne(
            { user_id: user._id, course_id: courseId },
            {
              $setOnInsert: {
                status: 'in_progress',
                progress_percent: 0,
                last_accessed_at: new Date(),
              },
            },
            { upsert: true }
          )
        )
      );
    }

    return res.status(201).json(order);
  } catch (error) {
    console.error('Orders create error:', error);
    return res.status(500).json({ message: 'Server error creating order' });
  }
});

router.get('/my', requireAuth, async (req, res) => {
  try {
    const orders = await Order.find({ user_id: req.user.id })
      .sort({ createdAt: -1 })
      .lean();
    return res.status(200).json(orders);
  } catch (error) {
    console.error('Orders list error:', error);
    return res.status(500).json({ message: 'Server error loading orders' });
  }
});

module.exports = router;
