const express = require('express');
const router = express.Router();

const upload = require('../middleware/uploadMiddleware');
const { uploadId } = require('../controllers/uploadController');

// POST /api/upload
router.post('/upload', upload.single('file'), uploadId);

module.exports = router;