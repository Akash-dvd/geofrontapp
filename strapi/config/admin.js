module.exports = ({ env }) => {
  // auth.secret was already configured previously; keep that and add apiToken.salt
  const authSecret = env('ADMIN_AUTH_SECRET', env('ADMIN_JWT_SECRET', 'change-me'));
  const apiTokenSalt = env('API_TOKEN_SALT', '');

  if (!apiTokenSalt) {
    // eslint-disable-next-line no-console
    console.warn('Warning: API_TOKEN_SALT is empty — admin API tokens may be insecure.');
  }

  return {
    auth: {
      secret: authSecret,
      // keep any other auth settings (you can add sessions config here if needed)
    },
    apiToken: {
      salt: apiTokenSalt,
    },
  };
};
