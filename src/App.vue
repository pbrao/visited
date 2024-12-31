<template>
  <v-app>
    <!-- Authentication Section -->
    <v-container
      v-if="!user"
      class="auth-section"
    >
      <v-card
        class="mx-auto"
        max-width="400"
      >
        <v-card-title class="text-center">
          Sign In with Magic Link
        </v-card-title>
        <v-card-text>
          <v-text-field
            v-model="email"
            label="Enter your email"
            type="email"
            outlined
          />
          <v-btn
            color="primary"
            block
            @click="signInWithMagicLink"
          >
            Send Magic Link
          </v-btn>
          <v-alert
            v-if="authMessage"
            type="info"
            class="mt-3"
          >
            {{ authMessage }}
          </v-alert>
        </v-card-text>
      </v-card>
    </v-container>

    <!-- Main App Content -->
    <v-container v-else>
      <v-card>
        <v-toolbar
          color="primary"
          dark
        >
          <v-toolbar-title>Visited</v-toolbar-title>
          <v-spacer />
          <v-btn
            color="error"
            @click="signOut"
          >
            Sign Out
          </v-btn>
        </v-toolbar>
        <v-card-text>
          <!-- Sticky Section -->
          <v-row class="sticky-section">
            <v-col cols="12" md="6">
              <v-card>
                <v-card-title>Stats</v-card-title>
                <v-card-text>
                  <p>{{ visitedCount }} / {{ totalCountries }} Countries Visited</p>
                  <p>{{ visitedPercentage }}% Visited, {{ remainingPercentage }}% Remaining</p>
                </v-card-text>
              </v-card>
            </v-col>
            <v-col cols="12" md="6">
              <v-card>
                <v-card-title>Visited Countries</v-card-title>
                <v-card-text>
                  <PieChart
                    v-if="chartData.datasets[0].data.length > 0 && chartData.datasets[0].data[0] !== 0 && chartData.datasets[0].data[1] !== 0"
                    :data="chartData"
                  />
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>

          <!-- Filter and Table Section -->
          <v-row>
            <v-col cols="12">
              <v-text-field
                v-model="filterText"
                label="Filter countries"
                outlined
                clearable
                class="mb-4"
              />
              <v-data-table
                :headers="headers"
                :items="filteredCountries"
                :items-per-page="-1"
                density="compact"
                hover
                fixed-header
              >
                <template v-slot:item.visited="{ item }">
                  <v-checkbox-btn
                    inline
                    color="indigo"
                    v-model="item.visited"
                    @change="updateVisitedStatus(item)"
                    density="compact"
                    :align="center"
                  />
                </template>
              </v-data-table>
            </v-col>
          </v-row>
    </v-container>
  </v-app>
</template>

<script>
import { createClient } from '@supabase/supabase-js';
import PieChart from './components/PieChart.vue';

// Initialize Supabase client
const supabase = createClient(
  process.env.VUE_APP_SUPABASE_URL,
  process.env.VUE_APP_SUPABASE_ANON_KEY
);

