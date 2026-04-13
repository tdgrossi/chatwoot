<script setup>
import { ref, computed } from 'vue';
import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import StageFormDialog from './StageFormDialog.vue';
import { usePipelineStore } from 'dashboard/stores/pipeline';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  show: { type: Boolean, required: true },
});

const emit = defineEmits(['update:show']);

const pipelineStore = usePipelineStore();
const showManageStagesModel = computed({
  get: () => props.show,
  set: val => emit('update:show', val),
});

const close = () => {
  showManageStagesModel.value = false;
};

// Sorted stages by position
const getSortedStages = () =>
  [...(pipelineStore.stages || [])].sort((a, b) => a.position - b.position);

const sortedStages = computed(() => getSortedStages());

// Stage form dialog state
const showFormDialog = ref(false);
const editingStage = ref(null);

const openCreateForm = () => {
  editingStage.value = null;
  showFormDialog.value = true;
};

const openEditForm = stage => {
  editingStage.value = stage;
  showFormDialog.value = true;
};

const closeFormDialog = () => {
  showFormDialog.value = false;
  editingStage.value = null;
};

const handleSave = async ({ name, color }) => {
  if (editingStage.value) {
    // Edit mode
    const previousStages = [...pipelineStore.stages];
    const index = pipelineStore.stages.findIndex(
      s => s.id === editingStage.value.id
    );
    const updated = { ...editingStage.value, name, color };
    if (index !== -1) pipelineStore.stages[index] = updated;
    try {
      await pipelineStore.updateStage({
        id: editingStage.value.id,
        name,
        color,
      });
    } catch {
      pipelineStore.stages = previousStages;
      useAlert('Failed to update stage. Please try again.');
    }
  } else {
    // Create mode
    const tempId = `temp-${Date.now()}`;
    const tempStage = {
      id: tempId,
      name,
      color,
      position: sortedStages.value.length,
    };
    pipelineStore.stages.push(tempStage);
    try {
      const newStage = await pipelineStore.createStage({ name, color });
      // Remove temp, store.push handles adding real one
      pipelineStore.stages = pipelineStore.stages.filter(s => s.id !== tempId);
      pipelineStore.stages.push(newStage);
    } catch {
      pipelineStore.stages = pipelineStore.stages.filter(s => s.id !== tempId);
      useAlert('Failed to create stage. Please try again.');
    }
  }
  closeFormDialog();
};

// Reorder
const moveStage = async (stage, direction) => {
  const sorted = getSortedStages();
  const index = sorted.findIndex(s => s.id === stage.id);
  const previousStages = [...pipelineStore.stages];

  const swapWith = direction === 'up' ? sorted[index - 1] : sorted[index + 1];
  if (!swapWith) return;

  const updated = pipelineStore.stages.map(s => {
    if (s.id === stage.id) return { ...s, position: swapWith.position };
    if (s.id === swapWith.id) return { ...s, position: s.position };
    return s;
  });
  pipelineStore.stages = updated;

  try {
    await pipelineStore.moveStage(stage.id, direction);
  } catch {
    pipelineStore.stages = previousStages;
    useAlert('Failed to reorder stage. Please try again.');
  }
};

// Delete
const stageToDelete = ref(null);
const showDeleteDialog = ref(false);
const confirmDeleteStage = stage => {
  stageToDelete.value = stage;
  showDeleteDialog.value = true;
};

const cancelDelete = () => {
  stageToDelete.value = null;
  showDeleteDialog.value = false;
};

const executeDelete = async () => {
  if (!stageToDelete.value) return;
  const id = stageToDelete.value.id;
  const previousStages = [...pipelineStore.stages];
  pipelineStore.stages = pipelineStore.stages.filter(s => s.id !== id);
  showDeleteDialog.value = false;
  stageToDelete.value = null;

  try {
    await pipelineStore.deleteStage(id);
  } catch {
    pipelineStore.stages = previousStages;
    useAlert('Failed to delete stage. Please try again.');
  }
};

