const express = require('express');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

// ─── Helper: sign JWT ──────────────────────────────────────────────────────────
function signToken(user) {
  return jwt.sign(
    { id: user._id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
}

// ─── POST /api/auth/register ───────────────────────────────────────────────────
// Body: { name, email, password, nmls_id?, state? }
// Returns 201: { token, user: { id, name, email, nmls_id, state, role } }
router.post('/register', async (req, res) => {
  try {
    const { name, email, password, nmls_id, state } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'Name, email and password are required' });
    }

    if (String(password).length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    const existing = await User.findOne({ email: email.toLowerCase().trim() });
    if (existing) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    const user = await User.create({ name, email, password, nmls_id, state });
    const token = signToken(user);

    return res.status(201).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        nmls_id: user.nmls_id,
        state: user.state,
        role: user.role,
      },
    });
  } catch (err) {
    console.error('Register error:', err);

    if (err?.name === 'ValidationError') {
      const firstMessage = Object.values(err.errors || {})
          .map((entry) => entry?.message)
          .find(Boolean);
      return res.status(400).json({ message: firstMessage || 'Invalid registration data' });
    }

    if (err?.code === 11000) {
      return res.status(400).json({ message: 'Email already registered' });
    }

    return res.status(500).json({ message: 'Server error during registration' });
  }
});

// ─── POST /api/auth/login ──────────────────────────────────────────────────────
// Body: { email, password }
// Returns 200: { token, user: { id, name, email, nmls_id, state, role } }
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Email and password are required' });
    }

    // select: false on password field — must explicitly include it
    const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
    if (!user) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    const token = signToken(user);

    return res.status(200).json({
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        nmls_id: user.nmls_id,
        state: user.state,
        role: user.role,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ message: 'Server error during login' });
  }
});

// ─── GET /api/auth/me (compat for catalog module) ──────────────────────────────
// Returns 200: { user: { id, name, email, nmls_id, state, role } }
router.get('/me', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    return res.status(200).json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        nmls_id: user.nmls_id,
        state: user.state,
        role: user.role,
      },
    });
  } catch (err) {
    console.error('Auth me error:', err);
    return res.status(500).json({ message: 'Server error fetching user profile' });
  }
});

// ─── GET /api/auth/profile (used by other screens) ────────────────────────────
router.get('/profile', requireAuth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ message: 'User not found' });

    return res.status(200).json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        nmls_id: user.nmls_id,
        state: user.state,
        role: user.role,
      },
    });
  } catch (err) {
    console.error('Auth profile error:', err);
    return res.status(500).json({ message: 'Server error fetching user profile' });
  }
});

// ─── POST /api/auth/change-password ───────────────────────────────────────────
// Body: { currentPassword, newPassword }
router.post('/change-password', requireAuth, async (req, res) => {
  try {
    const currentPassword = String(req.body?.currentPassword ?? '').trim();
    const newPassword = String(req.body?.newPassword ?? '').trim();

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Current password and new password are required' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    const user = await User.findById(req.user.id).select('+password');
    if (!user) return res.status(404).json({ message: 'User not found' });

    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ message: 'Current password is incorrect' });
    }

    user.password = newPassword;
    await user.save();

    return res.status(200).json({ message: 'Password updated successfully' });
  } catch (err) {
    console.error('Change password error:', err);
    return res.status(500).json({ message: 'Server error changing password' });
  }
});

module.exports = router;
