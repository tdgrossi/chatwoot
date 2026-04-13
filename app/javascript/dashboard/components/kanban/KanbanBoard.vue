<script setup>
import { computed } from 'vue';
import StageColumn from './StageColumn.vue';

const props = defineProps({
  stages: {
    type: Array,
    default: () => [],
  },
  contactsByStage: {
    type: Object,
    default: () => ({}),
  },
  unassignedContacts: {
    type: Array,
    default: () => [],
  },
  unassignedCount: {
    type: Number,
    default: 0,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['drop', 'card-click']);

// Stages ordered by position ascending (per D-12)
const orderedStages = computed(() =>
  [...props.stages].sort((a, b) => a.position - b.position)
);

const handleDrop = (stageId, event) => {
  console.log('[kanban] KanbanBoard received drop event', { stageId, event });
  emit('drop', event);
};

const handleCardClick = contact => {
  emit('card-click', contact);
};

const handleContactsUpdate = (stageId, updatedContacts) => {
  emit('update:contacts', { stageId, contacts: updatedContacts });
};
</script>

<template>
  <div class="kanban-board-wrapper w-full overflow-x-auto overflow-y-hidden">
    <div class="kanban-board flex gap-4 p-4 min-h-full">
      <!-- Unassigned column (leftmost, per D-05) -->
      <StageColumn
        :stage="{ id: 'unassigned', name: 'Unassigned', color: '#9CA3AF' }"
        :contacts="unassignedContacts"
        :is-loading="isLoading"
        :is-unassigned="true"
        :column-index="0"
        @drop="handleDrop('unassigned', $event)"
        @card-click="handleCardClick"
        @update:contacts="handleContactsUpdate('unassigned', $event)"
      />

      <!-- Stage columns (ordered by position, per D-12) -->
      <StageColumn
        v-for="(stage, index) in orderedStages"
        :key="stage.id"
        :stage="stage"
        :contacts="contactsByStage[stage.id] || []"
        :is-loading="isLoading"
        :is-unassigned="false"
        :column-index="index + 1"
        @drop="handleDrop(stage.id, $event)"
        @card-click="handleCardClick"
        @update:contacts="handleContactsUpdate(stage.id, $event)"
      />
    </div>
  </div>
</template>

<style scoped>
.kanban-board-wrapper {
  min-height: calc(100vh - 12rem);
}

.kanban-board {
  display: flex;
  gap: 1rem;
  padding: 1rem;
  align-items: flex-start;
}
</style>
