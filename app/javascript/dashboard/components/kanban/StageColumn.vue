<script setup>
import { computed } from 'vue';
import Draggable from 'vuedraggable';
import KanbanCard from './KanbanCard.vue';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
  contacts: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
  isUnassigned: {
    type: Boolean,
    default: false,
  },
  columnIndex: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['drop', 'card-click']);

const stageName = computed(() => props.stage?.name || 'Unknown Stage');
const stageColor = computed(() => props.stage?.color || '#6B7280');
const contactCount = computed(() => props.contacts.length);

const columnTitle = computed(() =>
  props.isUnassigned ? 'Unassigned' : stageName.value
);

const emptyMessage = computed(() =>
  props.isUnassigned
    ? 'No unassigned contacts'
    : `No contacts in ${stageName.value}`
);

const columnClasses = computed(() => ({
  'opacity-60 bg-n-slate-2 dark:bg-n-solid-3': props.isUnassigned,
  'bg-n-alpha-1': !props.isUnassigned,
}));

const handleDragEnd = event => {
  emit('drop', {
    contactId: event.item?.dataset?.contactId,
    fromStageId: event.from?.dataset?.stageId || null,
    toStageId: event.to?.dataset?.stageId || null,
    fromIndex: event.oldIndex,
    toIndex: event.newIndex,
  });
};

const onCardClick = contact => {
  emit('card-click', contact);
};
</script>

<template>
  <div
    class="stage-column flex flex-col flex-shrink-0 w-70"
    :data-stage-id="isUnassigned ? 'unassigned' : stage.id"
    :data-column-index="columnIndex"
  >
    <!-- Column Header -->
    <div
      class="flex items-center justify-between px-3 py-2.5 mb-2 rounded-t-lg"
      :class="columnClasses"
    >
      <div class="flex items-center gap-2 min-w-0">
        <!-- Color dot (hidden for unassigned) -->
        <span
          v-if="!isUnassigned"
          class="w-2.5 h-2.5 rounded-full flex-shrink-0"
          :style="{ backgroundColor: stageColor }"
        />
        <span class="text-sm font-semibold text-n-slate-12 truncate">
          {{ columnTitle }}
        </span>
      </div>
      <!-- Contact count badge -->
      <span
        class="inline-flex items-center justify-center min-w-5 h-5 px-1.5 text-xs font-medium rounded-full bg-n-slate-4 text-n-slate-11"
      >
        {{ contactCount }}
      </span>
    </div>

    <!-- Cards container -->
    <div class="flex-1 overflow-y-auto min-h-0">
      <!-- Loading skeleton -->
      <div v-if="isLoading" class="flex flex-col gap-2 p-1">
        <div
          v-for="i in 3"
          :key="i"
          class="h-14 rounded-lg bg-n-slate-3 animate-pulse"
        />
      </div>

      <!-- Draggable cards list -->
      <Draggable
        v-else
        v-model="contacts"
        :group="{ name: 'kanban', pull: true, put: true }"
        item-key="id"
        ghost-class="ghost"
        drag-class="drag"
        :animation="200"
        class="flex flex-col gap-2 p-1 min-h-10"
        :data-stage-id="isUnassigned ? 'unassigned' : stage.id"
        @end="handleDragEnd"
      >
        <template #item="{ element }">
          <div
            :data-contact-id="element.id"
            @click="onCardClick(element)"
          >
            <KanbanCard :contact="element" />
          </div>
        </template>

        <!-- Empty state -->
        <template #footer>
          <div
            v-if="!isLoading && contacts.length === 0"
            class="py-4 text-center text-xs text-n-slate-8 italic"
          >
            {{ emptyMessage }}
          </div>
        </template>
      </Draggable>
    </div>
  </div>
</template>

<style scoped>
.stage-column {
  width: 280px;
}

.ghost {
  opacity: 0.4;
  background-color: rgb(var(--color-n-slate-4) / 0.3);
  border-radius: 0.5rem;
  border: 2px dashed rgb(var(--color-n-slate-6));
}

.drag {
  opacity: 0.8;
  transform: rotate(2deg);
  box-shadow: 0 8px 16px rgb(var(--color-n-solid-3) / 0.3);
}
</style>
