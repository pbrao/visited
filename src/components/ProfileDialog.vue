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
            v-model:search="searchCountry"
            label="Country of Origin"
            required
            clearable
            @update:search="fetchCountries"
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
    profile: Object,
    modelValue: Boolean
  },
  emits: ['update:modelValue', 'update:profile'],
  data() {
    return {
      dialog: this.modelValue,
      firstName: this.profile?.first_name || '',
      lastName: this.profile?.last_name || '',
      countryOfOrigin: this.profile?.country_of_origin || '',
      countries: [],
      loadingCountries: false,
      searchCountry: ''
    };
  },
  watch: {
    modelValue(newVal) {
      this.dialog = newVal;
    },
    dialog(newVal) {
      this.$emit('update:modelValue', newVal);
    },
    profile: {
      immediate: true,
      handler(newProfile) {
        // Update fields when profile prop changes
        this.firstName = newProfile?.first_name || '';
        this.lastName = newProfile?.last_name || '';
        this.countryOfOrigin = newProfile?.country_of_origin || '';
      }
    }
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
        const { data, error } = await profiles.upsert({
          id: this.user.id,
          first_name: this.firstName,
          last_name: this.lastName,
          country_of_origin: this.countryOfOrigin
        }, {
          onConflict: 'id' // Ensure we update the existing profile
        });

        if (error) throw error;
        
        // Emit the updated profile data
        this.$emit('update:profile', {
          id: this.user.id,
          first_name: this.firstName,
          last_name: this.lastName,
          country_of_origin: this.countryOfOrigin
        });
        
        this.dialog = false;
      } catch (error) {
        console.error('Error saving profile:', error);
        alert('Failed to save profile. Please try again.');
      }
    }
  }
};
</script>
