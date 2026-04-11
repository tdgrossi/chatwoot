import PipelineStagesAPI from 'dashboard/api/pipelineStages';
import PipelineStatsAPI from 'dashboard/api/pipelineStats';
import ContactAPI from 'dashboard/api/contacts';
import { createStore } from 'dashboard/store/storeFactory';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { useAlert } from 'dashboard/composables';
import camelcaseKeys from 'camelcase-keys';

export const usePipelineStore = createStore({
  name: 'pipeline',
  type: 'pinia',
  API: PipelineStagesAPI,
  state: () => ({
    records: [],
    stages: [],
    stats: [],
    meta: {},
    contacts: {},
    contactsByStage: {},
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
    getContactsByStage: state => state.contactsByStage,
    getUnassignedContacts: state => {
      return Object.values(state.contacts).filter(
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
        this.stages.push(newStage);
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
      this.setUIFlag({ updatingContact: true });
      try {
        // Optimistic update: update local state immediately
        const contact = this.contacts[contactId];
        if (!contact) {
          this.setUIFlag({ updatingContact: false });
          return;
        }
        const previousStageId = contact.pipeline_stage_id;

        // Update contact's pipeline_stage_id in local state
        const updatedContact = {
          ...contact,
          pipeline_stage_id: toStageId === 'unassigned' ? null : toStageId,
        };
        this.contacts[contactId] = updatedContact;

        // Remove from old stage list
        const fromKey = fromStageId === 'unassigned' ? null : fromStageId;
        const fromContacts = this.contactsByStage[fromKey] || [];
        this.contactsByStage[fromKey] = fromContacts.filter(
          c => c.id !== contactId
        );

        // Add to new stage list
        const toKey = toStageId === 'unassigned' ? null : toStageId;
        if (!this.contactsByStage[toKey]) {
          this.contactsByStage[toKey] = [];
        }
        this.contactsByStage[toKey].push(updatedContact);

        // Persist via API (per D-10: PATCH contact with pipeline_stage_id)
        await ContactAPI.update(contactId, {
          pipeline_stage_id: toStageId === 'unassigned' ? null : toStageId,
        });

        this.setUIFlag({ updatingContact: false });
      } catch (error) {
        // Revert optimistic update on failure
        useAlert(
          window.VT_I18N.CONTACT_MOVE_ERROR ||
            'Failed to move contact. Please try again.'
        );

        // Try to restore contact to original stage
        const contact = this.contacts[contactId];
        if (contact) {
          this.contacts[contactId] = {
            ...contact,
            pipeline_stage_id:
              fromStageId === 'unassigned' ? null : fromStageId,
          };

          // Re-add to original stage
          const fromKey = fromStageId === 'unassigned' ? null : fromStageId;
          if (!this.contactsByStage[fromKey]) {
            this.contactsByStage[fromKey] = [];
          }
          if (
            !this.contactsByStage[fromKey].find(c => c.id === contactId)
          ) {
            this.contactsByStage[fromKey].push(contact);
          }
          // Remove from wrong stage
          const toKey = toStageId === 'unassigned' ? null : toStageId;
          const toContacts = this.contactsByStage[toKey] || [];
          this.contactsByStage[toKey] = toContacts.filter(
            c => c.id !== contactId
          );
        }

        this.setUIFlag({ updatingContact: false });
      }
    },
  }),
});
