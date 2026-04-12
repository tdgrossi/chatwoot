<script setup>
import { ref, computed, onMounted } from 'vue';
import { usePipelineStore } from '../../../../stores/pipeline';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import KanbanBoard from 'dashboard/components/kanban/KanbanBoard.vue';
import StageManagementModal from 'dashboard/components/pipeline/StageManagementModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const pipelineStore = usePipelineStore();
const store = useStore();
const { isAdmin } = useAdmin();

const showManageStages = ref(false);

// Loading state
const isLoading = ref(true);

// All contacts keyed by id (for quick lookup)
const contactsMap = ref({});

// Contacts grouped by stage id (null = unassigned)
const contactsByStage = ref({});

// Computed: ordered stages by position
const orderedStages = computed(() =>
  [...(pipelineStore.stages || [])].sort((a, b) => a.position - b.position)
);

// Computed: unassigned contacts (pipeline_stage_id = null)
const unassignedContacts = computed(() =>
  Object.values(contactsMap.value).filter(c => !c.pipeline_stage_id)
);

// Computed: contacts per stage (from contactsByStage)
const stageContacts = computed(() => {
  const result = {};
  orderedStages.value.forEach(stage => {
    result[stage.id] = contactsByStage.value[stage.id] || [];
  });
  return result;
});

// Computed: unassigned count
const unassignedCount = computed(() => unassignedContacts.value.length);

// Load all stages
const loadStages = async () => {
  try {
    await pipelineStore.fetchStages();
  } catch (error) {
    useAlert('Failed to load pipeline stages.');
  }
};

// Load contacts for a single stage via Vuex action
const loadContactsForStage = async stageId => {
  try {
    await store.dispatch('contacts/fetchByStage', {
      stageId,
      sortAttr: 'name',
    });
  } catch (error) {
    // Non-blocking: stage may have no contacts
  }
};

// Load all contacts (stages + unassigned) and group by stage
const loadAllContacts = async () => {
  // Get contacts from Vuex store (fetched by stages)
  const allContacts = Object.values(store.state.contacts?.records || {});

  // Group contacts by pipeline_stage_id
  const grouped = {};
  allContacts.forEach(contact => {
    const stageId = contact.pipeline_stage_id;
    if (!stageId) {
      // Unassigned - tracked separately
      contactsMap.value[contact.id] = contact;
    } else {
      if (!grouped[stageId]) {
        grouped[stageId] = [];
      }
      grouped[stageId].push(contact);
      contactsMap.value[contact.id] = contact;
    }
  });

  contactsByStage.value = grouped;
};

// Fetch contacts for each stage (parallel)
const fetchContactsForAllStages = async () => {
  const stages = pipelineStore.stages || [];
  await Promise.all(
    stages.map(stage =>
      store.dispatch('contacts/fetchByStage', { stageId: stage.id })
    )
  );
  await loadAllContacts();
};

// Fetch unassigned contacts (stageId = null)
const fetchUnassignedContacts = async () => {
  try {
    await store.dispatch('contacts/fetchByStage', { stageId: null });
    // After fetching, loadAllContacts will pick up unassigned via pipeline_stage_id = null
    const allContacts = Object.values(store.state.contacts?.records || {});
    allContacts.forEach(contact => {
      if (!contact.pipeline_stage_id) {
        contactsMap.value[contact.id] = contact;
      }
    });
  } catch (error) {
    // Non-blocking
  }
};

// Initialize: load stages, then load all contacts grouped by stage
onMounted(async () => {
  isLoading.value = true;
  try {
    await loadStages();
    // Fetch contacts for all stages in parallel
    await fetchContactsForAllStages();
    // Also fetch unassigned
    await fetchUnassignedContacts();
  } catch (error) {
    useAlert('Failed to load contacts. Please refresh.');
  } finally {
    isLoading.value = false;
  }
});

