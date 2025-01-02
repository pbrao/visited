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
    <v-container v-else class="main-container">
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
        
        <!-- Sticky Section -->
        <div class="sticky-wrapper">
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
          
          <!-- Sticky Filter -->
          <div class="sticky-filter">
            <v-text-field
              v-model="filterText"
              label="Filter countries"
              outlined
              clearable
              class="mb-4"
            />
          </div>
        </div>

        <!-- Scrollable Content -->
        <v-card-text class="scrollable-content">
          <!-- Table Section -->
          <v-row>
            <v-col cols="12">
              <v-data-table
                :headers="headers"
                :items="filteredCountries"
                :items-per-page="-1"
                density="compact"
                hover
                fixed-header
                height="calc(100vh - 64px - 200px - 80px - 32px)"
                class="fixed-header-table"
                hide-default-footer
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
        </v-card-text>
      </v-card>
    </v-container>
  </v-app>
</template>

<script>
import '@/assets/styles/main.scss'
import { supabase } from './supabase';
import PieChart from './components/PieChart.vue';

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
    try {
      // Debug headers and verify structure
      console.log('Headers:', JSON.stringify(this.headers, null, 2));

      // Check if the user is already signed in
      const { data: { user }, error: userError } = await supabase.auth.getUser();
      if (userError) throw userError;

      if (user) {
        this.user = user;
        console.log('User authenticated:', user.id);
        await this.fetchCountries();
      } else {
        console.log('No authenticated user');
      }

      // Listen for authentication events (e.g., Magic Link sign-in)
      supabase.auth.onAuthStateChange(async (event, session) => {
        console.log('Auth state changed:', event);
        if (event === 'SIGNED_IN') {
          this.user = session.user;
          try {
            await this.initializeCountriesForNewUser();
            await this.fetchCountries();
          } catch (error) {
            console.error('Error during sign-in initialization:', error);
          }
        } else if (event === 'SIGNED_OUT') {
          this.user = null;
          this.countries = [];
        }
      });
    } catch (error) {
      console.error('Error in mounted hook:', error);
    }
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
        console.log('Fetching countries for user:', this.user.id); // Debug log

        // Fetch all countries
        const { data: allCountries, error: countriesError } = await supabase
          .from('countries')
          .select('*')
          .order('name', { ascending: true });

        if (countriesError) {
          console.error('Error fetching countries:', countriesError);
          throw countriesError;
        }

        console.log('Fetched all countries:', allCountries); // Debug log

        // Fetch the user's visited status
        const { data: userCountries, error: userCountriesError } = await supabase
          .from('user_countries')
          .select('country_id, visited')
          .eq('user_id', this.user.id);

        if (userCountriesError) {
          console.error('Error fetching user countries:', userCountriesError);
          throw userCountriesError;
        }

        console.log('Fetched user countries:', userCountries); // Debug log

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

        console.log('Merged countries data:', this.countries); // Debug log
      } catch (error) {
        console.error('Error in fetchCountries:', error);
        throw error;
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
    },

    async initializeCountriesForNewUser() {
      try {
        // Check if user already has any country data
        const { data: existingData, error: checkError } = await supabase
          .from('user_countries')
          .select('country_id')
          .eq('user_id', this.user.id)
          .limit(1);

        if (checkError) throw checkError;

        // If no existing data, initialize with all countries as unvisited
        if (!existingData || existingData.length === 0) {
          console.log('Initializing countries for new user');
          
          // Get all countries
          const { data: countries, error: countriesError } = await supabase
            .from('countries')
            .select('id');

          if (countriesError) throw countriesError;

          // Prepare the data for insertion
          const userCountries = countries.map(country => ({
            user_id: this.user.id,
            country_id: country.id,
            visited: false
          }));

          // Insert the records
          const { error: insertError } = await supabase
            .from('user_countries')
            .insert(userCountries);

          if (insertError) throw insertError;
          
          console.log('Successfully initialized countries for new user');
        }
      } catch (error) {
        console.error('Error initializing countries:', error);
      }
    }
  }
}
</script>

