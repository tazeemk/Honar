// const router = require('express').Router();
// const auth = require('../middleware/authMiddleware');
// const db = require('../models');

// const WorkerProfile = db.WorkerProfile;
// const User = db.User;

// // COMPLETE PROFILE
// router.put('/complete', auth, async (req, res) => {
//   try {
//     let profile = await WorkerProfile.findOne({
//       where: { userId: req.user.id }
//     });

//     if (!profile) {
//       return res.status(404).json({ message: 'Profile not found' });
//     }

//     await profile.update(req.body);

//     await User.update(
//       { isProfileCompleted: true },
//       { where: { id: req.user.id } }
//     );

//     res.json(profile);
//   } catch (error) {
//     res.status(500).json({ message: error.message });
//   }
// });

// // SUBSCRIBE
// router.put('/subscribe', auth, async (req, res) => {
//   try {
//     let profile = await WorkerProfile.findOne({
//       where: { userId: req.user.id }
//     });

//     if (!profile) {
//       return res.status(404).json({ message: 'Profile not found' });
//     }

//     await profile.update({ subscriptionStatus: "ACTIVE" });

//     res.json(profile);
//   } catch (error) {
//     res.status(500).json({ message: error.message });
//   }
// });

// // UPLOAD ID
// router.put('/upload-id', auth, async (req, res) => {
//   try {
//     const { idProof } = req.body;

//     let profile = await WorkerProfile.findOne({
//       where: { userId: req.user.id }
//     });

//     if (!profile) {
//       return res.status(404).json({ message: 'Profile not found' });
//     }

//     await profile.update({ idProof, isVerified: true });

//     res.json(profile);
//   } catch (error) {
//     res.status(500).json({ message: error.message });
//   }
// });

// module.exports = router;



const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const db = require('../models');

const WorkerProfile = db.WorkerProfile;
const User = db.User;

// GET MY PROFILE
router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findByPk(req.user.id, {
      attributes: ['id', 'email', 'role', 'isProfileCompleted'],
      include: [
        {
          model: WorkerProfile,
          required: false,
        }
      ]
    });

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// COMPLETE PROFILE
// BUG FIX: Added upsert logic so category (and all fields) save even if profile doesn't exist yet
router.put('/complete', auth, async (req, res) => {
  try {
    let profile = await WorkerProfile.findOne({
      where: { userId: req.user.id }
    });

    if (!profile) {
      // Create profile if it doesn't exist (fixes category not saving bug)
      profile = await WorkerProfile.create({
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
    let profile = await WorkerProfile.findOne({
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

    let profile = await WorkerProfile.findOne({
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
