const uploadId = (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No file uploaded' });
    }

    return res.status(200).json({
      message: 'File uploaded successfully',
      filePath: req.file.path,
      fileName: req.file.filename
    });
  } catch (error) {
    return res.status(500).json({
      message: 'Upload failed',
      error: error.message
    });
  }
};

module.exports = { uploadId };