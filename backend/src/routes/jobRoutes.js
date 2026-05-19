const express = require('express');
const router = express.Router();
const auth = require('../middleware/authMiddleware');
const jobController = require('../controllers/jobController');

router.post('/', auth, jobController.createJobRequest);
router.get('/worker', auth, jobController.getWorkerJobRequests);
router.get('/client', auth, jobController.getClientJobRequests);
router.patch('/:id/status', auth, jobController.updateJobStatus);

module.exports = router;
