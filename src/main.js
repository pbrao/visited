import { createApp } from 'vue'
import App from './App.vue'
import { createVuetify } from 'vuetify'
import { VDataTable } from 'vuetify/lib/labs/VDataTable'
import 'vuetify/styles'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import '@mdi/font/css/materialdesignicons.css'

// Initialize Vuetify
const vuetify = createVuetify({
  components: {
    ...components,
    VDataTable,
  },
  directives,
  defaults: {
    VDataTable: {
      density: 'compact',
    },
  },
})

// Create the app and use Vuetify
createApp(App)
  .use(vuetify)
  .mount('#app')
