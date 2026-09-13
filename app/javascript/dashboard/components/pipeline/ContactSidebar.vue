<script setup>
import { ref, computed } from 'vue';
import { usePipelineStore } from '../../stores/pipeline';
import DropdownMenu from '../../components-next/dropdown-menu/DropdownMenu.vue';
import Avatar from '../../components-next/avatar/Avatar.vue';
import Icon from '../../components-next/icon/Icon.vue';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['close', 'stage-change']);

const pipelineStore = usePipelineStore();

const isDropdownOpen = ref(false);

const stageOptions = computed(() => {
  const options = [
    {
      action: 'select-stage',
      value: null,
      label: 'Unassigned',
      color: '#9CA3AF',
      isSelected: !props.contact.pipeline_stage_id,
    },
    ...pipelineStore.stages.map(stage => ({
      action: 'select-stage',
      value: stage.id,
      label: stage.name,
      color: stage.color,
      isSelected: props.contact.pipeline_stage_id === stage.id,
    })),
  ];
  return options;
});

const currentStageName = computed(() => {
  if (!props.contact.pipeline_stage_id) return 'Unassigned';
  const stage = pipelineStore.stages.find(
    s => s.id === props.contact.pipeline_stage_id
  );
  return stage ? stage.name : 'Unassigned';
});

const currentStageColor = computed(() => {
  if (!props.contact.pipeline_stage_id) return '#9CA3AF';
  const stage = pipelineStore.stages.find(
    s => s.id === props.contact.pipeline_stage_id
  );
  return stage ? stage.color : '#9CA3AF';
});

