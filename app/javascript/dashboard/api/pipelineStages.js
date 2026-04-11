/* global axios */
import ApiClient from './ApiClient';

class PipelineStagesAPI extends ApiClient {
  constructor() {
    super('pipeline_stages', { accountScoped: true });
  }

  move(id, direction) {
    return axios.patch(`${this.url}/${id}/move`, { direction });
  }
}

export default new PipelineStagesAPI();
