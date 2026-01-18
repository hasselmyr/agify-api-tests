module.exports = {
  default: {
    require: ['features/support/**/*.ts'],
    requireModule: ['ts-node/register'],
    format: ['progress', 'html:reports/cucumber-report.html'],
    formatOptions: { snippetInterface: 'async-await' },
    tags: 'not @skip' // Skip tests tagged with @skip by default
  }
};
