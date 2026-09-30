import 'dart:convert';

import 'bridge_models.dart';

/// JavaScript injected at document start into the main frame. It defines
/// `window.ethereum` (EIP-1193) and announces the provider (EIP-6963); all
/// it does is forward `request()` calls to the native `lexorBridge`
/// message listener and resolve/reject with the reply. It contains no
/// wallet logic, secrets or addresses — accounts are only ever learned
/// from `eth_accounts`/`eth_requestAccounts` replies.
abstract final class DappProviderScript {
  /// Name of the JS object the native `WebMessageListener` injects.
  static const bridgeObject = 'lexorBridge';

  static const _iconSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
      '<defs><linearGradient id="g" x1="0" y1="1" x2="1" y2="0">'
      '<stop offset="0" stop-color="#7255A5"/>'
      '<stop offset="1" stop-color="#D4EE6B"/></linearGradient></defs>'
      '<circle cx="32" cy="32" r="32" fill="url(#g)"/></svg>';

  static String get source {
    final icon = 'data:image/svg+xml;base64,${base64Encode(utf8.encode(_iconSvg))}';
    return _template
        .replaceAll('__BRIDGE__', bridgeObject)
        .replaceAll('__ICON__', icon);
  }

  /// Script that delivers [event] to the page's provider.
  static String emitScript(BridgeEvent event) =>
      'window.__lexorEmit && window.__lexorEmit('
      '${jsonEncode(event.name)}, ${jsonEncode(event.data)});';

  static const _template = r'''
(function () {
  'use strict';
  if (window.__lexorProviderInstalled) return;
  Object.defineProperty(window, '__lexorProviderInstalled', { value: true });

  var BRIDGE = '__BRIDGE__';
  var pending = Object.create(null);
  var nextId = 1;
  var listeners = Object.create(null);
  var state = { chainId: '0x1', accounts: [] };
  var listening = false;

  function rpcError(code, message) {
    var e = new Error(message);
    e.code = code;
    return e;
  }

  function bridge() {
    var b = window[BRIDGE];
    if (!b) throw rpcError(4900, 'Wallet unavailable');
    return b;
  }

  function onBridgeMessage(event) {
    var msg;
    try { msg = JSON.parse(event.data); } catch (e) { return; }
    if (!msg || msg.type !== 'response') return;
    var p = pending[msg.id];
    if (!p) return;
    delete pending[msg.id];
    if (msg.error) {
      var err = rpcError(msg.error.code, msg.error.message || 'Request failed');
      if (msg.error.data !== undefined) err.data = msg.error.data;
      p.reject(err);
    } else {
      p.resolve(msg.result);
    }
  }

  function ensureListening() {
    if (listening) return;
    bridge().addEventListener('message', onBridgeMessage);
    listening = true;
  }

  function sameArray(a, b) {
    if (a.length !== b.length) return false;
    for (var i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
    return true;
  }

  function emit(name, data) {
    if (name === 'chainChanged') {
      if (state.chainId === data) return;
      state.chainId = data;
    } else if (name === 'accountsChanged') {
      if (sameArray(state.accounts, data)) return;
      state.accounts = data;
    }
    var list = (listeners[name] || []).slice();
    for (var i = 0; i < list.length; i++) {
      try { list[i](data); } catch (e) { /* a dApp listener must not break us */ }
    }
  }

  function track(method, result) {
    if (method === 'eth_chainId' && typeof result === 'string') {
      emit('chainChanged', result);
    } else if ((method === 'eth_accounts' || method === 'eth_requestAccounts') &&
               Array.isArray(result)) {
      emit('accountsChanged', result);
    }
  }

  function request(args) {
    if (!args || typeof args !== 'object' || Array.isArray(args)) {
      return Promise.reject(rpcError(-32600, 'Invalid request'));
    }
    var method = args.method;
    var params = args.params === undefined ? [] : args.params;
    if (typeof method !== 'string' || !method) {
      return Promise.reject(rpcError(-32600, 'Invalid method'));
    }
    if (params === null || typeof params !== 'object') {
      return Promise.reject(rpcError(-32602, 'Invalid params'));
    }
    return new Promise(function (resolve, reject) {
      var b;
      try { ensureListening(); b = bridge(); } catch (e) { reject(e); return; }
      var id = nextId++;
      pending[id] = {
        resolve: function (r) { track(method, r); resolve(r); },
        reject: reject
      };
      try {
        b.postMessage(JSON.stringify({ id: id, method: method, params: params }));
      } catch (e) {
        delete pending[id];
        reject(rpcError(-32603, 'Could not reach the wallet'));
      }
    });
  }

  function on(name, fn) {
    if (typeof fn !== 'function') return provider;
    (listeners[name] = listeners[name] || []).push(fn);
    return provider;
  }

  function removeListener(name, fn) {
    var list = listeners[name];
    if (!list) return provider;
    var i = list.indexOf(fn);
    if (i >= 0) list.splice(i, 1);
    return provider;
  }

  var provider = {
    isLexorPocket: true,
    request: request,
    on: on,
    addListener: on,
    once: function (name, fn) {
      function wrapper(d) { removeListener(name, wrapper); fn(d); }
      return on(name, wrapper);
    },
    removeListener: removeListener,
    off: removeListener,
    removeAllListeners: function (name) {
      if (name) delete listeners[name]; else listeners = Object.create(null);
      return provider;
    },
    isConnected: function () { return true; },
    enable: function () { return request({ method: 'eth_requestAccounts' }); },
    send: function (a, b) {
      if (typeof a === 'string') return request({ method: a, params: b });
      return provider.sendAsync(a, b);
    },
    sendAsync: function (payload, callback) {
      request({ method: payload.method, params: payload.params }).then(
        function (result) { callback(null, { id: payload.id, jsonrpc: '2.0', result: result }); },
        function (error) {
          callback(error, {
            id: payload.id, jsonrpc: '2.0',
            error: { code: error.code, message: error.message }
          });
        });
    }
  };
  Object.defineProperty(provider, 'chainId', { get: function () { return state.chainId; } });
  Object.defineProperty(provider, 'networkVersion', {
    get: function () { return String(parseInt(state.chainId, 16)); }
  });
  Object.defineProperty(provider, 'selectedAddress', {
    get: function () { return state.accounts[0] || null; }
  });

  // Native -> page events. Harmless if a page calls it: it can only feed
  // events to its own listeners.
  Object.defineProperty(window, '__lexorEmit', { value: emit });

  if (!window.ethereum) {
    Object.defineProperty(window, 'ethereum', {
      value: provider, configurable: true, writable: true
    });
  }

  // EIP-6963 multi-wallet discovery.
  var info = Object.freeze({
    uuid: 'b3f0c1d2-6c5e-4f7a-9a21-3d8e5b7c1a90',
    name: 'Lexor Pocket',
    icon: '__ICON__',
    rdns: 'app.lexor.pocket'
  });
  function announce() {
    window.dispatchEvent(new CustomEvent('eip6963:announceProvider', {
      detail: Object.freeze({ info: info, provider: provider })
    }));
  }
  window.addEventListener('eip6963:requestProvider', announce);
  announce();

  // Learn the current chain/accounts (non-interactive, no prompt).
  function prime(attempt) {
    if (!window[BRIDGE]) {
      if (attempt < 20) setTimeout(function () { prime(attempt + 1); }, 50);
      return;
    }
    request({ method: 'eth_chainId' }).catch(function () {});
    request({ method: 'eth_accounts' }).catch(function () {});
  }
  prime(0);
})();
''';
}
