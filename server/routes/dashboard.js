const express = require('express');
const User = require('../models/User');
const { requireAuth } = require('../middleware/auth');
const { listOrdersByUser } = require('../data/order_store');

const router = express.Router();

router.get('/', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).lean();
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const orders = listOrdersByUser(req.user.id);

    const completions = {
      PE: [
        {
          course_title: 'SAFE Federal Core',
          completed_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 60).toISOString(),
        },
      ],
      CE: [
        {
          course_title: 'Annual CE 8-Hour',
          completed_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 14).toISOString(),
        },
      ],
    };

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
