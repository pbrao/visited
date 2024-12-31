import { createApp } from 'vue'
import App from './App.vue'
import { createVuetify } from 'vuetify'
import 'vuetify/styles' // Import Vuetify styles

// Initialize Vuetify
const vuetify = createVuetify()

// Create the app and use Vuetify
createApp(App)
  .use(vuetify)
  .mount('#app')
