// Every error response has the shape { error: { code, message, details? } }
// (see docs/api.md). Route handlers throw an HttpError; errorHandler formats it.
class HttpError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

const validationError = (message, details) => new HttpError(400, 'validation_error', message, details);
const forbidden = (message) => new HttpError(403, 'forbidden', message);
const notFound = (message) => new HttpError(404, 'not_found', message);
const conflict = (code, message) => new HttpError(409, code, message);

// eslint-disable-next-line no-unused-vars
function errorHandler(err, req, res, next) {
  // Errors from express.json(): malformed JSON, body too large, etc.
  if (!(err instanceof HttpError) && err.expose && err.status >= 400 && err.status < 500) {
    const message = err.type === 'entity.parse.failed' ? 'Request body is not valid JSON' : err.message;
    err = validationError(message);
  }
  if (!(err instanceof HttpError)) {
    console.error(err);
    err = new HttpError(500, 'internal_error', 'Something went wrong on the server');
  }
  const body = { code: err.code, message: err.message };
  if (err.details) body.details = err.details;
  res.status(err.status).json({ error: body });
}

module.exports = { HttpError, validationError, forbidden, notFound, conflict, errorHandler };
