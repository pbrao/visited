const { defineConfig } = require('@vue/cli-service')
const NodePolyfillPlugin = require('node-polyfill-webpack-plugin')

module.exports = defineConfig({
  transpileDependencies: true,
  css: {
    loaderOptions: {
      sass: {
        additionalData: `
          @import "@/assets/styles/_variables.scss";
        `
      }
    }
  },
  configureWebpack: {
    plugins: [
      new NodePolyfillPlugin()
    ],
    resolve: {
      fallback: {
        "fs": false
      }
    }
  }
})
