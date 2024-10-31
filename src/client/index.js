/* globals WebFont, XMLHttpRequest, FormData */

require('./less/style.less')

const Cookie = require('js-cookie')
const OptinEngine = require('./elm/Main.elm')

const addElementToDom = (div, el, insertAtBeginning) => {
  if (el.childNodes.length > 0 && insertAtBeginning) {
    el.insertBefore(div, el.childNodes[0])
  } else {
    el.appendChild(div)
  }
}

const injectRemoteJS = (src) => {
  return new Promise((resolve, reject) => {
    (function (d, script) {
      script = d.createElement('script')
      script.type = 'text/javascript'
      script.async = true
      script.onload = resolve
      script.src = src
      d.getElementsByTagName('head')[0].appendChild(script)
    }(document))
  })
}

function getStyle (el, prop) {
  var view = document.defaultView
  if (view && view.getComputedStyle) {
    return view.getComputedStyle(el, null)[prop]
  }
  return el.currentStyle[prop]
}

function fixedTopElements () {
  // I really have no idea why they wouldn't implement a
  // standard array here :(
  var all = Array.prototype.slice.call(
    document.getElementsByTagName('*'), 0
  )

  return all.filter((element) => {
    return (
      getStyle(element, 'position') === 'fixed' &&
      getStyle(element, 'top') === '0px'
    )
  })
}

var addEvent = (object, type, callback) => {
  if (object == null || typeof (object) === 'undefined') return
  if (object.addEventListener) {
    object.addEventListener(type, callback, false)
  } else if (object.attachEvent) {
    object.attachEvent('on' + type, callback)
  } else {
    object['on' + type] = callback
  }
}

var createApp = (options, promo, container) => {
  const div = document.createElement('div')
  const app = OptinEngine.Main.embed(div, options)
  const promoCookieKey = (promoId) => `optinengine-promo-hidden-${promoId}`
  const margins = {
    top: document.body.style.paddingTop || 0,
    bottom: document.body.style.paddingBottom || 0
  }
  const elementsToMove = fixedTopElements()

  const getBarHeight = () => {
    const bars = document.getElementsByClassName('optinengine-optin')
    if (!bars.length) {
      return 0
    }
    return bars[0].offsetHeight
  }

  const haveTopBar = () => {
    return document.getElementsByClassName('optinengine-optin flex-bar flex-top flex-fixed flex-push').length >= 1
  }

  addEvent(window, 'resize', () => {
    if (haveTopBar()) {
      setTopMargin()
    }
  })

  const resetMargins = () => {
    document.body.style.paddingTop = margins.top + 'px'
    document.body.style.paddingBottom = margins.bottom + 'px'
    elementsToMove.forEach((element) => {
      element.style.top = '0px'
    })
  }

  const setTopMargin = (height) => {
    height = getBarHeight() || height
    resetMargins()
    document.body.style.paddingTop = height + 'px'
    elementsToMove.forEach((element) => {
      element.style.top = height + 'px'
    })
  }

  app.ports.setTopMargin.subscribe((height) => {
    const checkTopBar = () => {
      if (haveTopBar()) {
        setTopMargin(height)
      } else {
        setTimeout(checkTopBar, 10)
      }
    }
    checkTopBar()
  })

  app.ports.setBottomMargin.subscribe((height) => {
    resetMargins()
    document.body.style.paddingBottom = height + 'px'
  })

  app.ports.resetMargins.subscribe(() => {
    resetMargins()
  })

  app.ports.addElementToDom.subscribe((insertAtBeginning) => {
    addElementToDom(div, app.container || document.body, insertAtBeginning)
  })

  app.ports.redirectToUrl.subscribe((info) => {
    if (info.newWindow) {
      window.open(info.url)
    } else {
      window.location = info.url
    }
  })

  app.ports.setPromoHidden.subscribe((info) => {
    if (info.duration > 0) {
      Cookie.set(promoCookieKey(info.promoId), '1', { expires: info.duration })
    }
    resetMargins()
  })

  app.ports.loadFonts.subscribe((fonts) => {
    injectRemoteJS('https://ajax.googleapis.com/ajax/libs/webfont/1/webfont.js').then(() => {
      WebFont.load({ google: { families: fonts } })
    })
  })

  app.setPromo = (promo, container) => {
    const promoInfo = promo.promo

    // this is a bit of a hack, basically if we don't need margins in this new
    // promo then reset the margins
    if (
      promoInfo.promoType !== 'bar' ||
      promoInfo.placement !== 'top' ||
      promoInfo.pushPage === false ||
      promoInfo.positionFixed === false) {
      resetMargins()
    }

    app.container = container

    // this appears to be some kind of bug in Elm, for some reason
    // it does not like the fields[] array that is passed out of
    // Elm being passed back into Elm
    app.ports.setPromo.send(JSON.parse(JSON.stringify(promo)))
  }

  if (promo) {
    const promoInfo = promo.promo

    // only use delay if we are not embedded
    if (promoInfo.displayDelaySeconds === 0 || isPromoEmbedded(promoInfo)) {
      app.setPromo(promo, container)
    } else {
      setTimeout(() => {
        app.setPromo(promo, container)
      }, promoInfo.displayDelaySeconds * 1000)
    }
  }

  return app
}

