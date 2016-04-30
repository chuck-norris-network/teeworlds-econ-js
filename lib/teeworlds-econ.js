var EventEmitter, Socket, TeeworldsEcon, escape, parseWeapon, ref, split, splitText,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Socket = require('net').Socket;

EventEmitter = require('events').EventEmitter;

split = require('split');

splitText = require('split-text');

ref = require('./utils'), parseWeapon = ref.parseWeapon, escape = ref.escape;

TeeworldsEcon = (function(superClass) {
  extend(TeeworldsEcon, superClass);

  function TeeworldsEcon(host, port, password) {
    this.disconnect = bind(this.disconnect, this);
    this.handleMessage = bind(this.handleMessage, this);
    TeeworldsEcon.__super__.constructor.apply(this, arguments);
    this.server = {
      host: host,
      port: port,
      password: password
    };
    this.connection = null;
  }

  TeeworldsEcon.prototype.exec = function(command) {
    if (!this.connection) {
      this.emit('error', new Error('Not connected'));
      return;
    }
    return this.connection.write(command + '\n');
  };

  TeeworldsEcon.prototype.say = function(message) {
    var chunk, chunks, i, len, results;
    chunks = message.split('\n').map(escape).map(function(line) {
      return splitText(line, 61);
    }).reduce(function(a, b) {
      return a.concat(b);
    });
    results = [];
    for (i = 0, len = chunks.length; i < len; i++) {
      chunk = chunks[i];
      results.push(this.exec("say \"" + chunk + "\""));
    }
    return results;
  };

  TeeworldsEcon.prototype.motd = function(message) {
    return this.exec("sv_motd \"" + (escape(message)) + "\"");
  };

  TeeworldsEcon.prototype.handleMessage = function(message) {
    var matches;
    if (matches = /^\[chat\]: \*\*\* '([^']+)' entered and joined the.*/.exec(message)) {
      this.emit('enter', matches[1]);
      return;
    }
    if (matches = /^\[chat\]: \*\*\* '([^']+)' has left the game.*/.exec(message)) {
      this.emit('leave', matches[1]);
      return;
    }
    if (matches = /^\[(teamchat|chat)\]: [0-9]+:[0-9-]+:([^:]+): (.*)$/.exec(message)) {
      this.emit('chat', matches[2], matches[3]);
      return;
    }
    if (matches = /^\[game\]: pickup player='[0-9-]+:([^']+)' item=(2|3)+\/([0-9\/]+)$/.exec(message)) {
      this.emit('pickup', matches[1], parseWeapon(parseInt(matches[3])));
      return;
    }
    if (matches = /^\[game\]: kill killer='[0-9-]+:([^']+)' victim='[0-9-]+:([^']+)' weapon=([-0-9]+) special=[0-9]+$/.exec(message)) {
      if (matches[3] === '-3') {
        return;
      }
      this.emit('kill', matches[1], matches[2], parseWeapon(parseInt(matches[3])));
      return;
    }
    if (message === 'Enter password:') {
      this.exec(this.server.password);
      return;
    }
    if (message === 'Authentication successful. External console access granted.') {
      this.emit('online');
      return;
    }
    if (/^Wrong password [0-9\/]+.$/.exec(message)) {
      this.emit('error', new Error(message + " Disconnecting"));
      return this.disconnect();
    }
    if (message === 'authentication timeout') {
      this.emit('error', new Error('Authentication timeout. Disconnecting'));
      return this.disconnect();
    }
  };

  TeeworldsEcon.prototype.connect = function() {
    if (this.connection) {
      return;
    }
    this.connection = new Socket();
    this.connection.pipe(split('\n\u0000\u0000')).on('data', this.handleMessage);
    this.connection.on('error', (function(_this) {
      return function(err) {
        return _this.emit('error', err);
      };
    })(this));
    this.connection.on('close', this.disconnect);
    this.connection.on('end', this.disconnect);
    this.connection.setKeepAlive(true);
    return this.connection.connect(this.server.port, this.server.host);
  };

  TeeworldsEcon.prototype.disconnect = function() {
    if (!this.connection) {
      return;
    }
    this.connection.removeAllListeners('data');
    this.connection.removeAllListeners('end');
    this.connection.removeAllListeners('error');
    this.connection.destroy();
    this.connection.unref();
    this.connection = null;
    return this.emit('end');
  };

  return TeeworldsEcon;

})(EventEmitter);

module.exports = TeeworldsEcon;
