<template>
  <div>
    <!-- Authentication Section -->
    <div v-if="!user" class="auth-section">
      <h2>Sign In with Magic Link</h2>
      <input v-model="email" type="email" placeholder="Enter your email" />
      <button @click="signInWithMagicLink">Send Magic Link</button>
      <p v-if="authMessage" class="auth-message">{{ authMessage }}</p>
    </div>

    <!-- Main App Content -->
    <div v-else>
      <div class="header">
        <h1>Visited</h1>
        <div class="stats">
          <p>{{ visitedCount }} / {{ totalCountries }} countries visited</p>
          <p>{{ visitedPercentage }}% visited, {{ remainingPercentage }}% remaining</p>
        </div>
        <button @click="signOut" class="sign-out-button">Sign Out</button>
      </div>
      <div class="table-container">
        <table class="countries-table">
          <thead>
            <tr>
              <th>#</th>
              <th>Country</th>
              <th>Visited</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(country, index) in countries" :key="country.name">
              <td>{{ index + 1 }}</td>
              <td>{{ country.name }}</td>
              <td>
                <input
                  type="checkbox"
                  v-model="country.visited"
                  @change="updateVisitedStatus(country)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client
const supabase = createClient(
  process.env.VUE_APP_SUPABASE_URL,
  process.env.VUE_APP_SUPABASE_ANON_KEY
);

export default {
  name: 'App',
  data() {
    return {
      email: '',
      authMessage: '',
      user: null,
      countries: [] // All countries with user-specific visited status
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
    }
  },
  async mounted() {
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
        this.countries = allCountries.map((country) => {
          const userCountry = userCountries.find(
            (uc) => uc.country_id === country.id
          );
          return {
            ...country,
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

<style>
body {
  margin: 0;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}
.auth-section {
  margin: 20px auto;
  max-width: 300px;
}
.auth-section input {
  width: 100%;
  padding: 10px;
  margin: 10px 0;
  border: 1px solid #ccc;
  border-radius: 5px;
}
.auth-section button {
  width: 100%;
  padding: 10px;
  background-color: #6a11cb;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}
.auth-section button:hover {
  background-color: #2575fc;
}
.auth-message {
  margin-top: 10px;
  color: #6a11cb;
}
#app {
  text-align: center;
  color: #2c3e50;
  padding: 20px;
}
.header {
  background: linear-gradient(135deg, #6a11cb, #2575fc);
  color: white;
  padding: 20px;
  border-radius: 10px;
  margin-bottom: 20px;
}
.sign-out-button {
  margin-top: 10px;
  padding: 10px 20px;
  background-color: #ff4757;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}
.sign-out-button:hover {
  background-color: #ff6b81;
}
.header h1 {
  margin: 0;
  font-size: 2.5rem;
}
.stats {
  margin-top: 10px;
  font-size: 1.1rem;
  opacity: 0.9;
}
.countries-table {
  width: 100%;
  border-collapse: collapse;
  border: 1px solid #e0e0e0;
  border-radius: 10px;
  overflow: hidden;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}
.countries-table th,
.countries-table td {
  padding: 12px 15px;
  text-align: left;
  border-bottom: 1px solid #e0e0e0;
}
.countries-table th {
  background-color: #f8f9fa;
  font-weight: 600;
  position: sticky;
  top: 0; /* Stick to the top of the table container */
  z-index: 50;
  box-shadow: 0 2px 2px -1px rgba(0, 0, 0, 0.1);
}

.countries-table tr:hover {
  background-color: #f1f3f5;
  cursor: pointer;
}

.table-container {
  max-height: 500px; /* Set a fixed height for the container */
  overflow-y: auto; /* Enable vertical scrolling */
  border: 1px solid #e0e0e0;
  border-radius: 10px;
}
</style>
