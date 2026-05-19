module.exports = (sequelize, DataTypes) => {
  const User = sequelize.define('User', {

    name: {
   type: DataTypes.STRING,
   allowNull: true
   },
   phone: {
  type: DataTypes.STRING,
  allowNull: true
},


    email: {
      type: DataTypes.STRING,
      allowNull: false,
      unique: true,
      validate: { isEmail: true }
    },
    password: {
      type: DataTypes.STRING,
      allowNull: false
    },
    role: {
      type: DataTypes.ENUM('client', 'worker', 'admin'),
      defaultValue: 'client'
    },
    isProfileCompleted: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  });

  return User;
};
