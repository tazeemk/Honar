const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const profileRoutes = require('./routes/profileRoutes');
const clientRoutes = require('./routes/clientRoutes');
const app = express();

const corsOptions = {
  origin: ['http://localhost:5173', 'http://192.168.1.39:5000', 'http://127.0.0.1:5000'],
  credentials: true
};


app.use(cors(corsOptions));
app.use(express.json());
app.use(cookieParser());

// Routes
const authRoutes = require('./routes/authRoutes');
const workerRoutes = require('./routes/workerRoutes');

app.use('/api/auth', authRoutes);
app.use('/api/worker', workerRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/client', clientRoutes);
app.use('/api/favorites', require('./routes/favoriteRoutes'));
app.use('/api/admin',     require('./routes/adminRoutes'));
app.use('/api/jobs', require('./routes/jobRoutes'));
module.exports = app;
