<script setup>
import { computed, onMounted } from 'vue';
import { usePipelineStore } from '../../../stores/pipeline';

const pipelineStore = usePipelineStore();

const isLoading = computed(() => pipelineStore.uiFlags.fetchingList);
const stats = computed(() => pipelineStore.getStats);
const totalCount = computed(() =>
  stats.value.reduce((sum, s) => sum + (s.count || 0), 0)
);
const totalAddedToday = computed(() =>
  stats.value.reduce((sum, s) => sum + (s.addedToday || 0), 0)
);

const emit = defineEmits(['filter-change']);

onMounted(async () => {
  if (!stats.value.length) {
    await pipelineStore.fetchStats();
  }
});

const handleCardClick = stageId => {
  emit('filter-change', stageId);
};
</script>

<template>
  <div class="flex gap-4 px-4 py-3 border-b border-n-weak overflow-x-auto">
    <!-- Skeleton state -->
    <template v-if="isLoading">
      <div
        v-for="i in (stats.length || 4)"
        :key="i"
        class="flex-shrink-0 w-32 h-16 bg-n-slate-3 rounded-lg animate-pulse"
      />
    </template>

    <!-- Loaded state -->
    <template v-else-if="stats.length">
      <!-- Per-stage cards -->
      <div
        v-for="stat in stats"
        :key="stat.stageId"
        class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4 cursor-pointer hover:shadow-md transition-shadow bg-n-surface-2"
        @click="handleCardClick(stat.stageId)"
      >
        <div class="flex items-center gap-1.5 mb-2">
          <span
            class="w-2 h-2 rounded-full"
            :style="{ backgroundColor: stat.color }"
          />
          <span
            class="text-xs font-medium text-n-slate-11 truncate"
          >{{ stat.name }}</span>
        </div>
        <div class="text-2xl font-semibold text-n-slate-12">
          {{ stat.count }}
        </div>
      </div>

      <!-- Total card -->
      <div
        class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4 bg-n-surface-2"
      >
        <div class="text-xs font-medium text-n-slate-11 mb-2">Total</div>
        <div class="text-2xl font-semibold text-n-slate-12">
          {{ totalCount }}
        </div>
      </div>

      <!-- Added Today card -->
      <div
        class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4 bg-n-surface-2"
      >
        <div class="text-xs font-medium text-n-slate-11 mb-2">Added Today</div>
        <div class="text-2xl font-semibold text-n-slate-12">
          {{ totalAddedToday }}
        </div>
      </div>
    </template>

    <!-- Empty state -->
    <template v-else>
      <div
        class="flex items-center justify-center w-full py-8 text-sm text-n-slate-11 gap-2"
      >
        <span class="i-lucide-bar-chart-3 size-4" />
        <span>No data yet</span>
      </div>
    </template>
  </div>
</template>
