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
  isFocused: {
    type: Boolean,
    default: false,
  },
  isSelected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const contactName = computed(() => props.contact.name || 'Unknown');
const thumbnail = computed(() => props.contact.thumbnail || '');
const lastActivityTime = computed(() => {
  const ts = props.contact.last_activity_at;
  if (!ts) return null;
  return dynamicTime(ts);
});

const schoolAttributeKeys = [
  'children_names',
  'child_name',
  'child_age',
  'child_grade',
  'grade_interest',
  'class_interest',
  'school_name',
];

const customAttributes = computed(() => {
  const attrs = props.contact.custom_attributes || {};
  const lines = [];
  for (const key of schoolAttributeKeys) {
    if (attrs[key] !== undefined && attrs[key] !== null && attrs[key] !== '') {
      lines.push({ key, value: attrs[key] });
      if (lines.length >= 2) break;
    }
  }
  return lines;
});

const fallbackInfo = computed(() => {
  if (customAttributes.value.length > 0) return null;
  return props.contact.email || null;
});

const handleCheckboxClick = e => {
  e.stopPropagation();
  emit('select', props.contact.id);
};
</script>

<template>
  <div
    class="kanban-card flex items-center gap-3 p-3 bg-n-solid-2 rounded-lg border cursor-grab select-none hover:border-n-slate-6 transition-colors group"
    :class="[
      isDragging ? 'opacity-50' : '',
      isFocused ? 'ring-2 ring-n-brand border-n-brand' : 'border-n-weak',
      isSelected ? 'border-l-2 border-l-n-brand' : '',
    ]"
  >
    <div class="relative">
      <input
        type="checkbox"
        :checked="isSelected"
        class="absolute top-0 left-0 w-4 h-4 rounded border-n-slate-6 text-n-brand focus:ring-n-brand cursor-pointer opacity-0 group-hover:opacity-100 transition-opacity z-10"
        @click="handleCheckboxClick"
      />
      <Avatar
        :name="contactName"
        :src="thumbnail"
        :size="36"
        hide-offline-status
        rounded-full
      />
    </div>
    <div class="flex flex-col min-w-0 flex-1">
      <span class="text-sm font-medium text-n-slate-12 truncate">
        {{ contactName }}
      </span>
      <template v-if="customAttributes.length > 0">
        <span
          v-for="attr in customAttributes"
          :key="attr.key"
          class="text-xs text-n-slate-10 truncate border-b border-n-weak pb-0.5 last:border-b-0 last:pb-0"
        >
          {{ attr.value }}
        </span>
      </template>
      <template v-else-if="fallbackInfo">
        <span class="text-xs text-n-slate-8 truncate">
          {{ fallbackInfo }}
        </span>
      </template>
      <span v-if="lastActivityTime" class="text-xs text-n-slate-10 truncate">
        {{ lastActivityTime }}
      </span>
      <span v-else class="text-xs text-n-slate-8 italic"> No activity </span>
    </div>
  </div>
</template>

<style scoped>
.kanban-card:active {
  cursor: grabbing;
}
</style>
