/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
<<<<<<< HEAD
  swcMinify: true,
  webpack: (config, { isServer }) => {
    if (!isServer) {
      config.resolve.fallback.fs = false
    }
    return config
  }
=======
>>>>>>> 6086ce81accc56b02047c58d3ba39511eb3cea6a
}

module.exports = nextConfig
