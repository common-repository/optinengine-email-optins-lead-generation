/* globals $, screen, tinymce, wp */

__webpack_public_path__ = window._optinEngineAdminPublicPath // eslint-disable-line

require('./less/style.less')
require('font-awesome-webpack')
require('expose?$!expose?jQuery!jquery')
require('./assets/arrive.min.js')
require('./assets/spectrum.js')
require('./assets/spectrum.css')

const FlexAdmin = require('./elm/Main.elm')
const templates = require('./js/templates.js')

const load = (options) => {
  const div = document.getElementById('optinengine-admin-container')
  const app = FlexAdmin.Main.embed(div, options)
  let fileUpload = null

  function openPopup (url, title, w, h) {
    const dualScreenLeft = window.screenLeft !== undefined ? window.screenLeft : screen.left
    const dualScreenTop = window.screenTop !== undefined ? window.screenTop : screen.top

    const width = window.innerWidth ? window.innerWidth : document.documentElement.clientWidth ? document.documentElement.clientWidth : screen.width
    const height = window.innerHeight ? window.innerHeight : document.documentElement.clientHeight ? document.documentElement.clientHeight : screen.height

    const left = ((width / 2) - (w / 2)) + dualScreenLeft
    const top = ((height / 2) - (h / 2)) + dualScreenTop
    const newWindow = window.open(url, title, 'scrollbars=yes, width=' + w + ', height=' + h + ', top=' + top + ', left=' + left)

    if (window.focus) {
      newWindow.focus()
    }
  }

  const setPromo = (promo) => {
    const iframe = document.getElementById('optinengine-preview')
    if (iframe && iframe.contentWindow && iframe.contentWindow.optinengine) {
      iframe.contentWindow
        .optinengine
        .setPreviewPromo(promo)
    } else {
      setTimeout(() => setPromo(promo), 100)
    }
  }

  app.ports.setPromo.subscribe((promo) => {
    setPromo(promo)
  })

  app.ports.redirect.subscribe((url) => {
    window.location.href = url
  })

  app.ports.enableBodyScroll.subscribe((enable) => {
    if (enable) {
      document.body.style.overflow = ''
    } else {
      document.body.style.overflow = 'hidden'
    }
  })

  app.ports.parseForm.subscribe((html) => {
    const el = document.createElement('html')
    el.innerHTML = html
    const form = $(el).find('form')
    const method = form.attr('method') || ''
    const action = form.attr('action') || ''
    const hidden = $.map(form.find('input[type="hidden"]'), (input) => {
      return {
        name: $(input).attr('name'),
        fieldType: 'hidden',
        mapping: '',
        value: $(input).val()
      }
    })
    const inputs = $.map(form.find('input[type="text"], input[type="email"]'), (input) => {
      return {
        name: $(input).attr('name'),
        fieldType: 'input',
        mapping: '',
        value: ''
      }
    })
    const fields = hidden.concat(inputs)
    app.ports.parsedFormInfo.send({
      action,
      method,
      fields
    })
  })

  app.ports.openAuthPopup.subscribe((url) => {
    openPopup(url, 'Authorize Email Provider', 700, 500)
  })

  app.ports.setTemplates.send(templates)
  app.ports.pickImageFromMedia.subscribe(() => {
    if (fileUpload) {
      fileUpload.open()
      return
    }

    fileUpload = wp.media.frames.file_frame = wp.media({
      title: 'Select a image to upload',
      library: {
        type: 'image'
      },
      button: {
        text: 'Use this image'
      },
      multiple: false
    })

    fileUpload.on('select', () => {
      const attachment = fileUpload.state().get('selection').first().toJSON()
      app.ports.pickImageFromMediaResult.send(attachment.url)
    })

    fileUpload.open()
  })

  const showThankyou = (show) => {
    const iframe = document.getElementById('optinengine-preview')
    if (iframe && iframe.contentWindow && iframe.contentWindow.optinengine) {
      iframe.contentWindow
        .optinengine
        .showThankyou(show)
    } else {
      setTimeout(() => showThankyou(show), 100)
    }
  }

  app.ports.showThankyou.subscribe((show) => {
    showThankyou(show)
  })

  const setupTinyMce = (editorId, onUpdate) => {
    const selector = '#' + editorId
    if (!$(selector).hasClass('wp-editor-area')) {
      const html = $(selector).data('html')
      tinymce.EditorManager.execCommand('mceRemoveEditor', true, editorId)
      $(selector).html(html)
      tinymce.init({
        selector: selector,
        height: 150,
        menubar: false,
        statusbar: false,
        plugins: 'textcolor colorpicker link',
        toolbar: 'forecolor backcolor bold italic underline alignleft aligncenter alignright link | fontsizeselect removeformat',
        // font_formats: 'Arial=arial,helvetica,sans-serif;Courier New=courier new,courier,monospace;AkrutiKndPadmini=Akpdmi-n',
        font_formats: 'Open Sans=Open Sans;Merriweather=Merriweather;Courier New=courier new,courier,monospace;AkrutiKndPadmini=Akpdmi-n',
        fontsize_formats: '8pt 9pt 10pt 11pt 12pt 13pt 14pt 15pt 16pt 17pt 18pt 19pt 20pt 21pt 22pt 23pt 24pt 25pt 26pt 27pt 28pt 29pt 30pt 31pt 32pt 33pt 34pt 35pt 36pt 37pt 38pt 39pt 40pt 41pt 42pt 43pt 44pt 45pt 46pt 47pt 48pt 49pt 50pt',
        textcolor_map: [
          '000000', 'Black',
          '993300', 'Burnt orange',
          '333300', 'Dark olive',
          '003300', 'Dark green',
          '003366', 'Dark azure',
          '000080', 'Navy Blue',
          '333399', 'Indigo',
          '333333', 'Very dark gray',
          '800000', 'Maroon',
          'FF6600', 'Orange',
          '808000', 'Olive',
          '008000', 'Green',
          '008080', 'Teal',
          '0000FF', 'Blue',
          '666699', 'Grayish blue',
          '808080', 'Gray',
          'FF0000', 'Red',
          'FF9900', 'Amber',
          '99CC00', 'Yellow green',
          '339966', 'Sea green',
          '33CCCC', 'Turquoise',
          '3366FF', 'Royal blue',
          '800080', 'Purple',
          '999999', 'Medium gray',
          'FF00FF', 'Magenta',
          'FFCC00', 'Gold',
          'FFFF00', 'Yellow',
          '00FF00', 'Lime',
          '00FFFF', 'Aqua',
          '00CCFF', 'Sky blue',
          '993366', 'Red violet',
          'FFFFFF', 'White',
          'FF99CC', 'Pink',
          'FFCC99', 'Peach',
          'FFFF99', 'Light yellow',
          'CCFFCC', 'Pale green',
          'CCFFFF', 'Pale cyan',
          '99CCFF', 'Light sky blue',
          'CC99FF', 'Plum'
        ],
        setup: (ed) => {
          ed.on('keyup', (e) => {
            onUpdate(ed.getContent())
          })

          ed.on('change', (e) => {
            onUpdate(ed.getContent())
          })
        }
      })
    }
  }

  $(document).arrive('#body-editor', function () {
    setupTinyMce('body-editor', (html) => {
      app.ports.updateBodyHtml.send(html)
    })
  })

  $(document).arrive('#headline-editor', function () {
    setupTinyMce('headline-editor', (html) => {
      app.ports.updateHeadlineHtml.send(html)
    })
  })

  $(document).arrive('#thank-you-headline-editor', function () {
    setupTinyMce('thank-you-headline-editor', (html) => {
      app.ports.updateThankYouHtml.send(html)
    })
  })

  $(document).arrive('#thank-you-body-editor', function () {
    setupTinyMce('thank-you-body-editor', (html) => {
      app.ports.updateThankYouBodyHtml.send(html)
    })
  })

  $(document).arrive('.color-picker', function () {
    const variable = $(this).data('variable')
    const color = $(this).data('color')
    $(this).spectrum({
      color: color,
      showPalette: true,
      hideAfterPaletteSelect: true,
      showInput: true,
      preferredFormat: 'hex3',
      change: function (color) {
        app.ports.updateColor.send({
          variable,
          color: color.toHexString()
        })
      },
      palette: [
        ['#000', '#444', '#666', '#999', '#ccc', '#eee', '#f3f3f3', '#fff'],
        ['#f00', '#f90', '#ff0', '#0f0', '#0ff', '#00f', '#90f', '#f0f'],
        ['#f4cccc', '#fce5cd', '#fff2cc', '#d9ead3', '#d0e0e3', '#cfe2f3', '#d9d2e9', '#ead1dc'],
        ['#ea9999', '#f9cb9c', '#ffe599', '#b6d7a8', '#a2c4c9', '#9fc5e8', '#b4a7d6', '#d5a6bd'],
        ['#e06666', '#f6b26b', '#ffd966', '#93c47d', '#76a5af', '#6fa8dc', '#8e7cc3', '#c27ba0'],
        ['#c00', '#e69138', '#f1c232', '#6aa84f', '#45818e', '#3d85c6', '#674ea7', '#a64d79'],
        ['#900', '#b45f06', '#bf9000', '#38761d', '#134f5c', '#0b5394', '#351c75', '#741b47'],
        ['#600', '#783f04', '#7f6000', '#274e13', '#0c343d', '#073763', '#20124d', '#4c1130']
      ]
    })
  })
}

module.exports = {
  load
}
