import { frontendURL } from '../../../helper/URLHelper';
import LeadsIndex from './pages/LeadsIndex.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const commonMeta = {
  featureFlag: FEATURE_FLAGS.CRM,
  permissions: ['administrator', 'agent'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/leads'),
    component: LeadsIndex,
    meta: commonMeta,
    children: [
      {
        path: '',
        name: 'leads_dashboard_index',
        component: LeadsIndex,
        meta: commonMeta,
      },
    ],
  },
];
