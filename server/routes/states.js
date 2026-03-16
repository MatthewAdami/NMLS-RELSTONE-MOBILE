const express = require('express');
const {
  listStateSummaries,
  getStateRequirement,
} = require('../data/state_requirements');

const router = express.Router();

router.get('/requirements', (req, res) => {
  try {
    const items = listStateSummaries({ search: req.query.search });
    return res.status(200).json(items);
  } catch (error) {
    console.error('States requirements list error:', error);
    return res
      .status(500)
      .json({ message: 'Server error loading state requirements' });
  }
});

router.get('/requirements/:stateCode', (req, res) => {
  try {
    const detail = getStateRequirement(req.params.stateCode);
    if (!detail) {
      return res.status(404).json({ message: 'State requirement not found' });
    }
    return res.status(200).json(detail);
  } catch (error) {
    console.error('State requirement detail error:', error);
    return res
      .status(500)
      .json({ message: 'Server error loading state requirement details' });
  }
});

module.exports = router;
