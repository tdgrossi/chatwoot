<script setup>
import { ref, onMounted } from 'vue';
import { usePipelineStore } from '../../../../stores/pipeline';

const pipelineStore = usePipelineStore();

const isLoading = ref(true);

onMounted(async () => {
  try {
    await Promise.all([pipelineStore.fetchStages(), pipelineStore.fetchStats()]);
  } finally {
    isLoading.value = false;
  }
});
</script>

<template>
  <div class="leads-index">
    <div v-if="isLoading" class="leads-loading">
      Loading pipeline...
    </div>
    <div v-else>
      <!-- Phase 5+ will render Kanban board here -->
      <p>Pipeline dashboard placeholder</p>
    </div>
  </div>
</template>
