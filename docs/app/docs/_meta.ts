export default {
  index: 'Getting Started',
  themes: 'Themes',
  localization: 'Localization',
  responsive: 'Responsive',
  'icon-library': 'Icon Library',
  'hooks': 'Hooks',
  api_reference: {
    title: 'API Reference',
    href: 'https://pub.dev/documentation/forui',
  },
  pub_dev: {
    title: 'Pub Dev',
    href: 'https://pub.dev/packages/forui',
  },

  '-- widgets': {
    type: 'separator',
    title: 'Widgets'
  },
  // TODO: Workaround for a seperator bug. Remove when patched.
  // A page need to be listed after a separator or else the order will be messed up.
  layout: 'Layout',
  form: 'Form',
  data: 'Data Presentation',
  tile: 'Tile',
  navigation: 'Navigation',
  feedback: 'Feedback',
  overlay: 'Overlay',
  foundation: 'Foundation',
  '*': {
    title: ''
  },
};
