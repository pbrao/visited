<template>
  <v-card>
    <v-card-title>{{ title }}</v-card-title>
    <v-card-text>
      <canvas ref="pieChart" width="400" height="400"></canvas> <!-- Explicit width and height -->
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
    this.renderChart();
  },
  methods: {
    renderChart() {
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
  width: 100% !important;
  height: 100% !important;
}
</style>
