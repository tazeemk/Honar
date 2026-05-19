const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const role = require('../middleware/roleMiddleware');
const { toggleFavorite, getMyFavorites, checkFavorite } = require('../controllers/favoriteController');

const clientOnly = [auth, role(['client'])];

router.get('/',                          clientOnly, getMyFavorites);
router.get('/check/:workerProfileId',    clientOnly, checkFavorite);
router.post('/toggle/:workerProfileId',  clientOnly, toggleFavorite);

module.exports = router;
