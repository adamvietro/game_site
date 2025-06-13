// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"
import KeyInput from "./hooks/KeyInput"

let Hooks = {}

Hooks.CopyBonus = {
  mounted() {
    this.el.addEventListener("click", (e) => {
      const visible = document.getElementById("wager_input")
      const guess = this.el.textContent.trim()
      const hidden = document.getElementById(`wager_hidden_${guess}`)
      if (visible && hidden) {
        hidden.value = visible.value || "1"
      }
    })
  }
}

Hooks.AutoDismiss = {
  mounted() {
    // Get the timeout value from the data attribute
    const timeout = this.el.dataset.timeout || 5000; // Default to 5000ms if not provided

    // Set a timeout to hide the flash message
    setTimeout(() => {
      this.el.style.opacity = "0";  // Fade out
      setTimeout(() => {
        this.el.remove();  // Completely remove the flash message from DOM after fade-out
      }, 500);  // Time for fade-out effect
    }, timeout);
  }
}


Hooks.FocusGuess = {
  mounted() {
    this.el.focus()
    this.el.select?.()
  },
  updated() {
    this.el.focus()
    this.el.select?.()
  }
}

Hooks.KeyInput = KeyInput

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  hooks: Hooks,
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken }
})

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

