<template>
  <v-card>
    <v-card-title>{{ title }}</v-card-title>
    <v-card-text>
      <canvas ref="pieChart" height="300"></canvas>
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
      console.log('Chart Data:', this.data);
      new Chart(ctx, {
        type: 'pie',
        data: this.data,
        options: {
          responsive: true,
          maintainAspectRatio: false,
        },
      });
    },
  },
};
</script>

<style scoped>
canvas {
  max-height: 300px;
  width: 100% !important;
}
</style>
