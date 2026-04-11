<script setup>
import { computed } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import { dynamicTime } from 'shared/helpers/timeHelper';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
  isDragging: {
    type: Boolean,
    default: false,
  },
});

const contactName = computed(() => props.contact.name || 'Unknown');
const thumbnail = computed(() => props.contact.thumbnail || '');
const lastActivityTime = computed(() => {
  const ts = props.contact.last_activity_at;
  if (!ts) return null;
  return dynamicTime(ts);
});
</script>

<template>
  <div
    class="kanban-card flex items-center gap-3 p-3 bg-n-solid-2 rounded-lg border border-n-weak cursor-grab select-none hover:border-n-slate-6 transition-colors"
    :class="{ 'opacity-50': isDragging }"
  >
    <Avatar
      :name="contactName"
      :src="thumbnail"
      :size="36"
      hide-offline-status
      rounded-full
    />
    <div class="flex flex-col min-w-0 flex-1">
      <span class="text-sm font-medium text-n-slate-12 truncate">
        {{ contactName }}
      </span>
      <span
        v-if="lastActivityTime"
        class="text-xs text-n-slate-10 truncate"
      >
        {{ lastActivityTime }}
      </span>
      <span
        v-else
        class="text-xs text-n-slate-8 italic"
      >
        No activity
      </span>
    </div>
  </div>
</template>

<style scoped>
.kanban-card:active {
  cursor: grabbing;
}
</style>
