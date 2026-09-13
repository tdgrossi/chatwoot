<script setup>
import { computed, onMounted } from 'vue';
import { usePipelineStore } from '../../stores/pipeline';

const emit = defineEmits(['filterchange']);

const pipelineStore = usePipelineStore();

const isLoading = computed(() => pipelineStore.uiFlags.fetchingList);
const stats = computed(() => pipelineStore.getStats);
const totalCount = computed(() =>
  (stats.value || []).reduce((sum, s) => sum + (s.count || 0), 0)
);
const totalAddedToday = computed(() =>
  (stats.value || []).reduce((sum, s) => sum + (s.addedToday || 0), 0)
);

onMounted(async () => {
  if (!(stats.value || []).length) {
    await pipelineStore.fetchStats();
  }
});

const handleCardClick = stageId => {
  emit('filter-change', stageId);
};
</script>

<template>
  <div class="relative">
    <div
      class="absolute left-0 top-0 bottom-0 w-4 bg-gradient-to-r from-n-solid-2 to-transparent pointer-events-none z-10"
    />
    <div
      class="absolute right-0 top-0 bottom-0 w-4 bg-gradient-to-l from-n-solid-2 to-transparent pointer-events-none z-10"
    />
    <div
      class="flex gap-4 px-4 py-3 border-b border-n-weak overflow-x-auto scrollbar-hide"
    >
      <!-- Skeleton state -->
      <template v-if="isLoading">
        <div
          v-for="i in (stats || []).length || 4"
          :key="i"
          class="flex-shrink-0 w-32 h-16 bg-n-slate-3 rounded-lg animate-pulse"
        />
      </template>

      <!-- Loaded state -->
      <template v-else-if="(stats || []).length">
        <!-- Per-stage cards -->
        <div
          v-for="stat in stats || []"
          :key="stat.stageId"
          class="group relative flex-shrink-0 w-32 border border-n-weak rounded-lg p-4 cursor-pointer hover:shadow-lg hover:-translate-y-0.5 transition-all bg-n-surface-2"
          @click="handleCardClick(stat.stageId)"
        >
          <div class="flex items-center gap-1.5 mb-2">
            <span
              class="w-2 h-2 rounded-full"
              :style="{ backgroundColor: stat.color }"
            />
            <span class="text-xs font-medium text-n-slate-11 truncate">{{
              stat.name
            }}</span>
          </div>
          <div class="text-2xl font-semibold" :style="{ color: stat.color }">
            {{ stat.count }}
          </div>
          <div
            class="absolute right-2 top-2 opacity-0 group-hover:opacity-100 transition-opacity"
          >
            <span class="i-lucide-filter size-3 text-n-slate-9" />
          </div>
        </div>

        <!-- Total card -->
        <div
          class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4 bg-n-surface-2"
        >
          <div class="text-xs font-medium text-n-slate-11 mb-2">
            <!-- eslint-disable-line @intlify/vue-i18n/no-raw-text -->Total
          </div>
          <div class="text-2xl font-semibold text-n-slate-12">
            {{ totalCount }}
          </div>
        </div>

        <!-- Added Today card -->
        <div
          class="flex-shrink-0 w-32 border border-n-weak rounded-lg p-4 bg-n-surface-2"
        >
          <div class="text-xs font-medium text-n-slate-11 mb-2">
            <!-- eslint-disable-line @intlify/vue-i18n/no-raw-text -->Added
            Today
          </div>
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
          <span><!-- eslint-disable-line @intlify/vue-i18n/no-raw-text -->No data
            yet</span>
        </div>
      </template>
    </div>
  </div>
</template>

<style scoped>
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
