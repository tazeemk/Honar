const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  // Try to get token from Authorization header (Bearer token) or cookies
  let token = null;

  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    token = req.headers.authorization.substring(7);
  } else if (req.cookies.accessToken) {
    token = req.cookies.accessToken;
  }

  if (!token) return res.status(401).json({ message: 'No token provided' });

  try {
    const user = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    req.user = user;
    next();
  } catch (err) {
    return res.status(403).json({ message: 'Invalid or expired token' });
  }
};