# Teeworlds External Console

[![NPM version][npm-image]][npm-url] ![License][license-image]

Teeworlds external console client.

## Installation

Install via npm:

```sh
npm install --save teeworlds-econ
```

Configure Teeworlds external console:

```
ec_port         8303
ec_password     secret
ec_output_level 2
```

## Usage

### Initialize and connect

```js
const TeeworldsEcon = require('teeworlds-econ');

const host = 'localhost'
const port = 8303
const password = 'secret'

const econ = new TeeworldsEcon(host, port, password);

econ.on('online', (err) => {
  console.log('Connected');
});

econ.on('error', (err) => {
  console.error('%s error: %s', err.name, err.message);
});

econ.connect();
```

## Handling game events

```js
econ.on('enter', (e) => {
  console.log('%s (%s) has entered the %s', e.player, e.client, e.team);
});

econ.on('leave', (e) => {
  console.log('%s has left the game', e.player);
});

econ.on('chat', (e) => {
  console.log('%s: "%s"', e.player, e.message);
});

econ.on('pickup', (e) => {
  console.log('%s picked up %s', e.player, e.weapon);
});

econ.on('kill', (e) => {
  console.log('%s killed %s with %s', e.killer, e.victim, e.weapon);
});
```

## Commands

```js
econ.say('gg'); // Send message to chat
econ.svMotd('Welcome!'); // Set message of the day
econ.status().then((status) => { // Fetch players list
  console.log(status);
});
econ.exec('sv_map dm2').then(() => { // Change current map to dm2
  console.log('Map changed');
});
```

## All supported game events

- `enter { player, team, client }`
- `leave { player, client }`
- `pickup { player, weapon, client }`
- `chat { type, player, message, team, client }`
- `kill { killer, victim, weapon, killerClient, victimClient }`
- `flaggrab { player, client }`
- `flagreturn {}`
- `capture { player, client }`
- `netban { ip, reason, minutes, life }`

## License

MIT

[npm-image]: https://img.shields.io/npm/v/teeworlds-econ.svg?style=flat-square
[npm-url]: https://www.npmjs.com/package/teeworlds-econ
[license-image]: https://img.shields.io/npm/l/teeworlds-econ.svg?style=flat-square