const isPromoEmbedded = (promo) => {
  switch (promo.promoType) {
    case 'before-post':
    case 'after-post':
    case 'inline':
    case 'widget':
      return true

    default:
      return false
  }
}

const api = (url, data) => {
  return new Promise((resolve, reject) => {
    var xhr = new XMLHttpRequest()

    xhr.onreadystatechange = function () {
      if (this.readyState !== 4) {
        return
      }

      if (this.status !== 200) {
        reject()
        return
      }

      var response = JSON.parse(this.responseText)
      resolve(response)
    }

    var formData = new FormData()
    for (let key in data) {
      formData.append(key, data[key])
    }

    xhr.withCredentials = true
    xhr.open('POST', url, true)
    xhr.send(formData)
  })
}

const setupWindowPreview = (options) => {
  const previewApp = createApp(options, null, null)

  const getPreviewContainer = (promo) => {
    console.log(promo.promo.promoType)
    switch (promo.promo.promoType) {
      case 'inline':
      case 'before-post':
      case 'after-post':
      case 'widget':
        return document.getElementsByClassName('container')[0]

      default:
        return null
    }
  }

  const setPreviewPromo = (promo) => {
    // disable any triggers
    promo.promo.displayDelaySeconds = 0

    const container = getPreviewContainer(promo)

    console.log(container)

    if (container) {
      if (promo.promo.formOrientation === 'bottom') {
        container.style.width = '380px'
      } else {
        container.style.width = '600px'
      }
    }

    previewApp.setPromo(
      promo, container
    )

    /*
    const res = JSON
      .stringify(promo, null, 2)
      .replace(new RegExp('"', 'g'), '\'')

    console.log(res)
    */
  }

  const showThankyou = (show) => {
    if (previewApp) {
      previewApp.ports.showThankyou.send(show)
    }
  }

  window.optinengine = {
    setPreviewPromo,
    showThankyou
  }
}

const getParentElements = (promo) => {
  switch (promo.promoType) {
    case 'inline':
    case 'widget':
      return document.querySelectorAll(`[data-optinengine-promo-${promo.id}]`)

    case 'before-post':
      return document.getElementsByClassName('optinengine_before_post')

    case 'after-post':
      return document.getElementsByClassName('optinengine_after_post')
  }

  return null
}

const load = (options) => {
  document.addEventListener('DOMContentLoaded', (event) => {
    if (options.editor) {
      setupWindowPreview(options)
    } else {
      api(options.api, {
        action: 'optinengine_get_promos',
        page_type: options.pageType,
        url: options.url
      }).then((res) => {
        res.promos.forEach((promo) => {
          const parentElements = getParentElements(promo)

          if (parentElements) {
            [].forEach.call(parentElements, (div) => {
              createApp(options, {
                affiliateId: res.affiliate_id,
                affiliateEnabled: res.affiliate_enabled,
                promo: promo
              }, div)
            })
          } else {
            createApp(options, {
              affiliateId: res.affiliate_id,
              affiliateEnabled: res.affiliate_enabled,
              promo: promo
            }, null)
          }
        })
      })
    }
  })
}

const disableClicks = () => {
  document.addEventListener('click', (e) => {
    e.stopPropagation()
    e.preventDefault()
  }, true)
}

module.exports = {
  load,
  disableClicks
}
