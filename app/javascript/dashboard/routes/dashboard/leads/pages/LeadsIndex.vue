<script setup>
import { ref, computed, onMounted } from 'vue';
import { usePipelineStore } from '../../../../stores/pipeline';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { OnClickOutside } from '@vueuse/components';
import KanbanBoard from 'dashboard/components/kanban/KanbanBoard.vue';
import StageManagementModal from 'dashboard/components/pipeline/StageManagementModal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import PipelineStatsPanel from 'dashboard/components/pipeline/PipelineStatsPanel.vue';
import ContactSidebar from 'dashboard/components/pipeline/ContactSidebar.vue';

const pipelineStore = usePipelineStore();
const store = useStore();
const { isAdmin } = useAdmin();

const showManageStages = ref(false);
const isStageFilterOpen = ref(false);

// Loading state
const isLoading = ref(true);

// All contacts keyed by id (for quick lookup)
const contactsMap = ref({});

// Contacts grouped by stage id (null = unassigned)
const contactsByStage = ref({});

// Sidebar state
const selectedContact = ref(null);
const isSidebarOpen = ref(false);

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

// Sync LeadsIndex local state after sidebar stage change (critical fix for Pitfall #2)
// pipelineStore.moveContactToStage() updates store state but LeadsIndex has its own
// contactsMap and contactsByStage refs. After the store action, we must sync the local
// refs back so the Kanban/list re-renders correctly.
const syncContactsAfterStageChange = (contactId, fromStageId, toStageId) => {
  console.log('[leads] syncContactsAfterStageChange called', { contactId, fromStageId, toStageId });
  console.log('[leads] pipelineStore.contacts:', pipelineStore.contacts);
  const updatedContact = pipelineStore.contacts[contactId];
  console.log('[leads] updatedContact from pipelineStore.contacts:', updatedContact ? updatedContact.id : 'UNDEFINED - this is the bug!');
  if (!updatedContact) return;

  // Update contactsMap with the updated contact from the store
  contactsMap.value[contactId] = updatedContact;

  // Sync contactsByStage: remove from source, add to destination
  const fromKey = fromStageId === null ? null : Number(fromStageId);
  const toKey = toStageId === null ? null : Number(toStageId);

  // Remove from source stage
  if (fromKey !== null && contactsByStage.value[fromKey]) {
    contactsByStage.value[fromKey] = contactsByStage.value[fromKey].filter(
      c => c.id !== contactId
    );
  }

  // Add to destination stage
  if (toKey !== null) {
    if (!contactsByStage.value[toKey]) {
      contactsByStage.value[toKey] = [];
    }
    // Remove first to avoid duplicates
    contactsByStage.value[toKey] = contactsByStage.value[toKey].filter(
      c => c.id !== contactId
    );
    contactsByStage.value[toKey].push(updatedContact);
  }

  // Force Vue reactivity on contactsByStage
  contactsByStage.value = { ...contactsByStage.value };
};

