module.exports = ({ env }) => {
  const raw = env('APP_KEYS', '');
  // split comma-separated keys, filter empties
  const keys = raw.split(',').map(k => k.trim()).filter(Boolean);
  if (!keys.length) {
    // fallback: generate in-memory keys (not persistent) - but we prefer env-based keys
    // eslint-disable-next-line no-console
    console.warn('Warning: APP_KEYS is empty — sessions may be insecure.');
  }
  return {
    host: env('HOST', '0.0.0.0'),
    port: env.int('PORT', 1337),
    app: {
      keys,
    },
  };
};
