const fs = require('fs');

const file = '/vroom-express/src/index.js';
let source = fs.readFileSync(file, 'utf8');

const logger = `const accessLogStream = rfs.createStream(path.join(args.logdir, 'access.log'), {
  compress: 'gzip',
  size: args.logsize,
});

app.use(morgan('combined', {stream: accessLogStream}));`;

const replacements = [
  [logger, '// RiderBiz local validation: HTTP access logging disabled.'],
  ["const morgan = require('morgan');\n", ''],
  ["const rfs = require('rotating-file-stream');\n", ''],
];

for (const [expected, replacement] of replacements) {
  if (source.split(expected).length !== 2) {
    throw new Error('Unexpected upstream source; access-log patch aborted.');
  }
  source = source.replace(expected, replacement);
}

fs.writeFileSync(file, source);
console.log('RiderBiz: HTTP access logger removed from local validation image.');
