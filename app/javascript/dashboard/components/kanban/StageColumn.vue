<script setup>
import { computed } from 'vue';
import Draggable from 'vuedraggable';
import KanbanCard from './KanbanCard.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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
  focusedCardIndex: {
    type: Number,
    default: -1,
  },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits([
  'drop',
  'cardclick',
  'update:contacts',
  'cardselect',
]);

const stageName = computed(() => props.stage?.name || 'Unknown Stage');
const stageColor = computed(() => props.stage?.color || '#6B7280');
const contactCount = computed(() => props.contacts.length);
const addedTodayCount = computed(() => {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  return props.contacts.filter(c => {
    if (!c.created_at) return false;
    const created = new Date(c.created_at);
    created.setHours(0, 0, 0, 0);
    return created.getTime() === today.getTime();
  }).length;
});

const columnTitle = computed(() =>
  props.isUnassigned ? 'Unassigned' : stageName.value
);

const columnClasses = computed(() => ({
  'opacity-60 bg-n-slate-2 dark:bg-n-solid-3': props.isUnassigned,
  'bg-n-alpha-1': !props.isUnassigned,
}));

const handleDragEnd = event => {
  const contactId = event.item?.dataset?.contactId;
  const fromStageId = event.from?.dataset?.stageId || null;
  const toStageId = event.to?.dataset?.stageId || null;
  emit('drop', {
    contactId,
    fromStageId,
    toStageId,
    fromIndex: event.oldIndex,
    toIndex: event.newIndex,
  });
};

const onCardClick = contact => {
  emit('cardclick', contact);
};

const onCardSelect = contactId => {
  emit('cardselect', contactId);
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
        class="relative inline-flex items-center justify-center min-w-5 h-5 px-1.5 text-xs font-medium rounded-full"
        :style="{ backgroundColor: stageColor + '33', color: stageColor }"
      >
        {{ contactCount }}
        <span
          v-if="addedTodayCount > 0"
          class="absolute -top-1 -right-1 inline-flex items-center justify-center min-w-4 h-4 px-1 text-[10px] font-medium rounded-full bg-n-teal-4 text-n-teal-11"
        >{{ `+${addedTodayCount}` }}
        </span>
      </span>
    </div>

    <!-- Cards container -->
    <div class="flex-1 overflow-y-auto min-h-0">
      <!-- Loading skeleton -->
      <div v-if="isLoading" class="flex flex-col gap-2 p-1">
        <div v-for="i in 3" :key="i" class="h-14 rounded-lg skeleton-shimmer" />
      </div>

      <!-- Draggable cards list -->
      <Draggable
        v-else
        :model-value="contacts"
        :group="{ name: 'kanban', pull: true, put: true }"
        item-key="id"
        ghost-class="ghost"
        drag-class="drag"
        :animation="200"
        class="flex flex-col gap-2 p-1 min-h-10"
        :data-stage-id="isUnassigned ? 'unassigned' : stage.id"
        @update:model-value="$emit('update:contacts', $event)"
        @end="handleDragEnd"
      >
        <template #item="{ element, index }">
          <div :data-contact-id="element.id" @click="onCardClick(element)">
            <KanbanCard
              :contact="element"
              :is-focused="index === focusedCardIndex"
              :is-selected="selectedContactIds.includes(element.id)"
              @select="onCardSelect"
            />
          </div>
        </template>

        <!-- Empty state -->
        <template #footer>
          <div
            v-if="!isLoading && contacts.length === 0"
            class="flex flex-col items-center justify-center py-6 gap-2"
          >
            <div
              class="w-10 h-10 rounded-full bg-n-alpha-2 flex items-center justify-center"
            >
              <Icon
                :icon="isUnassigned ? 'i-lucide-user-x' : 'i-lucide-user-plus'"
                class="text-n-slate-8 size-5"
              />
            </div>
            <span class="text-xs text-n-slate-8"><!-- eslint-disable-line @intlify/vue-i18n/no-raw-text -->
              {{
                isUnassigned
                  ? 'No unassigned contacts'
                  : 'No contacts in this stage'
              }}</span>
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
  opacity: 0.7;
  background-color: rgb(var(--color-n-slate-4) / 0.4);
  border-radius: 0.75rem;
  border: 2px dashed rgb(var(--color-n-slate-6));
  box-shadow: 0 4px 12px rgb(var(--color-n-solid-3) / 0.2);
}

.drag {
  opacity: 0.7;
  transform: rotate(2deg) scale(1.02);
  box-shadow: 0 12px 24px rgb(var(--color-n-solid-3) / 0.35);
  border-radius: 0.75rem;
}

@keyframes shimmer {
  0% {
    background-position: -200% 0;
  }
  100% {
    background-position: 200% 0;
  }
}

.skeleton-shimmer {
  background: linear-gradient(
    90deg,
    rgb(var(--color-n-slate-3)) 25%,
    rgb(var(--color-n-slate-4)) 50%,
    rgb(var(--color-n-slate-3)) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

@keyframes settle {
  0% {
    transform: scale(1.02);
  }
  50% {
    transform: scale(0.98);
  }
  100% {
    transform: scale(1);
  }
}

.settle {
  animation: settle 0.2s ease-out;
}
</style>
