const db = require('../models');

const { Job, User } = db;

const nameFromEmail = (email) => {
  if (!email) return 'User';
  return email
    .split('@')[0]
    .split(/[._-]+/)
    .filter(Boolean)
    .map((word) => `${word[0].toUpperCase()}${word.slice(1)}`)
    .join(' ') || 'User';
};

const serializeJob = (job) => {
  const plain = job.toJSON ? job.toJSON() : job;
  return {
    ...plain,
    clientName: nameFromEmail(plain.Client?.email),
    workerName: nameFromEmail(plain.Worker?.email),
  };
};

const includeUsers = [
  { model: User, as: 'Client', attributes: ['id', 'email', 'role'] },
  { model: User, as: 'Worker', attributes: ['id', 'email', 'role'] },
];

exports.createJobRequest = async (req, res) => {
  try {
    if (req.user.role !== 'client') {
      return res.status(403).json({ message: 'Only clients can send job requests' });
    }

    const { workerId, title, description, budget, preferredDate, location } = req.body;

    if (!workerId || !title || budget === undefined || budget === null || budget === '') {
      return res.status(400).json({ message: 'Worker, title, and budget are required' });
    }

    const worker = await User.findOne({ where: { id: workerId, role: 'worker' } });
    if (!worker) {
      return res.status(404).json({ message: 'Worker not found' });
    }

    const numericBudget = Number(budget);
    if (Number.isNaN(numericBudget) || numericBudget <= 0) {
      return res.status(400).json({ message: 'Budget must be a positive number' });
    }

    const job = await Job.create({
      clientId: req.user.id,
      workerId: worker.id,
      title: title.trim(),
      description: description?.trim() || '',
      budget: numericBudget,
      preferredDate: preferredDate || null,
      location: location?.trim() || '',
      status: 'pending',
    });

    const savedJob = await Job.findByPk(job.id, { include: includeUsers });
    res.status(201).json(serializeJob(savedJob));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getWorkerJobRequests = async (req, res) => {
  try {
    if (req.user.role !== 'worker') {
      return res.status(403).json({ message: 'Only workers can view assigned job requests' });
    }

    const jobs = await Job.findAll({
      where: { workerId: req.user.id },
      include: includeUsers,
      order: [['createdAt', 'DESC']],
    });

    res.json(jobs.map(serializeJob));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.getClientJobRequests = async (req, res) => {
  try {
    if (req.user.role !== 'client') {
      return res.status(403).json({ message: 'Only clients can view their job requests' });
    }

    const jobs = await Job.findAll({
      where: { clientId: req.user.id },
      include: includeUsers,
      order: [['createdAt', 'DESC']],
    });

    res.json(jobs.map(serializeJob));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

exports.updateJobStatus = async (req, res) => {
  try {
    if (req.user.role !== 'worker') {
      return res.status(403).json({ message: 'Only workers can update job requests' });
    }

    const { status, declineReason } = req.body;
    if (!['accepted', 'declined'].includes(status)) {
      return res.status(400).json({ message: 'Status must be accepted or declined' });
    }
    if (status === 'declined' && !declineReason?.trim()) {
      return res.status(400).json({ message: 'Please provide a decline reason' });
    }

    const job = await Job.findOne({
      where: { id: req.params.id, workerId: req.user.id },
      include: includeUsers,
    });

    if (!job) {
      return res.status(404).json({ message: 'Job request not found' });
    }

    if (job.status !== 'pending') {
      return res.status(400).json({ message: `Job request is already ${job.status}` });
    }

    const now = new Date();
    await job.update({
      status,
      respondedAt: now,
      acceptedAt: status === 'accepted' ? now : null,
      declinedAt: status === 'declined' ? now : null,
      declineReason: status === 'declined' ? declineReason.trim() : null,
    });

    await job.reload({ include: includeUsers });
    res.json(serializeJob(job));
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