const isFirstStage = stage => {
  const sorted = getSortedStages();
  return sorted.length === 0 || sorted[0].id === stage.id;
};

const isLastStage = stage => {
  const sorted = getSortedStages();
  return sorted.length === 0 || sorted[sorted.length - 1].id === stage.id;
};
</script>

<template>
  <Modal
    :show="showManageStagesModel"
    modal-type="right-aligned"
    :show-close-button="true"
    @close="close"
  >
    <div class="flex flex-col h-full">
      <!-- Header -->
      <div
        class="flex items-center justify-between px-4 py-3 border-b border-n-weak"
      >
        <h2 class="text-base font-semibold text-n-slate-12">Manage Stages</h2>
      </div>

      <!-- Body -->
      <div class="flex-1 overflow-auto p-4">
        <!-- Empty state -->
        <div
          v-if="sortedStages.length === 0"
          class="flex flex-col items-center justify-center py-12 text-center"
        >
          <p class="text-base font-semibold text-n-slate-12 mb-1">
            No stages yet
          </p>
          <p class="text-sm text-n-slate-11 mb-4">
            Create your first stage to organize your pipeline.
          </p>
          <Button
            label="Add stage"
            icon="i-lucide-plus"
            outline
            slate
            class="w-full"
            @click="openCreateForm"
          />
        </div>

        <!-- Stage list -->
        <div v-else class="flex flex-col gap-2">
          <!-- Add stage button -->
          <Button
            label="Add stage"
            icon="i-lucide-plus"
            outline
            slate
            class="w-full mb-1"
            @click="openCreateForm"
          />

          <!-- Stage rows -->
          <div
            v-for="stage in sortedStages"
            :key="stage.id"
            class="flex items-center gap-3 px-4 py-3 bg-n-alpha-3 rounded-lg cursor-pointer hover:bg-n-alpha-4 transition-colors"
            :title="stage.name"
            @click="openEditForm(stage)"
          >
            <!-- Color swatch -->
            <div
              class="rounded-md size-6 flex-shrink-0"
              :style="{ backgroundColor: stage.color }"
            />

            <!-- Stage name -->
            <span
              class="text-sm font-medium text-n-slate-12 flex-grow min-w-0 truncate"
            >
              {{ stage.name }}
            </span>

            <!-- Up button -->
            <Button
              icon="i-lucide-arrow-up"
              ghost
              slate
              size="sm"
              :disabled="isFirstStage(stage)"
              title="Move up"
              @click.stop="moveStage(stage, 'up')"
            />

            <!-- Down button -->
            <Button
              icon="i-lucide-arrow-down"
              ghost
              slate
              size="sm"
              :disabled="isLastStage(stage)"
              title="Move down"
              @click.stop="moveStage(stage, 'down')"
            />

            <!-- Delete button -->
            <Button
              icon="i-lucide-trash-2"
              ghost
              ruby
              size="sm"
              title="Delete stage"
              @click.stop="confirmDeleteStage(stage)"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- Create/Edit form dialog -->
    <StageFormDialog
      :show="showFormDialog"
      :mode="editingStage ? 'edit' : 'create'"
      :stage="editingStage"
      @save="handleSave"
      @close="closeFormDialog"
    />

    <!-- Delete confirmation dialog -->
    <Modal
      :show="showDeleteDialog"
      modal-type="centered"
      :show-close-button="false"
      @close="cancelDelete"
    >
      <div class="p-6">
        <h3 class="text-base font-semibold text-n-slate-12 mb-2">
          Delete stage?
        </h3>
        <p class="text-sm text-n-slate-11 mb-6">
          Contacts in this stage will be moved to unassigned. This cannot be
          undone.
        </p>
        <div class="flex gap-3 justify-end">
          <Button variant="ghost" slate label="Cancel" @click="cancelDelete" />
          <Button color="ruby" label="Delete" @click="executeDelete" />
        </div>
      </div>
    </Modal>
  </Modal>
</template>
