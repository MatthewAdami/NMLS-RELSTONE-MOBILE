const express = require('express');
const { requireAuth } = require('../middleware/auth');
const { findCourseById } = require('../data/courses');
const { addOrder, listOrdersByUser } = require('../data/order_store');

const router = express.Router();

router.post('/', requireAuth, (req, res) => {
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

  const order = {
    _id: `ord_${Date.now()}_${Math.floor(Math.random() * 100000)}`,
    user_id: req.user.id,
    status: 'pending',
    total_amount: Number(totalAmount.toFixed(2)),
    items: normalizedItems,
    createdAt: new Date().toISOString(),
  };

  addOrder(order);
  return res.status(201).json(order);
});

router.get('/my', requireAuth, (req, res) => {
  return res.status(200).json(listOrdersByUser(req.user.id));
});

module.exports = router;
