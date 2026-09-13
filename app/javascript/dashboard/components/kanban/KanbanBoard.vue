<script setup>
import { computed, ref } from 'vue';
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
  isLoading: {
    type: Boolean,
    default: false,
  },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['drop', 'cardclick', 'cardselect']);

const focusedColumnIndex = ref(0);
const focusedCardIndex = ref(-1);

const orderedStages = computed(() =>
  [...props.stages].sort((a, b) => a.position - b.position)
);

const allColumns = computed(() => {
  const cols = [{ id: 'unassigned', contacts: props.unassignedContacts }];
  orderedStages.value.forEach(s => {
    cols.push({ id: s.id, contacts: props.contactsByStage[s.id] || [] });
  });
  return cols;
});

const handleDrop = (stageId, event) => {
  emit('drop', event);
};

const handleCardClick = contact => {
  emit('cardclick', contact);
};

const handleCardSelect = contactId => {
  emit('cardselect', contactId);
};

const handleBoardKeydown = event => {
  const totalColumns = allColumns.value.length;
  if (totalColumns === 0) return;

  const currentColumn = allColumns.value[focusedColumnIndex.value];
  const contacts = currentColumn?.contacts || [];
  const maxCardIndex = contacts.length - 1;

  switch (event.key) {
    case 'ArrowRight':
      event.preventDefault();
      focusedColumnIndex.value = Math.min(
        focusedColumnIndex.value + 1,
        totalColumns - 1
      );
      focusedCardIndex.value = -1;
      break;
    case 'ArrowLeft':
      event.preventDefault();
      focusedColumnIndex.value = Math.max(focusedColumnIndex.value - 1, 0);
      focusedCardIndex.value = -1;
      break;
    case 'ArrowDown':
      event.preventDefault();
      if (maxCardIndex >= 0) {
        focusedCardIndex.value = Math.min(
          focusedCardIndex.value + 1,
          maxCardIndex
        );
      }
      break;
    case 'ArrowUp':
      event.preventDefault();
      focusedCardIndex.value = Math.max(focusedCardIndex.value - 1, -1);
      break;
    case 'Enter':
      if (focusedCardIndex.value >= 0 && contacts[focusedCardIndex.value]) {
        handleCardClick(contacts[focusedCardIndex.value]);
      }
      break;
    default:
      break;
  }
};
// The Kanban board receives stage changes via the `drop` event -> handleDrop in LeadsIndex.
// The update:contacts event fires synchronously during drag (before API call completes) and
// would race with the optimistic update, causing contact duplicates in the UI.
// syncContactsAfterStageChange in LeadsIndex correctly handles the async stage-change flow.
</script>

<template>
  <div
    class="kanban-board-wrapper w-full overflow-x-auto overflow-y-hidden"
    tabindex="0"
    @keydown="handleBoardKeydown"
  >
    <div class="kanban-board flex gap-4 p-4 min-h-full">
      <!-- Unassigned column (leftmost, per D-05) -->
      <StageColumn
        :stage="{ id: 'unassigned', name: 'Unassigned', color: '#9CA3AF' }"
        :contacts="unassignedContacts"
        :is-loading="isLoading"
        :is-unassigned="true"
        :column-index="0"
        :focused-card-index="focusedColumnIndex === 0 ? focusedCardIndex : -1"
        :selected-contact-ids="selectedContactIds"
        @drop="handleDrop('unassigned', $event)"
        @cardclick="handleCardClick"
        @cardselect="handleCardSelect"
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
        :focused-card-index="
          focusedColumnIndex === index + 1 ? focusedCardIndex : -1
        "
        :selected-contact-ids="selectedContactIds"
        @drop="handleDrop(stage.id, $event)"
        @cardclick="handleCardClick"
        @cardselect="handleCardSelect"
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