// Handle drag-drop
const handleDrop = async event => {
  const { contactId, fromStageId, toStageId } = event;
  if (!contactId) return;
  if (fromStageId === toStageId) return; // No-op if dropped in same column

  // Perform optimistic move locally
  const contact = contactsMap.value[contactId];
  if (!contact) return;

  // Normalize keys: 'unassigned' -> null, numeric stage ids
  const fromKey = fromStageId === 'unassigned' ? null : String(fromStageId);
  const toKey = toStageId === 'unassigned' ? null : String(toStageId);

  // Optimistically update contactsMap
  contactsMap.value[contactId] = {
    ...contact,
    pipeline_stage_id: toKey === 'null' ? null : toKey,
  };

  // Optimistically update contactsByStage: remove from source
  const fromNumKey =
    fromKey === 'null' ? null : fromKey === null ? null : Number(fromKey);
  const toNumKey =
    toKey === 'null' ? null : toKey === null ? null : Number(toKey);

  if (fromNumKey !== null) {
    contactsByStage.value[fromNumKey] = (
      contactsByStage.value[fromNumKey] || []
    ).filter(c => c.id !== contactId);
  }
  if (!contactsByStage.value[toNumKey]) {
    contactsByStage.value[toNumKey] = [];
  }
  // Remove from target first (in case fromKey === toKey)
  contactsByStage.value[toNumKey] = (contactsByStage.value[toNumKey] || []).filter(
    c => c.id !== contactId
  );
  // Force reactivity
  contactsByStage.value = { ...contactsByStage.value };

  // Call store action for API call with revert on failure
  try {
    await pipelineStore.moveContactToStage({
      contactId,
      fromStageId: fromKey,
      toStageId: toKey,
    });
  } catch (error) {
    // Store action handles revert + toast; reload contacts to ensure consistency
    await fetchContactsForAllStages();
    await fetchUnassignedContacts();
  }
};

// Handle card click (navigate to contact detail)
const handleCardClick = contact => {
  // TODO: Phase 7/8 - navigate to contact detail
  // eslint-disable-next-line no-console
  console.log('Contact clicked:', contact.id, contact.name);
};
</script>

<template>
  <div class="leads-index">
    <!-- Header with Manage Stages button -->
    <div class="flex items-center justify-between px-4 py-3 border-b border-n-weak">
      <h1 class="text-base font-semibold text-n-slate-12">Pipeline</h1>
      <Button
        v-if="isAdmin"
        label="Manage Stages"
        icon="i-lucide-settings"
        variant="outline"
        color="slate"
        size="sm"
        @click="showManageStages = true"
      />
    </div>

    <!-- Loading state -->
    <div v-if="isLoading" class="p-4">
      <div class="kanban-board flex gap-4">
        <!-- Skeleton for unassigned column -->
        <div class="flex-shrink-0 w-70">
          <div class="flex items-center justify-between px-3 py-2.5 mb-2 rounded-t-lg bg-n-alpha-1">
            <div class="h-4 w-24 bg-n-slate-3 rounded animate-pulse" />
            <div class="h-5 w-5 bg-n-slate-3 rounded-full animate-pulse" />
          </div>
          <div class="flex flex-col gap-2 p-1">
            <div v-for="i in 3" :key="i" class="h-14 bg-n-slate-3 rounded-lg animate-pulse" />
          </div>
        </div>
        <!-- Skeleton for stage columns -->
        <div v-for="i in 2" :key="i" class="flex-shrink-0 w-70">
          <div class="flex items-center justify-between px-3 py-2.5 mb-2 rounded-t-lg bg-n-alpha-1">
            <div class="h-4 w-32 bg-n-slate-3 rounded animate-pulse" />
            <div class="h-5 w-5 bg-n-slate-3 rounded-full animate-pulse" />
          </div>
          <div class="flex flex-col gap-2 p-1">
            <div v-for="j in 2" :key="j" class="h-14 bg-n-slate-3 rounded-lg animate-pulse" />
          </div>
        </div>
      </div>
    </div>

    <!-- Kanban board -->
    <KanbanBoard
      v-else
      :stages="orderedStages"
      :contacts-by-stage="stageContacts"
      :unassigned-contacts="unassignedContacts"
      :unassigned-count="unassignedCount"
      :is-loading="isLoading"
      @drop="handleDrop"
      @card-click="handleCardClick"
    />

    <!-- Manage Stages modal (admin only) -->
    <StageManagementModal v-model:show="showManageStages" />
  </div>
</template>

<style scoped>
.leads-index {
  height: calc(100vh - 4rem);
  overflow: hidden;
}
</style>
