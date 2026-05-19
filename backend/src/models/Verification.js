// src/models/Verification.js
// Admin ID verification requests

module.exports = (sequelize, DataTypes) => {
  const Verification = sequelize.define('Verification', {
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    userRole: {
      type: DataTypes.ENUM('worker', 'client'),
      allowNull: false,
    },
    docType: {
      type: DataTypes.ENUM('Passport', 'National ID', 'Driving License'),
      allowNull: false,
      defaultValue: 'National ID',
    },
    docPath: {
      type: DataTypes.STRING,
      allowNull: true,
    },
    status: {
      type: DataTypes.ENUM('pending', 'approved', 'rejected'),
      defaultValue: 'pending',
    },
    reviewedAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    reviewedBy: {
      type: DataTypes.INTEGER,
      allowNull: true,
    },
  });

  return Verification;
};
