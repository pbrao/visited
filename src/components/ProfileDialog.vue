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
          <v-text-field
            v-model="countryOfOrigin"
            label="Country of Origin"
            required
          />
          <v-btn type="submit" color="primary">Save</v-btn>
        </v-form>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script>
import { profiles } from '../supabase';

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
      countryOfOrigin: this.profile?.country_of_origin || ''
    };
  },
  methods: {
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
