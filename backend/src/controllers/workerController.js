const db = require('../models');
const { User, WorkerProfile } = db;

exports.createProfile = async (req, res) => {
  try {
    const profile = await WorkerProfile.create({
      ...req.body,
      userId: req.user.id
    });
    res.json(profile);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.getWorkers = async (req, res) => {
  try {
    const workers = await User.findAll({
      where: { role: 'worker' },
      attributes: ['id', 'email', 'role', 'isProfileCompleted', 'createdAt'],
      include: [
        {
          model: WorkerProfile,
          required: false
        }
      ],
      order: [['createdAt', 'DESC']]
    });

    res.json(workers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
