require('dotenv').config();

const path = require('path');
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const sequelize = require('./config/database');

// Import models
require('./models');

const app = require('./app');

// =========================
// Routes
// =========================

// Chat routes
const chatRoutes = require('./routes/chatRoutes');
app.use('/api/chat', chatRoutes);

// Upload routes
const uploadRoutes = require('./routes/uploadRoutes');
app.use('/api', uploadRoutes);

// =========================
// Static Files
// =========================

app.use(
  '/uploads',
  express.static(path.join(__dirname, 'uploads'))
);

app.use(
  express.static(path.join(__dirname, 'public'))
);

// =========================
// Test Route
// =========================

app.get('/', (req, res) => {
  res.send('✅ Honar backend running successfully');
});

// =========================
// React/Flutter Fallback
// =========================

// OPTIONAL
// Remove this if not needed

/*
app.get('*', (req, res) => {
  res.sendFile(
    path.join(__dirname, '../../frontend/index.html')
  );
});
*/

// =========================
// Sequelize Sync
// =========================

const syncOptions =
  process.env.NODE_ENV === 'production'
    ? { alter: false }
    : { alter: true };

// =========================
// Start Server
// =========================

sequelize.sync(syncOptions)
  .then(() => {

    console.log('✅ Database synced');

    // Create HTTP server

    const httpServer = http.createServer(app);

    // =========================
    // Socket.IO
    // =========================

    const io = new Server(httpServer, {

      cors: {
        origin: '*',
        methods: ['GET', 'POST']
      },

      transports: ['websocket']

    });

    // Register socket events

    require('./socket/chatSocket')(io);

    // =========================
    // Start Listening
    // =========================

    httpServer.listen(
      5000,
      '0.0.0.0',
      () => {

        console.log(
          `🚀 Server + Socket.IO running on port 5000 (${process.env.NODE_ENV || 'development'})`
        );

      }
    );

  })
  .catch(err => {

    console.error(
      '❌ Failed to sync database:',
      err
    );

    process.exit(1);

  });