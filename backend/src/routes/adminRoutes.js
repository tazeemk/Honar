// src/routes/adminRoutes.js
// Admin-only API routes

const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const role = require('../middleware/roleMiddleware');
const {
  getDashboard,
  approveVerification,
  rejectVerification,
  getAllUsers,
  getAllDisputes,
  resolveDispute,
} = require('../controllers/adminController');

// All admin routes need: valid JWT + role === 'admin'
router.use(auth, role(['admin']));

// Dashboard
router.get('/dashboard', getDashboard);

// Verification queue
router.post('/verify/:id/approve', approveVerification);
router.post('/verify/:id/reject', rejectVerification);

// Users
router.get('/users', getAllUsers);

// Disputes
router.get('/disputes', getAllDisputes);
router.put('/disputes/:id/resolve', resolveDispute);

module.exports = router;
