const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const db = require('../models');

const ClientProfile = db.ClientProfile;
const User = db.User;

// COMPLETE PROFILE
router.put('/complete', auth, async (req, res) => {
  try {
    let profile = await ClientProfile.findOne({
      where: { userId: req.user.id }
    });

    if (!profile) {
      // Create profile if it doesn't exist
      profile = await ClientProfile.create({
        userId: req.user.id,
        ...req.body
      });
    } else {
      await profile.update(req.body);
    }

    await User.update(
      { isProfileCompleted: true },
      { where: { id: req.user.id } }
    );

    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// SUBSCRIBE
router.put('/subscribe', auth, async (req, res) => {
  try {
    let profile = await ClientProfile.findOne({
      where: { userId: req.user.id }
    });

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    await profile.update({ subscriptionStatus: "ACTIVE" });

    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// UPLOAD ID
router.put('/upload-id', auth, async (req, res) => {
  try {
    const { idProof } = req.body;

    let profile = await ClientProfile.findOne({
      where: { userId: req.user.id }
    });

    if (!profile) {
      return res.status(404).json({ message: 'Profile not found' });
    }

    await profile.update({ idProof, isVerified: true });

    res.json(profile);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

module.exports = router;