// Called when user selects a new stage from the sidebar dropdown.
// Performs optimistic local update then calls pipelineStore.moveContactToStage().
// On success: syncs local state back from store (via syncContactsAfterStageChange).
// On failure: store action reverts + shows toast; we reload to ensure consistency.
const handleSidebarStageChange = async ({ toStageId }) => {
  const contact = selectedContact.value;
  if (!contact) return;

  const fromStageId = contact.pipeline_stage_id;

  // Normalize: null/undefined -> null, stage ids -> Number
  const normalizedFrom = fromStageId == null ? null : Number(fromStageId);
  const normalizedTo = toStageId == null ? null : Number(toStageId);

  // Skip if no actual change
  if (normalizedFrom === normalizedTo) return;

  // Optimistic local update (matches store behavior)
  contactsMap.value[contact.id] = {
    ...contact,
    pipeline_stage_id: normalizedTo,
  };

  try {
    await pipelineStore.moveContactToStage({
      contactId: contact.id,
      fromStageId: String(normalizedFrom ?? 'unassigned'),
      toStageId: String(normalizedTo ?? 'unassigned'),
    });
    // Sync store state back to LeadsIndex local refs
    syncContactsAfterStageChange(contact.id, normalizedFrom, normalizedTo);
  } catch (error) {
    console.log('[leads] handleSidebarStageChange catch block firing, error:', error?.message || error, '| contactId:', contact.id);
    console.log('[leads] RELOADING contacts (this causes revert!)');
    // Store action handles revert + toast. Reload to ensure consistency.
    await fetchContactsForAllStages();
    await fetchUnassignedContacts();
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
  console.log('[leads] handleDrop calling moveContactToStage', { contactId, fromKey, toKey });
  try {
    await pipelineStore.moveContactToStage({
      contactId,
      fromStageId: fromKey,
      toStageId: toKey,
    });
    // Sync store state back to LeadsIndex local refs (Pitfall #2 fix)
    syncContactsAfterStageChange(contactId, fromNumKey, toNumKey);
  } catch (error) {
    console.log('[leads] handleDrop catch block firing, error:', error?.message || error, '| contactId:', contactId);
    console.log('[leads] RELOADING contacts (this causes revert!)');
    // Store action handles revert + toast; reload contacts to ensure consistency
    await fetchContactsForAllStages();
    await fetchUnassignedContacts();
  }
};

// Open contact sidebar on card click
const handleCardClick = contact => {
  selectedContact.value = contact;
  isSidebarOpen.value = true;
};

// View toggle state (default to kanban per D-05)
const currentView = localStorage.getItem('crm_pipeline_view') || 'kanban';
const activeView = ref(currentView);

// Stage filter state (default to 'all')
const activeFilter = ref('all');

// Sort state (default: name asc per D-07)
const sortKey = ref('name');
const sortOrder = ref('asc');

const setView = view => {
  localStorage.setItem('crm_pipeline_view', view);
  activeView.value = view;
};

const stageFilterOptions = computed(() => {
  const options = [
    { action: 'filter', value: 'all', label: 'All stages', isSelected: activeFilter.value === 'all' },
    { action: 'filter', value: 'unassigned', label: 'Unassigned', isSelected: activeFilter.value === 'unassigned' },
  ];
  orderedStages.value.forEach(stage => {
    options.push({
      action: 'filter',
      value: stage.id,
      label: stage.name,
      isSelected: activeFilter.value === stage.id,
    });
  });
  return options;
});

const activeFilterLabel = computed(() => {
  if (activeFilter.value === 'all') return 'All stages';
  if (activeFilter.value === 'unassigned') return 'Unassigned';
  const stage = orderedStages.value.find(s => s.id === activeFilter.value);
  return stage ? stage.name : 'All stages';
});

const handleFilterChange = ({ action, value }) => {
  if (action === 'filter') {
    activeFilter.value = value;
    isStageFilterOpen.value = false;
  }
};

// Handle filter-change event from PipelineStatsPanel
const handleStatsFilterChange = stageId => {
  activeFilter.value = stageId;
};

const filteredContacts = computed(() => {
  const all = Object.values(contactsMap.value);
  if (activeFilter.value === 'all') return all;
  if (activeFilter.value === 'unassigned') {
    return all.filter(c => !c.pipeline_stage_id);
  }
  return all.filter(c => String(c.pipeline_stage_id) === String(activeFilter.value));
});

const sortedContacts = computed(() => {
  const contacts = [...filteredContacts.value];
  if (!sortKey.value) return contacts;
  return contacts.sort((a, b) => {
    const aVal = a[sortKey.value] || '';
    const bVal = b[sortKey.value] || '';
    const cmp = String(aVal).localeCompare(String(bVal));
    return sortOrder.value === 'asc' ? cmp : -cmp;
  });
});

const toggleSort = key => {
  if (sortKey.value === key) {
    if (sortOrder.value === 'asc') sortOrder.value = 'desc';
    else if (sortOrder.value === 'desc') {
      sortKey.value = null;
      sortOrder.value = null;
    }
  } else {
    sortKey.value = key;
    sortOrder.value = 'asc';
  }
};

// Open contact sidebar on row click
const handleRowClick = contact => {
  selectedContact.value = contact;
  isSidebarOpen.value = true;
};

const getStageName = stageId => {
  if (!stageId) return null;
  const stagesById = pipelineStore.getStagesById;
  return stagesById[stageId]?.name || null;
};

const getStageColor = stageId => {
  if (!stageId) return null;
  const stagesById = pipelineStore.getStagesById;
  return stagesById[stageId]?.color || null;
};

const formatDate = dateStr => {
  if (!dateStr) return '—';
  const date = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
  if (diffDays < 7) {
    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    return `${diffDays}d ago`;
  }
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};
</script>

<template>
  <div class="leads-index">
    <!-- Header with page title, filter, view toggle, and manage stages -->
    <div class="flex items-center justify-between px-4 py-3 border-b border-n-weak">
      <h1 class="text-base font-semibold text-n-slate-12">Pipeline</h1>
      <div class="flex items-center gap-2">
        <!-- Stage Filter Dropdown -->
        <div class="relative">
          <OnClickOutside @trigger="isStageFilterOpen = false">
            <Button
              variant="outline"
              color="slate"
              size="sm"
              icon="i-lucide-filter"
              :label="activeFilterLabel"
              @click="isStageFilterOpen = !isStageFilterOpen"
            />
            <DropdownMenu
              v-if="isStageFilterOpen"
              :menu-items="stageFilterOptions"
              class="absolute left-0 top-full mt-2 z-50"
              @action="handleFilterChange"
            />
          </OnClickOutside>
        </div>

        <!-- View Toggle Button Group -->
        <div class="flex gap-0 rounded-lg border border-n-weak overflow-hidden">
          <!-- Kanban toggle -->
          <Button
            ghost
            color="slate"
            size="sm"
            icon="i-lucide-columns"
            :class="{ '!bg-n-brand !text-white': activeView === 'kanban' }"
            class="!rounded-none"
            aria-label="Kanban view"
            :aria-pressed="activeView === 'kanban'"
            @click="setView('kanban')"
          />
          <!-- List toggle -->
          <Button
            ghost
            color="slate"
            size="sm"
            icon="i-lucide-list"
            :class="{ '!bg-n-brand !text-white': activeView === 'list' }"
            class="!rounded-none"
            aria-label="List view"
            :aria-pressed="activeView === 'list'"
            @click="setView('list')"
          />
        </div>

        <!-- Manage Stages button (admin only) -->
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
    </div>

    <!-- Pipeline Stats Panel -->
    <PipelineStatsPanel @filter-change="handleStatsFilterChange" />

    <!-- Kanban board or List view based on activeView -->
    <template v-if="activeView === 'kanban'">
      <template v-if="isLoading">
        <div class="p-4">
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
      </template>
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
    </template>

    <!-- List view -->
    <template v-else-if="activeView === 'list'">
      <div v-if="isLoading" class="p-4">
        <!-- Loading skeleton rows -->
        <table class="min-w-full table-auto">
          <thead class="border-t border-n-weak bg-n-alpha-1">
            <tr>
              <th v-for="(header, i) in ['Name', 'Email', 'Phone', 'Stage', 'Last Activity', 'Created At']" :key="i" class="py-4 ltr:pr-4 rtl:pl-4 text-start text-xs font-semibold text-n-slate-12 uppercase tracking-wide">Loading...</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="i in 5" :key="i" class="border-b border-n-weak">
              <td class="py-3 px-4"><div class="h-4 w-32 bg-n-slate-3 rounded animate-pulse" /></td>
              <td class="py-3 px-4"><div class="h-4 w-40 bg-n-slate-3 rounded animate-pulse" /></td>
              <td class="py-3 px-4"><div class="h-4 w-24 bg-n-slate-3 rounded animate-pulse" /></td>
              <td class="py-3 px-4"><div class="h-4 w-20 bg-n-slate-3 rounded animate-pulse" /></td>
              <td class="py-3 px-4"><div class="h-4 w-24 bg-n-slate-3 rounded animate-pulse" /></td>
              <td class="py-3 px-4"><div class="h-4 w-20 bg-n-slate-3 rounded animate-pulse" /></td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Actual list table -->
      <div v-else class="overflow-auto" style="height: calc(100vh - 10rem);">
        <table class="min-w-full table-auto divide-y divide-n-weak">
          <thead class="border-t border-n-weak bg-n-alpha-1 sticky top-0 z-10">
            <tr>
              <!-- Name column (sortable) -->
              <th class="py-3 ltr:pr-4 rtl:pl-4 text-start">
                <button
                  class="text-xs font-semibold text-n-slate-12 uppercase tracking-wide flex items-center gap-1 hover:text-n-brand transition-colors"
                  @click="toggleSort('name')"
                >
                  Name
                  <span v-if="sortKey === 'name'" class="i-lucide-chevrons-up-down text-n-slate-9 size-3" />
                  <span v-else class="i-lucide-chevrons-up text-n-slate-8 size-3 opacity-40" />
                </button>
              </th>
              <!-- Email column (sortable) -->
              <th class="py-3 ltr:pr-4 rtl:pl-4 text-start">
                <button
                  class="text-xs font-semibold text-n-slate-12 uppercase tracking-wide flex items-center gap-1 hover:text-n-brand transition-colors"
                  @click="toggleSort('email')"
                >
                  Email
                  <span v-if="sortKey === 'email'" class="i-lucide-chevrons-up-down text-n-slate-9 size-3" />
                  <span v-else class="i-lucide-chevrons-up text-n-slate-8 size-3 opacity-40" />
                </button>
              </th>
              <!-- Phone column (not sortable) -->
              <th class="py-3 ltr:pr-4 rtl:pl-4 text-start">
                <span class="text-xs font-semibold text-n-slate-12 uppercase tracking-wide">Phone</span>
              </th>
              <!-- Stage column (sortable) -->
              <th class="py-3 ltr:pr-4 rtl:pl-4 text-start">
                <button
                  class="text-xs font-semibold text-n-slate-12 uppercase tracking-wide flex items-center gap-1 hover:text-n-brand transition-colors"
                  @click="toggleSort('pipeline_stage_id')"
                >
                  Stage
                  <span v-if="sortKey === 'pipeline_stage_id'" class="i-lucide-chevrons-up-down text-n-slate-9 size-3" />
                  <span v-else class="i-lucide-chevrons-up text-n-slate-8 size-3 opacity-40" />
                </button>
              </th>
              <!-- Last Activity column (sortable) -->
              <th class="py-3 ltr:pr-4 rtl:pl-4 text-start">
                <button
                  class="text-xs font-semibold text-n-slate-12 uppercase tracking-wide flex items-center gap-1 hover:text-n-brand transition-colors"
                  @click="toggleSort('last_activity_at')"
                >
                  Last Activity
                  <span v-if="sortKey === 'last_activity_at'" class="i-lucide-chevrons-up-down text-n-slate-9 size-3" />
                  <span v-else class="i-lucide-chevrons-up text-n-slate-8 size-3 opacity-40" />
                </button>
              </th>
              <!-- Created At column (sortable) -->
              <th class="py-3 ltr:pr-4 rtl:pl-4 text-start">
                <button
                  class="text-xs font-semibold text-n-slate-12 uppercase tracking-wide flex items-center gap-1 hover:text-n-brand transition-colors"
                  @click="toggleSort('created_at')"
                >
                  Created At
                  <span v-if="sortKey === 'created_at'" class="i-lucide-chevrons-up-down text-n-slate-9 size-3" />
                  <span v-else class="i-lucide-chevrons-up text-n-slate-8 size-3 opacity-40" />
                </button>
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <!-- Empty state: truly empty (no contacts at all) -->
            <tr v-if="Object.keys(contactsMap).length === 0">
              <td colspan="6" class="py-20 text-center">
                <div class="flex flex-col items-center justify-center gap-3">
                  <span class="i-lucide-inbox size-12 text-n-slate-8" />
                  <h3 class="text-base font-semibold text-n-slate-12">No contacts yet</h3>
                  <p class="text-sm text-n-slate-11 max-w-xs text-center">Add contacts to your pipeline to see them here.</p>
                </div>
              </td>
            </tr>
            <!-- Empty state: filtered empty -->
            <tr v-else-if="sortedContacts.length === 0">
              <td colspan="6" class="py-20 text-center">
                <div class="flex flex-col items-center justify-center gap-3">
                  <span class="i-lucide-filter size-12 text-n-slate-8" />
                  <h3 class="text-base font-semibold text-n-slate-12">No contacts match your filters</h3>
                  <p class="text-sm text-n-slate-11 max-w-xs text-center">Try selecting a different stage or clearing the filter.</p>
                </div>
              </td>
            </tr>
            <!-- Contact rows -->
            <tr
              v-else
              v-for="contact in sortedContacts"
              :key="contact.id"
              class="border-b border-n-weak hover:bg-n-alpha-2 cursor-pointer transition-colors"
              @click="handleRowClick(contact)"
            >
              <!-- Name cell -->
              <td class="py-3 ltr:pr-4 rtl:pl-4">
                <span class="text-sm font-medium text-n-slate-12 truncate block">{{ contact.name }}</span>
              </td>
              <!-- Email cell -->
              <td class="py-3 ltr:pr-4 rtl:pl-4">
                <span class="text-sm text-n-slate-11 truncate block">{{ contact.email || '—' }}</span>
              </td>
              <!-- Phone cell -->
              <td class="py-3 ltr:pr-4 rtl:pl-4">
                <span class="text-sm text-n-slate-11 truncate block">{{ contact.phone_number || '—' }}</span>
              </td>
              <!-- Stage cell -->
              <td class="py-3 ltr:pr-4 rtl:pl-4">
                <span
                  v-if="getStageName(contact.pipeline_stage_id)"
                  class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium text-n-slate-12"
                  :style="{ backgroundColor: getStageColor(contact.pipeline_stage_id) + '20' }"
                >
                  <span
                    class="w-1.5 h-1.5 rounded-full flex-shrink-0"
                    :style="{ backgroundColor: getStageColor(contact.pipeline_stage_id) }"
                  />
                  {{ getStageName(contact.pipeline_stage_id) }}
                </span>
                <span v-else class="text-xs text-n-slate-11 italic">Unassigned</span>
              </td>
              <!-- Last Activity cell -->
              <td class="py-3 ltr:pr-4 rtl:pl-4">
                <span class="text-sm text-n-slate-11">{{ formatDate(contact.last_activity_at) }}</span>
              </td>
              <!-- Created At cell -->
              <td class="py-3 ltr:pr-4 rtl:pl-4">
                <span class="text-sm text-n-slate-11">{{ formatDate(contact.created_at) }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>

    <!-- Manage Stages modal (admin only) -->
    <StageManagementModal v-model:show="showManageStages" />

    <!-- Contact Sidebar -->
    <ContactSidebar
      v-if="isSidebarOpen && selectedContact"
      :contact="selectedContact"
      @close="isSidebarOpen = false"
      @stage-change="handleSidebarStageChange"
    />
  </div>
</template>

<style scoped>
.leads-index {
  height: calc(100vh - 4rem);
  overflow: hidden;
}
</style>