export default {
  name: 'App',
  components: {
    PieChart
  },
  data() {
    return {
      email: '',
      authMessage: '',
      user: null,
      countries: [], // All countries with user-specific visited status
      filterText: '', // New property for filter text
      headers: [
        {
          title: '#',
          key: 'index',
          align: 'start',
          sortable: false,
          width: '50px',
        },
        {
          title: 'Country Name',
          key: 'name',
          align: 'start',
          sortable: false,
          width: '200px',
        },
        {
          title: 'Visited',
          key: 'visited',
          align: 'center',
          sortable: false,
          width: '100px',
        },
      ],
    };
  },
  computed: {
    visitedCount() {
      return this.countries.filter(country => country.visited).length;
    },
    totalCountries() {
      return this.countries.length;
    },
    visitedPercentage() {
      return this.totalCountries > 0
        ? ((this.visitedCount / this.totalCountries) * 100).toFixed(2)
        : 0;
    },
    remainingPercentage() {
      return this.totalCountries > 0
        ? (100 - this.visitedPercentage).toFixed(2)
        : 0;
    },
    filteredCountries() { // New computed property
      const filtered = !this.filterText 
        ? this.countries 
        : this.countries.filter(country =>
            country.name.toLowerCase().startsWith(this.filterText.toLowerCase())
          );
      console.log('Filtered Countries:', JSON.stringify(filtered, null, 2)); // Debugging
      return filtered;
    },
    chartData() {
      const data = {
        labels: ['Visited', 'Remaining'],
        datasets: [
          {
            label: 'Countries',
            data: [this.visitedCount, this.totalCountries - this.visitedCount],
            backgroundColor: ['#1976D2', '#90EE90'], // Updated to light green for "Remaining"
          },
        ],
      };
      console.log('Computed Chart Data:', data); // Debugging: Log the computed data
      return data;
    }
  },
  async mounted() {
    // Debug headers and verify structure
    console.log('Headers:', JSON.stringify(this.headers, null, 2));

    // Check if the user is already signed in
    const { data: { user } } = await supabase.auth.getUser();
    this.user = user;

    // Fetch countries if the user is signed in
    if (this.user) {
      this.fetchCountries();
    }

    // Listen for authentication events (e.g., Magic Link sign-in)
    supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN') {
        this.user = session.user;
        await this.initializeCountriesForNewUser();
        this.fetchCountries();
      } else if (event === 'SIGNED_OUT') {
        this.user = null;
        this.countries = [];
      }
    });
  },
  methods: {
    async signInWithMagicLink() {
      try {
        const { error } = await supabase.auth.signInWithOtp({
          email: this.email,
          options: {
            emailRedirectTo: 'http://localhost:8080' // Replace with your redirect URL
          }
        });

        if (error) throw error;

        this.authMessage = 'Magic link sent! Check your email.';
      } catch (error) {
        this.authMessage = 'Error sending magic link: ' + error.message;
      }
    },
    async signOut() {
      try {
        const { error } = await supabase.auth.signOut();
        if (error) throw error;
        this.user = null;
      } catch (error) {
        console.error('Error signing out:', error);
      }
    },
    async fetchCountries() {
      try {
        // Fetch all countries
        const { data: allCountries, error: countriesError } = await supabase
          .from('countries')
          .select('*')
          .order('name', { ascending: true });

        if (countriesError) throw countriesError;

        // Fetch the user's visited status
        const { data: userCountries, error: userCountriesError } = await supabase
          .from('user_countries')
          .select('country_id, visited')
          .eq('user_id', this.user.id);

        if (userCountriesError) throw userCountriesError;

        // Merge the data
        this.countries = allCountries.map((country, index) => {
          const userCountry = userCountries.find(
            (uc) => uc.country_id === country.id
          );
          return {
            ...country,
            index: index + 1,
            visited: userCountry ? userCountry.visited : false,
          };
        });
      } catch (error) {
        console.error('Error fetching countries:', error);
      }
    },
    async updateVisitedStatus(country) {
      try {
        // Ensure the user is authenticated
        if (!this.user) {
          console.error('User is not authenticated');
          return;
        }

        // Debugging: Log the data being sent
        console.log('Updating visited status:', {
          user_id: this.user.id,
          country_id: country.id,
          visited: country.visited,
        });

        // Update or insert the user's visited status
        const { error } = await supabase
          .from('user_countries')
          .upsert(
            {
              user_id: this.user.id,
              country_id: country.id,
              visited: country.visited,
            },
            { onConflict: ['user_id', 'country_id'] }
          );

        if (error) throw error;

        console.log('Visited status updated successfully:', country.name, country.visited);
      } catch (error) {
        console.error('Error updating visited status:', error);
      }
    }
  }
}
</script>

<style scoped>
.auth-section {
  margin: 20px auto;
  max-width: 400px;
}

.sticky-section {
  position: sticky;
  top: 0;
  z-index: 2;
  background: white;
  padding-bottom: 16px;
  margin-bottom: 16px;
}
</style>
