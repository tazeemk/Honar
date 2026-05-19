// src/controllers/adminController.js
// All Admin Dashboard operations

const { User, WorkerProfile, ClientProfile, Verification, Dispute } = require('../models');
const { Op } = require('sequelize');

// ─── GET /api/admin/dashboard ─────────────────────────────────────────────
// Returns all stats, pending verifications, and active disputes in one call
const getDashboard = async (req, res) => {
  try {
    // Pending verification count
    const pendingIdCount = await Verification.count({
      where: { status: 'pending' },
    });

    // Active disputes count
    const disputeCount = await Dispute.count({
      where: { status: 'open' },
    });

    // Verification queue (last 20 pending)
    const verificationQueue = await Verification.findAll({
      where: { status: 'pending' },
      order: [['createdAt', 'DESC']],
      limit: 20,
      include: [
        {
          model: User,
          attributes: ['id', 'email', 'role'],
          include: [
            {
              model: WorkerProfile,
              required: false,
              attributes: ['category', 'city'],
            },
            {
              model: ClientProfile,
              required: false,
              attributes: ['city', 'residenceOrCompanyName'],
            },
          ],
        },
      ],
    });

    // Active disputes
    const activeDisputes = await Dispute.findAll({
      where: { status: { [Op.in]: ['open', 'under_review'] } },
      order: [['createdAt', 'DESC']],
      include: [
        {
          model: User,
          as: 'Client',
          attributes: ['id', 'email'],
        },
        {
          model: User,
          as: 'Worker',
          attributes: ['id', 'email'],
        },
      ],
    });

    // Platform stats
    const totalWorkers = await User.count({ where: { role: 'worker' } });
    const totalClients = await User.count({ where: { role: 'client' } });

    // Jobs this month
    const now = new Date();
    const firstOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const totalJobsThisMonth = await require('../models').Job.count({
      where: {
        createdAt: { [Op.gte]: firstOfMonth },
      },
    }).catch(() => 0); // Job model may not exist yet

    res.json({
      pendingIds: pendingIdCount,
      disputes: disputeCount,
      verificationQueue: verificationQueue.map((v) => ({
        id: v.id,
        userId: v.userId,
        userEmail: v.User?.email || '',
        userRole: v.userRole,
        profession:
          v.User?.WorkerProfile?.category ||
          v.User?.ClientProfile?.residenceOrCompanyName ||
          '',
        city:
          v.User?.WorkerProfile?.city || v.User?.ClientProfile?.city || '',
        docType: v.docType,
        status: v.status,
        createdAt: v.createdAt,
      })),
      activeDisputes: activeDisputes.map((d) => ({
        id: d.id,
        subject: d.subject,
        clientEmail: d.Client?.email || '',
        workerEmail: d.Worker?.email || '',
        status: d.status,
        createdAt: d.createdAt,
      })),
      stats: {
        totalWorkers,
        totalClients,
        jobsThisMonth: totalJobsThisMonth,
      },
    });
  } catch (err) {
    console.error('Admin dashboard error:', err);
    res.status(500).json({ message: 'Server error: ' + err.message });
  }
};

// ─── POST /api/admin/verify/:id/approve ──────────────────────────────────
const approveVerification = async (req, res) => {
  try {
    const verification = await Verification.findByPk(req.params.id);
    if (!verification) return res.status(404).json({ message: 'Not found' });

    await verification.update({
      status: 'approved',
      reviewedAt: new Date(),
      reviewedBy: req.user.id,
    });

    // Mark user profile as verified
    if (verification.userRole === 'worker') {
      await WorkerProfile.update(
        { isVerified: true },
        { where: { userId: verification.userId } }
      );
    } else {
      await ClientProfile.update(
        { isVerified: true },
        { where: { userId: verification.userId } }
      );
    }

    res.json({ message: 'Verification approved', id: verification.id });
  } catch (err) {
    console.error('Approve error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─── POST /api/admin/verify/:id/reject ───────────────────────────────────
const rejectVerification = async (req, res) => {
  try {
    const verification = await Verification.findByPk(req.params.id);
    if (!verification) return res.status(404).json({ message: 'Not found' });

    await verification.update({
      status: 'rejected',
      reviewedAt: new Date(),
      reviewedBy: req.user.id,
    });

    res.json({ message: 'Verification rejected', id: verification.id });
  } catch (err) {
    console.error('Reject error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─── GET /api/admin/users ─────────────────────────────────────────────────
// All users list (workers + clients)
const getAllUsers = async (req, res) => {
  try {
    const { role, page = 1, limit = 20 } = req.query;
    const where = role ? { role } : { role: { [Op.in]: ['worker', 'client'] } };

    const { count, rows } = await User.findAndCountAll({
      where,
      attributes: ['id', 'email', 'role', 'isProfileCompleted', 'createdAt'],
      include: [
        { model: WorkerProfile, required: false },
        { model: ClientProfile, required: false },
      ],
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      offset: (parseInt(page) - 1) * parseInt(limit),
    });

    res.json({ total: count, page: parseInt(page), users: rows });
  } catch (err) {
    console.error('Get users error:', err);
    res.status(500).json({ message: 'Server error' });
  }
};

// ─── GET /api/admin/disputes ──────────────────────────────────────────────
const getAllDisputes = async (req, res) => {
  try {
    const disputes = await Dispute.findAll({
      order: [['createdAt', 'DESC']],
      include: [
        { model: User, as: 'Client', attributes: ['id', 'email'] },
        { model: User, as: 'Worker', attributes: ['id', 'email'] },
      ],
    });
    res.json(disputes);
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
};

// ─── PUT /api/admin/disputes/:id/resolve ─────────────────────────────────
const resolveDispute = async (req, res) => {
  try {
    const { resolution } = req.body;
    const dispute = await Dispute.findByPk(req.params.id);
    if (!dispute) return res.status(404).json({ message: 'Not found' });

    await dispute.update({
      status: 'resolved',
      resolution,
      resolvedAt: new Date(),
      resolvedBy: req.user.id,
    });

    res.json({ message: 'Dispute resolved', id: dispute.id });
  } catch (err) {
    res.status(500).json({ message: 'Server error' });
  }
};

module.exports = {
  getDashboard,
  approveVerification,
  rejectVerification,
  getAllUsers,
  getAllDisputes,
  resolveDispute,
};
