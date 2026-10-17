// Minimal CORS so Flutter web (served from a different port) can call the API.
// Mobile builds don't need CORS, but it doesn't hurt them.
function cors(allowed = '*') {
  const origins = allowed.split(',').map((o) => o.trim()).filter(Boolean);
  const allowAll = origins.includes('*');

  return (req, res, next) => {
    const origin = req.get('Origin');
    if (allowAll) {
      res.set('Access-Control-Allow-Origin', '*');
    } else if (origin && origins.includes(origin)) {
      res.set('Access-Control-Allow-Origin', origin);
      res.vary('Origin');
    }
    if (req.method === 'OPTIONS') {
      res.set('Access-Control-Allow-Methods', 'GET, POST, PATCH, OPTIONS');
      res.set('Access-Control-Allow-Headers', 'Content-Type');
      res.set('Access-Control-Max-Age', '600');
      return res.status(204).end();
    }
    next();
  };
}

module.exports = { cors };
