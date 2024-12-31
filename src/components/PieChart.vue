<template>
  <div class="chart-container">
    <canvas ref="pieChart" width="200" height="200"></canvas>
  </div>
</template>

<script>
import { Chart, registerables } from 'chart.js';
Chart.register(...registerables);

export default {
  name: 'PieChart',
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      chartInstance: null, // Store the chart instance
    };
  },
  watch: {
    data: {
      handler(newData) {
        console.log('Chart data updated:', newData); // Debugging: Log the updated data
        this.renderChart();
      },
      deep: true, // Watch for changes in nested properties
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

      // Destroy the existing chart instance if it exists
      if (this.chartInstance) {
        this.chartInstance.destroy();
      }

      const ctx = this.$refs.pieChart.getContext('2d');
      console.log('Chart Data:', this.data); // Debugging: Log the chart data
      this.chartInstance = new Chart(ctx, {
        type: 'pie',
        data: this.data,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          plugins: {
            legend: {
              display: true,
              position: 'right',
            },
            tooltip: {
              callbacks: {
                label: (context) => {
                  const label = context.label || '';
                  const value = context.raw || 0;
                  const total = context.dataset.data.reduce((a, b) => a + b, 0);
                  const percentage = ((value / total) * 100).toFixed(2) + '%';
                  return `${label}: ${value} (${percentage})`;
                },
              },
            },
          },
        },
      });
    },
  },
  },
  beforeUnmount() {
    // Destroy the chart instance when the component is unmounted
    if (this.chartInstance) {
      this.chartInstance.destroy();
    }
  },
};
</script>

<style scoped>
.chart-container {
  width: 300px; /* Increase width to accommodate the legend */
  height: 200px; /* Fixed height for the container */
  margin: 0 auto; /* Center the chart */
}

canvas {
  width: 100% !important; /* Ensure canvas fills the container */
  height: 100% !important; /* Ensure canvas fills the container */
}
</style>
