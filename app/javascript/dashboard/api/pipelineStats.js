/* global axios */
import ApiClient from './ApiClient';

class PipelineStatsAPI extends ApiClient {
  constructor() {
    super('pipeline_stats', { accountScoped: true });
  }
}

export default new PipelineStatsAPI();
