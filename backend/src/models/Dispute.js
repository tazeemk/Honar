// src/models/Dispute.js
// Disputes between clients and workers

module.exports = (sequelize, DataTypes) => {
  const Dispute = sequelize.define('Dispute', {
    clientId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    workerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    subject: {
      type: DataTypes.STRING,
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    status: {
      type: DataTypes.ENUM('open', 'under_review', 'resolved', 'closed'),
      defaultValue: 'open',
    },
    resolvedAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    resolvedBy: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
    resolution: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
  });

  return Dispute;
};
