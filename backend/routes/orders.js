const express = require('express');
const jwt = require('jsonwebtoken');
const router = express.Router();

const Order = require('../models/Order');

// JWT middleware (matches your userRoutes signing: { userId: user._id })
const authMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Missing or invalid token' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret');

    req.user = { id: decoded.userId };
    return next();
  } catch (err) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};

// GET /api/orders/my
router.get('/my', authMiddleware, async (req, res) => {
  try {
    const orders = await Order.find({ user_id: req.user.id }).sort({ createdAt: -1 });
    return res.json(orders);
  } catch (error) {
    console.error('Error fetching orders:', error);
    return res.status(400).json({ message: 'Error fetching orders', error: error.message });
  }
});

module.exports = router;

