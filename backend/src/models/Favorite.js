module.exports = (sequelize, DataTypes) => {
  const Favorite = sequelize.define('Favorite', {
    clientId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    },
    workerId: {
      type: DataTypes.INTEGER,
      allowNull: false,
    }
  }, {
    tableName: 'Favorites',
    indexes: [
      { unique: true, fields: ['clientId', 'workerId'] }
    ]
  });

  return Favorite;
};
