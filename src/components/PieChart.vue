<template>
  <v-card>
    <v-card-title>{{ title }}</v-card-title>
    <v-card-text>
      <canvas ref="pieChart" width="200" height="200"></canvas> <!-- Reduced size -->
    </v-card-text>
  </v-card>
</template>

<script>
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

export default {
  name: 'PieChart',
  props: {
    title: {
      type: String,
      default: 'Pie Chart',
    },
    data: {
      type: Object,
      required: true,
    },
  },
  mounted() {
    console.log('PieChart mounted with data:', this.data); // Debugging: Log the data
    this.renderChart();
  },
  methods: {
    renderChart() {
      if (!this.data || !this.data.datasets || this.data.datasets.length === 0) {
        console.error('Invalid chart data:', this.data);
        return;
      }

      const ctx = this.$refs.pieChart.getContext('2d');
      console.log('Chart Data:', this.data); // Debugging: Log the chart data
      new Chart(ctx, {
        type: 'pie',
        data: this.data,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: true, // Ensure the legend is displayed
            },
          },
        },
      });
    },
  },
};
</script>

<style scoped>
canvas {
  width: 200px !important; /* Fixed width */
  height: 200px !important; /* Fixed height */
  min-height: 200px; /* Ensure the canvas has a minimum height */
}
</style>
