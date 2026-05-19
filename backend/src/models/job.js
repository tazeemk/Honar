module.exports = (sequelize, DataTypes) => {
  return sequelize.define("Job", {
    clientId: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    workerId: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    title: {
      type: DataTypes.STRING,
      allowNull: false
    },
    description: DataTypes.TEXT,
    budget: {
      type: DataTypes.FLOAT,
      allowNull: false
    },
    preferredDate: DataTypes.DATEONLY,
    location: DataTypes.STRING,
    status: {
      type: DataTypes.ENUM('pending', 'accepted', 'declined'),
      defaultValue: 'pending'
    },
    requestedAt: {
      type: DataTypes.DATE,
      defaultValue: DataTypes.NOW
    },
    respondedAt: DataTypes.DATE,
    acceptedAt: DataTypes.DATE,
    declinedAt: DataTypes.DATE,
    declineReason: DataTypes.TEXT
  });
};
