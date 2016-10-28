const Ugh = require('nrser/lib/ugh').Ugh;

const ugh = new Ugh({packageDir: __dirname});

ugh.autoTasks();

module.exports = ugh;
