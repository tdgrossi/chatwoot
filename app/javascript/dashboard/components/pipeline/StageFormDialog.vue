<script setup>
import { ref, watch, computed } from 'vue';
import Modal from 'dashboard/components/Modal.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';

const props = defineProps({
  show: { type: Boolean, required: true },
  mode: { type: String, default: 'create' }, // 'create' | 'edit'
  stage: { type: Object, default: null },
});

const emit = defineEmits(['save', 'close']);

const localShow = computed({
  get: () => props.show,
  set: val => { if (!val) emit('close'); },
});

const formData = ref({
  name: props.stage?.name || '',
  color: props.stage?.color || '#6B7280',
});

// Re-initialize form when stage prop changes (edit mode)
watch(() => props.stage, newStage => {
  formData.value = {
    name: newStage?.name || '',
    color: newStage?.color || '#6B7280',
  };
}, { immediate: true });

const handleSave = () => {
  if (!formData.value.name.trim()) return;
  emit('save', {
    name: formData.value.name.trim(),
    color: formData.value.color,
  });
};
</script>

<template>
  <Modal
    v-model:show="localShow"
    modal-type="centered"
    :show-close-button="true"
    :on-close="() => emit('close')"
    @close="emit('close')"
  >
    <form @submit.prevent="handleSave" class="p-6">
      <!-- Title -->
      <h3 class="text-base font-semibold text-n-slate-12 mb-4">
        {{ mode === 'create' ? 'Create Stage' : 'Update Stage' }}
      </h3>

      <!-- Stage name input -->
      <div class="mb-4">
        <label class="block text-xs font-medium text-n-slate-11 mb-1">
          Stage name
        </label>
        <input
          v-model="formData.name"
          type="text"
          placeholder="Stage name"
          maxlength="50"
          required
          class="w-full px-3 py-2 text-sm text-n-slate-12 bg-n-alpha-3 border border-n-weak rounded-lg outline-none focus:border-n-brand"
        />
      </div>

      <!-- Color picker -->
      <div class="mb-6">
        <label class="block text-xs font-medium text-n-slate-11 mb-1">
          Color
        </label>
        <ColorPicker v-model="formData.color" />
      </div>

      <!-- Actions -->
      <div class="flex gap-3 justify-end">
        <Button
          type="button"
          variant="ghost"
          slate
          label="Cancel"
          @click="emit('close')"
        />
        <Button
          type="submit"
          color="blue"
          :label="mode === 'create' ? 'Create Stage' : 'Update Stage'"
        />
      </div>
    </form>
  </Modal>
</template>
