const bcrypt = require('bcryptjs');
const db = require('../models');
const { generateAccessToken, generateRefreshToken } = require('../utils/tokenUtils');

const { User, WorkerProfile, RefreshToken } = db;

const register = async ({ email, password, role, name, phone }) =>{
  const exists = await User.findOne({ where: { email } });
  if (exists) throw new Error('User already exists');

  const hash = await bcrypt.hash(password, 10);

  const user = await User.create({
    email,
    password: hash,
    role: role.toLowerCase(),
    name,      // ✅ add
    phone      // ✅ add
  });

  if (role.toUpperCase() === 'WORKER') {
    await WorkerProfile.create({ userId: user.id });
  }

  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);

  await RefreshToken.create({ token: refreshToken });

  return {
    user: { id: user.id, email: user.email, role: user.role },
    accessToken,
    refreshToken
  };
};

const login = async ({ email, password }) => {
  const user = await User.findOne({ where: { email } });
  if (!user) throw new Error('Invalid credentials');

  const match = await bcrypt.compare(password, user.password);
  if (!match) throw new Error('Invalid credentials');

  const accessToken = generateAccessToken(user);
  const refreshToken = generateRefreshToken(user);

  await RefreshToken.create({ token: refreshToken });

  return {
    user: { id: user.id, email: user.email, role: user.role, isProfileCompleted: user.isProfileCompleted },
    accessToken,
    refreshToken
  };
};

module.exports = { register, login };
