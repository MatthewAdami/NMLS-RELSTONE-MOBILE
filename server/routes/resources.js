const express = require('express');
const mongoose = require('mongoose');

const router = express.Router();

const VALID_CATEGORIES = [
  'Study Tips',
  'State Guides',
  'Career Advice',
  'Industry News',
];

function asDate(value) {
  const d = value ? new Date(value) : null;
  return d && !Number.isNaN(d.getTime()) ? d : null;
}

function normalizeArticle(entry) {
  if (!entry) return null;

  const id = String(entry._id || '').trim();
  const title = String(entry.title || '').trim();
  const excerpt = String(entry.excerpt || '').trim();
  const category = String(entry.category || '').trim();
  const author = String(entry.author || 'Relstone Editorial').trim();
  const publishedAt = asDate(entry.publishedAt || entry.createdAt);

  const content = Array.isArray(entry.content)
    ? entry.content.map((p) => String(p).trim()).filter(Boolean)
    : [];

  const body = String(entry.body || '').trim();
  if (body && content.length === 0) {
    content.push(...body.split(/\n{2,}/).map((p) => p.trim()).filter(Boolean));
  }

  if (!id || !title || !excerpt || !category || !publishedAt) return null;

  return {
    id,
    title,
    excerpt,
    category,
    author,
    publishedAt: publishedAt.toISOString(),
    readMinutes: Number(entry.readMinutes || entry.read_minutes || 5),
    content,
  };
}

router.get('/', async (req, res) => {
  try {
    const db = mongoose.connection.db;
    if (!db) throw new Error('Database connection is not initialized');

    const query = {};

    const category = String(req.query.category || '').trim();
    if (category && category !== 'All') {
      query.category = category;
    }

    const now = new Date();
    const dateFilter = String(req.query.dateFilter || '').trim();
    if (dateFilter === 'last7') {
      query.publishedAt = { $gte: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) };
    } else if (dateFilter === 'last30') {
      query.publishedAt = { $gte: new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000) };
    } else if (dateFilter === 'thisYear') {
      query.publishedAt = {
        $gte: new Date(Date.UTC(now.getUTCFullYear(), 0, 1)),
        $lt: new Date(Date.UTC(now.getUTCFullYear() + 1, 0, 1)),
      };
    }

    const search = String(req.query.search || '').trim();
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: 'i' } },
        { excerpt: { $regex: search, $options: 'i' } },
        { author: { $regex: search, $options: 'i' } },
        { content: { $elemMatch: { $regex: search, $options: 'i' } } },
      ];
    }

    const docs = await db
      .collection('resources')
      .find(query)
      .sort({ publishedAt: -1, createdAt: -1 })
      .limit(100)
      .toArray();

    const articles = docs.map(normalizeArticle).filter(Boolean);

    return res.status(200).json({
      total: articles.length,
      categories: VALID_CATEGORIES,
      articles,
    });
  } catch (error) {
    console.error('Resources list error:', error);
    return res.status(500).json({ message: 'Server error loading resources' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const db = mongoose.connection.db;
    if (!db) throw new Error('Database connection is not initialized');

    const id = String(req.params.id || '').trim();
    if (!id) {
      return res.status(400).json({ message: 'Resource id is required' });
    }

    const objectId = mongoose.Types.ObjectId.isValid(id)
      ? new mongoose.Types.ObjectId(id)
      : id;

    const doc = await db.collection('resources').findOne({ _id: objectId });
    const article = normalizeArticle(doc);

    if (!article) {
      return res.status(404).json({ message: 'Resource not found' });
    }

    const relatedDocs = await db
      .collection('resources')
      .find({
        _id: { $ne: doc._id },
        category: article.category,
      })
      .sort({ publishedAt: -1, createdAt: -1 })
      .limit(3)
      .toArray();

    const related = relatedDocs.map(normalizeArticle).filter(Boolean);

    return res.status(200).json({ article, related });
  } catch (error) {
    console.error('Resource detail error:', error);
    return res.status(500).json({ message: 'Server error loading resource detail' });
  }
});

router.post('/newsletter-subscribe', async (req, res) => {
  try {
    const db = mongoose.connection.db;
    if (!db) throw new Error('Database connection is not initialized');

    const email = String(req.body?.email || '').trim().toLowerCase();
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
      return res.status(400).json({ message: 'Invalid email address' });
    }

    await db.collection('newsletter_subscribers').updateOne(
      { email },
      {
        $set: { email, updatedAt: new Date() },
        $setOnInsert: { createdAt: new Date() },
      },
      { upsert: true }
    );

    return res.status(200).json({ message: 'Subscribed successfully' });
  } catch (error) {
    console.error('Newsletter subscribe error:', error);
    return res.status(500).json({ message: 'Server error subscribing email' });
  }
});

module.exports = router;
