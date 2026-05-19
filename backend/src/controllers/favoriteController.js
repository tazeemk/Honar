const db = require('../models');
const { Favorite, WorkerProfile, ClientProfile } = db;

// Toggle save/unsave worker
exports.toggleFavorite = async (req, res) => {
  try {
    const { workerProfileId } = req.params;
    const userId = req.user.id;

    // Client ka ClientProfile dhundho
    const clientProfile = await ClientProfile.findOne({ where: { userId } });
    if (!clientProfile) {
      return res.status(404).json({ message: 'Client profile not found' });
    }

    const existing = await Favorite.findOne({
      where: { clientId: clientProfile.id, workerId: parseInt(workerProfileId) }
    });

    if (existing) {
      await existing.destroy();
      return res.json({ isFavorite: false, message: 'Removed from favorites' });
    } else {
      await Favorite.create({ clientId: clientProfile.id, workerId: parseInt(workerProfileId) });
      return res.json({ isFavorite: true, message: 'Added to favorites' });
    }
  } catch (err) {
    console.error('toggleFavorite error:', err);
    res.status(500).json({ message: err.message });
  }
};

// Check if a worker is favorited
exports.checkFavorite = async (req, res) => {
  try {
    const { workerProfileId } = req.params;
    const userId = req.user.id;

    const clientProfile = await ClientProfile.findOne({ where: { userId } });
    if (!clientProfile) return res.json({ isFavorite: false });

    const existing = await Favorite.findOne({
      where: { clientId: clientProfile.id, workerId: parseInt(workerProfileId) }
    });

    res.json({ isFavorite: !!existing });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

// Get my favorites list
exports.getMyFavorites = async (req, res) => {
  try {
    const userId = req.user.id;

    const clientProfile = await ClientProfile.findOne({ where: { userId } });
    if (!clientProfile) return res.json([]);

    const favorites = await Favorite.findAll({
      where: { clientId: clientProfile.id },
      include: [
        {
          model: WorkerProfile,
          include: [
            {
              model: db.User,
              attributes: ['id', 'email']
            }
          ]
        }
      ]
    });

    res.json(favorites);
  } catch (err) {
    console.error('getMyFavorites error:', err);
    res.status(500).json({ message: err.message });
  }
};
