module.exports = (sequelize, DataTypes) => {
  const ClientProfile = sequelize.define("ClientProfile", {
    userId: {
      type: DataTypes.INTEGER,
      allowNull: false
    },
    city: {
      type: DataTypes.STRING,
      allowNull: false
    },
    address: {
      type: DataTypes.TEXT,
      allowNull: false
    },
    residenceOrCompanyName: {
      type: DataTypes.STRING,
      allowNull: false
    },
    profileImage: {
      type: DataTypes.STRING,
      allowNull: true
    },
    idProof: {
      type: DataTypes.STRING,
      allowNull: true
    },
    isVerified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    },
    subscriptionStatus: {
      type: DataTypes.STRING,
      defaultValue: 'INACTIVE'
    }
  });

  return ClientProfile;
};
