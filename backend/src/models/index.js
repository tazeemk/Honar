const Sequelize = require('sequelize');
const sequelize = require('../config/database');

const db = {};

db.sequelize = sequelize;
db.Sequelize = Sequelize;

// ── 1. Initialize all models ────────────────────────────────────────────────
db.User          = require('./User')(sequelize, Sequelize.DataTypes);
db.WorkerProfile = require('./WorkerProfile')(sequelize, Sequelize.DataTypes);
db.ClientProfile = require('./ClientProfile')(sequelize, Sequelize.DataTypes);
db.Favorite      = require('./Favorite')(sequelize, Sequelize.DataTypes);
db.Job           = require('./job')(sequelize, Sequelize.DataTypes);
db.RefreshToken  = require('./RefreshToken')(sequelize, Sequelize.DataTypes);
db.Subscription  = require('./subscription')(sequelize, Sequelize.DataTypes);
db.Verification  = require('./Verification')(sequelize, Sequelize.DataTypes);
db.Dispute       = require('./Dispute')(sequelize, Sequelize.DataTypes);

// ── Chat models (new) ────────────────────────────────────────────────────────
db.ChatRoom = require('./ChatRoom')(sequelize, Sequelize.DataTypes);
db.Message  = require('./Message')(sequelize, Sequelize.DataTypes);

// ── 2. Associations ─────────────────────────────────────────────────────────

// User ↔ WorkerProfile
db.User.hasOne(db.WorkerProfile, { foreignKey: 'userId', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });
db.WorkerProfile.belongsTo(db.User, { foreignKey: 'userId', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });

// User ↔ ClientProfile
db.User.hasOne(db.ClientProfile, { foreignKey: 'userId', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });
db.ClientProfile.belongsTo(db.User, { foreignKey: 'userId', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });

// Favorites
db.ClientProfile.hasMany(db.Favorite, { foreignKey: 'clientId', onDelete: 'CASCADE' });
db.Favorite.belongsTo(db.ClientProfile, { foreignKey: 'clientId' });
db.WorkerProfile.hasMany(db.Favorite, { foreignKey: 'workerId', onDelete: 'CASCADE' });
db.Favorite.belongsTo(db.WorkerProfile, { foreignKey: 'workerId' });
db.ClientProfile.belongsToMany(db.WorkerProfile, { through: db.Favorite, foreignKey: 'clientId', otherKey: 'workerId', as: 'FavoriteWorkers' });
db.WorkerProfile.belongsToMany(db.ClientProfile, { through: db.Favorite, foreignKey: 'workerId', otherKey: 'clientId', as: 'FavoritedByClients' });

// Jobs
db.User.hasMany(db.Job, { foreignKey: 'clientId', as: 'ClientJobs', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });
db.Job.belongsTo(db.User, { foreignKey: 'clientId', as: 'Client', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });
db.User.hasMany(db.Job, { foreignKey: 'workerId', as: 'WorkerJobs', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });
db.Job.belongsTo(db.User, { foreignKey: 'workerId', as: 'Worker', onDelete: 'RESTRICT', onUpdate: 'CASCADE' });

// Verification (Admin)
db.User.hasMany(db.Verification, { foreignKey: 'userId', onDelete: 'CASCADE' });
db.Verification.belongsTo(db.User, { foreignKey: 'userId' });

// Disputes (Admin)
db.User.hasMany(db.Dispute, { foreignKey: 'clientId', as: 'ClientDisputes' });
db.Dispute.belongsTo(db.User, { foreignKey: 'clientId', as: 'Client' });
db.User.hasMany(db.Dispute, { foreignKey: 'workerId', as: 'WorkerDisputes' });
db.Dispute.belongsTo(db.User, { foreignKey: 'workerId', as: 'Worker' });

// ── Chat associations (new) ──────────────────────────────────────────────────
// One job has at most one chat room
db.Job.hasOne(db.ChatRoom, { foreignKey: 'jobId', onDelete: 'CASCADE' });
db.ChatRoom.belongsTo(db.Job, { foreignKey: 'jobId' });

// A chat room has many messages
db.ChatRoom.hasMany(db.Message, { foreignKey: 'chatRoomId', onDelete: 'CASCADE' });
db.Message.belongsTo(db.ChatRoom, { foreignKey: 'chatRoomId' });

// Each message has a sender (User)
db.User.hasMany(db.Message, { foreignKey: 'senderId', as: 'SentMessages' });
db.Message.belongsTo(db.User, { foreignKey: 'senderId', as: 'Sender' });

module.exports = db;