const handleDropdownAction = ({ action, value }) => {
  console.log('[sidebar] stage change handler called', {
    action,
    value,
    currentStageId: props.contact?.pipeline_stage_id,
  });
  if (action === 'select-stage') {
    isDropdownOpen.value = false;
    emit('stage-change', { toStageId: value });
  }
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
  return date.toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

const formatRelativeDate = dateStr => {
  if (!dateStr) return '—';
  const date = new Date(dateStr);
  const now = new Date();
  const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
  if (diffDays === 0) return 'Today';
  if (diffDays === 1) return 'Yesterday';
  if (diffDays < 7) return `${diffDays} days ago`;
  if (diffDays < 30) return `${Math.floor(diffDays / 7)} weeks ago`;
  if (diffDays < 365) return `${Math.floor(diffDays / 30)} months ago`;
  return `${Math.floor(diffDays / 365)} years ago`;
};

const copyToClipboard = async (text, label) => {
  try {
    await navigator.clipboard.writeText(text);
    useAlert(`${label} copied to clipboard`);
  } catch {
    useAlert(`Failed to copy ${label}`);
  }
};

const closeDropdown = () => {
  isDropdownOpen.value = false;
};
</script>

<template>
  <Teleport to="body">
    <!-- Backdrop overlay -->
    <Transition name="backdrop-fade">
      <div
        class="fixed inset-0 z-40 bg-black/30 backdrop-blur-sm"
        @click="$emit('close')"
      />
    </Transition>

    <!-- Sidebar panel -->
    <Transition name="sidebar">
      <div
        class="fixed right-0 top-0 h-full w-full max-w-md bg-n-solid-2 border-l border-n-weak shadow-xl z-50 flex flex-col"
      >
        <!-- Header -->
        <div
          class="flex items-center justify-between px-4 py-3 border-b border-n-weak"
        >
          <span class="text-sm font-semibold text-n-slate-12">Contact Details</span>
          <button
            class="p-1.5 rounded-lg hover:bg-n-alpha-1 transition-colors"
            aria-label="Close sidebar"
            @click="$emit('close')"
          >
            <Icon
              icon="i-lucide-panel-right-close"
              class="size-4 text-n-slate-11"
            />
          </button>
        </div>

        <!-- Body -->
        <div class="flex-1 overflow-y-auto px-4 py-4">
          <!-- Contact header -->
          <div class="flex items-center gap-3">
            <Avatar :name="contact.name" size="lg" rounded-full />
            <span class="text-base font-semibold text-n-slate-12">{{
              contact.name
            }}</span>
          </div>

          <div class="border-t border-n-weak my-4" />

          <!-- Contact fields -->
          <div class="group flex flex-col gap-3">
            <div>
              <div class="text-xs font-medium text-n-slate-11 mb-1">Email</div>
              <div class="flex items-center justify-between">
                <div class="text-sm text-n-slate-12">
                  {{ contact.email || '—' }}
                </div>
                <button
                  v-if="contact.email"
                  class="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-n-alpha-1 transition-opacity"
                  title="Copy email"
                  @click="copyToClipboard(contact.email, 'Email')"
                >
                  <Icon icon="i-lucide-copy" class="size-3 text-n-slate-9" />
                </button>
              </div>
            </div>
            <div>
              <div class="text-xs font-medium text-n-slate-11 mb-1">Phone</div>
              <div class="flex items-center justify-between">
                <div class="text-sm text-n-slate-12">
                  {{ contact.phone_number || '—' }}
                </div>
                <button
                  v-if="contact.phone_number"
                  class="opacity-0 group-hover:opacity-100 p-1 rounded hover:bg-n-alpha-1 transition-opacity"
                  title="Copy phone"
                  @click="copyToClipboard(contact.phone_number, 'Phone')"
                >
                  <Icon icon="i-lucide-copy" class="size-3 text-n-slate-9" />
                </button>
              </div>
            </div>
            <div>
              <div class="text-xs font-medium text-n-slate-11 mb-1">
                Last Activity
              </div>
              <div class="text-sm text-n-slate-12">
                {{ formatDate(contact.last_activity_at) }}
              </div>
            </div>
          </div>

          <!-- Action buttons -->
          <div class="flex gap-2 mt-2">
            <button
              class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg bg-n-alpha-1 hover:bg-n-alpha-2 text-n-slate-12 transition-colors"
              @click="
                copyToClipboard(
                  contact.email || contact.phone_number || '',
                  'Contact info'
                )
              "
            >
              <Icon icon="i-lucide-copy" class="size-3" />
              Copy
            </button>
            <button
              class="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium rounded-lg bg-n-alpha-1 hover:bg-n-alpha-2 text-n-slate-12 transition-colors"
            >
              <Icon icon="i-lucide-edit" class="size-3" />
              Edit
            </button>
          </div>

          <div class="border-t border-n-weak my-4" />

          <!-- Pipeline Stage section -->
          <div class="mt-4 p-3 rounded-xl bg-n-alpha-1 border border-n-weak">
            <span class="text-xs font-medium text-n-slate-11 mb-2 block">Pipeline Stage</span>

            <!-- Dropdown trigger -->
            <div class="relative">
              <button
                class="flex items-center justify-between w-full px-3 py-2 rounded-lg border border-n-weak bg-n-surface-1 hover:bg-n-alpha-1 cursor-pointer transition-colors"
                @click="isDropdownOpen = !isDropdownOpen"
              >
                <div class="flex items-center gap-2">
                  <span
                    class="w-2 h-2 rounded-full flex-shrink-0"
                    :style="{ backgroundColor: currentStageColor }"
                  />
                  <span class="text-sm text-n-slate-12">{{
                    currentStageName
                  }}</span>
                </div>
                <Icon
                  icon="i-lucide-chevron-down"
                  class="size-4 text-n-slate-11"
                />
              </button>

              <!-- Dropdown menu - custom styled list -->
              <div
                v-if="isDropdownOpen"
                class="absolute top-full start-0 mt-1 z-50 bg-n-alpha-3 backdrop-blur-[100px] outline outline-1 outline-n-container rounded-xl shadow-lg py-2 px-2 min-w-[136px]"
              >
                <button
                  v-for="(item, index) in stageOptions"
                  :key="index"
                  type="button"
                  class="inline-flex items-center justify-start w-full h-8 min-w-0 gap-2 px-2 py-1.5 transition-all duration-200 ease-in-out border-0 rounded-lg hover:bg-n-alpha-1 dark:hover:bg-n-alpha-2"
                  :class="{
                    'bg-n-alpha-1 dark:bg-n-solid-active': item.isSelected,
                  }"
                  @click="handleDropdownAction(item)"
                >
                  <span
                    class="w-2 h-2 rounded-full flex-shrink-0"
                    :style="{ backgroundColor: item.color }"
                  />
                  <span class="text-sm text-n-slate-12 truncate">{{
                    item.label
                  }}</span>
                </button>
              </div>

              <!-- Click-outside overlay to close -->
              <div
                v-if="isDropdownOpen"
                class="fixed inset-0 z-40"
                @click.stop="closeDropdown"
              />
            </div>
          </div>

          <!-- Created date section -->
          <div class="mt-4 pt-4 border-t border-n-weak">
            <div class="text-xs font-medium text-n-slate-11 mb-1">Created</div>
            <div class="text-sm text-n-slate-12">
              {{ formatRelativeDate(contact.created_at) }}
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.sidebar-enter-active,
.sidebar-leave-active {
  transition: transform 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.sidebar-enter-from,
.sidebar-leave-to {
  transform: translateX(100%);
}

.backdrop-fade-enter-active,
.backdrop-fade-leave-active {
  transition: opacity 0.2s ease;
}

.backdrop-fade-enter-from,
.backdrop-fade-leave-to {
  opacity: 0;
}
</style>
