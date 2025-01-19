<template>
  <v-dialog v-model="dialog" max-width="500">
    <v-card>
      <v-card-title>Edit Profile</v-card-title>
      <v-card-text>
        <v-form @submit.prevent="saveProfile">
          <v-text-field
            v-model="firstName"
            label="First Name"
            required
          />
          <v-text-field
            v-model="lastName"
            label="Last Name"
            required
          />
          <v-autocomplete
            v-model="countryOfOrigin"
            :items="countries"
            :loading="loadingCountries"
            :search-input.sync="searchCountry"
            label="Country of Origin"
            required
            clearable
            @update:search-input="fetchCountries"
            @focus="fetchCountries"
          >
            <template v-slot:no-data>
              <v-list-item>
                <v-list-item-title>
                  Start typing to search countries...
                </v-list-item-title>
              </v-list-item>
            </template>
          </v-autocomplete>
          <v-btn type="submit" color="primary">Save</v-btn>
        </v-form>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script>
import { profiles, supabase } from '../supabase';

export default {
  props: {
    user: Object,
    profile: Object
  },
  data() {
    return {
      dialog: false,
      firstName: this.profile?.first_name || '',
      lastName: this.profile?.last_name || '',
      countryOfOrigin: this.profile?.country_of_origin || '',
      countries: [],
      loadingCountries: false,
      searchCountry: ''
    };
  },
  methods: {
    async fetchCountries(search = '') {
      try {
        this.loadingCountries = true;
        const { data, error } = await supabase
          .from('countries')
          .select('name')
          .ilike('name', `%${search}%`)
          .limit(10);

        if (error) throw error;
        this.countries = data.map(c => c.name);
      } catch (error) {
        console.error('Error fetching countries:', error);
      } finally {
        this.loadingCountries = false;
      }
    },
    async saveProfile() {
      try {
        const { error } = await profiles.upsert({
          id: this.user.id,
          first_name: this.firstName,
          last_name: this.lastName,
          country_of_origin: this.countryOfOrigin
        });

        if (error) throw error;
        
        this.$emit('update:profile', {
          first_name: this.firstName,
          last_name: this.lastName,
          country_of_origin: this.countryOfOrigin
        });
        
        this.dialog = false;
      } catch (error) {
        console.error('Error saving profile:', error);
      }
    }
  }
};
</script>
