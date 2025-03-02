<template>
  <v-app>
    <!-- Authentication Section -->
    <v-app-bar v-if="user" color="primary" dark>
      <v-toolbar-title>
        {{ profile?.first_name ? `Welcome, ${profile.first_name}` : 'Visited' }}
      </v-toolbar-title>
      <v-spacer />

      <!-- Move menu to the right side -->
      <v-menu
        v-model="menu"
        :close-on-content-click="true"
        location="bottom end"
      >
        <template v-slot:activator="{ props }">
          <v-btn
            icon
            v-bind="props"
          >
            <v-icon>mdi-menu</v-icon>
          </v-btn>
        </template>

        <v-card min-width="200">
          <v-list>
            <v-list-item
              v-if="profile"
              :title="profile.first_name"
              :subtitle="profile.country_of_origin"
            >
              <template v-slot:prepend>
                <v-avatar color="primary">
                  <span class="text-h6">{{ profile.first_name?.charAt(0) }}</span>
                </v-avatar>
              </template>
            </v-list-item>
          </v-list>

          <v-divider />

          <v-list>
            <v-list-item @click="profileDialog = true">
              <v-list-item-title>Edit Profile</v-list-item-title>
            </v-list-item>
            <v-list-item @click="signOut">
              <v-list-item-title>Sign Out</v-list-item-title>
            </v-list-item>
          </v-list>
        </v-card>
      </v-menu>
    </v-app-bar>

    <ProfileDialog
      v-model:profile="profile"
      :user="user"
      v-model="profileDialog"
    />

    <v-container v-if="!user" class="auth-section">
      <v-card class="mx-auto" max-width="400">
        <v-card-title class="text-center">Sign In with Magic Link</v-card-title>
        <v-card-text>
          <v-text-field v-model="email" label="Enter your email" type="email" outlined />
          <v-btn color="primary" block @click="signInWithMagicLink">Send Magic Link</v-btn>
          <v-alert v-if="authMessage" type="info" class="mt-3">{{ authMessage }}</v-alert>
        </v-card-text>
      </v-card>
    </v-container>

    <!-- Main App Content -->
    <v-container v-else class="main-container">
      <div class="content-wrapper">
        <v-card>
          <v-toolbar color="primary" dark>
            <v-toolbar-title>Visited</v-toolbar-title>
            <v-spacer />
          </v-toolbar>

          <!-- Sticky Section -->
          <div class="sticky-wrapper">
            <v-row class="sticky-section" style="align-items: stretch;">
              <v-col cols="12" md="6" class="d-flex flex-column">
                <v-card>
                  <v-card-title>Stats</v-card-title>
                  <v-card-text>
                    <p>{{ visitedCount }} / {{ totalCountries }} Countries Visited</p>
                    <p>{{ visitedPercentage }}% Visited, {{ remainingPercentage }}% Remaining</p>
                  </v-card-text>
                </v-card>

                <v-card class="mt-4 flex-grow-1">
                  <v-card-title>Filter By</v-card-title>
                  <v-card-text class="d-flex flex-column" style="height: 100%; padding-top: 16px;">
                    <v-btn-toggle
                      v-model="filterStatus"
                      color="primary"
                      mandatory
                    >
                      <v-btn value="all">
                        All
                      </v-btn>

                      <v-btn value="visited">
                        Visited
                      </v-btn>

                      <v-btn value="remaining">
                        Remaining
                      </v-btn>
                    </v-btn-toggle>
                  </v-card-text>
                </v-card>
              </v-col>
              <v-col cols="12" md="6">
                <v-card style="height: 100%;">
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
            <v-row>
              <v-col cols="12">
                <v-data-table
                  :headers="headers"
                  :items="filteredCountries"
                  :items-per-page="-1"
                  density="compact"
                  hover
                  fixed-header
                  class="fixed-header-table"
                  height="400"
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
      </div>
    </v-container>
  </v-app>
</template>

<script>
import '@/assets/styles/main.scss'
import { supabase, profiles } from './supabase';
import PieChart from './components/PieChart.vue';
import ProfileDialog from './components/ProfileDialog.vue';

export default {
  name: 'App',
  components: {
    PieChart,
    ProfileDialog
  },
  data() {
    return {
      email: '',
      authMessage: '',
      user: null,
      profile: null,
      menu: false,
      profileDialog: false,
      countries: [], // All countries with user-specific visited status
      filterText: '', // New property for filter text
      filterStatus: 'all', // 'all', 'visited', or 'remaining'
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
    filteredCountries() {
      // First filter by search text
      let filtered = !this.filterText 
        ? this.countries 
        : this.countries.filter(country =>
            country.name.toLowerCase().startsWith(this.filterText.toLowerCase())
          );

      // Then filter by status
      switch (this.filterStatus) {
        case 'visited':
          filtered = filtered.filter(country => country.visited);
          break;
        case 'remaining':
          filtered = filtered.filter(country => !country.visited);
          break;
        // 'all' case is handled by default
      }

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
        await this.fetchProfile();
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
    async fetchProfile() {
      try {
        const { data, error } = await profiles
          .select('*')
          .eq('id', this.user.id)
          .single();
          
        if (error) throw error;
        this.profile = data;
      } catch (error) {
        console.error('Error fetching profile:', error);
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

