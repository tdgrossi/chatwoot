<script setup>
import { ref, defineProps, defineEmits, nextTick } from 'vue';
import { Chrome } from '@lk77/vue3-color';

import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  modelValue: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['update:modelValue']);

const isPickerOpen = ref(false);
const triggerRef = ref(null);
const pickerStyle = ref({});

const computePickerPosition = () => {
  if (!triggerRef.value) return;
  const rect = triggerRef.value.getBoundingClientRect();
  pickerStyle.value = {
    position: 'fixed',
    top: `${rect.bottom + 8}px`,
    left: `${rect.left}px`,
    zIndex: 9999,
  };
};

const toggleColorPicker = async () => {
  isPickerOpen.value = !isPickerOpen.value;
  if (isPickerOpen.value) {
    await nextTick();
    computePickerPosition();
  }
};

const closeColorPicker = () => {
  if (isPickerOpen.value) {
    isPickerOpen.value = false;
  }
};

const updateColor = e => {
  emit('update:modelValue', e.hex);
};
</script>

<template>
  <div ref="triggerRef" class="relative w-fit">
    <Button
      type="button"
      color="slate"
      icon="i-lucide-pipette"
      trailing-icon
      class="!px-3 !py-3 [&>svg]:w-4 [&>svg]:h-4"
      @click.stop="toggleColorPicker"
    >
      <div class="flex items-center flex-grow gap-2">
        <span
          class="rounded-md size-4"
          :style="{ backgroundColor: modelValue }"
        />
        <span class="min-w-0 truncate">{{ modelValue }}</span>
      </div>
    </Button>
  </div>
  <Teleport to="body">
    <div v-if="isPickerOpen" :style="pickerStyle">
      <Chrome
        v-on-clickaway="closeColorPicker"
        disable-alpha
        :model-value="modelValue"
        class="colorpicker--chrome"
        @update:model-value="updateColor"
      />
    </div>
  </Teleport>
</template>

<style scoped lang="scss">
.colorpicker--chrome.vc-chrome {
  @apply shadow-lg bg-n-background border border-n-weak dark:border-n-weak rounded-[8px];

  :deep() {
    .vc-chrome-saturation-wrap {
      @apply rounded-t-[7px];

      .vc-saturation {
        @apply rounded-t-[8px];
      }
    }

    .vc-chrome-body {
      @apply rounded-b-[7px] bg-n-alpha-3;

      .vc-chrome-toggle-btn {
        .vc-chrome-toggle-icon svg {
          @apply [&>path]:fill-n-slate-10 dark:[&>path]:fill-n-slate-10 left-3 relative;
        }
        .vc-chrome-toggle-icon-highlight {
          @apply bg-n-background;
        }
      }
    }

    input,
    .vc-input__input {
      @apply bg-n-background text-n-slate-12 rounded-md shadow-none;
    }

    .vc-input__label {
      @apply text-n-slate-11 dark:text-n-slate-11;
    }
  }
}
</style>
