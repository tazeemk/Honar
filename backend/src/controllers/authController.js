const authService = require('../services/authService');
const jwt = require('jsonwebtoken');
const db = require('../models');

const { RefreshToken } = db;

const register = async (req, res) => {
  try {
    const { user, accessToken, refreshToken } = await authService.register(req.body);
    res.status(201).json({
      message: 'User registered successfully',
      user: { id: user.id, email: user.email, role: user.role },
      accessToken,
      refreshToken
    });
  } catch (e) {
    res.status(400).json({ message: e.message });
  }
};

const login = async (req, res) => {
  try {
    const { accessToken, refreshToken, user } = await authService.login(req.body);
    res.json({
      message: 'Login success',
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        isProfileCompleted: user.isProfileCompleted
      },
      accessToken,
      refreshToken
    });
  } catch (e) {
    res.status(401).json({ message: e.message });
  }
};

const refresh = async (req, res) => {
  // Support both cookie and Authorization header for refresh token
  let token = req.cookies?.refreshToken;
  if (!token && req.body?.refreshToken) token = req.body.refreshToken;
  if (!token) return res.sendStatus(401);

  const exists = await RefreshToken.findOne({ where: { token } });
  if (!exists) return res.sendStatus(403);

  jwt.verify(token, process.env.JWT_REFRESH_SECRET, async (err, user) => {
    if (err) return res.sendStatus(403);

    // Delete old refresh token and generate new pair
    await RefreshToken.destroy({ where: { token } });

    const newAccess = jwt.sign(
      { id: user.id, role: user.role },
      process.env.JWT_ACCESS_SECRET,
      { expiresIn: '15m' }
    );
    const newRefresh = jwt.sign(
      { id: user.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );

    await RefreshToken.create({ token: newRefresh });

    res.json({ accessToken: newAccess, refreshToken: newRefresh, message: 'Token refreshed' });
  });
};

const logout = async (req, res) => {
  const token = req.cookies?.refreshToken || req.body?.refreshToken;
  if (token) {
    await RefreshToken.destroy({ where: { token } });
  }
  res.clearCookie('accessToken');
  res.clearCookie('refreshToken');
  res.json({ message: 'Logged out' });
};

module.exports = { register, login, refresh, logout };
