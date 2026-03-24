const express = require('express');
const http = require('http');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const authRoutes = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const coursesRoutes = require('./routes/courses');
const ordersRoutes = require('./routes/orders');
const statesRoutes = require('./routes/states');
const examPrepRoutes = require('./routes/exam_prep');
const notificationsRoutes = require('./routes/notifications');
const resourcesRoutes = require('./routes/resources');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/api/health', (_req, res) => {
  return res.status(200).json({ ok: true, message: 'API is running' });
});

app.use('/api/auth', authRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/courses', coursesRoutes);
app.use('/api/orders', ordersRoutes);
app.use('/api/states', statesRoutes);
app.use('/api/exam-prep', examPrepRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/resources', resourcesRoutes);

const PORT = Number(process.env.PORT) || 5000;
const COMPAT_PORT = 3000;
const MONGO_URI = process.env.MONGO_URI;

function startServer(port, label) {
  const server = http.createServer(app);

  server.on('error', (error) => {
    if (error?.code === 'EADDRINUSE') {
      console.warn(`${label} server port ${port} is already in use`);
      return;
    }
    console.error(`${label} server failed on port ${port}:`, error.message || error);
  });

  server.listen(port, () => {
    console.log(`${label} server running on http://localhost:${port}`);
  });
}

if (!MONGO_URI) {
  console.error('Missing MONGO_URI in .env');
  process.exit(1);
}

mongoose
  .connect(MONGO_URI)
  .then(() => {
    console.log('Connected to MongoDB');
    startServer(PORT, 'Primary');
    if (COMPAT_PORT !== PORT) {
      startServer(COMPAT_PORT, 'Compat');
    }
  })
  .catch((error) => {
    console.error('Failed to connect to MongoDB:', error.message);
    process.exit(1);
  });
