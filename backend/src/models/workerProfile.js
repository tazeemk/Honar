module.exports = (sequelize, DataTypes) => {
  const WorkerProfile = sequelize.define("WorkerProfile", {
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    category: DataTypes.STRING,
    bio: DataTypes.TEXT,
    rate: DataTypes.FLOAT,
    city: DataTypes.STRING,
    skills: DataTypes.STRING,
    idProof: DataTypes.STRING,
    isVerified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    subscriptionStatus: {
      type: DataTypes.STRING,
      defaultValue: 'INACTIVE'
    }
  });

  return WorkerProfile;
};