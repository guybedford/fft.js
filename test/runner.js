import Mocha from 'mocha';
import fs from 'fs';
import path from 'path';

var runner = new Mocha({ ui: 'bdd' });
runner.suite.emit('pre-require', global, 'global-mocha-context', runner);

let file = process.argv[3];

var tests = file ? [file] : fs.readdirSync('test').filter(function(testName) {
  return testName !== 'runner.js' && testName.endsWith('.js');
});

runNextTests()
.then(function() {
  runner.run()
})
.catch(function(err) {
  setTimeout(function() {
    throw err;
  });
});

function runNextTests() {
  var test = tests.shift();

  if (!test)
    return Promise.resolve();

  return import(path.resolve('test/' + test))
  .then(function() {
    return runNextTests();
  });
}
