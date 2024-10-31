/* globals __dirname */

const CleanWebpackPlugin = require('clean-webpack-plugin')
require('colors')
const path = require('path')
const webpack = require('webpack')

const debug = process.env.NODE_ENV !== 'production'
const elmSource = path.resolve(path.join(__dirname, './admin/elm'))
const output = path.resolve(path.join(__dirname, '../dist/admin'))

// Notification plugin that shows errors on each build
const WebpackNotifierPlugin = function () {}

WebpackNotifierPlugin.prototype.compilationDone = function (stats) {
  const log = (error) => {
    console.log(`
ERROR in ${error.module.rawRequest}
${error.error.toString()}`.red.bold)
  }
  if (stats.compilation.errors.length) {
    console.log('\n***** BUILD FAILED *****\n')
    stats.compilation.errors.forEach(log)
  } else {
    console.log('\n***** BUILD OK *****\n')
  }
}

WebpackNotifierPlugin.prototype.apply = function (compiler) {
  compiler.plugin('done', this.compilationDone.bind(this))
}

const plugins = (isDebug) => {
  const cleanDist = new CleanWebpackPlugin([output], {
    root: path.join(__dirname, '../'),
    verbose: true,
    dry: false,
    exclude: []
  })

  if (isDebug) {
    return [
      new webpack.NoErrorsPlugin(),
      cleanDist,
      // new LiveReloadPlugin(),
      new WebpackNotifierPlugin()
    ]
  } else {
    return [
      new webpack.NoErrorsPlugin(),
      cleanDist,
      new webpack.optimize.UglifyJsPlugin({
        compress: {
          warnings: false
        }
      }),
      new webpack.optimize.DedupePlugin(),
      new webpack.optimize.OccurenceOrderPlugin()
    ]
  }
}

const devTool = (isDebug) => {
  if (isDebug) {
    return 'inline-source-map'
  } else {
    return ''
  }
}

module.exports = {
  entry: {
    app: [ './admin/index.js' ]
  },

  output: {
    path: output,
    filename: '[name].js',
    publicPath: null,
    libraryTarget: 'var',
    library: 'OptinEngineAdmin'
  },

  module: {
    loaders: [
      {
        test: /\.(css|scss)$/,
        loaders: [
          'style-loader',
          'css-loader'
        ]
      },
      {
        test: /\.html$/,
        exclude: /node_modules/,
        loader: 'file?name=[name].[ext]'
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        // loader: 'elm-webpack?cwd=' + elmSource
        loader: 'elm-hot!elm-webpack?verbose=true&warn=true&cwd=' + elmSource
      },
      {
        test: /\.less$/,
        loader: 'style!css!less'
      },
      {
        test: /\.woff(2)?(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'url-loader?limit=10000&mimetype=application/font-woff'
      },
      {
        test: /\.(ttf|eot|svg|png)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        loader: 'file-loader'
      },
      {
        test: /\.js$/,
        exclude: /(node_modules|bower_components|assets)/,
        loaders: [
          'babel',
          'eslint-loader'
        ]
      }
    ],

    noParse: [/\.elm$/, /\.elmproj$/]
  },

  eslint: {
    failOnWarning: true,
    failOnError: true
  },

  plugins: plugins(debug),
  devtool: devTool(debug)
}
