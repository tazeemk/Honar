module.exports = (sequelize, DataTypes) => {
  return sequelize.define("Subscription", {
    plan: DataTypes.STRING,
    price: DataTypes.FLOAT,
    startDate: DataTypes.DATE,
    endDate: DataTypes.DATE,
    status: DataTypes.STRING
  });
};