import PipelineStagesAPI from 'dashboard/api/pipelineStages';
import PipelineStatsAPI from 'dashboard/api/pipelineStats';
import ContactAPI from 'dashboard/api/contacts';
import { createStore } from 'dashboard/store/storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { useAlert } from 'dashboard/composables';
import camelcaseKeys from 'camelcase-keys';
import vuexStore from 'dashboard/store';

export const usePipelineStore = createStore({
  name: 'pipeline',
  type: 'pinia',
  API: PipelineStagesAPI,
  state: () => ({
    records: [],
    stages: [],
    stats: [],
    meta: {},
    uiFlags: {
      fetchingList: false,
      fetchingItem: false,
      fetchingContacts: false,
      updatingContact: false,
      creatingItem: false,
      updatingItem: false,
      deletingItem: false,
    },
  }),
  getters: {
    getStagesList: state => camelcaseKeys(state.stages, { deep: true }),
    getStats: state => camelcaseKeys(state.stats, { deep: true }),
    getStagesById: state => {
      const map = {};
      state.stages.forEach(s => {
        map[s.id] = s;
      });
      return map;
    },
    getContactsByStage: _state => ({}),
    // Read unassigned contacts from Vuex store (pipelineStore.contacts is always empty)
    getUnassignedContacts: _state => {
      return Object.values(vuexStore.state.contacts?.records || {}).filter(
        contact => !contact.pipeline_stage_id
      );
    },
  },
  actions: () => ({
    setUIFlag(data) {
      this.uiFlags = {
        ...this.uiFlags,
        ...data,
      };
    },

    setMeta(meta) {
      this.meta = {
        ...this.meta,
        totalCount: Number(meta.total_count || meta.totalCount || 0),
        page: Number(meta.page || 1),
      };
    },

    async fetchStages() {
      this.setUIFlag({ fetchingList: true });
      try {
        const response = await PipelineStagesAPI.get();
        this.stages = response.data.payload || response.data;
        this.setUIFlag({ fetchingList: false });
      } catch (error) {
        throwErrorMessage(error);
        this.setUIFlag({ fetchingList: false });
      }
    },

    async fetchStats() {
      this.setUIFlag({ fetchingList: true });
      try {
        const response = await PipelineStatsAPI.get();
        this.stats = response.data || [];
        this.setUIFlag({ fetchingList: false });
      } catch (error) {
        throwErrorMessage(error);
        this.setUIFlag({ fetchingList: false });
      }
    },

    async createStage(data) {
      this.setUIFlag({ creatingItem: true });
      try {
        const response = await PipelineStagesAPI.create(data);
        const newStage = response.data.payload || response.data;
        // NOTE: Don't push here - StageManagementModal handles adding to stages array
        this.setUIFlag({ creatingItem: false });
        return newStage;
      } catch (error) {
        throwErrorMessage(error);
        this.setUIFlag({ creatingItem: false });
      }
    },

    async updateStage({ id, ...data }) {
      this.setUIFlag({ updatingItem: true });
      try {
        const response = await PipelineStagesAPI.update(id, data);
        const updated = response.data.payload || response.data;
        const index = this.stages.findIndex(s => s.id === updated.id);
        if (index !== -1) this.stages[index] = updated;
        this.setUIFlag({ updatingItem: false });
        return updated;
      } catch (error) {
        throwErrorMessage(error);
        this.setUIFlag({ updatingItem: false });
      }
    },

    async deleteStage(id) {
      this.setUIFlag({ deletingItem: true });
      try {
        await PipelineStagesAPI.delete(id);
        this.stages = this.stages.filter(s => s.id !== id);
        this.setUIFlag({ deletingItem: false });
      } catch (error) {
        throwErrorMessage(error);
        this.setUIFlag({ deletingItem: false });
      }
    },

    async moveStage(id, direction) {
      this.setUIFlag({ updatingItem: true });
      try {
        await PipelineStagesAPI.move(id, direction);
        await this.fetchStages();
        this.setUIFlag({ updatingItem: false });
      } catch (error) {
        throwErrorMessage(error);
        this.setUIFlag({ updatingItem: false });
      }
    },

    async moveContactToStage({ contactId, fromStageId, toStageId }) {
      console.log('[pipeline] moveContactToStage called', { contactId, fromStageId, toStageId });
      this.setUIFlag({ updatingContact: true });
      try {
        // Read contact from Vuex store (pipelineStore.contacts is always empty {})
        const contact = vuexStore.state.contacts?.records?.[contactId];
        console.log('[pipeline] contact from vuexStore:', contact ? contact.id : 'NOT FOUND', '| contactId:', contactId);
        console.log('[pipeline] vuexStore contacts keys:', Object.keys(vuexStore.state.contacts?.records || {}));
        if (!contact) {
          console.log('[pipeline] EARLY RETURN: contact not found in vuexStore');
          useAlert('Contact not found. Please refresh the page.');
          this.setUIFlag({ updatingContact: false });
          return;
        }

        // Persist via API (per D-10: PATCH contact with pipeline_stage_id)
        const apiPayload = { pipeline_stage_id: toStageId === 'unassigned' ? null : toStageId };
        console.log('[pipeline] API request:', { contactId, ...apiPayload });
        await ContactAPI.update(contactId, apiPayload);
        console.log('[pipeline] API SUCCESS - contact moved');

        this.setUIFlag({ updatingContact: false });
      } catch (error) {
        console.log('[pipeline] API ERROR:', error?.message || error, '| status:', error?.response?.status);
        // Show error toast on failure
        useAlert(
          window.VT_I18N.CONTACT_MOVE_ERROR ||
            'Failed to move contact. Please try again.'
        );
        this.setUIFlag({ updatingContact: false });
        throw error; // Re-throw so caller can handle
      }
    },
  }),
});
