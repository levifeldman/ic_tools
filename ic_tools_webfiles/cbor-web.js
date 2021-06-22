(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.cbor = f()}})(function(){var define,module,exports;return (function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
(function (global){(function (){
'use strict';

var possibleNames = [
	'BigInt64Array',
	'BigUint64Array',
	'Float32Array',
	'Float64Array',
	'Int16Array',
	'Int32Array',
	'Int8Array',
	'Uint16Array',
	'Uint32Array',
	'Uint8Array',
	'Uint8ClampedArray'
];

module.exports = function availableTypedArrays() {
	var out = [];
	for (var i = 0; i < possibleNames.length; i++) {
		if (typeof global[possibleNames[i]] === 'function') {
			out[out.length] = possibleNames[i];
		}
	}
	return out;
};

}).call(this)}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{}],2:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var callBind = require('./');

var $indexOf = callBind(GetIntrinsic('String.prototype.indexOf'));

module.exports = function callBoundIntrinsic(name, allowMissing) {
	var intrinsic = GetIntrinsic(name, !!allowMissing);
	if (typeof intrinsic === 'function' && $indexOf(name, '.prototype.') > -1) {
		return callBind(intrinsic);
	}
	return intrinsic;
};

},{"./":3,"get-intrinsic":8}],3:[function(require,module,exports){
'use strict';

var bind = require('function-bind');
var GetIntrinsic = require('get-intrinsic');

var $apply = GetIntrinsic('%Function.prototype.apply%');
var $call = GetIntrinsic('%Function.prototype.call%');
var $reflectApply = GetIntrinsic('%Reflect.apply%', true) || bind.call($call, $apply);

var $gOPD = GetIntrinsic('%Object.getOwnPropertyDescriptor%', true);
var $defineProperty = GetIntrinsic('%Object.defineProperty%', true);
var $max = GetIntrinsic('%Math.max%');

if ($defineProperty) {
	try {
		$defineProperty({}, 'a', { value: 1 });
	} catch (e) {
		// IE 8 has a broken defineProperty
		$defineProperty = null;
	}
}

module.exports = function callBind(originalFunction) {
	var func = $reflectApply(bind, $call, arguments);
	if ($gOPD && $defineProperty) {
		var desc = $gOPD(func, 'length');
		if (desc.configurable) {
			// original length, plus the receiver, minus any additional arguments (after the receiver)
			$defineProperty(
				func,
				'length',
				{ value: 1 + $max(0, originalFunction.length - (arguments.length - 1)) }
			);
		}
	}
	return func;
};

var applyBind = function applyBind() {
	return $reflectApply(bind, $apply, arguments);
};

if ($defineProperty) {
	$defineProperty(module.exports, 'apply', { value: applyBind });
} else {
	module.exports.apply = applyBind;
}

},{"function-bind":7,"get-intrinsic":8}],4:[function(require,module,exports){
'use strict';

var GetIntrinsic = require('get-intrinsic');

var $gOPD = GetIntrinsic('%Object.getOwnPropertyDescriptor%');
if ($gOPD) {
	try {
		$gOPD([], 'length');
	} catch (e) {
		// IE 8 has a broken gOPD
		$gOPD = null;
	}
}

module.exports = $gOPD;

},{"get-intrinsic":8}],5:[function(require,module,exports){

var hasOwn = Object.prototype.hasOwnProperty;
var toString = Object.prototype.toString;

module.exports = function forEach (obj, fn, ctx) {
    if (toString.call(fn) !== '[object Function]') {
        throw new TypeError('iterator must be a function');
    }
    var l = obj.length;
    if (l === +l) {
        for (var i = 0; i < l; i++) {
            fn.call(ctx, obj[i], i, obj);
        }
    } else {
        for (var k in obj) {
            if (hasOwn.call(obj, k)) {
                fn.call(ctx, obj[k], k, obj);
            }
        }
    }
};


},{}],6:[function(require,module,exports){
'use strict';

/* eslint no-invalid-this: 1 */

var ERROR_MESSAGE = 'Function.prototype.bind called on incompatible ';
var slice = Array.prototype.slice;
var toStr = Object.prototype.toString;
var funcType = '[object Function]';

module.exports = function bind(that) {
    var target = this;
    if (typeof target !== 'function' || toStr.call(target) !== funcType) {
        throw new TypeError(ERROR_MESSAGE + target);
    }
    var args = slice.call(arguments, 1);

    var bound;
    var binder = function () {
        if (this instanceof bound) {
            var result = target.apply(
                this,
                args.concat(slice.call(arguments))
            );
            if (Object(result) === result) {
                return result;
            }
            return this;
        } else {
            return target.apply(
                that,
                args.concat(slice.call(arguments))
            );
        }
    };

    var boundLength = Math.max(0, target.length - args.length);
    var boundArgs = [];
    for (var i = 0; i < boundLength; i++) {
        boundArgs.push('$' + i);
    }

    bound = Function('binder', 'return function (' + boundArgs.join(',') + '){ return binder.apply(this,arguments); }')(binder);

    if (target.prototype) {
        var Empty = function Empty() {};
        Empty.prototype = target.prototype;
        bound.prototype = new Empty();
        Empty.prototype = null;
    }

    return bound;
};

},{}],7:[function(require,module,exports){
'use strict';

var implementation = require('./implementation');

module.exports = Function.prototype.bind || implementation;

},{"./implementation":6}],8:[function(require,module,exports){
'use strict';

var undefined;

var $SyntaxError = SyntaxError;
var $Function = Function;
var $TypeError = TypeError;

// eslint-disable-next-line consistent-return
var getEvalledConstructor = function (expressionSyntax) {
	try {
		return $Function('"use strict"; return (' + expressionSyntax + ').constructor;')();
	} catch (e) {}
};

var $gOPD = Object.getOwnPropertyDescriptor;
if ($gOPD) {
	try {
		$gOPD({}, '');
	} catch (e) {
		$gOPD = null; // this is IE 8, which has a broken gOPD
	}
}

var throwTypeError = function () {
	throw new $TypeError();
};
var ThrowTypeError = $gOPD
	? (function () {
		try {
			// eslint-disable-next-line no-unused-expressions, no-caller, no-restricted-properties
			arguments.callee; // IE 8 does not throw here
			return throwTypeError;
		} catch (calleeThrows) {
			try {
				// IE 8 throws on Object.getOwnPropertyDescriptor(arguments, '')
				return $gOPD(arguments, 'callee').get;
			} catch (gOPDthrows) {
				return throwTypeError;
			}
		}
	}())
	: throwTypeError;

var hasSymbols = require('has-symbols')();

var getProto = Object.getPrototypeOf || function (x) { return x.__proto__; }; // eslint-disable-line no-proto

var needsEval = {};

var TypedArray = typeof Uint8Array === 'undefined' ? undefined : getProto(Uint8Array);

var INTRINSICS = {
	'%AggregateError%': typeof AggregateError === 'undefined' ? undefined : AggregateError,
	'%Array%': Array,
	'%ArrayBuffer%': typeof ArrayBuffer === 'undefined' ? undefined : ArrayBuffer,
	'%ArrayIteratorPrototype%': hasSymbols ? getProto([][Symbol.iterator]()) : undefined,
	'%AsyncFromSyncIteratorPrototype%': undefined,
	'%AsyncFunction%': needsEval,
	'%AsyncGenerator%': needsEval,
	'%AsyncGeneratorFunction%': needsEval,
	'%AsyncIteratorPrototype%': needsEval,
	'%Atomics%': typeof Atomics === 'undefined' ? undefined : Atomics,
	'%BigInt%': typeof BigInt === 'undefined' ? undefined : BigInt,
	'%Boolean%': Boolean,
	'%DataView%': typeof DataView === 'undefined' ? undefined : DataView,
	'%Date%': Date,
	'%decodeURI%': decodeURI,
	'%decodeURIComponent%': decodeURIComponent,
	'%encodeURI%': encodeURI,
	'%encodeURIComponent%': encodeURIComponent,
	'%Error%': Error,
	'%eval%': eval, // eslint-disable-line no-eval
	'%EvalError%': EvalError,
	'%Float32Array%': typeof Float32Array === 'undefined' ? undefined : Float32Array,
	'%Float64Array%': typeof Float64Array === 'undefined' ? undefined : Float64Array,
	'%FinalizationRegistry%': typeof FinalizationRegistry === 'undefined' ? undefined : FinalizationRegistry,
	'%Function%': $Function,
	'%GeneratorFunction%': needsEval,
	'%Int8Array%': typeof Int8Array === 'undefined' ? undefined : Int8Array,
	'%Int16Array%': typeof Int16Array === 'undefined' ? undefined : Int16Array,
	'%Int32Array%': typeof Int32Array === 'undefined' ? undefined : Int32Array,
	'%isFinite%': isFinite,
	'%isNaN%': isNaN,
	'%IteratorPrototype%': hasSymbols ? getProto(getProto([][Symbol.iterator]())) : undefined,
	'%JSON%': typeof JSON === 'object' ? JSON : undefined,
	'%Map%': typeof Map === 'undefined' ? undefined : Map,
	'%MapIteratorPrototype%': typeof Map === 'undefined' || !hasSymbols ? undefined : getProto(new Map()[Symbol.iterator]()),
	'%Math%': Math,
	'%Number%': Number,
	'%Object%': Object,
	'%parseFloat%': parseFloat,
	'%parseInt%': parseInt,
	'%Promise%': typeof Promise === 'undefined' ? undefined : Promise,
	'%Proxy%': typeof Proxy === 'undefined' ? undefined : Proxy,
	'%RangeError%': RangeError,
	'%ReferenceError%': ReferenceError,
	'%Reflect%': typeof Reflect === 'undefined' ? undefined : Reflect,
	'%RegExp%': RegExp,
	'%Set%': typeof Set === 'undefined' ? undefined : Set,
	'%SetIteratorPrototype%': typeof Set === 'undefined' || !hasSymbols ? undefined : getProto(new Set()[Symbol.iterator]()),
	'%SharedArrayBuffer%': typeof SharedArrayBuffer === 'undefined' ? undefined : SharedArrayBuffer,
	'%String%': String,
	'%StringIteratorPrototype%': hasSymbols ? getProto(''[Symbol.iterator]()) : undefined,
	'%Symbol%': hasSymbols ? Symbol : undefined,
	'%SyntaxError%': $SyntaxError,
	'%ThrowTypeError%': ThrowTypeError,
	'%TypedArray%': TypedArray,
	'%TypeError%': $TypeError,
	'%Uint8Array%': typeof Uint8Array === 'undefined' ? undefined : Uint8Array,
	'%Uint8ClampedArray%': typeof Uint8ClampedArray === 'undefined' ? undefined : Uint8ClampedArray,
	'%Uint16Array%': typeof Uint16Array === 'undefined' ? undefined : Uint16Array,
	'%Uint32Array%': typeof Uint32Array === 'undefined' ? undefined : Uint32Array,
	'%URIError%': URIError,
	'%WeakMap%': typeof WeakMap === 'undefined' ? undefined : WeakMap,
	'%WeakRef%': typeof WeakRef === 'undefined' ? undefined : WeakRef,
	'%WeakSet%': typeof WeakSet === 'undefined' ? undefined : WeakSet
};

var doEval = function doEval(name) {
	var value;
	if (name === '%AsyncFunction%') {
		value = getEvalledConstructor('async function () {}');
	} else if (name === '%GeneratorFunction%') {
		value = getEvalledConstructor('function* () {}');
	} else if (name === '%AsyncGeneratorFunction%') {
		value = getEvalledConstructor('async function* () {}');
	} else if (name === '%AsyncGenerator%') {
		var fn = doEval('%AsyncGeneratorFunction%');
		if (fn) {
			value = fn.prototype;
		}
	} else if (name === '%AsyncIteratorPrototype%') {
		var gen = doEval('%AsyncGenerator%');
		if (gen) {
			value = getProto(gen.prototype);
		}
	}

	INTRINSICS[name] = value;

	return value;
};

var LEGACY_ALIASES = {
	'%ArrayBufferPrototype%': ['ArrayBuffer', 'prototype'],
	'%ArrayPrototype%': ['Array', 'prototype'],
	'%ArrayProto_entries%': ['Array', 'prototype', 'entries'],
	'%ArrayProto_forEach%': ['Array', 'prototype', 'forEach'],
	'%ArrayProto_keys%': ['Array', 'prototype', 'keys'],
	'%ArrayProto_values%': ['Array', 'prototype', 'values'],
	'%AsyncFunctionPrototype%': ['AsyncFunction', 'prototype'],
	'%AsyncGenerator%': ['AsyncGeneratorFunction', 'prototype'],
	'%AsyncGeneratorPrototype%': ['AsyncGeneratorFunction', 'prototype', 'prototype'],
	'%BooleanPrototype%': ['Boolean', 'prototype'],
	'%DataViewPrototype%': ['DataView', 'prototype'],
	'%DatePrototype%': ['Date', 'prototype'],
	'%ErrorPrototype%': ['Error', 'prototype'],
	'%EvalErrorPrototype%': ['EvalError', 'prototype'],
	'%Float32ArrayPrototype%': ['Float32Array', 'prototype'],
	'%Float64ArrayPrototype%': ['Float64Array', 'prototype'],
	'%FunctionPrototype%': ['Function', 'prototype'],
	'%Generator%': ['GeneratorFunction', 'prototype'],
	'%GeneratorPrototype%': ['GeneratorFunction', 'prototype', 'prototype'],
	'%Int8ArrayPrototype%': ['Int8Array', 'prototype'],
	'%Int16ArrayPrototype%': ['Int16Array', 'prototype'],
	'%Int32ArrayPrototype%': ['Int32Array', 'prototype'],
	'%JSONParse%': ['JSON', 'parse'],
	'%JSONStringify%': ['JSON', 'stringify'],
	'%MapPrototype%': ['Map', 'prototype'],
	'%NumberPrototype%': ['Number', 'prototype'],
	'%ObjectPrototype%': ['Object', 'prototype'],
	'%ObjProto_toString%': ['Object', 'prototype', 'toString'],
	'%ObjProto_valueOf%': ['Object', 'prototype', 'valueOf'],
	'%PromisePrototype%': ['Promise', 'prototype'],
	'%PromiseProto_then%': ['Promise', 'prototype', 'then'],
	'%Promise_all%': ['Promise', 'all'],
	'%Promise_reject%': ['Promise', 'reject'],
	'%Promise_resolve%': ['Promise', 'resolve'],
	'%RangeErrorPrototype%': ['RangeError', 'prototype'],
	'%ReferenceErrorPrototype%': ['ReferenceError', 'prototype'],
	'%RegExpPrototype%': ['RegExp', 'prototype'],
	'%SetPrototype%': ['Set', 'prototype'],
	'%SharedArrayBufferPrototype%': ['SharedArrayBuffer', 'prototype'],
	'%StringPrototype%': ['String', 'prototype'],
	'%SymbolPrototype%': ['Symbol', 'prototype'],
	'%SyntaxErrorPrototype%': ['SyntaxError', 'prototype'],
	'%TypedArrayPrototype%': ['TypedArray', 'prototype'],
	'%TypeErrorPrototype%': ['TypeError', 'prototype'],
	'%Uint8ArrayPrototype%': ['Uint8Array', 'prototype'],
	'%Uint8ClampedArrayPrototype%': ['Uint8ClampedArray', 'prototype'],
	'%Uint16ArrayPrototype%': ['Uint16Array', 'prototype'],
	'%Uint32ArrayPrototype%': ['Uint32Array', 'prototype'],
	'%URIErrorPrototype%': ['URIError', 'prototype'],
	'%WeakMapPrototype%': ['WeakMap', 'prototype'],
	'%WeakSetPrototype%': ['WeakSet', 'prototype']
};

var bind = require('function-bind');
var hasOwn = require('has');
var $concat = bind.call(Function.call, Array.prototype.concat);
var $spliceApply = bind.call(Function.apply, Array.prototype.splice);
var $replace = bind.call(Function.call, String.prototype.replace);
var $strSlice = bind.call(Function.call, String.prototype.slice);

/* adapted from https://github.com/lodash/lodash/blob/4.17.15/dist/lodash.js#L6735-L6744 */
var rePropName = /[^%.[\]]+|\[(?:(-?\d+(?:\.\d+)?)|(["'])((?:(?!\2)[^\\]|\\.)*?)\2)\]|(?=(?:\.|\[\])(?:\.|\[\]|%$))/g;
var reEscapeChar = /\\(\\)?/g; /** Used to match backslashes in property paths. */
var stringToPath = function stringToPath(string) {
	var first = $strSlice(string, 0, 1);
	var last = $strSlice(string, -1);
	if (first === '%' && last !== '%') {
		throw new $SyntaxError('invalid intrinsic syntax, expected closing `%`');
	} else if (last === '%' && first !== '%') {
		throw new $SyntaxError('invalid intrinsic syntax, expected opening `%`');
	}
	var result = [];
	$replace(string, rePropName, function (match, number, quote, subString) {
		result[result.length] = quote ? $replace(subString, reEscapeChar, '$1') : number || match;
	});
	return result;
};
/* end adaptation */

var getBaseIntrinsic = function getBaseIntrinsic(name, allowMissing) {
	var intrinsicName = name;
	var alias;
	if (hasOwn(LEGACY_ALIASES, intrinsicName)) {
		alias = LEGACY_ALIASES[intrinsicName];
		intrinsicName = '%' + alias[0] + '%';
	}

	if (hasOwn(INTRINSICS, intrinsicName)) {
		var value = INTRINSICS[intrinsicName];
		if (value === needsEval) {
			value = doEval(intrinsicName);
		}
		if (typeof value === 'undefined' && !allowMissing) {
			throw new $TypeError('intrinsic ' + name + ' exists, but is not available. Please file an issue!');
		}

		return {
			alias: alias,
			name: intrinsicName,
			value: value
		};
	}

	throw new $SyntaxError('intrinsic ' + name + ' does not exist!');
};

module.exports = function GetIntrinsic(name, allowMissing) {
	if (typeof name !== 'string' || name.length === 0) {
		throw new $TypeError('intrinsic name must be a non-empty string');
	}
	if (arguments.length > 1 && typeof allowMissing !== 'boolean') {
		throw new $TypeError('"allowMissing" argument must be a boolean');
	}

	var parts = stringToPath(name);
	var intrinsicBaseName = parts.length > 0 ? parts[0] : '';

	var intrinsic = getBaseIntrinsic('%' + intrinsicBaseName + '%', allowMissing);
	var intrinsicRealName = intrinsic.name;
	var value = intrinsic.value;
	var skipFurtherCaching = false;

	var alias = intrinsic.alias;
	if (alias) {
		intrinsicBaseName = alias[0];
		$spliceApply(parts, $concat([0, 1], alias));
	}

	for (var i = 1, isOwn = true; i < parts.length; i += 1) {
		var part = parts[i];
		var first = $strSlice(part, 0, 1);
		var last = $strSlice(part, -1);
		if (
			(
				(first === '"' || first === "'" || first === '`')
				|| (last === '"' || last === "'" || last === '`')
			)
			&& first !== last
		) {
			throw new $SyntaxError('property names with quotes must have matching quotes');
		}
		if (part === 'constructor' || !isOwn) {
			skipFurtherCaching = true;
		}

		intrinsicBaseName += '.' + part;
		intrinsicRealName = '%' + intrinsicBaseName + '%';

		if (hasOwn(INTRINSICS, intrinsicRealName)) {
			value = INTRINSICS[intrinsicRealName];
		} else if (value != null) {
			if (!(part in value)) {
				if (!allowMissing) {
					throw new $TypeError('base intrinsic for ' + name + ' exists, but the property is not available.');
				}
				return void undefined;
			}
			if ($gOPD && (i + 1) >= parts.length) {
				var desc = $gOPD(value, part);
				isOwn = !!desc;

				// By convention, when a data property is converted to an accessor
				// property to emulate a data property that does not suffer from
				// the override mistake, that accessor's getter is marked with
				// an `originalValue` property. Here, when we detect this, we
				// uphold the illusion by pretending to see that original data
				// property, i.e., returning the value rather than the getter
				// itself.
				if (isOwn && 'get' in desc && !('originalValue' in desc.get)) {
					value = desc.get;
				} else {
					value = value[part];
				}
			} else {
				isOwn = hasOwn(value, part);
				value = value[part];
			}

			if (isOwn && !skipFurtherCaching) {
				INTRINSICS[intrinsicRealName] = value;
			}
		}
	}
	return value;
};

},{"function-bind":7,"has":11,"has-symbols":9}],9:[function(require,module,exports){
'use strict';

var origSymbol = typeof Symbol !== 'undefined' && Symbol;
var hasSymbolSham = require('./shams');

module.exports = function hasNativeSymbols() {
	if (typeof origSymbol !== 'function') { return false; }
	if (typeof Symbol !== 'function') { return false; }
	if (typeof origSymbol('foo') !== 'symbol') { return false; }
	if (typeof Symbol('bar') !== 'symbol') { return false; }

	return hasSymbolSham();
};

},{"./shams":10}],10:[function(require,module,exports){
'use strict';

/* eslint complexity: [2, 18], max-statements: [2, 33] */
module.exports = function hasSymbols() {
	if (typeof Symbol !== 'function' || typeof Object.getOwnPropertySymbols !== 'function') { return false; }
	if (typeof Symbol.iterator === 'symbol') { return true; }

	var obj = {};
	var sym = Symbol('test');
	var symObj = Object(sym);
	if (typeof sym === 'string') { return false; }

	if (Object.prototype.toString.call(sym) !== '[object Symbol]') { return false; }
	if (Object.prototype.toString.call(symObj) !== '[object Symbol]') { return false; }

	// temp disabled per https://github.com/ljharb/object.assign/issues/17
	// if (sym instanceof Symbol) { return false; }
	// temp disabled per https://github.com/WebReflection/get-own-property-symbols/issues/4
	// if (!(symObj instanceof Symbol)) { return false; }

	// if (typeof Symbol.prototype.toString !== 'function') { return false; }
	// if (String(sym) !== Symbol.prototype.toString.call(sym)) { return false; }

	var symVal = 42;
	obj[sym] = symVal;
	for (sym in obj) { return false; } // eslint-disable-line no-restricted-syntax, no-unreachable-loop
	if (typeof Object.keys === 'function' && Object.keys(obj).length !== 0) { return false; }

	if (typeof Object.getOwnPropertyNames === 'function' && Object.getOwnPropertyNames(obj).length !== 0) { return false; }

	var syms = Object.getOwnPropertySymbols(obj);
	if (syms.length !== 1 || syms[0] !== sym) { return false; }

	if (!Object.prototype.propertyIsEnumerable.call(obj, sym)) { return false; }

	if (typeof Object.getOwnPropertyDescriptor === 'function') {
		var descriptor = Object.getOwnPropertyDescriptor(obj, sym);
		if (descriptor.value !== symVal || descriptor.enumerable !== true) { return false; }
	}

	return true;
};

},{}],11:[function(require,module,exports){
'use strict';

var bind = require('function-bind');

module.exports = bind.call(Function.call, Object.prototype.hasOwnProperty);

},{"function-bind":7}],12:[function(require,module,exports){
if (typeof Object.create === 'function') {
  // implementation from standard node.js 'util' module
  module.exports = function inherits(ctor, superCtor) {
    if (superCtor) {
      ctor.super_ = superCtor
      ctor.prototype = Object.create(superCtor.prototype, {
        constructor: {
          value: ctor,
          enumerable: false,
          writable: true,
          configurable: true
        }
      })
    }
  };
} else {
  // old school shim for old browsers
  module.exports = function inherits(ctor, superCtor) {
    if (superCtor) {
      ctor.super_ = superCtor
      var TempCtor = function () {}
      TempCtor.prototype = superCtor.prototype
      ctor.prototype = new TempCtor()
      ctor.prototype.constructor = ctor
    }
  }
}

},{}],13:[function(require,module,exports){
'use strict';

var hasToStringTag = typeof Symbol === 'function' && typeof Symbol.toStringTag === 'symbol';
var callBound = require('call-bind/callBound');

var $toString = callBound('Object.prototype.toString');

var isStandardArguments = function isArguments(value) {
	if (hasToStringTag && value && typeof value === 'object' && Symbol.toStringTag in value) {
		return false;
	}
	return $toString(value) === '[object Arguments]';
};

var isLegacyArguments = function isArguments(value) {
	if (isStandardArguments(value)) {
		return true;
	}
	return value !== null &&
		typeof value === 'object' &&
		typeof value.length === 'number' &&
		value.length >= 0 &&
		$toString(value) !== '[object Array]' &&
		$toString(value.callee) === '[object Function]';
};

var supportsStandardArguments = (function () {
	return isStandardArguments(arguments);
}());

isStandardArguments.isLegacyArguments = isLegacyArguments; // for tests

module.exports = supportsStandardArguments ? isStandardArguments : isLegacyArguments;

},{"call-bind/callBound":2}],14:[function(require,module,exports){
'use strict';

var toStr = Object.prototype.toString;
var fnToStr = Function.prototype.toString;
var isFnRegex = /^\s*(?:function)?\*/;
var hasToStringTag = typeof Symbol === 'function' && typeof Symbol.toStringTag === 'symbol';
var getProto = Object.getPrototypeOf;
var getGeneratorFunc = function () { // eslint-disable-line consistent-return
	if (!hasToStringTag) {
		return false;
	}
	try {
		return Function('return function*() {}')();
	} catch (e) {
	}
};
var GeneratorFunction;

module.exports = function isGeneratorFunction(fn) {
	if (typeof fn !== 'function') {
		return false;
	}
	if (isFnRegex.test(fnToStr.call(fn))) {
		return true;
	}
	if (!hasToStringTag) {
		var str = toStr.call(fn);
		return str === '[object GeneratorFunction]';
	}
	if (!getProto) {
		return false;
	}
	if (typeof GeneratorFunction === 'undefined') {
		var generatorFunc = getGeneratorFunc();
		GeneratorFunction = generatorFunc ? getProto(generatorFunc) : false;
	}
	return getProto(fn) === GeneratorFunction;
};

},{}],15:[function(require,module,exports){
(function (global){(function (){
'use strict';

var forEach = require('foreach');
var availableTypedArrays = require('available-typed-arrays');
var callBound = require('call-bind/callBound');

var $toString = callBound('Object.prototype.toString');
var hasSymbols = require('has-symbols')();
var hasToStringTag = hasSymbols && typeof Symbol.toStringTag === 'symbol';

var typedArrays = availableTypedArrays();

var $indexOf = callBound('Array.prototype.indexOf', true) || function indexOf(array, value) {
	for (var i = 0; i < array.length; i += 1) {
		if (array[i] === value) {
			return i;
		}
	}
	return -1;
};
var $slice = callBound('String.prototype.slice');
var toStrTags = {};
var gOPD = require('es-abstract/helpers/getOwnPropertyDescriptor');
var getPrototypeOf = Object.getPrototypeOf; // require('getprototypeof');
if (hasToStringTag && gOPD && getPrototypeOf) {
	forEach(typedArrays, function (typedArray) {
		var arr = new global[typedArray]();
		if (!(Symbol.toStringTag in arr)) {
			throw new EvalError('this engine has support for Symbol.toStringTag, but ' + typedArray + ' does not have the property! Please report this.');
		}
		var proto = getPrototypeOf(arr);
		var descriptor = gOPD(proto, Symbol.toStringTag);
		if (!descriptor) {
			var superProto = getPrototypeOf(proto);
			descriptor = gOPD(superProto, Symbol.toStringTag);
		}
		toStrTags[typedArray] = descriptor.get;
	});
}

var tryTypedArrays = function tryAllTypedArrays(value) {
	var anyTrue = false;
	forEach(toStrTags, function (getter, typedArray) {
		if (!anyTrue) {
			try {
				anyTrue = getter.call(value) === typedArray;
			} catch (e) { /**/ }
		}
	});
	return anyTrue;
};

module.exports = function isTypedArray(value) {
	if (!value || typeof value !== 'object') { return false; }
	if (!hasToStringTag) {
		var tag = $slice($toString(value), 8, -1);
		return $indexOf(typedArrays, tag) > -1;
	}
	if (!gOPD) { return false; }
	return tryTypedArrays(value);
};

}).call(this)}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"available-typed-arrays":1,"call-bind/callBound":2,"es-abstract/helpers/getOwnPropertyDescriptor":4,"foreach":5,"has-symbols":9}],16:[function(require,module,exports){
// shim for using process in browser
var process = module.exports = {};

// cached from whatever global is present so that test runners that stub it
// don't break things.  But we need to wrap it in a try catch in case it is
// wrapped in strict mode code which doesn't define any globals.  It's inside a
// function because try/catches deoptimize in certain engines.

var cachedSetTimeout;
var cachedClearTimeout;

function defaultSetTimout() {
    throw new Error('setTimeout has not been defined');
}
function defaultClearTimeout () {
    throw new Error('clearTimeout has not been defined');
}
(function () {
    try {
        if (typeof setTimeout === 'function') {
            cachedSetTimeout = setTimeout;
        } else {
            cachedSetTimeout = defaultSetTimout;
        }
    } catch (e) {
        cachedSetTimeout = defaultSetTimout;
    }
    try {
        if (typeof clearTimeout === 'function') {
            cachedClearTimeout = clearTimeout;
        } else {
            cachedClearTimeout = defaultClearTimeout;
        }
    } catch (e) {
        cachedClearTimeout = defaultClearTimeout;
    }
} ())
function runTimeout(fun) {
    if (cachedSetTimeout === setTimeout) {
        //normal enviroments in sane situations
        return setTimeout(fun, 0);
    }
    // if setTimeout wasn't available but was latter defined
    if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
        cachedSetTimeout = setTimeout;
        return setTimeout(fun, 0);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedSetTimeout(fun, 0);
    } catch(e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
            return cachedSetTimeout.call(null, fun, 0);
        } catch(e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
            return cachedSetTimeout.call(this, fun, 0);
        }
    }


}
function runClearTimeout(marker) {
    if (cachedClearTimeout === clearTimeout) {
        //normal enviroments in sane situations
        return clearTimeout(marker);
    }
    // if clearTimeout wasn't available but was latter defined
    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
        cachedClearTimeout = clearTimeout;
        return clearTimeout(marker);
    }
    try {
        // when when somebody has screwed with setTimeout but no I.E. maddness
        return cachedClearTimeout(marker);
    } catch (e){
        try {
            // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
            return cachedClearTimeout.call(null, marker);
        } catch (e){
            // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
            // Some versions of I.E. have different rules for clearTimeout vs setTimeout
            return cachedClearTimeout.call(this, marker);
        }
    }



}
var queue = [];
var draining = false;
var currentQueue;
var queueIndex = -1;

function cleanUpNextTick() {
    if (!draining || !currentQueue) {
        return;
    }
    draining = false;
    if (currentQueue.length) {
        queue = currentQueue.concat(queue);
    } else {
        queueIndex = -1;
    }
    if (queue.length) {
        drainQueue();
    }
}

function drainQueue() {
    if (draining) {
        return;
    }
    var timeout = runTimeout(cleanUpNextTick);
    draining = true;

    var len = queue.length;
    while(len) {
        currentQueue = queue;
        queue = [];
        while (++queueIndex < len) {
            if (currentQueue) {
                currentQueue[queueIndex].run();
            }
        }
        queueIndex = -1;
        len = queue.length;
    }
    currentQueue = null;
    draining = false;
    runClearTimeout(timeout);
}

process.nextTick = function (fun) {
    var args = new Array(arguments.length - 1);
    if (arguments.length > 1) {
        for (var i = 1; i < arguments.length; i++) {
            args[i - 1] = arguments[i];
        }
    }
    queue.push(new Item(fun, args));
    if (queue.length === 1 && !draining) {
        runTimeout(drainQueue);
    }
};

// v8 likes predictible objects
function Item(fun, array) {
    this.fun = fun;
    this.array = array;
}
Item.prototype.run = function () {
    this.fun.apply(null, this.array);
};
process.title = 'browser';
process.browser = true;
process.env = {};
process.argv = [];
process.version = ''; // empty string to avoid regexp issues
process.versions = {};

function noop() {}

process.on = noop;
process.addListener = noop;
process.once = noop;
process.off = noop;
process.removeListener = noop;
process.removeAllListeners = noop;
process.emit = noop;
process.prependListener = noop;
process.prependOnceListener = noop;

process.listeners = function (name) { return [] }

process.binding = function (name) {
    throw new Error('process.binding is not supported');
};

process.cwd = function () { return '/' };
process.chdir = function (dir) {
    throw new Error('process.chdir is not supported');
};
process.umask = function() { return 0; };

},{}],17:[function(require,module,exports){
module.exports = function isBuffer(arg) {
  return arg && typeof arg === 'object'
    && typeof arg.copy === 'function'
    && typeof arg.fill === 'function'
    && typeof arg.readUInt8 === 'function';
}
},{}],18:[function(require,module,exports){
// Currently in sync with Node.js lib/internal/util/types.js
// https://github.com/nodejs/node/commit/112cc7c27551254aa2b17098fb774867f05ed0d9

'use strict';

var isArgumentsObject = require('is-arguments');
var isGeneratorFunction = require('is-generator-function');
var whichTypedArray = require('which-typed-array');
var isTypedArray = require('is-typed-array');

function uncurryThis(f) {
  return f.call.bind(f);
}

var BigIntSupported = typeof BigInt !== 'undefined';
var SymbolSupported = typeof Symbol !== 'undefined';

var ObjectToString = uncurryThis(Object.prototype.toString);

var numberValue = uncurryThis(Number.prototype.valueOf);
var stringValue = uncurryThis(String.prototype.valueOf);
var booleanValue = uncurryThis(Boolean.prototype.valueOf);

if (BigIntSupported) {
  var bigIntValue = uncurryThis(BigInt.prototype.valueOf);
}

if (SymbolSupported) {
  var symbolValue = uncurryThis(Symbol.prototype.valueOf);
}

function checkBoxedPrimitive(value, prototypeValueOf) {
  if (typeof value !== 'object') {
    return false;
  }
  try {
    prototypeValueOf(value);
    return true;
  } catch(e) {
    return false;
  }
}

exports.isArgumentsObject = isArgumentsObject;
exports.isGeneratorFunction = isGeneratorFunction;
exports.isTypedArray = isTypedArray;

// Taken from here and modified for better browser support
// https://github.com/sindresorhus/p-is-promise/blob/cda35a513bda03f977ad5cde3a079d237e82d7ef/index.js
function isPromise(input) {
	return (
		(
			typeof Promise !== 'undefined' &&
			input instanceof Promise
		) ||
		(
			input !== null &&
			typeof input === 'object' &&
			typeof input.then === 'function' &&
			typeof input.catch === 'function'
		)
	);
}
exports.isPromise = isPromise;

function isArrayBufferView(value) {
  if (typeof ArrayBuffer !== 'undefined' && ArrayBuffer.isView) {
    return ArrayBuffer.isView(value);
  }

  return (
    isTypedArray(value) ||
    isDataView(value)
  );
}
exports.isArrayBufferView = isArrayBufferView;


function isUint8Array(value) {
  return whichTypedArray(value) === 'Uint8Array';
}
exports.isUint8Array = isUint8Array;

function isUint8ClampedArray(value) {
  return whichTypedArray(value) === 'Uint8ClampedArray';
}
exports.isUint8ClampedArray = isUint8ClampedArray;

function isUint16Array(value) {
  return whichTypedArray(value) === 'Uint16Array';
}
exports.isUint16Array = isUint16Array;

function isUint32Array(value) {
  return whichTypedArray(value) === 'Uint32Array';
}
exports.isUint32Array = isUint32Array;

function isInt8Array(value) {
  return whichTypedArray(value) === 'Int8Array';
}
exports.isInt8Array = isInt8Array;

function isInt16Array(value) {
  return whichTypedArray(value) === 'Int16Array';
}
exports.isInt16Array = isInt16Array;

function isInt32Array(value) {
  return whichTypedArray(value) === 'Int32Array';
}
exports.isInt32Array = isInt32Array;

function isFloat32Array(value) {
  return whichTypedArray(value) === 'Float32Array';
}
exports.isFloat32Array = isFloat32Array;

function isFloat64Array(value) {
  return whichTypedArray(value) === 'Float64Array';
}
exports.isFloat64Array = isFloat64Array;

function isBigInt64Array(value) {
  return whichTypedArray(value) === 'BigInt64Array';
}
exports.isBigInt64Array = isBigInt64Array;

function isBigUint64Array(value) {
  return whichTypedArray(value) === 'BigUint64Array';
}
exports.isBigUint64Array = isBigUint64Array;

function isMapToString(value) {
  return ObjectToString(value) === '[object Map]';
}
isMapToString.working = (
  typeof Map !== 'undefined' &&
  isMapToString(new Map())
);

function isMap(value) {
  if (typeof Map === 'undefined') {
    return false;
  }

  return isMapToString.working
    ? isMapToString(value)
    : value instanceof Map;
}
exports.isMap = isMap;

function isSetToString(value) {
  return ObjectToString(value) === '[object Set]';
}
isSetToString.working = (
  typeof Set !== 'undefined' &&
  isSetToString(new Set())
);
function isSet(value) {
  if (typeof Set === 'undefined') {
    return false;
  }

  return isSetToString.working
    ? isSetToString(value)
    : value instanceof Set;
}
exports.isSet = isSet;

function isWeakMapToString(value) {
  return ObjectToString(value) === '[object WeakMap]';
}
isWeakMapToString.working = (
  typeof WeakMap !== 'undefined' &&
  isWeakMapToString(new WeakMap())
);
function isWeakMap(value) {
  if (typeof WeakMap === 'undefined') {
    return false;
  }

  return isWeakMapToString.working
    ? isWeakMapToString(value)
    : value instanceof WeakMap;
}
exports.isWeakMap = isWeakMap;

function isWeakSetToString(value) {
  return ObjectToString(value) === '[object WeakSet]';
}
isWeakSetToString.working = (
  typeof WeakSet !== 'undefined' &&
  isWeakSetToString(new WeakSet())
);
function isWeakSet(value) {
  return isWeakSetToString(value);
}
exports.isWeakSet = isWeakSet;

function isArrayBufferToString(value) {
  return ObjectToString(value) === '[object ArrayBuffer]';
}
isArrayBufferToString.working = (
  typeof ArrayBuffer !== 'undefined' &&
  isArrayBufferToString(new ArrayBuffer())
);
function isArrayBuffer(value) {
  if (typeof ArrayBuffer === 'undefined') {
    return false;
  }

  return isArrayBufferToString.working
    ? isArrayBufferToString(value)
    : value instanceof ArrayBuffer;
}
exports.isArrayBuffer = isArrayBuffer;

function isDataViewToString(value) {
  return ObjectToString(value) === '[object DataView]';
}
isDataViewToString.working = (
  typeof ArrayBuffer !== 'undefined' &&
  typeof DataView !== 'undefined' &&
  isDataViewToString(new DataView(new ArrayBuffer(1), 0, 1))
);
function isDataView(value) {
  if (typeof DataView === 'undefined') {
    return false;
  }

  return isDataViewToString.working
    ? isDataViewToString(value)
    : value instanceof DataView;
}
exports.isDataView = isDataView;

// Store a copy of SharedArrayBuffer in case it's deleted elsewhere
var SharedArrayBufferCopy = typeof SharedArrayBuffer !== 'undefined' ? SharedArrayBuffer : undefined;
function isSharedArrayBufferToString(value) {
  return ObjectToString(value) === '[object SharedArrayBuffer]';
}
function isSharedArrayBuffer(value) {
  if (typeof SharedArrayBufferCopy === 'undefined') {
    return false;
  }

  if (typeof isSharedArrayBufferToString.working === 'undefined') {
    isSharedArrayBufferToString.working = isSharedArrayBufferToString(new SharedArrayBufferCopy());
  }

  return isSharedArrayBufferToString.working
    ? isSharedArrayBufferToString(value)
    : value instanceof SharedArrayBufferCopy;
}
exports.isSharedArrayBuffer = isSharedArrayBuffer;

function isAsyncFunction(value) {
  return ObjectToString(value) === '[object AsyncFunction]';
}
exports.isAsyncFunction = isAsyncFunction;

function isMapIterator(value) {
  return ObjectToString(value) === '[object Map Iterator]';
}
exports.isMapIterator = isMapIterator;

function isSetIterator(value) {
  return ObjectToString(value) === '[object Set Iterator]';
}
exports.isSetIterator = isSetIterator;

function isGeneratorObject(value) {
  return ObjectToString(value) === '[object Generator]';
}
exports.isGeneratorObject = isGeneratorObject;

function isWebAssemblyCompiledModule(value) {
  return ObjectToString(value) === '[object WebAssembly.Module]';
}
exports.isWebAssemblyCompiledModule = isWebAssemblyCompiledModule;

function isNumberObject(value) {
  return checkBoxedPrimitive(value, numberValue);
}
exports.isNumberObject = isNumberObject;

function isStringObject(value) {
  return checkBoxedPrimitive(value, stringValue);
}
exports.isStringObject = isStringObject;

function isBooleanObject(value) {
  return checkBoxedPrimitive(value, booleanValue);
}
exports.isBooleanObject = isBooleanObject;

function isBigIntObject(value) {
  return BigIntSupported && checkBoxedPrimitive(value, bigIntValue);
}
exports.isBigIntObject = isBigIntObject;

function isSymbolObject(value) {
  return SymbolSupported && checkBoxedPrimitive(value, symbolValue);
}
exports.isSymbolObject = isSymbolObject;

function isBoxedPrimitive(value) {
  return (
    isNumberObject(value) ||
    isStringObject(value) ||
    isBooleanObject(value) ||
    isBigIntObject(value) ||
    isSymbolObject(value)
  );
}
exports.isBoxedPrimitive = isBoxedPrimitive;

function isAnyArrayBuffer(value) {
  return typeof Uint8Array !== 'undefined' && (
    isArrayBuffer(value) ||
    isSharedArrayBuffer(value)
  );
}
exports.isAnyArrayBuffer = isAnyArrayBuffer;

['isProxy', 'isExternal', 'isModuleNamespaceObject'].forEach(function(method) {
  Object.defineProperty(exports, method, {
    enumerable: false,
    value: function() {
      throw new Error(method + ' is not supported in userland');
    }
  });
});

},{"is-arguments":13,"is-generator-function":14,"is-typed-array":15,"which-typed-array":20}],19:[function(require,module,exports){
(function (process){(function (){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

var getOwnPropertyDescriptors = Object.getOwnPropertyDescriptors ||
  function getOwnPropertyDescriptors(obj) {
    var keys = Object.keys(obj);
    var descriptors = {};
    for (var i = 0; i < keys.length; i++) {
      descriptors[keys[i]] = Object.getOwnPropertyDescriptor(obj, keys[i]);
    }
    return descriptors;
  };

var formatRegExp = /%[sdj%]/g;
exports.format = function(f) {
  if (!isString(f)) {
    var objects = [];
    for (var i = 0; i < arguments.length; i++) {
      objects.push(inspect(arguments[i]));
    }
    return objects.join(' ');
  }

  var i = 1;
  var args = arguments;
  var len = args.length;
  var str = String(f).replace(formatRegExp, function(x) {
    if (x === '%%') return '%';
    if (i >= len) return x;
    switch (x) {
      case '%s': return String(args[i++]);
      case '%d': return Number(args[i++]);
      case '%j':
        try {
          return JSON.stringify(args[i++]);
        } catch (_) {
          return '[Circular]';
        }
      default:
        return x;
    }
  });
  for (var x = args[i]; i < len; x = args[++i]) {
    if (isNull(x) || !isObject(x)) {
      str += ' ' + x;
    } else {
      str += ' ' + inspect(x);
    }
  }
  return str;
};


// Mark that a method should not be used.
// Returns a modified function which warns once by default.
// If --no-deprecation is set, then it is a no-op.
exports.deprecate = function(fn, msg) {
  if (typeof process !== 'undefined' && process.noDeprecation === true) {
    return fn;
  }

  // Allow for deprecating things in the process of starting up.
  if (typeof process === 'undefined') {
    return function() {
      return exports.deprecate(fn, msg).apply(this, arguments);
    };
  }

  var warned = false;
  function deprecated() {
    if (!warned) {
      if (process.throwDeprecation) {
        throw new Error(msg);
      } else if (process.traceDeprecation) {
        console.trace(msg);
      } else {
        console.error(msg);
      }
      warned = true;
    }
    return fn.apply(this, arguments);
  }

  return deprecated;
};


var debugs = {};
var debugEnvRegex = /^$/;

if (process.env.NODE_DEBUG) {
  var debugEnv = process.env.NODE_DEBUG;
  debugEnv = debugEnv.replace(/[|\\{}()[\]^$+?.]/g, '\\$&')
    .replace(/\*/g, '.*')
    .replace(/,/g, '$|^')
    .toUpperCase();
  debugEnvRegex = new RegExp('^' + debugEnv + '$', 'i');
}
exports.debuglog = function(set) {
  set = set.toUpperCase();
  if (!debugs[set]) {
    if (debugEnvRegex.test(set)) {
      var pid = process.pid;
      debugs[set] = function() {
        var msg = exports.format.apply(exports, arguments);
        console.error('%s %d: %s', set, pid, msg);
      };
    } else {
      debugs[set] = function() {};
    }
  }
  return debugs[set];
};


/**
 * Echos the value of a value. Trys to print the value out
 * in the best way possible given the different types.
 *
 * @param {Object} obj The object to print out.
 * @param {Object} opts Optional options object that alters the output.
 */
/* legacy: obj, showHidden, depth, colors*/
function inspect(obj, opts) {
  // default options
  var ctx = {
    seen: [],
    stylize: stylizeNoColor
  };
  // legacy...
  if (arguments.length >= 3) ctx.depth = arguments[2];
  if (arguments.length >= 4) ctx.colors = arguments[3];
  if (isBoolean(opts)) {
    // legacy...
    ctx.showHidden = opts;
  } else if (opts) {
    // got an "options" object
    exports._extend(ctx, opts);
  }
  // set default options
  if (isUndefined(ctx.showHidden)) ctx.showHidden = false;
  if (isUndefined(ctx.depth)) ctx.depth = 2;
  if (isUndefined(ctx.colors)) ctx.colors = false;
  if (isUndefined(ctx.customInspect)) ctx.customInspect = true;
  if (ctx.colors) ctx.stylize = stylizeWithColor;
  return formatValue(ctx, obj, ctx.depth);
}
exports.inspect = inspect;


// http://en.wikipedia.org/wiki/ANSI_escape_code#graphics
inspect.colors = {
  'bold' : [1, 22],
  'italic' : [3, 23],
  'underline' : [4, 24],
  'inverse' : [7, 27],
  'white' : [37, 39],
  'grey' : [90, 39],
  'black' : [30, 39],
  'blue' : [34, 39],
  'cyan' : [36, 39],
  'green' : [32, 39],
  'magenta' : [35, 39],
  'red' : [31, 39],
  'yellow' : [33, 39]
};

// Don't use 'blue' not visible on cmd.exe
inspect.styles = {
  'special': 'cyan',
  'number': 'yellow',
  'boolean': 'yellow',
  'undefined': 'grey',
  'null': 'bold',
  'string': 'green',
  'date': 'magenta',
  // "name": intentionally not styling
  'regexp': 'red'
};


function stylizeWithColor(str, styleType) {
  var style = inspect.styles[styleType];

  if (style) {
    return '\u001b[' + inspect.colors[style][0] + 'm' + str +
           '\u001b[' + inspect.colors[style][1] + 'm';
  } else {
    return str;
  }
}


function stylizeNoColor(str, styleType) {
  return str;
}


function arrayToHash(array) {
  var hash = {};

  array.forEach(function(val, idx) {
    hash[val] = true;
  });

  return hash;
}


function formatValue(ctx, value, recurseTimes) {
  // Provide a hook for user-specified inspect functions.
  // Check that value is an object with an inspect function on it
  if (ctx.customInspect &&
      value &&
      isFunction(value.inspect) &&
      // Filter out the util module, it's inspect function is special
      value.inspect !== exports.inspect &&
      // Also filter out any prototype objects using the circular check.
      !(value.constructor && value.constructor.prototype === value)) {
    var ret = value.inspect(recurseTimes, ctx);
    if (!isString(ret)) {
      ret = formatValue(ctx, ret, recurseTimes);
    }
    return ret;
  }

  // Primitive types cannot have properties
  var primitive = formatPrimitive(ctx, value);
  if (primitive) {
    return primitive;
  }

  // Look up the keys of the object.
  var keys = Object.keys(value);
  var visibleKeys = arrayToHash(keys);

  if (ctx.showHidden) {
    keys = Object.getOwnPropertyNames(value);
  }

  // IE doesn't make error fields non-enumerable
  // http://msdn.microsoft.com/en-us/library/ie/dww52sbt(v=vs.94).aspx
  if (isError(value)
      && (keys.indexOf('message') >= 0 || keys.indexOf('description') >= 0)) {
    return formatError(value);
  }

  // Some type of object without properties can be shortcutted.
  if (keys.length === 0) {
    if (isFunction(value)) {
      var name = value.name ? ': ' + value.name : '';
      return ctx.stylize('[Function' + name + ']', 'special');
    }
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    }
    if (isDate(value)) {
      return ctx.stylize(Date.prototype.toString.call(value), 'date');
    }
    if (isError(value)) {
      return formatError(value);
    }
  }

  var base = '', array = false, braces = ['{', '}'];

  // Make Array say that they are Array
  if (isArray(value)) {
    array = true;
    braces = ['[', ']'];
  }

  // Make functions say that they are functions
  if (isFunction(value)) {
    var n = value.name ? ': ' + value.name : '';
    base = ' [Function' + n + ']';
  }

  // Make RegExps say that they are RegExps
  if (isRegExp(value)) {
    base = ' ' + RegExp.prototype.toString.call(value);
  }

  // Make dates with properties first say the date
  if (isDate(value)) {
    base = ' ' + Date.prototype.toUTCString.call(value);
  }

  // Make error with message first say the error
  if (isError(value)) {
    base = ' ' + formatError(value);
  }

  if (keys.length === 0 && (!array || value.length == 0)) {
    return braces[0] + base + braces[1];
  }

  if (recurseTimes < 0) {
    if (isRegExp(value)) {
      return ctx.stylize(RegExp.prototype.toString.call(value), 'regexp');
    } else {
      return ctx.stylize('[Object]', 'special');
    }
  }

  ctx.seen.push(value);

  var output;
  if (array) {
    output = formatArray(ctx, value, recurseTimes, visibleKeys, keys);
  } else {
    output = keys.map(function(key) {
      return formatProperty(ctx, value, recurseTimes, visibleKeys, key, array);
    });
  }

  ctx.seen.pop();

  return reduceToSingleString(output, base, braces);
}


function formatPrimitive(ctx, value) {
  if (isUndefined(value))
    return ctx.stylize('undefined', 'undefined');
  if (isString(value)) {
    var simple = '\'' + JSON.stringify(value).replace(/^"|"$/g, '')
                                             .replace(/'/g, "\\'")
                                             .replace(/\\"/g, '"') + '\'';
    return ctx.stylize(simple, 'string');
  }
  if (isNumber(value))
    return ctx.stylize('' + value, 'number');
  if (isBoolean(value))
    return ctx.stylize('' + value, 'boolean');
  // For some reason typeof null is "object", so special case here.
  if (isNull(value))
    return ctx.stylize('null', 'null');
}


function formatError(value) {
  return '[' + Error.prototype.toString.call(value) + ']';
}


function formatArray(ctx, value, recurseTimes, visibleKeys, keys) {
  var output = [];
  for (var i = 0, l = value.length; i < l; ++i) {
    if (hasOwnProperty(value, String(i))) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          String(i), true));
    } else {
      output.push('');
    }
  }
  keys.forEach(function(key) {
    if (!key.match(/^\d+$/)) {
      output.push(formatProperty(ctx, value, recurseTimes, visibleKeys,
          key, true));
    }
  });
  return output;
}


function formatProperty(ctx, value, recurseTimes, visibleKeys, key, array) {
  var name, str, desc;
  desc = Object.getOwnPropertyDescriptor(value, key) || { value: value[key] };
  if (desc.get) {
    if (desc.set) {
      str = ctx.stylize('[Getter/Setter]', 'special');
    } else {
      str = ctx.stylize('[Getter]', 'special');
    }
  } else {
    if (desc.set) {
      str = ctx.stylize('[Setter]', 'special');
    }
  }
  if (!hasOwnProperty(visibleKeys, key)) {
    name = '[' + key + ']';
  }
  if (!str) {
    if (ctx.seen.indexOf(desc.value) < 0) {
      if (isNull(recurseTimes)) {
        str = formatValue(ctx, desc.value, null);
      } else {
        str = formatValue(ctx, desc.value, recurseTimes - 1);
      }
      if (str.indexOf('\n') > -1) {
        if (array) {
          str = str.split('\n').map(function(line) {
            return '  ' + line;
          }).join('\n').substr(2);
        } else {
          str = '\n' + str.split('\n').map(function(line) {
            return '   ' + line;
          }).join('\n');
        }
      }
    } else {
      str = ctx.stylize('[Circular]', 'special');
    }
  }
  if (isUndefined(name)) {
    if (array && key.match(/^\d+$/)) {
      return str;
    }
    name = JSON.stringify('' + key);
    if (name.match(/^"([a-zA-Z_][a-zA-Z_0-9]*)"$/)) {
      name = name.substr(1, name.length - 2);
      name = ctx.stylize(name, 'name');
    } else {
      name = name.replace(/'/g, "\\'")
                 .replace(/\\"/g, '"')
                 .replace(/(^"|"$)/g, "'");
      name = ctx.stylize(name, 'string');
    }
  }

  return name + ': ' + str;
}


function reduceToSingleString(output, base, braces) {
  var numLinesEst = 0;
  var length = output.reduce(function(prev, cur) {
    numLinesEst++;
    if (cur.indexOf('\n') >= 0) numLinesEst++;
    return prev + cur.replace(/\u001b\[\d\d?m/g, '').length + 1;
  }, 0);

  if (length > 60) {
    return braces[0] +
           (base === '' ? '' : base + '\n ') +
           ' ' +
           output.join(',\n  ') +
           ' ' +
           braces[1];
  }

  return braces[0] + base + ' ' + output.join(', ') + ' ' + braces[1];
}


// NOTE: These type checking functions intentionally don't use `instanceof`
// because it is fragile and can be easily faked with `Object.create()`.
exports.types = require('./support/types');

function isArray(ar) {
  return Array.isArray(ar);
}
exports.isArray = isArray;

function isBoolean(arg) {
  return typeof arg === 'boolean';
}
exports.isBoolean = isBoolean;

function isNull(arg) {
  return arg === null;
}
exports.isNull = isNull;

function isNullOrUndefined(arg) {
  return arg == null;
}
exports.isNullOrUndefined = isNullOrUndefined;

function isNumber(arg) {
  return typeof arg === 'number';
}
exports.isNumber = isNumber;

function isString(arg) {
  return typeof arg === 'string';
}
exports.isString = isString;

function isSymbol(arg) {
  return typeof arg === 'symbol';
}
exports.isSymbol = isSymbol;

function isUndefined(arg) {
  return arg === void 0;
}
exports.isUndefined = isUndefined;

function isRegExp(re) {
  return isObject(re) && objectToString(re) === '[object RegExp]';
}
exports.isRegExp = isRegExp;
exports.types.isRegExp = isRegExp;

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}
exports.isObject = isObject;

function isDate(d) {
  return isObject(d) && objectToString(d) === '[object Date]';
}
exports.isDate = isDate;
exports.types.isDate = isDate;

function isError(e) {
  return isObject(e) &&
      (objectToString(e) === '[object Error]' || e instanceof Error);
}
exports.isError = isError;
exports.types.isNativeError = isError;

function isFunction(arg) {
  return typeof arg === 'function';
}
exports.isFunction = isFunction;

function isPrimitive(arg) {
  return arg === null ||
         typeof arg === 'boolean' ||
         typeof arg === 'number' ||
         typeof arg === 'string' ||
         typeof arg === 'symbol' ||  // ES6 symbol
         typeof arg === 'undefined';
}
exports.isPrimitive = isPrimitive;

exports.isBuffer = require('./support/isBuffer');

function objectToString(o) {
  return Object.prototype.toString.call(o);
}


function pad(n) {
  return n < 10 ? '0' + n.toString(10) : n.toString(10);
}


var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep',
              'Oct', 'Nov', 'Dec'];

// 26 Feb 16:19:34
function timestamp() {
  var d = new Date();
  var time = [pad(d.getHours()),
              pad(d.getMinutes()),
              pad(d.getSeconds())].join(':');
  return [d.getDate(), months[d.getMonth()], time].join(' ');
}


// log is just a thin wrapper to console.log that prepends a timestamp
exports.log = function() {
  console.log('%s - %s', timestamp(), exports.format.apply(exports, arguments));
};


/**
 * Inherit the prototype methods from one constructor into another.
 *
 * The Function.prototype.inherits from lang.js rewritten as a standalone
 * function (not on Function.prototype). NOTE: If this file is to be loaded
 * during bootstrapping this function needs to be rewritten using some native
 * functions as prototype setup using normal JavaScript does not work as
 * expected during bootstrapping (see mirror.js in r114903).
 *
 * @param {function} ctor Constructor function which needs to inherit the
 *     prototype.
 * @param {function} superCtor Constructor function to inherit prototype from.
 */
exports.inherits = require('inherits');

exports._extend = function(origin, add) {
  // Don't do anything if add isn't an object
  if (!add || !isObject(add)) return origin;

  var keys = Object.keys(add);
  var i = keys.length;
  while (i--) {
    origin[keys[i]] = add[keys[i]];
  }
  return origin;
};

function hasOwnProperty(obj, prop) {
  return Object.prototype.hasOwnProperty.call(obj, prop);
}

var kCustomPromisifiedSymbol = typeof Symbol !== 'undefined' ? Symbol('util.promisify.custom') : undefined;

exports.promisify = function promisify(original) {
  if (typeof original !== 'function')
    throw new TypeError('The "original" argument must be of type Function');

  if (kCustomPromisifiedSymbol && original[kCustomPromisifiedSymbol]) {
    var fn = original[kCustomPromisifiedSymbol];
    if (typeof fn !== 'function') {
      throw new TypeError('The "util.promisify.custom" argument must be of type Function');
    }
    Object.defineProperty(fn, kCustomPromisifiedSymbol, {
      value: fn, enumerable: false, writable: false, configurable: true
    });
    return fn;
  }

  function fn() {
    var promiseResolve, promiseReject;
    var promise = new Promise(function (resolve, reject) {
      promiseResolve = resolve;
      promiseReject = reject;
    });

    var args = [];
    for (var i = 0; i < arguments.length; i++) {
      args.push(arguments[i]);
    }
    args.push(function (err, value) {
      if (err) {
        promiseReject(err);
      } else {
        promiseResolve(value);
      }
    });

    try {
      original.apply(this, args);
    } catch (err) {
      promiseReject(err);
    }

    return promise;
  }

  Object.setPrototypeOf(fn, Object.getPrototypeOf(original));

  if (kCustomPromisifiedSymbol) Object.defineProperty(fn, kCustomPromisifiedSymbol, {
    value: fn, enumerable: false, writable: false, configurable: true
  });
  return Object.defineProperties(
    fn,
    getOwnPropertyDescriptors(original)
  );
}

exports.promisify.custom = kCustomPromisifiedSymbol

function callbackifyOnRejected(reason, cb) {
  // `!reason` guard inspired by bluebird (Ref: https://goo.gl/t5IS6M).
  // Because `null` is a special error value in callbacks which means "no error
  // occurred", we error-wrap so the callback consumer can distinguish between
  // "the promise rejected with null" or "the promise fulfilled with undefined".
  if (!reason) {
    var newReason = new Error('Promise was rejected with a falsy value');
    newReason.reason = reason;
    reason = newReason;
  }
  return cb(reason);
}

function callbackify(original) {
  if (typeof original !== 'function') {
    throw new TypeError('The "original" argument must be of type Function');
  }

  // We DO NOT return the promise as it gives the user a false sense that
  // the promise is actually somehow related to the callback's execution
  // and that the callback throwing will reject the promise.
  function callbackified() {
    var args = [];
    for (var i = 0; i < arguments.length; i++) {
      args.push(arguments[i]);
    }

    var maybeCb = args.pop();
    if (typeof maybeCb !== 'function') {
      throw new TypeError('The last argument must be of type Function');
    }
    var self = this;
    var cb = function() {
      return maybeCb.apply(self, arguments);
    };
    // In true node style we process the callback on `nextTick` with all the
    // implications (stack, `uncaughtException`, `async_hooks`)
    original.apply(this, args)
      .then(function(ret) { process.nextTick(cb.bind(null, null, ret)) },
            function(rej) { process.nextTick(callbackifyOnRejected.bind(null, rej, cb)) });
  }

  Object.setPrototypeOf(callbackified, Object.getPrototypeOf(original));
  Object.defineProperties(callbackified,
                          getOwnPropertyDescriptors(original));
  return callbackified;
}
exports.callbackify = callbackify;

}).call(this)}).call(this,require('_process'))
},{"./support/isBuffer":17,"./support/types":18,"_process":16,"inherits":12}],20:[function(require,module,exports){
(function (global){(function (){
'use strict';

var forEach = require('foreach');
var availableTypedArrays = require('available-typed-arrays');
var callBound = require('call-bind/callBound');

var $toString = callBound('Object.prototype.toString');
var hasSymbols = require('has-symbols')();
var hasToStringTag = hasSymbols && typeof Symbol.toStringTag === 'symbol';

var typedArrays = availableTypedArrays();

var $slice = callBound('String.prototype.slice');
var toStrTags = {};
var gOPD = require('es-abstract/helpers/getOwnPropertyDescriptor');
var getPrototypeOf = Object.getPrototypeOf; // require('getprototypeof');
if (hasToStringTag && gOPD && getPrototypeOf) {
	forEach(typedArrays, function (typedArray) {
		if (typeof global[typedArray] === 'function') {
			var arr = new global[typedArray]();
			if (!(Symbol.toStringTag in arr)) {
				throw new EvalError('this engine has support for Symbol.toStringTag, but ' + typedArray + ' does not have the property! Please report this.');
			}
			var proto = getPrototypeOf(arr);
			var descriptor = gOPD(proto, Symbol.toStringTag);
			if (!descriptor) {
				var superProto = getPrototypeOf(proto);
				descriptor = gOPD(superProto, Symbol.toStringTag);
			}
			toStrTags[typedArray] = descriptor.get;
		}
	});
}

var tryTypedArrays = function tryAllTypedArrays(value) {
	var foundName = false;
	forEach(toStrTags, function (getter, typedArray) {
		if (!foundName) {
			try {
				var name = getter.call(value);
				if (name === typedArray) {
					foundName = name;
				}
			} catch (e) {}
		}
	});
	return foundName;
};

var isTypedArray = require('is-typed-array');

module.exports = function whichTypedArray(value) {
	if (!isTypedArray(value)) { return false; }
	if (!hasToStringTag) { return $slice($toString(value), 8, -1); }
	return tryTypedArrays(value);
};

}).call(this)}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"available-typed-arrays":1,"call-bind/callBound":2,"es-abstract/helpers/getOwnPropertyDescriptor":4,"foreach":5,"has-symbols":9,"is-typed-array":15}],21:[function(require,module,exports){
/*! For license information please see cbor.js.LICENSE.txt */
!function(t,e){"object"==typeof exports&&"object"==typeof module?module.exports=e(function(){try{return require("bignumber.js")}catch(t){}}(),require("util")):"function"==typeof define&&define.amd?define([,"util"],e):"object"==typeof exports?exports.cbor=e(function(){try{return require("bignumber.js")}catch(t){}}(),require("util")):t.cbor=e(t.BigNumber,t.util)}(this,(function(t,e){return(()=>{var r={742:(t,e)=>{"use strict";e.byteLength=function(t){var e=u(t),r=e[0],n=e[1];return 3*(r+n)/4-n},e.toByteArray=function(t){var e,r,o=u(t),s=o[0],a=o[1],l=new i(function(t,e,r){return 3*(e+r)/4-r}(0,s,a)),c=0,f=a>0?s-4:s;for(r=0;r<f;r+=4)e=n[t.charCodeAt(r)]<<18|n[t.charCodeAt(r+1)]<<12|n[t.charCodeAt(r+2)]<<6|n[t.charCodeAt(r+3)],l[c++]=e>>16&255,l[c++]=e>>8&255,l[c++]=255&e;return 2===a&&(e=n[t.charCodeAt(r)]<<2|n[t.charCodeAt(r+1)]>>4,l[c++]=255&e),1===a&&(e=n[t.charCodeAt(r)]<<10|n[t.charCodeAt(r+1)]<<4|n[t.charCodeAt(r+2)]>>2,l[c++]=e>>8&255,l[c++]=255&e),l},e.fromByteArray=function(t){for(var e,n=t.length,i=n%3,o=[],s=16383,a=0,u=n-i;a<u;a+=s)o.push(l(t,a,a+s>u?u:a+s));return 1===i?(e=t[n-1],o.push(r[e>>2]+r[e<<4&63]+"==")):2===i&&(e=(t[n-2]<<8)+t[n-1],o.push(r[e>>10]+r[e>>4&63]+r[e<<2&63]+"=")),o.join("")};for(var r=[],n=[],i="undefined"!=typeof Uint8Array?Uint8Array:Array,o="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",s=0,a=o.length;s<a;++s)r[s]=o[s],n[o.charCodeAt(s)]=s;function u(t){var e=t.length;if(e%4>0)throw new Error("Invalid string. Length must be a multiple of 4");var r=t.indexOf("=");return-1===r&&(r=e),[r,r===e?0:4-r%4]}function l(t,e,n){for(var i,o,s=[],a=e;a<n;a+=3)i=(t[a]<<16&16711680)+(t[a+1]<<8&65280)+(255&t[a+2]),s.push(r[(o=i)>>18&63]+r[o>>12&63]+r[o>>6&63]+r[63&o]);return s.join("")}n["-".charCodeAt(0)]=62,n["_".charCodeAt(0)]=63},764:(t,e,r)=>{"use strict";const n=r(742),i=r(645),o="function"==typeof Symbol&&"function"==typeof Symbol.for?Symbol.for("nodejs.util.inspect.custom"):null;e.Buffer=u,e.SlowBuffer=function(t){return+t!=t&&(t=0),u.alloc(+t)},e.INSPECT_MAX_BYTES=50;const s=2147483647;function a(t){if(t>s)throw new RangeError('The value "'+t+'" is invalid for option "size"');const e=new Uint8Array(t);return Object.setPrototypeOf(e,u.prototype),e}function u(t,e,r){if("number"==typeof t){if("string"==typeof e)throw new TypeError('The "string" argument must be of type string. Received type number');return f(t)}return l(t,e,r)}function l(t,e,r){if("string"==typeof t)return function(t,e){if("string"==typeof e&&""!==e||(e="utf8"),!u.isEncoding(e))throw new TypeError("Unknown encoding: "+e);const r=0|y(t,e);let n=a(r);const i=n.write(t,e);return i!==r&&(n=n.slice(0,i)),n}(t,e);if(ArrayBuffer.isView(t))return function(t){if(K(t,Uint8Array)){const e=new Uint8Array(t);return p(e.buffer,e.byteOffset,e.byteLength)}return h(t)}(t);if(null==t)throw new TypeError("The first argument must be one of type string, Buffer, ArrayBuffer, Array, or Array-like Object. Received type "+typeof t);if(K(t,ArrayBuffer)||t&&K(t.buffer,ArrayBuffer))return p(t,e,r);if("undefined"!=typeof SharedArrayBuffer&&(K(t,SharedArrayBuffer)||t&&K(t.buffer,SharedArrayBuffer)))return p(t,e,r);if("number"==typeof t)throw new TypeError('The "value" argument must not be of type number. Received type number');const n=t.valueOf&&t.valueOf();if(null!=n&&n!==t)return u.from(n,e,r);const i=function(t){if(u.isBuffer(t)){const e=0|d(t.length),r=a(e);return 0===r.length||t.copy(r,0,0,e),r}return void 0!==t.length?"number"!=typeof t.length||X(t.length)?a(0):h(t):"Buffer"===t.type&&Array.isArray(t.data)?h(t.data):void 0}(t);if(i)return i;if("undefined"!=typeof Symbol&&null!=Symbol.toPrimitive&&"function"==typeof t[Symbol.toPrimitive])return u.from(t[Symbol.toPrimitive]("string"),e,r);throw new TypeError("The first argument must be one of type string, Buffer, ArrayBuffer, Array, or Array-like Object. Received type "+typeof t)}function c(t){if("number"!=typeof t)throw new TypeError('"size" argument must be of type number');if(t<0)throw new RangeError('The value "'+t+'" is invalid for option "size"')}function f(t){return c(t),a(t<0?0:0|d(t))}function h(t){const e=t.length<0?0:0|d(t.length),r=a(e);for(let n=0;n<e;n+=1)r[n]=255&t[n];return r}function p(t,e,r){if(e<0||t.byteLength<e)throw new RangeError('"offset" is outside of buffer bounds');if(t.byteLength<e+(r||0))throw new RangeError('"length" is outside of buffer bounds');let n;return n=void 0===e&&void 0===r?new Uint8Array(t):void 0===r?new Uint8Array(t,e):new Uint8Array(t,e,r),Object.setPrototypeOf(n,u.prototype),n}function d(t){if(t>=s)throw new RangeError("Attempt to allocate Buffer larger than maximum size: 0x"+s.toString(16)+" bytes");return 0|t}function y(t,e){if(u.isBuffer(t))return t.length;if(ArrayBuffer.isView(t)||K(t,ArrayBuffer))return t.byteLength;if("string"!=typeof t)throw new TypeError('The "string" argument must be one of type string, Buffer, or ArrayBuffer. Received type '+typeof t);const r=t.length,n=arguments.length>2&&!0===arguments[2];if(!n&&0===r)return 0;let i=!1;for(;;)switch(e){case"ascii":case"latin1":case"binary":return r;case"utf8":case"utf-8":return Y(t).length;case"ucs2":case"ucs-2":case"utf16le":case"utf-16le":return 2*r;case"hex":return r>>>1;case"base64":return q(t).length;default:if(i)return n?-1:Y(t).length;e=(""+e).toLowerCase(),i=!0}}function g(t,e,r){let n=!1;if((void 0===e||e<0)&&(e=0),e>this.length)return"";if((void 0===r||r>this.length)&&(r=this.length),r<=0)return"";if((r>>>=0)<=(e>>>=0))return"";for(t||(t="utf8");;)switch(t){case"hex":return R(this,e,r);case"utf8":case"utf-8":return I(this,e,r);case"ascii":return O(this,e,r);case"latin1":case"binary":return x(this,e,r);case"base64":return T(this,e,r);case"ucs2":case"ucs-2":case"utf16le":case"utf-16le":return N(this,e,r);default:if(n)throw new TypeError("Unknown encoding: "+t);t=(t+"").toLowerCase(),n=!0}}function b(t,e,r){const n=t[e];t[e]=t[r],t[r]=n}function m(t,e,r,n,i){if(0===t.length)return-1;if("string"==typeof r?(n=r,r=0):r>2147483647?r=2147483647:r<-2147483648&&(r=-2147483648),X(r=+r)&&(r=i?0:t.length-1),r<0&&(r=t.length+r),r>=t.length){if(i)return-1;r=t.length-1}else if(r<0){if(!i)return-1;r=0}if("string"==typeof e&&(e=u.from(e,n)),u.isBuffer(e))return 0===e.length?-1:w(t,e,r,n,i);if("number"==typeof e)return e&=255,"function"==typeof Uint8Array.prototype.indexOf?i?Uint8Array.prototype.indexOf.call(t,e,r):Uint8Array.prototype.lastIndexOf.call(t,e,r):w(t,[e],r,n,i);throw new TypeError("val must be string, number or Buffer")}function w(t,e,r,n,i){let o,s=1,a=t.length,u=e.length;if(void 0!==n&&("ucs2"===(n=String(n).toLowerCase())||"ucs-2"===n||"utf16le"===n||"utf-16le"===n)){if(t.length<2||e.length<2)return-1;s=2,a/=2,u/=2,r/=2}function l(t,e){return 1===s?t[e]:t.readUInt16BE(e*s)}if(i){let n=-1;for(o=r;o<a;o++)if(l(t,o)===l(e,-1===n?0:o-n)){if(-1===n&&(n=o),o-n+1===u)return n*s}else-1!==n&&(o-=o-n),n=-1}else for(r+u>a&&(r=a-u),o=r;o>=0;o--){let r=!0;for(let n=0;n<u;n++)if(l(t,o+n)!==l(e,n)){r=!1;break}if(r)return o}return-1}function _(t,e,r,n){r=Number(r)||0;const i=t.length-r;n?(n=Number(n))>i&&(n=i):n=i;const o=e.length;let s;for(n>o/2&&(n=o/2),s=0;s<n;++s){const n=parseInt(e.substr(2*s,2),16);if(X(n))return s;t[r+s]=n}return s}function E(t,e,r,n){return V(Y(e,t.length-r),t,r,n)}function v(t,e,r,n){return V(function(t){const e=[];for(let r=0;r<t.length;++r)e.push(255&t.charCodeAt(r));return e}(e),t,r,n)}function S(t,e,r,n){return V(q(e),t,r,n)}function A(t,e,r,n){return V(function(t,e){let r,n,i;const o=[];for(let s=0;s<t.length&&!((e-=2)<0);++s)r=t.charCodeAt(s),n=r>>8,i=r%256,o.push(i),o.push(n);return o}(e,t.length-r),t,r,n)}function T(t,e,r){return 0===e&&r===t.length?n.fromByteArray(t):n.fromByteArray(t.slice(e,r))}function I(t,e,r){r=Math.min(t.length,r);const n=[];let i=e;for(;i<r;){const e=t[i];let o=null,s=e>239?4:e>223?3:e>191?2:1;if(i+s<=r){let r,n,a,u;switch(s){case 1:e<128&&(o=e);break;case 2:r=t[i+1],128==(192&r)&&(u=(31&e)<<6|63&r,u>127&&(o=u));break;case 3:r=t[i+1],n=t[i+2],128==(192&r)&&128==(192&n)&&(u=(15&e)<<12|(63&r)<<6|63&n,u>2047&&(u<55296||u>57343)&&(o=u));break;case 4:r=t[i+1],n=t[i+2],a=t[i+3],128==(192&r)&&128==(192&n)&&128==(192&a)&&(u=(15&e)<<18|(63&r)<<12|(63&n)<<6|63&a,u>65535&&u<1114112&&(o=u))}}null===o?(o=65533,s=1):o>65535&&(o-=65536,n.push(o>>>10&1023|55296),o=56320|1023&o),n.push(o),i+=s}return function(t){const e=t.length;if(e<=B)return String.fromCharCode.apply(String,t);let r="",n=0;for(;n<e;)r+=String.fromCharCode.apply(String,t.slice(n,n+=B));return r}(n)}e.kMaxLength=s,u.TYPED_ARRAY_SUPPORT=function(){try{const t=new Uint8Array(1),e={foo:function(){return 42}};return Object.setPrototypeOf(e,Uint8Array.prototype),Object.setPrototypeOf(t,e),42===t.foo()}catch(t){return!1}}(),u.TYPED_ARRAY_SUPPORT||"undefined"==typeof console||"function"!=typeof console.error||console.error("This browser lacks typed array (Uint8Array) support which is required by `buffer` v5.x. Use `buffer` v4.x if you require old browser support."),Object.defineProperty(u.prototype,"parent",{enumerable:!0,get:function(){if(u.isBuffer(this))return this.buffer}}),Object.defineProperty(u.prototype,"offset",{enumerable:!0,get:function(){if(u.isBuffer(this))return this.byteOffset}}),u.poolSize=8192,u.from=function(t,e,r){return l(t,e,r)},Object.setPrototypeOf(u.prototype,Uint8Array.prototype),Object.setPrototypeOf(u,Uint8Array),u.alloc=function(t,e,r){return function(t,e,r){return c(t),t<=0?a(t):void 0!==e?"string"==typeof r?a(t).fill(e,r):a(t).fill(e):a(t)}(t,e,r)},u.allocUnsafe=function(t){return f(t)},u.allocUnsafeSlow=function(t){return f(t)},u.isBuffer=function(t){return null!=t&&!0===t._isBuffer&&t!==u.prototype},u.compare=function(t,e){if(K(t,Uint8Array)&&(t=u.from(t,t.offset,t.byteLength)),K(e,Uint8Array)&&(e=u.from(e,e.offset,e.byteLength)),!u.isBuffer(t)||!u.isBuffer(e))throw new TypeError('The "buf1", "buf2" arguments must be one of type Buffer or Uint8Array');if(t===e)return 0;let r=t.length,n=e.length;for(let i=0,o=Math.min(r,n);i<o;++i)if(t[i]!==e[i]){r=t[i],n=e[i];break}return r<n?-1:n<r?1:0},u.isEncoding=function(t){switch(String(t).toLowerCase()){case"hex":case"utf8":case"utf-8":case"ascii":case"latin1":case"binary":case"base64":case"ucs2":case"ucs-2":case"utf16le":case"utf-16le":return!0;default:return!1}},u.concat=function(t,e){if(!Array.isArray(t))throw new TypeError('"list" argument must be an Array of Buffers');if(0===t.length)return u.alloc(0);let r;if(void 0===e)for(e=0,r=0;r<t.length;++r)e+=t[r].length;const n=u.allocUnsafe(e);let i=0;for(r=0;r<t.length;++r){let e=t[r];if(K(e,Uint8Array))i+e.length>n.length?(u.isBuffer(e)||(e=u.from(e)),e.copy(n,i)):Uint8Array.prototype.set.call(n,e,i);else{if(!u.isBuffer(e))throw new TypeError('"list" argument must be an Array of Buffers');e.copy(n,i)}i+=e.length}return n},u.byteLength=y,u.prototype._isBuffer=!0,u.prototype.swap16=function(){const t=this.length;if(t%2!=0)throw new RangeError("Buffer size must be a multiple of 16-bits");for(let e=0;e<t;e+=2)b(this,e,e+1);return this},u.prototype.swap32=function(){const t=this.length;if(t%4!=0)throw new RangeError("Buffer size must be a multiple of 32-bits");for(let e=0;e<t;e+=4)b(this,e,e+3),b(this,e+1,e+2);return this},u.prototype.swap64=function(){const t=this.length;if(t%8!=0)throw new RangeError("Buffer size must be a multiple of 64-bits");for(let e=0;e<t;e+=8)b(this,e,e+7),b(this,e+1,e+6),b(this,e+2,e+5),b(this,e+3,e+4);return this},u.prototype.toString=function(){const t=this.length;return 0===t?"":0===arguments.length?I(this,0,t):g.apply(this,arguments)},u.prototype.toLocaleString=u.prototype.toString,u.prototype.equals=function(t){if(!u.isBuffer(t))throw new TypeError("Argument must be a Buffer");return this===t||0===u.compare(this,t)},u.prototype.inspect=function(){let t="";const r=e.INSPECT_MAX_BYTES;return t=this.toString("hex",0,r).replace(/(.{2})/g,"$1 ").trim(),this.length>r&&(t+=" ... "),"<Buffer "+t+">"},o&&(u.prototype[o]=u.prototype.inspect),u.prototype.compare=function(t,e,r,n,i){if(K(t,Uint8Array)&&(t=u.from(t,t.offset,t.byteLength)),!u.isBuffer(t))throw new TypeError('The "target" argument must be one of type Buffer or Uint8Array. Received type '+typeof t);if(void 0===e&&(e=0),void 0===r&&(r=t?t.length:0),void 0===n&&(n=0),void 0===i&&(i=this.length),e<0||r>t.length||n<0||i>this.length)throw new RangeError("out of range index");if(n>=i&&e>=r)return 0;if(n>=i)return-1;if(e>=r)return 1;if(this===t)return 0;let o=(i>>>=0)-(n>>>=0),s=(r>>>=0)-(e>>>=0);const a=Math.min(o,s),l=this.slice(n,i),c=t.slice(e,r);for(let t=0;t<a;++t)if(l[t]!==c[t]){o=l[t],s=c[t];break}return o<s?-1:s<o?1:0},u.prototype.includes=function(t,e,r){return-1!==this.indexOf(t,e,r)},u.prototype.indexOf=function(t,e,r){return m(this,t,e,r,!0)},u.prototype.lastIndexOf=function(t,e,r){return m(this,t,e,r,!1)},u.prototype.write=function(t,e,r,n){if(void 0===e)n="utf8",r=this.length,e=0;else if(void 0===r&&"string"==typeof e)n=e,r=this.length,e=0;else{if(!isFinite(e))throw new Error("Buffer.write(string, encoding, offset[, length]) is no longer supported");e>>>=0,isFinite(r)?(r>>>=0,void 0===n&&(n="utf8")):(n=r,r=void 0)}const i=this.length-e;if((void 0===r||r>i)&&(r=i),t.length>0&&(r<0||e<0)||e>this.length)throw new RangeError("Attempt to write outside buffer bounds");n||(n="utf8");let o=!1;for(;;)switch(n){case"hex":return _(this,t,e,r);case"utf8":case"utf-8":return E(this,t,e,r);case"ascii":case"latin1":case"binary":return v(this,t,e,r);case"base64":return S(this,t,e,r);case"ucs2":case"ucs-2":case"utf16le":case"utf-16le":return A(this,t,e,r);default:if(o)throw new TypeError("Unknown encoding: "+n);n=(""+n).toLowerCase(),o=!0}},u.prototype.toJSON=function(){return{type:"Buffer",data:Array.prototype.slice.call(this._arr||this,0)}};const B=4096;function O(t,e,r){let n="";r=Math.min(t.length,r);for(let i=e;i<r;++i)n+=String.fromCharCode(127&t[i]);return n}function x(t,e,r){let n="";r=Math.min(t.length,r);for(let i=e;i<r;++i)n+=String.fromCharCode(t[i]);return n}function R(t,e,r){const n=t.length;(!e||e<0)&&(e=0),(!r||r<0||r>n)&&(r=n);let i="";for(let n=e;n<r;++n)i+=J[t[n]];return i}function N(t,e,r){const n=t.slice(e,r);let i="";for(let t=0;t<n.length-1;t+=2)i+=String.fromCharCode(n[t]+256*n[t+1]);return i}function L(t,e,r){if(t%1!=0||t<0)throw new RangeError("offset is not uint");if(t+e>r)throw new RangeError("Trying to access beyond buffer length")}function P(t,e,r,n,i,o){if(!u.isBuffer(t))throw new TypeError('"buffer" argument must be a Buffer instance');if(e>i||e<o)throw new RangeError('"value" argument is out of bounds');if(r+n>t.length)throw new RangeError("Index out of range")}function M(t,e,r,n,i){G(e,n,i,t,r,7);let o=Number(e&BigInt(4294967295));t[r++]=o,o>>=8,t[r++]=o,o>>=8,t[r++]=o,o>>=8,t[r++]=o;let s=Number(e>>BigInt(32)&BigInt(4294967295));return t[r++]=s,s>>=8,t[r++]=s,s>>=8,t[r++]=s,s>>=8,t[r++]=s,r}function U(t,e,r,n,i){G(e,n,i,t,r,7);let o=Number(e&BigInt(4294967295));t[r+7]=o,o>>=8,t[r+6]=o,o>>=8,t[r+5]=o,o>>=8,t[r+4]=o;let s=Number(e>>BigInt(32)&BigInt(4294967295));return t[r+3]=s,s>>=8,t[r+2]=s,s>>=8,t[r+1]=s,s>>=8,t[r]=s,r+8}function j(t,e,r,n,i,o){if(r+n>t.length)throw new RangeError("Index out of range");if(r<0)throw new RangeError("Index out of range")}function k(t,e,r,n,o){return e=+e,r>>>=0,o||j(t,0,r,4),i.write(t,e,r,n,23,4),r+4}function $(t,e,r,n,o){return e=+e,r>>>=0,o||j(t,0,r,8),i.write(t,e,r,n,52,8),r+8}u.prototype.slice=function(t,e){const r=this.length;(t=~~t)<0?(t+=r)<0&&(t=0):t>r&&(t=r),(e=void 0===e?r:~~e)<0?(e+=r)<0&&(e=0):e>r&&(e=r),e<t&&(e=t);const n=this.subarray(t,e);return Object.setPrototypeOf(n,u.prototype),n},u.prototype.readUintLE=u.prototype.readUIntLE=function(t,e,r){t>>>=0,e>>>=0,r||L(t,e,this.length);let n=this[t],i=1,o=0;for(;++o<e&&(i*=256);)n+=this[t+o]*i;return n},u.prototype.readUintBE=u.prototype.readUIntBE=function(t,e,r){t>>>=0,e>>>=0,r||L(t,e,this.length);let n=this[t+--e],i=1;for(;e>0&&(i*=256);)n+=this[t+--e]*i;return n},u.prototype.readUint8=u.prototype.readUInt8=function(t,e){return t>>>=0,e||L(t,1,this.length),this[t]},u.prototype.readUint16LE=u.prototype.readUInt16LE=function(t,e){return t>>>=0,e||L(t,2,this.length),this[t]|this[t+1]<<8},u.prototype.readUint16BE=u.prototype.readUInt16BE=function(t,e){return t>>>=0,e||L(t,2,this.length),this[t]<<8|this[t+1]},u.prototype.readUint32LE=u.prototype.readUInt32LE=function(t,e){return t>>>=0,e||L(t,4,this.length),(this[t]|this[t+1]<<8|this[t+2]<<16)+16777216*this[t+3]},u.prototype.readUint32BE=u.prototype.readUInt32BE=function(t,e){return t>>>=0,e||L(t,4,this.length),16777216*this[t]+(this[t+1]<<16|this[t+2]<<8|this[t+3])},u.prototype.readBigUInt64LE=Z((function(t){W(t>>>=0,"offset");const e=this[t],r=this[t+7];void 0!==e&&void 0!==r||z(t,this.length-8);const n=e+256*this[++t]+65536*this[++t]+this[++t]*2**24,i=this[++t]+256*this[++t]+65536*this[++t]+r*2**24;return BigInt(n)+(BigInt(i)<<BigInt(32))})),u.prototype.readBigUInt64BE=Z((function(t){W(t>>>=0,"offset");const e=this[t],r=this[t+7];void 0!==e&&void 0!==r||z(t,this.length-8);const n=e*2**24+65536*this[++t]+256*this[++t]+this[++t],i=this[++t]*2**24+65536*this[++t]+256*this[++t]+r;return(BigInt(n)<<BigInt(32))+BigInt(i)})),u.prototype.readIntLE=function(t,e,r){t>>>=0,e>>>=0,r||L(t,e,this.length);let n=this[t],i=1,o=0;for(;++o<e&&(i*=256);)n+=this[t+o]*i;return i*=128,n>=i&&(n-=Math.pow(2,8*e)),n},u.prototype.readIntBE=function(t,e,r){t>>>=0,e>>>=0,r||L(t,e,this.length);let n=e,i=1,o=this[t+--n];for(;n>0&&(i*=256);)o+=this[t+--n]*i;return i*=128,o>=i&&(o-=Math.pow(2,8*e)),o},u.prototype.readInt8=function(t,e){return t>>>=0,e||L(t,1,this.length),128&this[t]?-1*(255-this[t]+1):this[t]},u.prototype.readInt16LE=function(t,e){t>>>=0,e||L(t,2,this.length);const r=this[t]|this[t+1]<<8;return 32768&r?4294901760|r:r},u.prototype.readInt16BE=function(t,e){t>>>=0,e||L(t,2,this.length);const r=this[t+1]|this[t]<<8;return 32768&r?4294901760|r:r},u.prototype.readInt32LE=function(t,e){return t>>>=0,e||L(t,4,this.length),this[t]|this[t+1]<<8|this[t+2]<<16|this[t+3]<<24},u.prototype.readInt32BE=function(t,e){return t>>>=0,e||L(t,4,this.length),this[t]<<24|this[t+1]<<16|this[t+2]<<8|this[t+3]},u.prototype.readBigInt64LE=Z((function(t){W(t>>>=0,"offset");const e=this[t],r=this[t+7];void 0!==e&&void 0!==r||z(t,this.length-8);const n=this[t+4]+256*this[t+5]+65536*this[t+6]+(r<<24);return(BigInt(n)<<BigInt(32))+BigInt(e+256*this[++t]+65536*this[++t]+this[++t]*2**24)})),u.prototype.readBigInt64BE=Z((function(t){W(t>>>=0,"offset");const e=this[t],r=this[t+7];void 0!==e&&void 0!==r||z(t,this.length-8);const n=(e<<24)+65536*this[++t]+256*this[++t]+this[++t];return(BigInt(n)<<BigInt(32))+BigInt(this[++t]*2**24+65536*this[++t]+256*this[++t]+r)})),u.prototype.readFloatLE=function(t,e){return t>>>=0,e||L(t,4,this.length),i.read(this,t,!0,23,4)},u.prototype.readFloatBE=function(t,e){return t>>>=0,e||L(t,4,this.length),i.read(this,t,!1,23,4)},u.prototype.readDoubleLE=function(t,e){return t>>>=0,e||L(t,8,this.length),i.read(this,t,!0,52,8)},u.prototype.readDoubleBE=function(t,e){return t>>>=0,e||L(t,8,this.length),i.read(this,t,!1,52,8)},u.prototype.writeUintLE=u.prototype.writeUIntLE=function(t,e,r,n){t=+t,e>>>=0,r>>>=0,n||P(this,t,e,r,Math.pow(2,8*r)-1,0);let i=1,o=0;for(this[e]=255&t;++o<r&&(i*=256);)this[e+o]=t/i&255;return e+r},u.prototype.writeUintBE=u.prototype.writeUIntBE=function(t,e,r,n){t=+t,e>>>=0,r>>>=0,n||P(this,t,e,r,Math.pow(2,8*r)-1,0);let i=r-1,o=1;for(this[e+i]=255&t;--i>=0&&(o*=256);)this[e+i]=t/o&255;return e+r},u.prototype.writeUint8=u.prototype.writeUInt8=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,1,255,0),this[e]=255&t,e+1},u.prototype.writeUint16LE=u.prototype.writeUInt16LE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,2,65535,0),this[e]=255&t,this[e+1]=t>>>8,e+2},u.prototype.writeUint16BE=u.prototype.writeUInt16BE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,2,65535,0),this[e]=t>>>8,this[e+1]=255&t,e+2},u.prototype.writeUint32LE=u.prototype.writeUInt32LE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,4,4294967295,0),this[e+3]=t>>>24,this[e+2]=t>>>16,this[e+1]=t>>>8,this[e]=255&t,e+4},u.prototype.writeUint32BE=u.prototype.writeUInt32BE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,4,4294967295,0),this[e]=t>>>24,this[e+1]=t>>>16,this[e+2]=t>>>8,this[e+3]=255&t,e+4},u.prototype.writeBigUInt64LE=Z((function(t,e=0){return M(this,t,e,BigInt(0),BigInt("0xffffffffffffffff"))})),u.prototype.writeBigUInt64BE=Z((function(t,e=0){return U(this,t,e,BigInt(0),BigInt("0xffffffffffffffff"))})),u.prototype.writeIntLE=function(t,e,r,n){if(t=+t,e>>>=0,!n){const n=Math.pow(2,8*r-1);P(this,t,e,r,n-1,-n)}let i=0,o=1,s=0;for(this[e]=255&t;++i<r&&(o*=256);)t<0&&0===s&&0!==this[e+i-1]&&(s=1),this[e+i]=(t/o>>0)-s&255;return e+r},u.prototype.writeIntBE=function(t,e,r,n){if(t=+t,e>>>=0,!n){const n=Math.pow(2,8*r-1);P(this,t,e,r,n-1,-n)}let i=r-1,o=1,s=0;for(this[e+i]=255&t;--i>=0&&(o*=256);)t<0&&0===s&&0!==this[e+i+1]&&(s=1),this[e+i]=(t/o>>0)-s&255;return e+r},u.prototype.writeInt8=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,1,127,-128),t<0&&(t=255+t+1),this[e]=255&t,e+1},u.prototype.writeInt16LE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,2,32767,-32768),this[e]=255&t,this[e+1]=t>>>8,e+2},u.prototype.writeInt16BE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,2,32767,-32768),this[e]=t>>>8,this[e+1]=255&t,e+2},u.prototype.writeInt32LE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,4,2147483647,-2147483648),this[e]=255&t,this[e+1]=t>>>8,this[e+2]=t>>>16,this[e+3]=t>>>24,e+4},u.prototype.writeInt32BE=function(t,e,r){return t=+t,e>>>=0,r||P(this,t,e,4,2147483647,-2147483648),t<0&&(t=4294967295+t+1),this[e]=t>>>24,this[e+1]=t>>>16,this[e+2]=t>>>8,this[e+3]=255&t,e+4},u.prototype.writeBigInt64LE=Z((function(t,e=0){return M(this,t,e,-BigInt("0x8000000000000000"),BigInt("0x7fffffffffffffff"))})),u.prototype.writeBigInt64BE=Z((function(t,e=0){return U(this,t,e,-BigInt("0x8000000000000000"),BigInt("0x7fffffffffffffff"))})),u.prototype.writeFloatLE=function(t,e,r){return k(this,t,e,!0,r)},u.prototype.writeFloatBE=function(t,e,r){return k(this,t,e,!1,r)},u.prototype.writeDoubleLE=function(t,e,r){return $(this,t,e,!0,r)},u.prototype.writeDoubleBE=function(t,e,r){return $(this,t,e,!1,r)},u.prototype.copy=function(t,e,r,n){if(!u.isBuffer(t))throw new TypeError("argument should be a Buffer");if(r||(r=0),n||0===n||(n=this.length),e>=t.length&&(e=t.length),e||(e=0),n>0&&n<r&&(n=r),n===r)return 0;if(0===t.length||0===this.length)return 0;if(e<0)throw new RangeError("targetStart out of bounds");if(r<0||r>=this.length)throw new RangeError("Index out of range");if(n<0)throw new RangeError("sourceEnd out of bounds");n>this.length&&(n=this.length),t.length-e<n-r&&(n=t.length-e+r);const i=n-r;return this===t&&"function"==typeof Uint8Array.prototype.copyWithin?this.copyWithin(e,r,n):Uint8Array.prototype.set.call(t,this.subarray(r,n),e),i},u.prototype.fill=function(t,e,r,n){if("string"==typeof t){if("string"==typeof e?(n=e,e=0,r=this.length):"string"==typeof r&&(n=r,r=this.length),void 0!==n&&"string"!=typeof n)throw new TypeError("encoding must be a string");if("string"==typeof n&&!u.isEncoding(n))throw new TypeError("Unknown encoding: "+n);if(1===t.length){const e=t.charCodeAt(0);("utf8"===n&&e<128||"latin1"===n)&&(t=e)}}else"number"==typeof t?t&=255:"boolean"==typeof t&&(t=Number(t));if(e<0||this.length<e||this.length<r)throw new RangeError("Out of range index");if(r<=e)return this;let i;if(e>>>=0,r=void 0===r?this.length:r>>>0,t||(t=0),"number"==typeof t)for(i=e;i<r;++i)this[i]=t;else{const o=u.isBuffer(t)?t:u.from(t,n),s=o.length;if(0===s)throw new TypeError('The value "'+t+'" is invalid for argument "value"');for(i=0;i<r-e;++i)this[i+e]=o[i%s]}return this};const F={};function D(t,e,r){F[t]=class extends r{constructor(){super(),Object.defineProperty(this,"message",{value:e.apply(this,arguments),writable:!0,configurable:!0}),this.name=`${this.name} [${t}]`,this.stack,delete this.name}get code(){return t}set code(t){Object.defineProperty(this,"code",{configurable:!0,enumerable:!0,value:t,writable:!0})}toString(){return`${this.name} [${t}]: ${this.message}`}}}function C(t){let e="",r=t.length;const n="-"===t[0]?1:0;for(;r>=n+4;r-=3)e=`_${t.slice(r-3,r)}${e}`;return`${t.slice(0,r)}${e}`}function G(t,e,r,n,i,o){if(t>r||t<e){const n="bigint"==typeof e?"n":"";let i;throw i=o>3?0===e||e===BigInt(0)?`>= 0${n} and < 2${n} ** ${8*(o+1)}${n}`:`>= -(2${n} ** ${8*(o+1)-1}${n}) and < 2 ** ${8*(o+1)-1}${n}`:`>= ${e}${n} and <= ${r}${n}`,new F.ERR_OUT_OF_RANGE("value",i,t)}!function(t,e,r){W(e,"offset"),void 0!==t[e]&&void 0!==t[e+r]||z(e,t.length-(r+1))}(n,i,o)}function W(t,e){if("number"!=typeof t)throw new F.ERR_INVALID_ARG_TYPE(e,"number",t)}function z(t,e,r){if(Math.floor(t)!==t)throw W(t,r),new F.ERR_OUT_OF_RANGE(r||"offset","an integer",t);if(e<0)throw new F.ERR_BUFFER_OUT_OF_BOUNDS;throw new F.ERR_OUT_OF_RANGE(r||"offset",`>= ${r?1:0} and <= ${e}`,t)}D("ERR_BUFFER_OUT_OF_BOUNDS",(function(t){return t?`${t} is outside of buffer bounds`:"Attempt to access memory outside buffer bounds"}),RangeError),D("ERR_INVALID_ARG_TYPE",(function(t,e){return`The "${t}" argument must be of type number. Received type ${typeof e}`}),TypeError),D("ERR_OUT_OF_RANGE",(function(t,e,r){let n=`The value of "${t}" is out of range.`,i=r;return Number.isInteger(r)&&Math.abs(r)>2**32?i=C(String(r)):"bigint"==typeof r&&(i=String(r),(r>BigInt(2)**BigInt(32)||r<-(BigInt(2)**BigInt(32)))&&(i=C(i)),i+="n"),n+=` It must be ${e}. Received ${i}`,n}),RangeError);const H=/[^+/0-9A-Za-z-_]/g;function Y(t,e){let r;e=e||1/0;const n=t.length;let i=null;const o=[];for(let s=0;s<n;++s){if(r=t.charCodeAt(s),r>55295&&r<57344){if(!i){if(r>56319){(e-=3)>-1&&o.push(239,191,189);continue}if(s+1===n){(e-=3)>-1&&o.push(239,191,189);continue}i=r;continue}if(r<56320){(e-=3)>-1&&o.push(239,191,189),i=r;continue}r=65536+(i-55296<<10|r-56320)}else i&&(e-=3)>-1&&o.push(239,191,189);if(i=null,r<128){if((e-=1)<0)break;o.push(r)}else if(r<2048){if((e-=2)<0)break;o.push(r>>6|192,63&r|128)}else if(r<65536){if((e-=3)<0)break;o.push(r>>12|224,r>>6&63|128,63&r|128)}else{if(!(r<1114112))throw new Error("Invalid code point");if((e-=4)<0)break;o.push(r>>18|240,r>>12&63|128,r>>6&63|128,63&r|128)}}return o}function q(t){return n.toByteArray(function(t){if((t=(t=t.split("=")[0]).trim().replace(H,"")).length<2)return"";for(;t.length%4!=0;)t+="=";return t}(t))}function V(t,e,r,n){let i;for(i=0;i<n&&!(i+r>=e.length||i>=t.length);++i)e[i+r]=t[i];return i}function K(t,e){return t instanceof e||null!=t&&null!=t.constructor&&null!=t.constructor.name&&t.constructor.name===e.name}function X(t){return t!=t}const J=function(){const t="0123456789abcdef",e=new Array(256);for(let r=0;r<16;++r){const n=16*r;for(let i=0;i<16;++i)e[n+i]=t[r]+t[i]}return e}();function Z(t){return"undefined"==typeof BigInt?Q:t}function Q(){throw new Error("BigInt not supported")}},141:(t,e,r)=>{"use strict";e.BigNumber=r(66).BigNumber,e.Commented=r(20),e.Diagnose=r(694),e.Decoder=r(774),e.Encoder=r(666),e.Simple=r(32),e.Tagged=r(785),e.Map=r(70),e.UI=e.Commented.comment,e.fI=e.Decoder.decodeAll,e.h8=e.Decoder.decodeFirst,e.cc=e.Decoder.decodeAllSync,e.$u=e.Decoder.decodeFirstSync,e.M=e.Diagnose.diagnose,e.cv=e.Encoder.encode,e.N2=e.Encoder.encodeCanonical,e.TG=e.Encoder.encodeOne,e.WR=e.Encoder.encodeAsync,e.Jx=e.Decoder.decodeFirstSync,e.ww={decode:e.Decoder.decodeFirstSync,encode:e.Encoder.encode,buffer:!0,name:"cbor"},e.vc=!0},20:(t,e,r)=>{"use strict";const n=r(830),i=r(873),o=r(774),s=r(202),{MT:a,NUMBYTES:u,SYMS:l}=r(66),{Buffer:c}=r(764);function f(t){return t>1?"s":""}class h extends n.Transform{constructor(t={}){const{depth:e=1,max_depth:r=10,no_summary:n=!1,tags:i={},bigint:a,preferWeb:u,encoding:l,...c}=t;super({...c,readableObjectMode:!1,writableObjectMode:!1}),this.depth=e,this.max_depth=r,this.all=new s,i[24]||(i[24]=this._tag_24.bind(this)),this.parser=new o({tags:i,max_depth:r,bigint:a,preferWeb:u,encoding:l}),this.parser.on("value",this._on_value.bind(this)),this.parser.on("start",this._on_start.bind(this)),this.parser.on("start-string",this._on_start_string.bind(this)),this.parser.on("stop",this._on_stop.bind(this)),this.parser.on("more-bytes",this._on_more.bind(this)),this.parser.on("error",this._on_error.bind(this)),n||this.parser.on("data",this._on_data.bind(this)),this.parser.bs.on("read",this._on_read.bind(this))}_tag_24(t){const e=new h({depth:this.depth+1,no_summary:!0});e.on("data",(t=>this.push(t))),e.on("error",(t=>this.emit("error",t))),e.end(t)}_transform(t,e,r){this.parser.write(t,e,r)}_flush(t){return this.parser._flush(t)}static comment(t,e={},r=null){if(null==t)throw new Error("input required");({options:e,cb:r}=function(t,e){switch(typeof t){case"function":return{options:{},cb:t};case"string":return{options:{encoding:t},cb:e};case"number":return{options:{max_depth:t},cb:e};case"object":return{options:t||{},cb:e};default:throw new TypeError("Unknown option type")}}(e,r));const n=new s,{encoding:o="hex",...a}=e,u=new h(a);let l=null;return"function"==typeof r?(u.on("end",(()=>{r(null,n.toString("utf8"))})),u.on("error",r)):l=new Promise(((t,e)=>{u.on("end",(()=>{t(n.toString("utf8"))})),u.on("error",e)})),u.pipe(n),i.guessEncoding(t,o).pipe(u),l}_on_error(t){this.push("ERROR: "),this.push(t.toString()),this.push("\n")}_on_read(t){this.all.write(t);const e=t.toString("hex");this.push(new Array(this.depth+1).join("  ")),this.push(e);let r=2*(this.max_depth-this.depth)-e.length;return r<1&&(r=1),this.push(new Array(r+1).join(" ")),this.push("-- ")}_on_more(t,e,r,n){let i="";switch(this.depth++,t){case a.POS_INT:i="Positive number,";break;case a.NEG_INT:i="Negative number,";break;case a.ARRAY:i="Array, length";break;case a.MAP:i="Map, count";break;case a.BYTE_STRING:i="Bytes, length";break;case a.UTF8_STRING:i="String, length";break;case a.SIMPLE_FLOAT:i=1===e?"Simple value,":"Float,"}return this.push(i+" next "+e+" byte"+f(e)+"\n")}_on_start_string(t,e,r,n){let i="";switch(this.depth++,t){case a.BYTE_STRING:i="Bytes, length: "+e;break;case a.UTF8_STRING:i="String, length: "+e.toString()}return this.push(i+"\n")}_on_start(t,e,r,n){switch(this.depth++,r){case a.ARRAY:this.push(`[${n}], `);break;case a.MAP:n%2?this.push(`{Val:${Math.floor(n/2)}}, `):this.push(`{Key:${Math.floor(n/2)}}, `)}switch(t){case a.TAG:this.push(`Tag #${e}`),24===e&&this.push(" Encoded CBOR data item");break;case a.ARRAY:e===l.STREAM?this.push("Array (streaming)"):this.push(`Array, ${e} item${f(e)}`);break;case a.MAP:e===l.STREAM?this.push("Map (streaming)"):this.push(`Map, ${e} pair${f(e)}`);break;case a.BYTE_STRING:this.push("Bytes (streaming)");break;case a.UTF8_STRING:this.push("String (streaming)")}return this.push("\n")}_on_stop(t){return this.depth--}_on_value(t,e,r,n){if(t!==l.BREAK)switch(e){case a.ARRAY:this.push(`[${r}], `);break;case a.MAP:r%2?this.push(`{Val:${Math.floor(r/2)}}, `):this.push(`{Key:${Math.floor(r/2)}}, `)}const o=i.cborValueToString(t,-1/0);switch("string"==typeof t||c.isBuffer(t)?(t.length>0&&(this.push(o),this.push("\n")),this.depth--):(this.push(o),this.push("\n")),n){case u.ONE:case u.TWO:case u.FOUR:case u.EIGHT:this.depth--}}_on_data(){return this.push("0x"),this.push(this.all.read().toString("hex")),this.push("\n")}}t.exports=h},66:(t,e,r)=>{"use strict";let n=null;try{n=r(937).BigNumber}catch(t){}if(e.BigNumber=n,e.MT={POS_INT:0,NEG_INT:1,BYTE_STRING:2,UTF8_STRING:3,ARRAY:4,MAP:5,TAG:6,SIMPLE_FLOAT:7},e.TAG={DATE_STRING:0,DATE_EPOCH:1,POS_BIGINT:2,NEG_BIGINT:3,DECIMAL_FRAC:4,BIGFLOAT:5,BASE64URL_EXPECTED:21,BASE64_EXPECTED:22,BASE16_EXPECTED:23,CBOR:24,URI:32,BASE64URL:33,BASE64:34,REGEXP:35,MIME:36,SET:258},e.NUMBYTES={ZERO:0,ONE:24,TWO:25,FOUR:26,EIGHT:27,INDEFINITE:31},e.SIMPLE={FALSE:20,TRUE:21,NULL:22,UNDEFINED:23},e.SYMS={NULL:Symbol.for("github.com/hildjj/node-cbor/null"),UNDEFINED:Symbol.for("github.com/hildjj/node-cbor/undef"),PARENT:Symbol.for("github.com/hildjj/node-cbor/parent"),BREAK:Symbol.for("github.com/hildjj/node-cbor/break"),STREAM:Symbol.for("github.com/hildjj/node-cbor/stream")},e.SHIFT32=4294967296,e.BI={MINUS_ONE:BigInt(-1),NEG_MAX:BigInt(-1)-BigInt(Number.MAX_SAFE_INTEGER),MAXINT32:BigInt("0xffffffff"),MAXINT64:BigInt("0xffffffffffffffff"),SHIFT32:BigInt(e.SHIFT32)},e.BigNumber){const t=new e.BigNumber(-1);e.BN={MINUS_ONE:t,NEG_MAX:t.minus(new e.BigNumber(Number.MAX_SAFE_INTEGER.toString(16),16)),TWO:new e.BigNumber(2),MAXINT:new e.BigNumber("0x20000000000000"),MAXINT32:new e.BigNumber(4294967295),MAXINT64:new e.BigNumber("0xffffffffffffffff"),SHIFT32:new e.BigNumber(e.SHIFT32)}}},774:(t,e,r)=>{"use strict";const n=r(71),i=r(785),o=r(32),s=r(873),a=r(202),u=r(66),{MT:l,NUMBYTES:c,SYMS:f,BI:h}=u,{Buffer:p}=r(764),d=Symbol("count"),y=Symbol("major type"),g=Symbol("error"),b=Symbol("not found");function m(t,e,r){const n=[];return n[d]=r,n[f.PARENT]=t,n[y]=e,n}function w(t,e){const r=new a;return r[d]=-1,r[f.PARENT]=t,r[y]=e,r}function _(t){return s.bufferToBigInt(t)}function E(t){return h.MINUS_ONE-s.bufferToBigInt(t)}class v extends Error{constructor(t,e){super(`Unexpected data: 0x${t.toString(16)}`),this.name="UnexpectedDataError",this.byte=t,this.value=e}}function S(t,e){switch(typeof t){case"function":return{options:{},cb:t};case"string":return{options:{encoding:t},cb:e};case"object":return{options:t||{},cb:e};default:throw new TypeError("Unknown option type")}}class A extends n{constructor(t={}){const{tags:e={},max_depth:r=-1,bigint:n=!0,preferWeb:i=!1,required:o=!1,encoding:s="hex",extendedResults:u=!1,...l}=t;super({defaultEncoding:s,...l}),this.running=!0,this.max_depth=r,this.tags=e,this.preferWeb=i,this.extendedResults=u,this.bigint=n,this.required=o,u&&(this.bs.on("read",this._onRead.bind(this)),this.valueBytes=new a),n&&(null==this.tags[2]&&(this.tags[2]=_),null==this.tags[3]&&(this.tags[3]=E))}static nullcheck(t){switch(t){case f.NULL:return null;case f.UNDEFINED:return;case b:throw new Error("Value not found");default:return t}}static decodeFirstSync(t,e={}){if(null==t)throw new TypeError("input required");({options:e}=S(e));const{encoding:r="hex",...n}=e,i=new A(n),o=s.guessEncoding(t,r),a=i._parse();let u=a.next();for(;!u.done;){const t=o.read(u.value);if(null==t||t.length!==u.value)throw new Error("Insufficient data");i.extendedResults&&i.valueBytes.write(t),u=a.next(t)}let l=null;if(i.extendedResults)l=u.value,l.unused=o.read();else if(l=A.nullcheck(u.value),o.length>0){const t=o.read(1);throw o.unshift(t),new v(t[0],l)}return l}static decodeAllSync(t,e={}){if(null==t)throw new TypeError("input required");({options:e}=S(e));const{encoding:r="hex",...n}=e,i=new A(n),o=s.guessEncoding(t,r),a=[];for(;o.length>0;){const t=i._parse();let e=t.next();for(;!e.done;){const r=o.read(e.value);if(null==r||r.length!==e.value)throw new Error("Insufficient data");i.extendedResults&&i.valueBytes.write(r),e=t.next(r)}a.push(A.nullcheck(e.value))}return a}static decodeFirst(t,e={},r=null){if(null==t)throw new TypeError("input required");({options:e,cb:r}=S(e,r));const{encoding:n="hex",required:i=!1,...o}=e,a=new A(o);let u=b;const l=s.guessEncoding(t,n),c=new Promise(((t,e)=>{a.on("data",(t=>{u=A.nullcheck(t),a.close()})),a.once("error",(r=>a.extendedResults&&r instanceof v?(u.unused=a.bs.slice(),t(u)):(u!==b&&(r.value=u),u=g,a.close(),e(r)))),a.once("end",(()=>{switch(u){case b:return i?e(new Error("No CBOR found")):t(u);case g:return;default:return t(u)}}))}));return"function"==typeof r&&c.then((t=>r(null,t)),r),l.pipe(a),c}static decodeAll(t,e={},r=null){if(null==t)throw new TypeError("input required");({options:e,cb:r}=S(e,r));const{encoding:n="hex",...i}=e,o=new A(i),a=[];o.on("data",(t=>a.push(A.nullcheck(t))));const u=new Promise(((t,e)=>{o.on("error",e),o.on("end",(()=>t(a)))}));return"function"==typeof r&&u.then((t=>r(void 0,t)),(t=>r(t,void 0))),s.guessEncoding(t,n).pipe(o),u}close(){this.running=!1,this.__fresh=!0}_onRead(t){this.valueBytes.write(t)}*_parse(){let t=null,e=0,r=null;for(;;){if(this.max_depth>=0&&e>this.max_depth)throw new Error("Maximum depth "+this.max_depth+" exceeded");const[n]=yield 1;if(!this.running)throw this.bs.unshift(p.from([n])),new v(n);const g=n>>5,b=31&n,_=null!=t?t[y]:void 0,E=null!=t?t.length:void 0;switch(b){case c.ONE:this.emit("more-bytes",g,1,_,E),[r]=yield 1;break;case c.TWO:case c.FOUR:case c.EIGHT:{const t=1<<b-24;this.emit("more-bytes",g,t,_,E);const e=yield t;r=g===l.SIMPLE_FLOAT?e:s.parseCBORint(b,e,this.bigint);break}case 28:case 29:case 30:throw this.running=!1,new Error("Additional info not implemented: "+b);case c.INDEFINITE:switch(g){case l.POS_INT:case l.NEG_INT:case l.TAG:throw new Error(`Invalid indefinite encoding for MT ${g}`)}r=-1;break;default:r=b}switch(g){case l.POS_INT:break;case l.NEG_INT:if(r===Number.MAX_SAFE_INTEGER)if(this.bigint)r=h.NEG_MAX;else{if(!u.BigNumber)throw new Error("No bigint and no bignumber.js");r=u.BN.NEG_MAX}else r=u.BigNumber&&r instanceof u.BigNumber?u.BN.MINUS_ONE.minus(r):"bigint"==typeof r?h.MINUS_ONE-r:-1-r;break;case l.BYTE_STRING:case l.UTF8_STRING:switch(r){case 0:this.emit("start-string",g,r,_,E),r=g===l.UTF8_STRING?"":this.preferWeb?new Uint8Array(0):p.allocUnsafe(0);break;case-1:this.emit("start",g,f.STREAM,_,E),t=w(t,g),e++;continue;default:this.emit("start-string",g,r,_,E),r=yield r,g===l.UTF8_STRING?r=s.utf8(r):this.preferWeb&&(r=new Uint8Array(r.buffer,r.byteOffset,r.length))}break;case l.ARRAY:case l.MAP:switch(r){case 0:r=g===l.MAP?{}:[];break;case-1:this.emit("start",g,f.STREAM,_,E),t=m(t,g,-1),e++;continue;default:this.emit("start",g,r,_,E),t=m(t,g,r*(g-3)),e++;continue}break;case l.TAG:this.emit("start",g,r,_,E),t=m(t,g,1),t.push(r),e++;continue;case l.SIMPLE_FLOAT:if("number"==typeof r){if(b===c.ONE&&r<32)throw new Error(`Invalid two-byte encoding of simple value ${r}`);const e=null!=t;r=o.decode(r,e,e&&t[d]<0)}else r=s.parseCBORfloat(r)}this.emit("value",r,_,E,b);let S=!1;for(;null!=t;){switch(!1){case r!==f.BREAK:t[d]=1;break;case!Array.isArray(t):t.push(r);break;case!(t instanceof a):{const e=t[y];if(null!=e&&e!==g)throw this.running=!1,new Error("Invalid major type in indefinite encoding");t.write(r)}}if(0!=--t[d]){S=!0;break}if(--e,delete t[d],Array.isArray(t))switch(t[y]){case l.ARRAY:r=t;break;case l.MAP:{let e=!0;if(t.length%2!=0)throw new Error("Invalid map length: "+t.length);for(let r=0,n=t.length;r<n;r+=2)if("string"!=typeof t[r]||"__proto__"===t[r]){e=!1;break}if(e){r={};for(let e=0,n=t.length;e<n;e+=2)r[t[e]]=t[e+1]}else{r=new Map;for(let e=0,n=t.length;e<n;e+=2)r.set(t[e],t[e+1])}break}case l.TAG:r=new i(t[0],t[1]).convert(this.tags)}else if(t instanceof a)switch(t[y]){case l.BYTE_STRING:r=t.slice(),this.preferWeb&&(r=new Uint8Array(r.buffer,r.byteOffset,r.length));break;case l.UTF8_STRING:r=t.toString("utf-8")}this.emit("stop",t[y]);const n=t;t=t[f.PARENT],delete n[f.PARENT],delete n[y]}if(!S){if(this.extendedResults){const t=this.valueBytes.slice(),e={value:A.nullcheck(r),bytes:t,length:t.length};return this.valueBytes=new a,e}return r}}}}A.NOT_FOUND=b,t.exports=A},694:(t,e,r)=>{"use strict";const n=r(830),i=r(774),o=r(873),s=r(202),{MT:a,SYMS:u}=r(66);class l extends n.Transform{constructor(t={}){const{separator:e="\n",stream_errors:r=!1,tags:n,max_depth:o,bigint:s,preferWeb:a,encoding:u,...l}=t;super({...l,readableObjectMode:!1,writableObjectMode:!1}),this.float_bytes=-1,this.separator=e,this.stream_errors=r,this.parser=new i({tags:n,max_depth:o,bigint:s,preferWeb:a,encoding:u}),this.parser.on("more-bytes",this._on_more.bind(this)),this.parser.on("value",this._on_value.bind(this)),this.parser.on("start",this._on_start.bind(this)),this.parser.on("stop",this._on_stop.bind(this)),this.parser.on("data",this._on_data.bind(this)),this.parser.on("error",this._on_error.bind(this))}_transform(t,e,r){return this.parser.write(t,e,r)}_flush(t){return this.parser._flush((e=>this.stream_errors?(e&&this._on_error(e),t()):t(e)))}static diagnose(t,e={},r=null){if(null==t)throw new Error("input required");({options:e,cb:r}=function(t,e){switch(typeof t){case"function":return{options:{},cb:t};case"string":return{options:{encoding:t},cb:e};case"object":return{options:t||{},cb:e};default:throw new TypeError("Unknown option type")}}(e,r));const{encoding:n="hex",...i}=e,a=new s,u=new l(i);let c=null;return"function"==typeof r?(u.on("end",(()=>r(null,a.toString("utf8")))),u.on("error",r)):c=new Promise(((t,e)=>{u.on("end",(()=>t(a.toString("utf8")))),u.on("error",e)})),u.pipe(a),o.guessEncoding(t,n).pipe(u),c}_on_error(t){return this.stream_errors?this.push(t.toString()):this.emit("error",t)}_on_more(t,e,r,n){t===a.SIMPLE_FLOAT&&(this.float_bytes={2:1,4:2,8:3}[e])}_fore(t,e){switch(t){case a.BYTE_STRING:case a.UTF8_STRING:case a.ARRAY:e>0&&this.push(", ");break;case a.MAP:e>0&&(e%2?this.push(": "):this.push(", "))}}_on_value(t,e,r){if(t===u.BREAK)return;this._fore(e,r);const n=this.float_bytes;this.float_bytes=-1,this.push(o.cborValueToString(t,n))}_on_start(t,e,r,n){switch(this._fore(r,n),t){case a.TAG:this.push(`${e}(`);break;case a.ARRAY:this.push("[");break;case a.MAP:this.push("{");break;case a.BYTE_STRING:case a.UTF8_STRING:this.push("(")}e===u.STREAM&&this.push("_ ")}_on_stop(t){switch(t){case a.TAG:this.push(")");break;case a.ARRAY:this.push("]");break;case a.MAP:this.push("}");break;case a.BYTE_STRING:case a.UTF8_STRING:this.push(")")}}_on_data(){this.push(this.separator)}}t.exports=l},666:(t,e,r)=>{"use strict";const n=r(830),i=r(202),o=r(873),s=r(66),{MT:a,NUMBYTES:u,SHIFT32:l,SIMPLE:c,SYMS:f,TAG:h,BI:p}=s,{Buffer:d}=r(764),y=a.SIMPLE_FLOAT<<5|u.TWO,g=a.SIMPLE_FLOAT<<5|u.FOUR,b=a.SIMPLE_FLOAT<<5|u.EIGHT,m=a.SIMPLE_FLOAT<<5|c.TRUE,w=a.SIMPLE_FLOAT<<5|c.FALSE,_=a.SIMPLE_FLOAT<<5|c.UNDEFINED,E=a.SIMPLE_FLOAT<<5|c.NULL,v=d.from([255]),S=d.from("f97e00","hex"),A=d.from("f9fc00","hex"),T=d.from("f97c00","hex"),I=d.from("f98000","hex");class B extends n.Transform{constructor(t={}){const{canonical:e=!1,encodeUndefined:r,disallowUndefinedKeys:n=!1,dateType:o="number",collapseBigIntegers:a=!1,detectLoops:u=!1,omitUndefinedProperties:l=!1,genTypes:c=[],...f}=t;if(super({...f,readableObjectMode:!1,writableObjectMode:!0}),this.canonical=e,this.encodeUndefined=r,this.disallowUndefinedKeys=n,this.dateType=function(t){if(!t)return"number";switch(t.toLowerCase()){case"number":return"number";case"float":return"float";case"int":return"int";case"string":return"string"}throw new TypeError(`dateType invalid, got "${t}"`)}(o),this.collapseBigIntegers=!!this.canonical||a,this.detectLoops=u,"boolean"==typeof u)u&&(this.detectLoops=new WeakSet);else if(!(u instanceof WeakSet))throw new TypeError("detectLoops must be boolean or WeakSet");if(this.omitUndefinedProperties=l,this.semanticTypes={Array:this._pushArray,Date:this._pushDate,Buffer:this._pushBuffer,[d.name]:this._pushBuffer,Map:this._pushMap,NoFilter:this._pushNoFilter,[i.name]:this._pushNoFilter,RegExp:this._pushRegexp,Set:this._pushSet,ArrayBuffer:this._pushArrayBuffer,Uint8ClampedArray:this._pushTypedArray,Uint8Array:this._pushTypedArray,Uint16Array:this._pushTypedArray,Uint32Array:this._pushTypedArray,Int8Array:this._pushTypedArray,Int16Array:this._pushTypedArray,Int32Array:this._pushTypedArray,Float32Array:this._pushTypedArray,Float64Array:this._pushTypedArray,URL:this._pushURL,Boolean:this._pushBoxed,Number:this._pushBoxed,String:this._pushBoxed},s.BigNumber&&(this.semanticTypes[s.BigNumber.name]=this._pushBigNumber),"undefined"!=typeof BigUint64Array&&(this.semanticTypes[BigUint64Array.name]=this._pushTypedArray),"undefined"!=typeof BigInt64Array&&(this.semanticTypes[BigInt64Array.name]=this._pushTypedArray),Array.isArray(c))for(let t=0,e=c.length;t<e;t+=2)this.addSemanticType(c[t],c[t+1]);else for(const[t,e]of Object.entries(c))this.addSemanticType(t,e)}_transform(t,e,r){return r(!1===this.pushAny(t)?new Error("Push Error"):void 0)}_flush(t){return t()}addSemanticType(t,e){const r="string"==typeof t?t:t.name,n=this.semanticTypes[r];if(e){if("function"!=typeof e)throw new TypeError("fun must be of type function");this.semanticTypes[r]=e}else n&&delete this.semanticTypes[r];return n}_pushUInt8(t){const e=d.allocUnsafe(1);return e.writeUInt8(t,0),this.push(e)}_pushUInt16BE(t){const e=d.allocUnsafe(2);return e.writeUInt16BE(t,0),this.push(e)}_pushUInt32BE(t){const e=d.allocUnsafe(4);return e.writeUInt32BE(t,0),this.push(e)}_pushFloatBE(t){const e=d.allocUnsafe(4);return e.writeFloatBE(t,0),this.push(e)}_pushDoubleBE(t){const e=d.allocUnsafe(8);return e.writeDoubleBE(t,0),this.push(e)}_pushNaN(){return this.push(S)}_pushInfinity(t){const e=t<0?A:T;return this.push(e)}_pushFloat(t){if(this.canonical){const e=d.allocUnsafe(2);if(o.writeHalf(e,t))return this._pushUInt8(y)&&this.push(e)}return Math.fround(t)===t?this._pushUInt8(g)&&this._pushFloatBE(t):this._pushUInt8(b)&&this._pushDoubleBE(t)}_pushInt(t,e,r){const n=e<<5;switch(!1){case!(t<24):return this._pushUInt8(n|t);case!(t<=255):return this._pushUInt8(n|u.ONE)&&this._pushUInt8(t);case!(t<=65535):return this._pushUInt8(n|u.TWO)&&this._pushUInt16BE(t);case!(t<=4294967295):return this._pushUInt8(n|u.FOUR)&&this._pushUInt32BE(t);case!(t<=Number.MAX_SAFE_INTEGER):return this._pushUInt8(n|u.EIGHT)&&this._pushUInt32BE(Math.floor(t/l))&&this._pushUInt32BE(t%l);default:return e===a.NEG_INT?this._pushFloat(r):this._pushFloat(t)}}_pushIntNum(t){return Object.is(t,-0)?this.push(I):t<0?this._pushInt(-t-1,a.NEG_INT,t):this._pushInt(t,a.POS_INT)}_pushNumber(t){switch(!1){case!isNaN(t):return this._pushNaN();case isFinite(t):return this._pushInfinity(t);case Math.round(t)!==t:return this._pushIntNum(t);default:return this._pushFloat(t)}}_pushString(t){const e=d.byteLength(t,"utf8");return this._pushInt(e,a.UTF8_STRING)&&this.push(t,"utf8")}_pushBoolean(t){return this._pushUInt8(t?m:w)}_pushUndefined(t){switch(typeof this.encodeUndefined){case"undefined":return this._pushUInt8(_);case"function":return this.pushAny(this.encodeUndefined.call(this,t));case"object":{const t=o.bufferishToBuffer(this.encodeUndefined);if(t)return this.push(t)}}return this.pushAny(this.encodeUndefined)}_pushNull(t){return this._pushUInt8(E)}_pushArray(t,e,r){r={indefinite:!1,...r};const n=e.length;if(r.indefinite){if(!t._pushUInt8(a.ARRAY<<5|u.INDEFINITE))return!1}else if(!t._pushInt(n,a.ARRAY))return!1;for(let r=0;r<n;r++)if(!t.pushAny(e[r]))return!1;return!(r.indefinite&&!t.push(v))}_pushTag(t){return this._pushInt(t,a.TAG)}_pushDate(t,e){switch(t.dateType){case"string":return t._pushTag(h.DATE_STRING)&&t._pushString(e.toISOString());case"int":case"integer":return t._pushTag(h.DATE_EPOCH)&&t._pushIntNum(Math.round(e/1e3));case"float":return t._pushTag(h.DATE_EPOCH)&&t._pushFloat(e/1e3);case"number":default:return t._pushTag(h.DATE_EPOCH)&&t.pushAny(e/1e3)}}_pushBuffer(t,e){return t._pushInt(e.length,a.BYTE_STRING)&&t.push(e)}_pushNoFilter(t,e){return t._pushBuffer(t,e.slice())}_pushRegexp(t,e){return t._pushTag(h.REGEXP)&&t.pushAny(e.source)}_pushSet(t,e){if(!t._pushTag(h.SET))return!1;if(!t._pushInt(e.size,a.ARRAY))return!1;for(const r of e)if(!t.pushAny(r))return!1;return!0}_pushURL(t,e){return t._pushTag(h.URI)&&t.pushAny(e.toString())}_pushBoxed(t,e){return t._pushAny(e.valueOf())}_pushBigint(t){let e=a.POS_INT,r=h.POS_BIGINT;if(t.isNegative()&&(t=t.negated().minus(1),e=a.NEG_INT,r=h.NEG_BIGINT),this.collapseBigIntegers&&t.lte(s.BN.MAXINT64))return t.lte(s.BN.MAXINT32)?this._pushInt(t.toNumber(),e):this._pushUInt8(e<<5|u.EIGHT)&&this._pushUInt32BE(t.dividedToIntegerBy(s.BN.SHIFT32).toNumber())&&this._pushUInt32BE(t.mod(s.BN.SHIFT32).toNumber());let n=t.toString(16);n.length%2&&(n="0"+n);const i=d.from(n,"hex");return this._pushTag(r)&&this._pushBuffer(this,i)}_pushJSBigint(t){let e=a.POS_INT,r=h.POS_BIGINT;if(t<0&&(t=-t+p.MINUS_ONE,e=a.NEG_INT,r=h.NEG_BIGINT),this.collapseBigIntegers&&t<=p.MAXINT64)return t<=4294967295?this._pushInt(Number(t),e):this._pushUInt8(e<<5|u.EIGHT)&&this._pushUInt32BE(Number(t/p.SHIFT32))&&this._pushUInt32BE(Number(t%p.SHIFT32));let n=t.toString(16);n.length%2&&(n="0"+n);const i=d.from(n,"hex");return this._pushTag(r)&&this._pushBuffer(this,i)}_pushBigNumber(t,e){if(e.isNaN())return t._pushNaN();if(!e.isFinite())return t._pushInfinity(e.isNegative()?-1/0:1/0);if(e.isInteger())return t._pushBigint(e);if(!t._pushTag(h.DECIMAL_FRAC)||!t._pushInt(2,a.ARRAY))return!1;const r=e.decimalPlaces(),n=e.shiftedBy(r);return!!t._pushIntNum(-r)&&(n.abs().isLessThan(s.BN.MAXINT)?t._pushIntNum(n.toNumber()):t._pushBigint(n))}_pushMap(t,e,r){r={indefinite:!1,...r};let n=[...e.entries()];if(t.omitUndefinedProperties&&(n=n.filter((([t,e])=>void 0!==e))),r.indefinite){if(!t._pushUInt8(a.MAP<<5|u.INDEFINITE))return!1}else if(!t._pushInt(n.length,a.MAP))return!1;if(t.canonical){const e=new B({genTypes:t.semanticTypes,canonical:t.canonical,detectLoops:!!t.detectLoops,dateType:t.dateType,disallowUndefinedKeys:t.disallowUndefinedKeys,collapseBigIntegers:t.collapseBigIntegers}),r=new i({highWaterMark:t.readableHighWaterMark});e.pipe(r),n.sort((([t],[n])=>{e.pushAny(t);const i=r.read();e.pushAny(n);const o=r.read();return i.compare(o)}));for(const[e,r]of n){if(t.disallowUndefinedKeys&&void 0===e)throw new Error("Invalid Map key: undefined");if(!t.pushAny(e)||!t.pushAny(r))return!1}}else for(const[e,r]of n){if(t.disallowUndefinedKeys&&void 0===e)throw new Error("Invalid Map key: undefined");if(!t.pushAny(e)||!t.pushAny(r))return!1}return!(r.indefinite&&!t.push(v))}_pushTypedArray(t,e){let r=64,n=e.BYTES_PER_ELEMENT;const{name:i}=e.constructor;return i.startsWith("Float")?(r|=16,n/=2):i.includes("U")||(r|=8),(i.includes("Clamped")||1!==n&&!o.isBigEndian())&&(r|=4),r|={1:0,2:1,4:2,8:3}[n],!!t._pushTag(r)&&t._pushBuffer(t,d.from(e.buffer,e.byteOffset,e.byteLength))}_pushArrayBuffer(t,e){return t._pushBuffer(t,d.from(e))}removeLoopDetectors(){return!!this.detectLoops&&(this.detectLoops=new WeakSet,!0)}_pushObject(t,e){if(!t)return this._pushNull(t);if(!(e={indefinite:!1,skipTypes:!1,...e}).indefinite&&this.detectLoops){if(this.detectLoops.has(t))throw new Error("Loop detected while CBOR encoding.\nCall removeLoopDetectors before resuming.");this.detectLoops.add(t)}if(!e.skipTypes){const e=t.encodeCBOR;if("function"==typeof e)return e.call(t,this);const r=this.semanticTypes[t.constructor.name];if(r)return r.call(t,this,t)}const r=Object.keys(t).filter((e=>{const r=typeof t[e];return"function"!==r&&(!this.omitUndefinedProperties||"undefined"!==r)})),n={};if(this.canonical&&r.sort(((t,e)=>{const r=n[t]||(n[t]=B.encode(t)),i=n[e]||(n[e]=B.encode(e));return r.compare(i)})),e.indefinite){if(!this._pushUInt8(a.MAP<<5|u.INDEFINITE))return!1}else if(!this._pushInt(r.length,a.MAP))return!1;let i=null;for(let e=0,o=r.length;e<o;e++){const o=r[e];if(this.canonical&&(i=n[o])){if(!this.push(i))return!1}else if(!this._pushString(o))return!1;if(!this.pushAny(t[o]))return!1}if(e.indefinite){if(!this.push(v))return!1}else this.detectLoops&&this.detectLoops.delete(t);return!0}pushAny(t){switch(typeof t){case"number":return this._pushNumber(t);case"bigint":return this._pushJSBigint(t);case"string":return this._pushString(t);case"boolean":return this._pushBoolean(t);case"undefined":return this._pushUndefined(t);case"object":return this._pushObject(t);case"symbol":switch(t){case f.NULL:return this._pushNull(null);case f.UNDEFINED:return this._pushUndefined(void 0);default:throw new Error("Unknown symbol: "+t.toString())}default:throw new Error("Unknown type: "+typeof t+", "+(t.toString?t.toString():""))}}_pushAny(t){return this.pushAny(t)}_encodeAll(t){const e=new i({highWaterMark:this.readableHighWaterMark});this.pipe(e);for(const e of t)this.pushAny(e);return this.end(),e.read()}static encodeIndefinite(t,e,r={}){if(null==e){if(null==this)throw new Error("No object to encode");e=this}const{chunkSize:n=4096}=r;let i=!0;const s=typeof e;let l=null;if("string"===s){i=i&&t._pushUInt8(a.UTF8_STRING<<5|u.INDEFINITE);let r=0;for(;r<e.length;){const o=r+n;i=i&&t._pushString(e.slice(r,o)),r=o}i=i&&t.push(v)}else if(l=o.bufferishToBuffer(e)){i=i&&t._pushUInt8(a.BYTE_STRING<<5|u.INDEFINITE);let e=0;for(;e<l.length;){const r=e+n;i=i&&t._pushBuffer(t,l.slice(e,r)),e=r}i=i&&t.push(v)}else if(Array.isArray(e))i=i&&t._pushArray(t,e,{indefinite:!0});else if(e instanceof Map)i=i&&t._pushMap(t,e,{indefinite:!0});else{if("object"!==s)throw new Error("Invalid indefinite encoding");i=i&&t._pushObject(e,{indefinite:!0,skipTypes:!0})}return i}static encode(...t){return(new B)._encodeAll(t)}static encodeCanonical(...t){return new B({canonical:!0})._encodeAll(t)}static encodeOne(t,e){return new B(e)._encodeAll([t])}static encodeAsync(t,e){return new Promise(((r,n)=>{const i=[],o=new B(e);o.on("data",(t=>i.push(t))),o.on("error",n),o.on("finish",(()=>r(d.concat(i)))),o.pushAny(t),o.end()}))}}t.exports=B},70:(t,e,r)=>{"use strict";const{Buffer:n}=r(764),i=r(666),o=r(774),{MT:s}=r(66);class a extends Map{constructor(t){super(t)}static _encode(t){return i.encodeCanonical(t).toString("base64")}static _decode(t){return o.decodeFirstSync(t,"base64")}get(t){return super.get(a._encode(t))}set(t,e){return super.set(a._encode(t),e)}delete(t){return super.delete(a._encode(t))}has(t){return super.has(a._encode(t))}*keys(){for(const t of super.keys())yield a._decode(t)}*entries(){for(const t of super.entries())yield[a._decode(t[0]),t[1]]}[Symbol.iterator](){return this.entries()}forEach(t,e){if("function"!=typeof t)throw new TypeError("Must be function");for(const e of super.entries())t.call(this,e[1],a._decode(e[0]),this)}encodeCBOR(t){if(!t._pushInt(this.size,s.MAP))return!1;if(t.canonical){const e=Array.from(super.entries()).map((t=>[n.from(t[0],"base64"),t[1]]));e.sort(((t,e)=>t[0].compare(e[0])));for(const r of e)if(!t.push(r[0])||!t.pushAny(r[1]))return!1}else for(const e of super.entries())if(!t.push(n.from(e[0],"base64"))||!t.pushAny(e[1]))return!1;return!0}}t.exports=a},32:(t,e,r)=>{"use strict";const{MT:n,SIMPLE:i,SYMS:o}=r(66);class s{constructor(t){if("number"!=typeof t)throw new Error("Invalid Simple type: "+typeof t);if(t<0||t>255||(0|t)!==t)throw new Error("value must be a small positive integer: "+t);this.value=t}toString(){return"simple("+this.value+")"}inspect(t,e){return"simple("+this.value+")"}encodeCBOR(t){return t._pushInt(this.value,n.SIMPLE_FLOAT)}static isSimple(t){return t instanceof s}static decode(t,e=!0,r=!1){switch(t){case i.FALSE:return!1;case i.TRUE:return!0;case i.NULL:return e?null:o.NULL;case i.UNDEFINED:if(e)return;return o.UNDEFINED;case-1:if(!e||!r)throw new Error("Invalid BREAK");return o.BREAK;default:return new s(t)}}}t.exports=s},785:(t,e,r)=>{"use strict";const n=r(66),i=r(873);function o(t,e){if(i.isBufferish(t))t.toJSON=e;else if(Array.isArray(t))for(const r of t)o(r,e);else if(t&&"object"==typeof t&&(!(t instanceof u)||t.tag<21||t.tag>23))for(const r of Object.values(t))o(r,e)}const s={64:Uint8Array,65:Uint16Array,66:Uint32Array,68:Uint8ClampedArray,69:Uint16Array,70:Uint32Array,72:Int8Array,73:Int16Array,74:Int32Array,77:Int16Array,78:Int32Array,81:Float32Array,82:Float64Array,85:Float32Array,86:Float64Array};"undefined"!=typeof BigUint64Array&&(s[67]=BigUint64Array,s[71]=BigUint64Array),"undefined"!=typeof BigInt64Array&&(s[75]=BigInt64Array,s[79]=BigInt64Array);const a=Symbol("INTERNAL_JSON");class u{constructor(t,e,r){if(this.tag=t,this.value=e,this.err=r,"number"!=typeof this.tag)throw new Error("Invalid tag type ("+typeof this.tag+")");if(this.tag<0||(0|this.tag)!==this.tag)throw new Error("Tag must be a positive integer: "+this.tag)}toJSON(){if(this[a])return this[a]();const t={tag:this.tag,value:this.value};return this.err&&(t.err=this.err),t}toString(){return`${this.tag}(${JSON.stringify(this.value)})`}encodeCBOR(t){return t._pushTag(this.tag),t.pushAny(this.value)}convert(t){let e=null!=t?t[this.tag]:void 0;if("function"!=typeof e&&(e=u["_tag_"+this.tag],"function"!=typeof e)){if(e=s[this.tag],"function"!=typeof e)return this;e=this._toTypedArray}try{return e.call(this,this.value)}catch(t){return t&&t.message&&t.message.length>0?this.err=t.message:this.err=t,this}}_toTypedArray(t){const{tag:e}=this,r=s[e];if(!r)throw new Error(`Invalid typed array tag: ${e}`);const n=2**(((16&e)>>4)+(3&e));return!(4&e)!==i.isBigEndian()&&n>1&&function(t,e,r,n){const i=new DataView(t),[o,s]={2:[i.getUint16,i.setUint16],4:[i.getUint32,i.setUint32],8:[i.getBigUint64,i.setBigUint64]}[e],a=r+n;for(let t=r;t<a;t+=e)s.call(i,t,o.call(i,t,!0))}(t.buffer,n,t.byteOffset,t.byteLength),new r(t.buffer.slice(t.byteOffset,t.byteOffset+t.byteLength))}static _tag_0(t){return new Date(t)}static _tag_1(t){return new Date(1e3*t)}static _tag_2(t){return i.bufferToBignumber(t)}static _tag_3(t){const e=i.bufferToBignumber(t);return n.BN.MINUS_ONE.minus(e)}static _tag_4(t){if(!n.BigNumber)throw new Error("No bignumber.js");return new n.BigNumber(t[1]).shiftedBy(t[0])}static _tag_5(t){if(!n.BigNumber)throw new Error("No bignumber.js");return n.BN.TWO.pow(t[0]).times(t[1])}static _tag_21(t){return i.isBufferish(t)?this[a]=()=>i.base64url(t):o(t,(function(){return i.base64url(this)})),this}static _tag_22(t){return i.isBufferish(t)?this[a]=()=>i.base64(t):o(t,(function(){return i.base64(this)})),this}static _tag_23(t){return i.isBufferish(t)?this[a]=()=>t.toString("hex"):o(t,(function(){return this.toString("hex")})),this}static _tag_32(t){return new URL(t)}static _tag_33(t){if(!t.match(/^[a-zA-Z0-9_-]+$/))throw new Error("Invalid base64url characters");const e=t.length%4;if(1===e)throw new Error("Invalid base64url length");if(2===e){if(-1==="AQgw".indexOf(t[t.length-1]))throw new Error("Invalid base64 padding")}else if(3===e&&-1==="AEIMQUYcgkosw048".indexOf(t[t.length-1]))throw new Error("Invalid base64 padding");return this}static _tag_34(t){const e=t.match(/^[a-zA-Z0-9+/]+(={0,2})$/);if(!e)throw new Error("Invalid base64url characters");if(t.length%4!=0)throw new Error("Invalid base64url length");if("="===e[1]){if(-1==="AQgw".indexOf(t[t.length-2]))throw new Error("Invalid base64 padding")}else if("=="===e[1]&&-1==="AEIMQUYcgkosw048".indexOf(t[t.length-3]))throw new Error("Invalid base64 padding");return this}static _tag_35(t){return new RegExp(t)}static _tag_258(t){return new Set(t)}}u.INTERNAL_JSON=a,t.exports=u},873:(t,e,r)=>{"use strict";const{Buffer:n}=r(764),i=r(202),o=r(830),s=r(960),a=r(66),{NUMBYTES:u,SHIFT32:l,BI:c,SYMS:f}=a;let h=null;try{h=r(669)}catch(t){h=r(595)}e.inspect=h.inspect;const p=new s("utf8",{fatal:!0,ignoreBOM:!0});e.utf8=t=>p.decode(t),e.utf8.checksUTF8=!0,e.isBufferish=function(t){return t&&"object"==typeof t&&(n.isBuffer(t)||t instanceof Uint8Array||t instanceof Uint8ClampedArray||t instanceof ArrayBuffer||t instanceof DataView)},e.bufferishToBuffer=function(t){return n.isBuffer(t)?t:ArrayBuffer.isView(t)?n.from(t.buffer,t.byteOffset,t.byteLength):t instanceof ArrayBuffer?n.from(t):null},e.parseCBORint=function(t,e,r=!0){switch(t){case u.ONE:return e.readUInt8(0);case u.TWO:return e.readUInt16BE(0);case u.FOUR:return e.readUInt32BE(0);case u.EIGHT:{const t=e.readUInt32BE(0),n=e.readUInt32BE(4);if(t>2097151){if(r)return BigInt(t)*c.SHIFT32+BigInt(n);if(!a.BigNumber)throw new Error("No bigint and no bignumber.js");return new a.BigNumber(t).times(l).plus(n)}return t*l+n}default:throw new Error("Invalid additional info for int: "+t)}},e.writeHalf=function(t,e){const r=n.allocUnsafe(4);r.writeFloatBE(e,0);const i=r.readUInt32BE(0);if(0!=(8191&i))return!1;let o=i>>16&32768;const s=i>>23&255,a=8388607&i;if(s>=113&&s<=142)o+=(s-112<<10)+(a>>13);else{if(!(s>=103&&s<113))return!1;if(a&(1<<126-s)-1)return!1;o+=a+8388608>>126-s}return t.writeUInt16BE(o),!0},e.parseHalf=function(t){const e=128&t[0]?-1:1,r=(124&t[0])>>2,n=(3&t[0])<<8|t[1];return r?31===r?e*(n?NaN:Infinity):e*Math.pow(2,r-25)*(1024+n):5.960464477539063e-8*e*n},e.parseCBORfloat=function(t){switch(t.length){case 2:return e.parseHalf(t);case 4:return t.readFloatBE(0);case 8:return t.readDoubleBE(0);default:throw new Error("Invalid float size: "+t.length)}},e.hex=function(t){return n.from(t.replace(/^0x/,""),"hex")},e.bin=function(t){let e=0,r=(t=t.replace(/\s/g,"")).length%8||8;const i=[];for(;r<=t.length;)i.push(parseInt(t.slice(e,r),2)),e=r,r+=8;return n.from(i)},e.arrayEqual=function(t,e){return null==t&&null==e||null!=t&&null!=e&&t.length===e.length&&t.every(((t,r)=>t===e[r]))},e.bufferToBignumber=function(t){if(!a.BigNumber)throw new Error("No bigint and no bignumber.js");return new a.BigNumber(t.toString("hex"),16)},e.bufferToBigInt=function(t){return BigInt("0x"+t.toString("hex"))},e.cborValueToString=function(t,r=-1){switch(typeof t){case"symbol":{switch(t){case f.NULL:return"null";case f.UNDEFINED:return"undefined";case f.BREAK:return"BREAK"}if(t.description)return t.description;const e=t.toString().match(/^Symbol\((.*)\)/);return e&&e[1]?e[1]:"Symbol"}case"string":return JSON.stringify(t);case"bigint":return t.toString();case"number":return r>0?h.inspect(t)+"_"+r:h.inspect(t)}const n=e.bufferishToBuffer(t);if(n){const t=n.toString("hex");return r===-1/0?t:`h'${t}'`}return a.BigNumber&&a.BigNumber.isBigNumber(t)?t.toString():t&&"function"==typeof t.inspect?t.inspect():h.inspect(t)},e.guessEncoding=function(t,r){if("string"==typeof t)return new i(t,null!=r?r:"hex");const n=e.bufferishToBuffer(t);if(n)return new i(n);if((s=t)instanceof o.Readable||["read","on","pipe"].every((t=>"function"==typeof s[t])))return t;var s;throw new Error("Unknown input type")};const d={"=":"","+":"-","/":"_"};e.base64url=function(t){return e.bufferishToBuffer(t).toString("base64").replace(/[=+/]/g,(t=>d[t]))},e.base64=function(t){return e.bufferishToBuffer(t).toString("base64")},e.isBigEndian=function(){const t=new Uint8Array(4);return!((new Uint32Array(t.buffer)[0]=1)&t[0])}},960:(t,e,r)=>{"use strict";let n=null;if("function"==typeof TextDecoder)n=TextDecoder;else if("undefined"!=typeof window)n=window.TextDecoder;else if("undefined"!=typeof self)n=self.TextDecoder;else try{const t=r(669);"function"!=typeof n&&(n=t.TextDecoder)}catch(t){}if("function"!=typeof n){class t{constructor(t,e){this.utfLabel=t,this.options=e}decode(t){const e=t.toString(this.utfLabel);if(this.options.fatal)for(const t of e)if(65533===t.codePointAt(0)){const t=new TypeError("[ERR_ENCODING_INVALID_ENCODED_DATA]: The encoded data was not valid for encoding "+this.utfLabel);throw t.code="ERR_ENCODING_INVALID_ENCODED_DATA",t.errno=12,t}return e}}n=t}t.exports=n},202:(t,e,r)=>{"use strict";const n=r(830),{Buffer:i}=r(764),o=r(960);let s=null,a=Symbol.for("nodejs.util.inspect.custom");try{s=r(669),a=s.inspect.custom}catch(t){}const u=new o("utf8",{fatal:!0,ignoreBOM:!0});class l extends n.Transform{constructor(t,e,r){null==r&&(r={});let n=null,o=null;switch(typeof t){case"object":i.isBuffer(t)?(n=t,null!=e&&"object"==typeof e&&(r=e)):r=t;break;case"string":n=t,null!=e&&"object"==typeof e?r=e:o=e}null==r&&(r={}),null==n&&(n=r.input),null==o&&(o=r.inputEncoding),delete r.input,delete r.inputEncoding;const s=null==r.watchPipe||r.watchPipe;delete r.watchPipe;const a=!!r.readError;delete r.readError,super(r),this.readError=a,s&&this.on("pipe",(t=>{const e=t._readableState.objectMode;if(this.length>0&&e!==this._readableState.objectMode)throw new Error("Do not switch objectMode in the middle of the stream");this._readableState.objectMode=e,this._writableState.objectMode=e})),null!=n&&this.end(n,o)}static isNoFilter(t){return t instanceof this}static compare(t,e){if(!(t instanceof this))throw new TypeError("Arguments must be NoFilters");return t===e?0:t.compare(e)}static concat(t,e){if(!Array.isArray(t))throw new TypeError("list argument must be an Array of NoFilters");if(0===t.length||0===e)return i.alloc(0);null==e&&(e=t.reduce(((t,e)=>{if(!(e instanceof l))throw new TypeError("list argument must be an Array of NoFilters");return t+e.length}),0));let r=!0,n=!0;const o=t.map((t=>{if(!(t instanceof l))throw new TypeError("list argument must be an Array of NoFilters");const e=t.slice();return i.isBuffer(e)?n=!1:r=!1,e}));if(r)return i.concat(o,e);if(n)return[].concat(...o).slice(0,e);throw new Error("Concatenating mixed object and byte streams not supported")}_transform(t,e,r){this._readableState.objectMode||i.isBuffer(t)||(t=i.from(t,e)),this.push(t),r()}_bufArray(){let t=this._readableState.buffer;if(!Array.isArray(t)){let e=t.head;for(t=[];null!=e;)t.push(e.data),e=e.next}return t}read(t){const e=super.read(t);if(null!=e){if(this.emit("read",e),this.readError&&e.length<t)throw new Error(`Read ${e.length}, wanted ${t}`)}else if(this.readError)throw new Error(`No data available, wanted ${t}`);return e}promise(t){let e=!1;return new Promise(((r,n)=>{this.on("finish",(()=>{const n=this.read();null==t||e||(e=!0,t(null,n)),r(n)})),this.on("error",(r=>{null==t||e||(e=!0,t(r)),n(r)}))}))}compare(t){if(!(t instanceof l))throw new TypeError("Arguments must be NoFilters");if(this===t)return 0;const e=this.slice(),r=t.slice();if(i.isBuffer(e)&&i.isBuffer(r))return e.compare(r);throw new Error("Cannot compare streams in object mode")}equals(t){return 0===this.compare(t)}slice(t,e){if(this._readableState.objectMode)return this._bufArray().slice(t,e);const r=this._bufArray();switch(r.length){case 0:return i.alloc(0);case 1:return r[0].slice(t,e);default:return i.concat(r).slice(t,e)}}get(t){return this.slice()[t]}toJSON(){const t=this.slice();return i.isBuffer(t)?t.toJSON():t}toString(t,e,r){const n=this.slice(e,r);return i.isBuffer(n)?t&&"utf8"!==t?n.toString(t,e,r):u.decode(n):JSON.stringify(n)}inspect(t,e){return this[a](t,e)}[a](t,e){const r=this._bufArray().map((t=>i.isBuffer(t)?(null!=e?e.stylize:void 0)?e.stylize(t.toString("hex"),"string"):t.toString("hex"):s?s.inspect(t,e):t.toString())).join(", ");return`${this.constructor.name} [${r}]`}get length(){return this._readableState.length}writeBigInt(t){let e=t.toString(16);if(t<0){const r=BigInt(Math.floor(e.length/2));e=(t=(BigInt(1)<<r*BigInt(8))+t).toString(16)}return e.length%2&&(e="0"+e),this.push(i.from(e,"hex"))}readUBigInt(t){const e=this.read(t);return i.isBuffer(e)?BigInt("0x"+e.toString("hex")):null}readBigInt(t){const e=this.read(t);if(!i.isBuffer(e))return null;let r=BigInt("0x"+e.toString("hex"));return 128&e[0]&&(r-=BigInt(1)<<BigInt(e.length)*BigInt(8)),r}}function c(t,e){return function(r){const n=this.read(e);return i.isBuffer(n)?n[t].call(n,0,!0):null}}function f(t,e){return function(r){const n=i.alloc(e);return n[t].call(n,r,0,!0),this.push(n)}}Object.assign(l.prototype,{writeUInt8:f("writeUInt8",1),writeUInt16LE:f("writeUInt16LE",2),writeUInt16BE:f("writeUInt16BE",2),writeUInt32LE:f("writeUInt32LE",4),writeUInt32BE:f("writeUInt32BE",4),writeInt8:f("writeInt8",1),writeInt16LE:f("writeInt16LE",2),writeInt16BE:f("writeInt16BE",2),writeInt32LE:f("writeInt32LE",4),writeInt32BE:f("writeInt32BE",4),writeFloatLE:f("writeFloatLE",4),writeFloatBE:f("writeFloatBE",4),writeDoubleLE:f("writeDoubleLE",8),writeDoubleBE:f("writeDoubleBE",8),readUInt8:c("readUInt8",1),readUInt16LE:c("readUInt16LE",2),readUInt16BE:c("readUInt16BE",2),readUInt32LE:c("readUInt32LE",4),readUInt32BE:c("readUInt32BE",4),readInt8:c("readInt8",1),readInt16LE:c("readInt16LE",2),readInt16BE:c("readInt16BE",2),readInt32LE:c("readInt32LE",4),readInt32BE:c("readInt32BE",4),readFloatLE:c("readFloatLE",4),readFloatBE:c("readFloatBE",4),readDoubleLE:c("readDoubleLE",8),readDoubleBE:c("readDoubleBE",8)}),t.exports=l},71:(t,e,r)=>{"use strict";const n=r(830),i=r(202),o=n.Transform;t.exports=class extends o{constructor(t){super(t),this._writableState.objectMode=!1,this._readableState.objectMode=!0,this.bs=new i,this.__restart()}_transform(t,e,r){for(this.bs.write(t);this.bs.length>=this.__needed;){let t=null;const e=null===this.__needed?void 0:this.bs.read(this.__needed);try{t=this.__parser.next(e)}catch(t){return r(t)}this.__needed&&(this.__fresh=!1),t.done?(this.push(t.value),this.__restart()):this.__needed=t.value||1/0}return r()}*_parse(){throw new Error("Must be implemented in subclass")}__restart(){this.__needed=null,this.__parser=this._parse(),this.__fresh=!0}_flush(t){t(this.__fresh?null:new Error("unexpected end of input"))}}},187:t=>{"use strict";var e,r="object"==typeof Reflect?Reflect:null,n=r&&"function"==typeof r.apply?r.apply:function(t,e,r){return Function.prototype.apply.call(t,e,r)};e=r&&"function"==typeof r.ownKeys?r.ownKeys:Object.getOwnPropertySymbols?function(t){return Object.getOwnPropertyNames(t).concat(Object.getOwnPropertySymbols(t))}:function(t){return Object.getOwnPropertyNames(t)};var i=Number.isNaN||function(t){return t!=t};function o(){o.init.call(this)}t.exports=o,t.exports.once=function(t,e){return new Promise((function(r,n){function i(r){t.removeListener(e,o),n(r)}function o(){"function"==typeof t.removeListener&&t.removeListener("error",i),r([].slice.call(arguments))}y(t,e,o,{once:!0}),"error"!==e&&function(t,e,r){"function"==typeof t.on&&y(t,"error",e,{once:!0})}(t,i)}))},o.EventEmitter=o,o.prototype._events=void 0,o.prototype._eventsCount=0,o.prototype._maxListeners=void 0;var s=10;function a(t){if("function"!=typeof t)throw new TypeError('The "listener" argument must be of type Function. Received type '+typeof t)}function u(t){return void 0===t._maxListeners?o.defaultMaxListeners:t._maxListeners}function l(t,e,r,n){var i,o,s,l;if(a(r),void 0===(o=t._events)?(o=t._events=Object.create(null),t._eventsCount=0):(void 0!==o.newListener&&(t.emit("newListener",e,r.listener?r.listener:r),o=t._events),s=o[e]),void 0===s)s=o[e]=r,++t._eventsCount;else if("function"==typeof s?s=o[e]=n?[r,s]:[s,r]:n?s.unshift(r):s.push(r),(i=u(t))>0&&s.length>i&&!s.warned){s.warned=!0;var c=new Error("Possible EventEmitter memory leak detected. "+s.length+" "+String(e)+" listeners added. Use emitter.setMaxListeners() to increase limit");c.name="MaxListenersExceededWarning",c.emitter=t,c.type=e,c.count=s.length,l=c,console&&console.warn&&console.warn(l)}return t}function c(){if(!this.fired)return this.target.removeListener(this.type,this.wrapFn),this.fired=!0,0===arguments.length?this.listener.call(this.target):this.listener.apply(this.target,arguments)}function f(t,e,r){var n={fired:!1,wrapFn:void 0,target:t,type:e,listener:r},i=c.bind(n);return i.listener=r,n.wrapFn=i,i}function h(t,e,r){var n=t._events;if(void 0===n)return[];var i=n[e];return void 0===i?[]:"function"==typeof i?r?[i.listener||i]:[i]:r?function(t){for(var e=new Array(t.length),r=0;r<e.length;++r)e[r]=t[r].listener||t[r];return e}(i):d(i,i.length)}function p(t){var e=this._events;if(void 0!==e){var r=e[t];if("function"==typeof r)return 1;if(void 0!==r)return r.length}return 0}function d(t,e){for(var r=new Array(e),n=0;n<e;++n)r[n]=t[n];return r}function y(t,e,r,n){if("function"==typeof t.on)n.once?t.once(e,r):t.on(e,r);else{if("function"!=typeof t.addEventListener)throw new TypeError('The "emitter" argument must be of type EventEmitter. Received type '+typeof t);t.addEventListener(e,(function i(o){n.once&&t.removeEventListener(e,i),r(o)}))}}Object.defineProperty(o,"defaultMaxListeners",{enumerable:!0,get:function(){return s},set:function(t){if("number"!=typeof t||t<0||i(t))throw new RangeError('The value of "defaultMaxListeners" is out of range. It must be a non-negative number. Received '+t+".");s=t}}),o.init=function(){void 0!==this._events&&this._events!==Object.getPrototypeOf(this)._events||(this._events=Object.create(null),this._eventsCount=0),this._maxListeners=this._maxListeners||void 0},o.prototype.setMaxListeners=function(t){if("number"!=typeof t||t<0||i(t))throw new RangeError('The value of "n" is out of range. It must be a non-negative number. Received '+t+".");return this._maxListeners=t,this},o.prototype.getMaxListeners=function(){return u(this)},o.prototype.emit=function(t){for(var e=[],r=1;r<arguments.length;r++)e.push(arguments[r]);var i="error"===t,o=this._events;if(void 0!==o)i=i&&void 0===o.error;else if(!i)return!1;if(i){var s;if(e.length>0&&(s=e[0]),s instanceof Error)throw s;var a=new Error("Unhandled error."+(s?" ("+s.message+")":""));throw a.context=s,a}var u=o[t];if(void 0===u)return!1;if("function"==typeof u)n(u,this,e);else{var l=u.length,c=d(u,l);for(r=0;r<l;++r)n(c[r],this,e)}return!0},o.prototype.addListener=function(t,e){return l(this,t,e,!1)},o.prototype.on=o.prototype.addListener,o.prototype.prependListener=function(t,e){return l(this,t,e,!0)},o.prototype.once=function(t,e){return a(e),this.on(t,f(this,t,e)),this},o.prototype.prependOnceListener=function(t,e){return a(e),this.prependListener(t,f(this,t,e)),this},o.prototype.removeListener=function(t,e){var r,n,i,o,s;if(a(e),void 0===(n=this._events))return this;if(void 0===(r=n[t]))return this;if(r===e||r.listener===e)0==--this._eventsCount?this._events=Object.create(null):(delete n[t],n.removeListener&&this.emit("removeListener",t,r.listener||e));else if("function"!=typeof r){for(i=-1,o=r.length-1;o>=0;o--)if(r[o]===e||r[o].listener===e){s=r[o].listener,i=o;break}if(i<0)return this;0===i?r.shift():function(t,e){for(;e+1<t.length;e++)t[e]=t[e+1];t.pop()}(r,i),1===r.length&&(n[t]=r[0]),void 0!==n.removeListener&&this.emit("removeListener",t,s||e)}return this},o.prototype.off=o.prototype.removeListener,o.prototype.removeAllListeners=function(t){var e,r,n;if(void 0===(r=this._events))return this;if(void 0===r.removeListener)return 0===arguments.length?(this._events=Object.create(null),this._eventsCount=0):void 0!==r[t]&&(0==--this._eventsCount?this._events=Object.create(null):delete r[t]),this;if(0===arguments.length){var i,o=Object.keys(r);for(n=0;n<o.length;++n)"removeListener"!==(i=o[n])&&this.removeAllListeners(i);return this.removeAllListeners("removeListener"),this._events=Object.create(null),this._eventsCount=0,this}if("function"==typeof(e=r[t]))this.removeListener(t,e);else if(void 0!==e)for(n=e.length-1;n>=0;n--)this.removeListener(t,e[n]);return this},o.prototype.listeners=function(t){return h(this,t,!0)},o.prototype.rawListeners=function(t){return h(this,t,!1)},o.listenerCount=function(t,e){return"function"==typeof t.listenerCount?t.listenerCount(e):p.call(t,e)},o.prototype.listenerCount=p,o.prototype.eventNames=function(){return this._eventsCount>0?e(this._events):[]}},645:(t,e)=>{e.read=function(t,e,r,n,i){var o,s,a=8*i-n-1,u=(1<<a)-1,l=u>>1,c=-7,f=r?i-1:0,h=r?-1:1,p=t[e+f];for(f+=h,o=p&(1<<-c)-1,p>>=-c,c+=a;c>0;o=256*o+t[e+f],f+=h,c-=8);for(s=o&(1<<-c)-1,o>>=-c,c+=n;c>0;s=256*s+t[e+f],f+=h,c-=8);if(0===o)o=1-l;else{if(o===u)return s?NaN:1/0*(p?-1:1);s+=Math.pow(2,n),o-=l}return(p?-1:1)*s*Math.pow(2,o-n)},e.write=function(t,e,r,n,i,o){var s,a,u,l=8*o-i-1,c=(1<<l)-1,f=c>>1,h=23===i?Math.pow(2,-24)-Math.pow(2,-77):0,p=n?0:o-1,d=n?1:-1,y=e<0||0===e&&1/e<0?1:0;for(e=Math.abs(e),isNaN(e)||e===1/0?(a=isNaN(e)?1:0,s=c):(s=Math.floor(Math.log(e)/Math.LN2),e*(u=Math.pow(2,-s))<1&&(s--,u*=2),(e+=s+f>=1?h/u:h*Math.pow(2,1-f))*u>=2&&(s++,u/=2),s+f>=c?(a=0,s=c):s+f>=1?(a=(e*u-1)*Math.pow(2,i),s+=f):(a=e*Math.pow(2,f-1)*Math.pow(2,i),s=0));i>=8;t[r+p]=255&a,p+=d,a/=256,i-=8);for(s=s<<i|a,l+=i;l>0;t[r+p]=255&s,p+=d,s/=256,l-=8);t[r+p-d]|=128*y}},717:t=>{"function"==typeof Object.create?t.exports=function(t,e){e&&(t.super_=e,t.prototype=Object.create(e.prototype,{constructor:{value:t,enumerable:!1,writable:!0,configurable:!0}}))}:t.exports=function(t,e){if(e){t.super_=e;var r=function(){};r.prototype=e.prototype,t.prototype=new r,t.prototype.constructor=t}}},595:function(t){t.exports=(()=>{"use strict";var t={255:(t,e)=>{e.l=class{hexSlice(t=0,e){return Array.prototype.map.call(this.slice(t,e),(t=>("00"+t.toString(16)).slice(-2))).join("")}}},48:(t,e,r)=>{const n=r(765),{internalBinding:i,Array:o,ArrayIsArray:s,ArrayPrototypeFilter:a,ArrayPrototypeForEach:u,ArrayPrototypePush:l,ArrayPrototypePushApply:c,ArrayPrototypeSort:f,ArrayPrototypeUnshift:h,BigIntPrototypeValueOf:p,BooleanPrototypeValueOf:d,DatePrototypeGetTime:y,DatePrototypeToISOString:g,DatePrototypeToString:b,ErrorPrototypeToString:m,FunctionPrototypeCall:w,FunctionPrototypeToString:_,JSONStringify:E,MapPrototypeGetSize:v,MapPrototypeEntries:S,MathFloor:A,MathMax:T,MathMin:I,MathRound:B,MathSqrt:O,Number:x,NumberIsNaN:R,NumberParseFloat:N,NumberParseInt:L,NumberPrototypeValueOf:P,Object:M,ObjectAssign:U,ObjectCreate:j,ObjectDefineProperty:k,ObjectGetOwnPropertyDescriptor:$,ObjectGetOwnPropertyNames:F,ObjectGetOwnPropertySymbols:D,ObjectGetPrototypeOf:C,ObjectIs:G,ObjectKeys:W,ObjectPrototypeHasOwnProperty:z,ObjectPrototypePropertyIsEnumerable:H,ObjectSeal:Y,ObjectSetPrototypeOf:q,ReflectOwnKeys:V,RegExp:K,RegExpPrototypeTest:X,RegExpPrototypeToString:J,SafeStringIterator:Z,SafeMap:Q,SafeSet:tt,SetPrototypeGetSize:et,SetPrototypeValues:rt,String:nt,StringPrototypeCharCodeAt:it,StringPrototypeCodePointAt:ot,StringPrototypeIncludes:st,StringPrototypeNormalize:at,StringPrototypePadEnd:ut,StringPrototypePadStart:lt,StringPrototypeRepeat:ct,StringPrototypeReplace:ft,StringPrototypeSlice:ht,StringPrototypeSplit:pt,StringPrototypeToLowerCase:dt,StringPrototypeTrim:yt,StringPrototypeValueOf:gt,SymbolPrototypeToString:bt,SymbolPrototypeValueOf:mt,SymbolIterator:wt,SymbolToStringTag:_t,TypedArrayPrototypeGetLength:Et,TypedArrayPrototypeGetSymbolToStringTag:vt,Uint8Array:St,uncurryThis:At}=n,{getOwnNonIndexProperties:Tt,getPromiseDetails:It,getProxyDetails:Bt,kPending:Ot,kRejected:xt,previewEntries:Rt,getConstructorName:Nt,getExternalValue:Lt,propertyFilter:{ALL_PROPERTIES:Pt,ONLY_ENUMERABLE:Mt},Proxy:Ut}=r(891),{customInspectSymbol:jt,isError:kt,join:$t,removeColors:Ft}=r(335),{codes:{ERR_INVALID_ARG_TYPE:Dt},isStackOverflowError:Ct}=r(101),{isAsyncFunction:Gt,isGeneratorFunction:Wt,isAnyArrayBuffer:zt,isArrayBuffer:Ht,isArgumentsObject:Yt,isBoxedPrimitive:qt,isDataView:Vt,isExternal:Kt,isMap:Xt,isMapIterator:Jt,isModuleNamespaceObject:Zt,isNativeError:Qt,isPromise:te,isSet:ee,isSetIterator:re,isWeakMap:ne,isWeakSet:ie,isRegExp:oe,isDate:se,isTypedArray:ae,isStringObject:ue,isNumberObject:le,isBooleanObject:ce,isBigIntObject:fe}=r(63),he=r(183),{NativeModule:pe}=r(992),{validateObject:de}=r(356);let ye;const ge=new tt(a(F(r.g),(t=>X(/^[A-Z][a-zA-Z0-9]+$/,t)))),be=t=>void 0===t&&void 0!==t,me=Y({showHidden:!1,depth:2,colors:!1,customInspect:!0,showProxy:!1,maxArrayLength:100,maxStringLength:1e4,breakLength:80,compact:3,sorted:!1,getters:!1}),we=/[\x00-\x1f\x27\x5c\x7f-\x9f]/,_e=/[\x00-\x1f\x27\x5c\x7f-\x9f]/g,Ee=/[\x00-\x1f\x5c\x7f-\x9f]/,ve=/[\x00-\x1f\x5c\x7f-\x9f]/g,Se=/^[a-zA-Z_][a-zA-Z_0-9]*$/,Ae=/^(0|[1-9][0-9]*)$/,Te=/^    at (?:[^/\\(]+ \(|)node:(.+):\d+:\d+\)?$/,Ie=/^    at (?:[^/\\(]+ \(|)(.+)\.js:\d+:\d+\)?$/,Be=/[/\\]node_modules[/\\](.+?)(?=[/\\])/g,Oe=/^(\s+[^(]*?)\s*{/,xe=/(\/\/.*?\n)|(\/\*(.|\n)*?\*\/)/g,Re=["\\x00","\\x01","\\x02","\\x03","\\x04","\\x05","\\x06","\\x07","\\b","\\t","\\n","\\x0B","\\f","\\r","\\x0E","\\x0F","\\x10","\\x11","\\x12","\\x13","\\x14","\\x15","\\x16","\\x17","\\x18","\\x19","\\x1A","\\x1B","\\x1C","\\x1D","\\x1E","\\x1F","","","","","","","","\\'","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","\\\\","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","","\\x7F","\\x80","\\x81","\\x82","\\x83","\\x84","\\x85","\\x86","\\x87","\\x88","\\x89","\\x8A","\\x8B","\\x8C","\\x8D","\\x8E","\\x8F","\\x90","\\x91","\\x92","\\x93","\\x94","\\x95","\\x96","\\x97","\\x98","\\x99","\\x9A","\\x9B","\\x9C","\\x9D","\\x9E","\\x9F"],Ne=new K("[\\u001B\\u009B][[\\]()#;?]*(?:(?:(?:[a-zA-Z\\d]*(?:;[-a-zA-Z\\d\\/#&.:=?%@~_]*)*)?\\u0007)|(?:(?:\\d{1,4}(?:;\\d{0,4})*)?[\\dA-PR-TZcf-ntqry=><~]))","g");let Le;function Pe(t,e){const r={budget:{},indentationLvl:0,seen:[],currentDepth:0,stylize:Ce,showHidden:me.showHidden,depth:me.depth,colors:me.colors,customInspect:me.customInspect,showProxy:me.showProxy,maxArrayLength:me.maxArrayLength,maxStringLength:me.maxStringLength,breakLength:me.breakLength,compact:me.compact,sorted:me.sorted,getters:me.getters};if(arguments.length>1)if(arguments.length>2&&(void 0!==arguments[2]&&(r.depth=arguments[2]),arguments.length>3&&void 0!==arguments[3]&&(r.colors=arguments[3])),"boolean"==typeof e)r.showHidden=e;else if(e){const t=W(e);for(let n=0;n<t.length;++n){const i=t[n];z(me,i)||"stylize"===i?r[i]=e[i]:void 0===r.userOptions&&(r.userOptions=e)}}return r.colors&&(r.stylize=De),null===r.maxArrayLength&&(r.maxArrayLength=1/0),null===r.maxStringLength&&(r.maxStringLength=1/0),Ke(r,t,0)}Pe.custom=jt,k(Pe,"defaultOptions",{get:()=>me,set:t=>(de(t,"options"),U(me,t))});const Me=39,Ue=49;function je(t,e){k(Pe.colors,e,{get(){return this[t]},set(e){this[t]=e},configurable:!0,enumerable:!1})}function ke(t,e){return-1===e?`"${t}"`:-2===e?`\`${t}\``:`'${t}'`}Pe.colors=U(j(null),{reset:[0,0],bold:[1,22],dim:[2,22],italic:[3,23],underline:[4,24],blink:[5,25],inverse:[7,27],hidden:[8,28],strikethrough:[9,29],doubleunderline:[21,24],black:[30,Me],red:[31,Me],green:[32,Me],yellow:[33,Me],blue:[34,Me],magenta:[35,Me],cyan:[36,Me],white:[37,Me],bgBlack:[40,Ue],bgRed:[41,Ue],bgGreen:[42,Ue],bgYellow:[43,Ue],bgBlue:[44,Ue],bgMagenta:[45,Ue],bgCyan:[46,Ue],bgWhite:[47,Ue],framed:[51,54],overlined:[53,55],gray:[90,Me],redBright:[91,Me],greenBright:[92,Me],yellowBright:[93,Me],blueBright:[94,Me],magentaBright:[95,Me],cyanBright:[96,Me],whiteBright:[97,Me],bgGray:[100,Ue],bgRedBright:[101,Ue],bgGreenBright:[102,Ue],bgYellowBright:[103,Ue],bgBlueBright:[104,Ue],bgMagentaBright:[105,Ue],bgCyanBright:[106,Ue],bgWhiteBright:[107,Ue]}),je("gray","grey"),je("gray","blackBright"),je("bgGray","bgGrey"),je("bgGray","bgBlackBright"),je("dim","faint"),je("strikethrough","crossedout"),je("strikethrough","strikeThrough"),je("strikethrough","crossedOut"),je("hidden","conceal"),je("inverse","swapColors"),je("inverse","swapcolors"),je("doubleunderline","doubleUnderline"),Pe.styles=U(j(null),{special:"cyan",number:"yellow",bigint:"yellow",boolean:"yellow",undefined:"grey",null:"bold",string:"green",symbol:"green",date:"magenta",regexp:"red",module:"underline"});const $e=t=>Re[it(t)];function Fe(t){let e=we,r=_e,n=39;if(st(t,"'")&&(st(t,'"')?st(t,"`")||st(t,"${")||(n=-2):n=-1,39!==n&&(e=Ee,r=ve)),t.length<5e3&&!X(e,t))return ke(t,n);if(t.length>100)return ke(t=ft(t,r,$e),n);let i="",o=0;const s=t.length;for(let e=0;e<s;e++){const r=it(t,e);(r===n||92===r||r<32||r>126&&r<160)&&(i+=o===e?Re[r]:`${ht(t,o,e)}${Re[r]}`,o=e+1)}return o!==s&&(i+=ht(t,o)),ke(i,n)}function De(t,e){const r=Pe.styles[e];if(void 0!==r){const e=Pe.colors[r];if(void 0!==e)return`[${e[0]}m${t}[${e[1]}m`}return t}function Ce(t){return t}function Ge(){return[]}function We(t,e){try{return t instanceof e}catch{return!1}}function ze(t,e,r,n){let i;const o=t;for(;t||be(t);){const s=$(t,"constructor");if(void 0!==s&&"function"==typeof s.value&&""!==s.value.name&&We(o,s.value))return void 0===n||i===t&&ge.has(s.value.name)||He(e,o,i||o,r,n),s.value.name;t=C(t),void 0===i&&(i=t)}if(null===i)return null;const s=Nt(o);if(r>e.depth&&null!==e.depth)return`${s} <Complex prototype>`;const a=ze(i,e,r+1,n);return null===a?`${s} <${Pe(i,{...e,customInspect:!1,depth:-1})}>`:`${s} <${a}>`}function He(t,e,r,n,i){let o,s,a=0;do{if(0!==a||e===r){if(null===(r=C(r)))return;const t=$(r,"constructor");if(void 0!==t&&"function"==typeof t.value&&ge.has(t.value.name))return}0===a?s=new tt:u(o,(t=>s.add(t))),o=V(r);for(const u of o){if("constructor"===u||z(e,u)||0!==a&&s.has(u))continue;const o=$(r,u);if("function"==typeof o.value)continue;const c=dr(t,r,n,u,0,o,e);t.colors?l(i,`[2m${c}[22m`):l(i,c)}}while(3!=++a)}function Ye(t,e,r,n=""){return null===t?""!==e&&r!==e?`[${r}${n}: null prototype] [${e}] `:`[${r}${n}: null prototype] `:""!==e&&t!==e?`${t}${n} [${e}] `:`${t}${n} `}function qe(t,e){let r;const n=D(t);if(e)r=F(t),0!==n.length&&c(r,n);else{try{r=W(t)}catch(e){he(Qt(e)&&"ReferenceError"===e.name&&Zt(t)),r=F(t)}0!==n.length&&c(r,a(n,(e=>H(t,e))))}return r}function Ve(t,e,r){let n="";return null===e&&(n=Nt(t),n===r&&(n="Object")),Ye(e,r,n)}function Ke(t,e,r,i){if("object"!=typeof e&&"function"!=typeof e&&!be(e))return Qe(t.stylize,e,t);if(null===e)return t.stylize("null","null");const o=e,a=Bt(e,!!t.showProxy);if(void 0!==a){if(t.showProxy)return function(t,e,r){if(r>t.depth&&null!==t.depth)return t.stylize("Proxy [Array]","special");r+=1,t.indentationLvl+=2;const n=[Ke(t,e[0],r),Ke(t,e[1],r)];return t.indentationLvl-=2,gr(t,n,"",["Proxy [","]"],2,r)}(t,a,r);e=a}if(t.customInspect){const n=e[jt];if("function"==typeof n&&n!==Pe&&(!e.constructor||e.constructor.prototype!==e)){const e=null===t.depth?null:t.depth-r,i=w(n,o,e,function(t,e){const r={stylize:t.stylize,showHidden:t.showHidden,depth:t.depth,colors:t.colors,customInspect:t.customInspect,showProxy:t.showProxy,maxArrayLength:t.maxArrayLength,maxStringLength:t.maxStringLength,breakLength:t.breakLength,compact:t.compact,sorted:t.sorted,getters:t.getters,...t.userOptions};if(e){q(r,null);for(const t of W(r))"object"!=typeof r[t]&&"function"!=typeof r[t]||null===r[t]||delete r[t];r.stylize=q(((e,r)=>{let n;try{n=`${t.stylize(e,r)}`}catch{}return"string"!=typeof n?e:n}),null)}return r}(t,void 0!==a||!(o instanceof M)));if(i!==o)return"string"!=typeof i?Ke(t,i,r):i.replace(/\n/g,`\n${" ".repeat(t.indentationLvl)}`)}}if(t.seen.includes(e)){let r=1;return void 0===t.circular?(t.circular=new Q,t.circular.set(e,r)):(r=t.circular.get(e),void 0===r&&(r=t.circular.size+1,t.circular.set(e,r))),t.stylize(`[Circular *${r}]`,"special")}return function(t,e,r,i){let o,a;t.showHidden&&(r<=t.depth||null===t.depth)&&(a=[]);const u=ze(e,t,r,a);void 0!==a&&0===a.length&&(a=void 0);let l=e[_t];("string"!=typeof l||""!==l&&(t.showHidden?z:H)(e,_t))&&(l="");let c,f="",w=Ge,E=!0,A=0;const T=t.showHidden?Pt:Mt;let I,B=0;if(e[wt]||null===u)if(E=!1,s(e)){const t="Array"!==u||""!==l?Ye(u,l,"Array",`(${e.length})`):"";if(o=Tt(e,T),c=[`${t}[`,"]"],0===e.length&&0===o.length&&void 0===a)return`${c[0]}]`;B=2,w=nr}else if(ee(e)){const r=et(e),n=Ye(u,l,"Set",`(${r})`);if(o=qe(e,t.showHidden),w=null!==u?or.bind(null,e):or.bind(null,rt(e)),0===r&&0===o.length&&void 0===a)return`${n}{}`;c=[`${n}{`,"}"]}else if(Xt(e)){const r=v(e),n=Ye(u,l,"Map",`(${r})`);if(o=qe(e,t.showHidden),w=null!==u?sr.bind(null,e):sr.bind(null,S(e)),0===r&&0===o.length&&void 0===a)return`${n}{}`;c=[`${n}{`,"}"]}else if(ae(e)){o=Tt(e,T);let r=e,i="";null===u&&(i=vt(e),r=new n[i](e));const s=Et(e);if(c=[`${Ye(u,l,i,`(${s})`)}[`,"]"],0===e.length&&0===o.length&&!t.showHidden)return`${c[0]}]`;w=ir.bind(null,r,s),B=2}else Jt(e)?(o=qe(e,t.showHidden),c=Xe("Map",l),w=hr.bind(null,c)):re(e)?(o=qe(e,t.showHidden),c=Xe("Set",l),w=hr.bind(null,c)):E=!0;if(E)if(o=qe(e,t.showHidden),c=["{","}"],"Object"===u){if(Yt(e)?c[0]="[Arguments] {":""!==l&&(c[0]=`${Ye(u,l,"Object")}{`),0===o.length&&void 0===a)return`${c[0]}}`}else if("function"==typeof e){if(f=function(t,e,r){const n=_(t);if("class"===n.slice(0,5)&&n.endsWith("}")){const i=n.slice(5,-1),o=i.indexOf("{");if(-1!==o&&(!i.slice(0,o).includes("(")||Oe.test(i.replace(xe))))return function(t,e,r){let n=`class ${z(t,"name")&&t.name||"(anonymous)"}`;if("Function"!==e&&null!==e&&(n+=` [${e}]`),""!==r&&e!==r&&(n+=` [${r}]`),null!==e){const e=C(t).name;e&&(n+=` extends ${e}`)}else n+=" extends [null prototype]";return`[${n}]`}(t,e,r)}let i="Function";Wt(t)&&(i=`Generator${i}`),Gt(t)&&(i=`Async${i}`);let o=`[${i}`;return null===e&&(o+=" (null prototype)"),""===t.name?o+=" (anonymous)":o+=`: ${t.name}`,o+="]",e!==i&&null!==e&&(o+=` ${e}`),""!==r&&e!==r&&(o+=` [${r}]`),o}(e,u,l),0===o.length&&void 0===a)return t.stylize(f,"special")}else if(oe(e)){f=J(null!==u?e:new K(e));const n=Ye(u,l,"RegExp");if("RegExp "!==n&&(f=`${n}${f}`),0===o.length&&void 0===a||r>t.depth&&null!==t.depth)return t.stylize(f,"regexp")}else if(se(e)){f=R(y(e))?b(e):g(e);const r=Ye(u,l,"Date");if("Date "!==r&&(f=`${r}${f}`),0===o.length&&void 0===a)return t.stylize(f,"date")}else if(kt(e)){if(f=function(t,e,r,n,i){const o=null!=t.name?nt(t.name):"Error";let s=o.length,a=t.stack?nt(t.stack):m(t);if(!n.showHidden&&0!==i.length)for(const e of["name","message","stack"]){const r=i.indexOf(e);-1!==r&&a.includes(t[e])&&i.splice(r,1)}if(null===e||o.endsWith("Error")&&a.startsWith(o)&&(a.length===s||":"===a[s]||"\n"===a[s])){let t="Error";if(null===e){const e=a.match(/^([A-Z][a-z_ A-Z0-9[\]()-]+)(?::|\n {4}at)/)||a.match(/^([a-z_A-Z0-9-]*Error)$/);t=e&&e[1]||"",s=t.length,t=t||"Error"}const n=Ye(e,r,t).slice(0,-1);o!==n&&(a=n.includes(o)?0===s?`${n}: ${a}`:`${n}${a.slice(s)}`:`${n} [${o}]${a.slice(s)}`)}let u=t.message&&a.indexOf(t.message)||-1;-1!==u&&(u+=t.message.length);const l=a.indexOf("\n    at",u);if(-1===l)a=`[${a}]`;else if(n.colors){let t=a.slice(0,l);const e=a.slice(l+1).split("\n");for(const r of e){const e=r.match(Te)||r.match(Ie);if(null!==e&&pe.exists(e[1]))t+=`\n${n.stylize(r,"undefined")}`;else{let e;t+="\n";let i=0;for(;e=Be.exec(r);)t+=r.slice(i,e.index+14),t+=n.stylize(e[1],"module"),i=e.index+e[0].length;t+=0===i?r:r.slice(i)}}a=t}if(0!==n.indentationLvl){const t=" ".repeat(n.indentationLvl);a=a.replace(/\n/g,`\n${t}`)}return a}(e,u,l,t,o),0===o.length&&void 0===a)return f}else if(zt(e)){const r=Ye(u,l,Ht(e)?"ArrayBuffer":"SharedArrayBuffer");if(void 0===i)w=rr;else if(0===o.length&&void 0===a)return r+`{ byteLength: ${Je(t.stylize,e.byteLength)} }`;c[0]=`${r}{`,h(o,"byteLength")}else if(Vt(e))c[0]=`${Ye(u,l,"DataView")}{`,h(o,"byteLength","byteOffset","buffer");else if(te(e))c[0]=`${Ye(u,l,"Promise")}{`,w=pr;else if(ie(e))c[0]=`${Ye(u,l,"WeakSet")}{`,w=t.showHidden?cr:lr;else if(ne(e))c[0]=`${Ye(u,l,"WeakMap")}{`,w=t.showHidden?fr:lr;else if(Zt(e))c[0]=`${Ye(u,l,"Module")}{`,w=tr.bind(null,o);else if(qt(e)){if(f=function(t,e,r,n,i){let o,s;le(t)?(o=P,s="Number"):ue(t)?(o=gt,s="String",r.splice(0,t.length)):ce(t)?(o=d,s="Boolean"):fe(t)?(o=p,s="BigInt"):(o=mt,s="Symbol");let a=`[${s}`;return s!==n&&(a+=null===n?" (null prototype)":` (${n})`),a+=`: ${Qe(Ce,o(t),e)}]`,""!==i&&i!==n&&(a+=` [${i}]`),0!==r.length||e.stylize===Ce?a:e.stylize(a,dt(s))}(e,t,o,u,l),0===o.length&&void 0===a)return f}else{if(0===o.length&&void 0===a){if(Kt(e)){const r=Lt(e).toString(16);return t.stylize(`[External: ${r}]`,"special")}return`${Ve(e,u,l)}{}`}c[0]=`${Ve(e,u,l)}{`}if(r>t.depth&&null!==t.depth){let r=Ve(e,u,l).slice(0,-1);return null!==u&&(r=`[${r}]`),t.stylize(r,"special")}r+=1,t.seen.push(e),t.currentDepth=r;const O=t.indentationLvl;try{for(I=w(t,e,r),A=0;A<o.length;A++)I.push(dr(t,e,r,o[A],B));void 0!==a&&I.push(...a)}catch(r){return function(t,e,r,n){if(Ct(e))return t.seen.pop(),t.indentationLvl=n,t.stylize(`[${r}: Inspection interrupted prematurely. Maximum call stack size exceeded.]`,"special");he.fail(e.stack)}(t,r,Ve(e,u,l).slice(0,-1),O)}if(void 0!==t.circular){const r=t.circular.get(e);if(void 0!==r){const e=t.stylize(`<ref *${r}>`,"special");!0!==t.compact?f=""===f?e:`${e} ${f}`:c[0]=`${e} ${c[0]}`}}if(t.seen.pop(),t.sorted){const e=!0===t.sorted?void 0:t.sorted;if(0===B)I=I.sort(e);else if(o.length>1){const t=I.slice(I.length-o.length).sort(e);I.splice(I.length-o.length,o.length,...t)}}const x=gr(t,I,f,c,B,r,e),N=(t.budget[t.indentationLvl]||0)+x.length;return t.budget[t.indentationLvl]=N,N>2**27&&(t.depth=-1),x}(t,e,r,i)}function Xe(t,e){return e!==`${t} Iterator`&&(""!==e&&(e+="] ["),e+=`${t} Iterator`),[`[${e}] {`,"}"]}function Je(t,e){return t(G(e,-0)?"-0":`${e}`,"number")}function Ze(t,e){return t(`${e}n`,"bigint")}function Qe(t,e,r){if("string"==typeof e){let n="";if(e.length>r.maxStringLength){const t=e.length-r.maxStringLength;e=e.slice(0,r.maxStringLength),n=`... ${t} more character${t>1?"s":""}`}return!0!==r.compact&&e.length>16&&e.length>r.breakLength-r.indentationLvl-4?e.split(/\n/).map(((e,r,n)=>t(Fe(e+(r===n.length-1?"":"\n")),"string"))).join(` +\n${" ".repeat(r.indentationLvl+2)}`)+n:t(Fe(e),"string")+n}return"number"==typeof e?Je(t,e):"bigint"==typeof e?Ze(t,e):"boolean"==typeof e?t(`${e}`,"boolean"):void 0===e?t("undefined","undefined"):t(bt(e),"symbol")}function tr(t,e,r,n){const i=new o(t.length);for(let o=0;o<t.length;o++)try{i[o]=dr(e,r,n,t[o],0)}catch(r){if(!Qt(r)||"ReferenceError"!==r.name)throw r;const s={[t[o]]:""};i[o]=dr(e,s,n,t[o],0);const a=i[o].lastIndexOf(" ");i[o]=i[o].slice(0,a+1)+e.stylize("<uninitialized>","special")}return t.length=0,i}function er(t,e,r,n,i,o){const s=W(e);let a=o;for(;o<s.length&&i.length<n;o++){const u=s[o],l=+u;if(l>2**32-2)break;if(`${a}`!==u){if(!Ae.test(u))break;const e=l-a,r=`<${e} empty item${e>1?"s":""}>`;if(i.push(t.stylize(r,"undefined")),a=l,i.length===n)break}i.push(dr(t,e,r,u,1)),a++}const u=e.length-a;if(i.length!==n){if(u>0){const e=`<${u} empty item${u>1?"s":""}>`;i.push(t.stylize(e,"undefined"))}}else u>0&&i.push(`... ${u} more item${u>1?"s":""}`);return i}function rr(t,e){let n;try{n=new St(e)}catch{return[t.stylize("(detached)","special")]}void 0===ye&&(ye=At(r(255).l.prototype.hexSlice));let i=yt(ft(ye(n,0,I(t.maxArrayLength,n.length)),/(.{2})/g,"$1 "));const o=n.length-t.maxArrayLength;return o>0&&(i+=` ... ${o} more byte${o>1?"s":""}`),[`${t.stylize("[Uint8Contents]","special")}: <${i}>`]}function nr(t,e,r){const n=e.length,i=I(T(0,t.maxArrayLength),n),o=n-i,s=[];for(let n=0;n<i;n++){if(!z(e,n))return er(t,e,r,i,s,n);s.push(dr(t,e,r,n,1))}return o>0&&s.push(`... ${o} more item${o>1?"s":""}`),s}function ir(t,e,r,n,i){const s=I(T(0,r.maxArrayLength),e),a=t.length-s,u=new o(s),c=t.length>0&&"number"==typeof t[0]?Je:Ze;for(let e=0;e<s;++e)u[e]=c(r.stylize,t[e]);if(a>0&&(u[s]=`... ${a} more item${a>1?"s":""}`),r.showHidden){r.indentationLvl+=2;for(const e of["BYTES_PER_ELEMENT","length","byteLength","byteOffset","buffer"]){const n=Ke(r,t[e],i,!0);l(u,`[${e}]: ${n}`)}r.indentationLvl-=2}return u}function or(t,e,r,n){const i=[];e.indentationLvl+=2;for(const r of t)l(i,Ke(e,r,n));return e.indentationLvl-=2,i}function sr(t,e,r,n){const i=[];e.indentationLvl+=2;for(const{0:r,1:o}of t)i.push(`${Ke(e,r,n)} => `+Ke(e,o,n));return e.indentationLvl-=2,i}function ar(t,e,r,n){const i=T(t.maxArrayLength,0),s=I(i,r.length),a=new o(s);t.indentationLvl+=2;for(let n=0;n<s;n++)a[n]=Ke(t,r[n],e);t.indentationLvl-=2,0!==n||t.sorted||f(a);const u=r.length-s;return u>0&&l(a,`... ${u} more item${u>1?"s":""}`),a}function ur(t,e,r,n){const i=T(t.maxArrayLength,0),s=r.length/2,a=s-i,u=I(i,s);let l=new o(u),c=0;if(t.indentationLvl+=2,0===n){for(;c<u;c++){const n=2*c;l[c]=`${Ke(t,r[n],e)} => ${Ke(t,r[n+1],e)}`}t.sorted||(l=l.sort())}else for(;c<u;c++){const n=2*c,i=[Ke(t,r[n],e),Ke(t,r[n+1],e)];l[c]=gr(t,i,"",["[","]"],2,e)}return t.indentationLvl-=2,a>0&&l.push(`... ${a} more item${a>1?"s":""}`),l}function lr(t){return[t.stylize("<items unknown>","special")]}function cr(t,e,r){return ar(t,r,Rt(e),0)}function fr(t,e,r){return ur(t,r,Rt(e),0)}function hr(t,e,r,n){const{0:i,1:o}=Rt(r,!0);return o?(t[0]=t[0].replace(/ Iterator] {$/," Entries] {"),ur(e,n,i,2)):ar(e,n,i,1)}function pr(t,e,r){let n;const{0:i,1:o}=It(e);if(i===Ot)n=[t.stylize("<pending>","special")];else{t.indentationLvl+=2;const e=Ke(t,o,r);t.indentationLvl-=2,n=[i===xt?`${t.stylize("<rejected>","special")} ${e}`:e]}return n}function dr(t,e,r,n,i,o,s=e){let a,u,l=" ";if(void 0!==(o=o||$(e,n)||{value:e[n],enumerable:!0}).value){const e=!0!==t.compact||0!==i?2:3;t.indentationLvl+=e,u=Ke(t,o.value,r),3===e&&t.breakLength<Le(u,t.colors)&&(l=`\n${" ".repeat(t.indentationLvl)}`),t.indentationLvl-=e}else if(void 0!==o.get){const e=void 0!==o.set?"Getter/Setter":"Getter",n=t.stylize,i="special";if(t.getters&&(!0===t.getters||"get"===t.getters&&void 0===o.set||"set"===t.getters&&void 0!==o.set))try{const a=w(o.get,s);if(t.indentationLvl+=2,null===a)u=`${n(`[${e}:`,i)} ${n("null","null")}${n("]",i)}`;else if("object"==typeof a)u=`${n(`[${e}]`,i)} ${Ke(t,a,r)}`;else{const r=Qe(n,a,t);u=`${n(`[${e}:`,i)} ${r}${n("]",i)}`}t.indentationLvl-=2}catch(t){const r=`<Inspection threw (${t.message})>`;u=`${n(`[${e}:`,i)} ${r}${n("]",i)}`}else u=t.stylize(`[${e}]`,i)}else u=void 0!==o.set?t.stylize("[Setter]","special"):t.stylize("undefined","undefined");if(1===i)return u;if("symbol"==typeof n){const e=ft(bt(n),_e,$e);a=`[${t.stylize(e,"symbol")}]`}else a="__proto__"===n?"['__proto__']":!1===o.enumerable?`[${ft(n,_e,$e)}]`:X(Se,n)?t.stylize(n,"name"):t.stylize(Fe(n),"string");return`${a}:${l}${u}`}function yr(t,e,r,n){let i=e.length+r;if(i+e.length>t.breakLength)return!1;for(let r=0;r<e.length;r++)if(t.colors?i+=Ft(e[r]).length:i+=e[r].length,i>t.breakLength)return!1;return""===n||!st(n,"\n")}function gr(t,e,r,n,i,s,a){if(!0!==t.compact){if("number"==typeof t.compact&&t.compact>=1){const u=e.length;if(2===i&&u>6&&(e=function(t,e,r){let n=0,i=0,s=0,a=e.length;t.maxArrayLength<e.length&&a--;const u=new o(a);for(;s<a;s++){const r=Le(e[s],t.colors);u[s]=r,n+=r+2,i<r&&(i=r)}const c=i+2;if(3*c+t.indentationLvl<t.breakLength&&(n/c>5||i<=6)){const i=2.5,o=O(c-n/e.length),s=T(c-3-o,1),f=I(B(O(i*s*a)/s),A((t.breakLength-t.indentationLvl)/c),4*t.compact,15);if(f<=1)return e;const h=[],p=[];for(let t=0;t<f;t++){let r=0;for(let n=t;n<e.length;n+=f)u[n]>r&&(r=u[n]);r+=2,p[t]=r}let d=lt;if(void 0!==r)for(let t=0;t<e.length;t++)if("number"!=typeof r[t]&&"bigint"!=typeof r[t]){d=ut;break}for(let t=0;t<a;t+=f){const r=I(t+f,a);let n="",i=t;for(;i<r-1;i++){const r=p[i-t]+e[i].length-u[i];n+=d(`${e[i]}, `,r," ")}if(d===lt){const r=p[i-t]+e[i].length-u[i]-2;n+=lt(e[i],r," ")}else n+=e[i];l(h,n)}t.maxArrayLength<e.length&&l(h,e[a]),e=h}return e}(t,e,a)),t.currentDepth-s<t.compact&&u===e.length&&yr(t,e,e.length+t.indentationLvl+n[0].length+r.length+10,r))return`${r?`${r} `:""}${n[0]} ${$t(e,", ")} ${n[1]}`}const u=`\n${ct(" ",t.indentationLvl)}`;return`${r?`${r} `:""}${n[0]}${u}  ${$t(e,`,${u}  `)}${u}${n[1]}`}if(yr(t,e,0,r))return`${n[0]}${r?` ${r}`:""} ${$t(e,", ")} `+n[1];const u=ct(" ",t.indentationLvl),c=""===r&&1===n[0].length?" ":`${r?` ${r}`:""}\n${u}  `;return`${n[0]}${c}${$t(e,`,\n${u}  `)} ${n[1]}`}function br(t){const e=Bt(t,!1);if(void 0!==e&&(t=e),"function"!=typeof t.toString)return!0;if(z(t,"toString"))return!1;let r=t;do{r=C(r)}while(!z(r,"toString"));const n=$(r,"constructor");return void 0!==n&&"function"==typeof n.value&&ge.has(n.value.name)}const mr=t=>pt(t.message,"\n",1)[0];let wr;function _r(t){try{return E(t)}catch(t){if(!wr)try{const t={};t.a=t,E(t)}catch(t){wr=mr(t)}if("TypeError"===t.name&&mr(t)===wr)return"[Circular]";throw t}}function Er(t,e){const r=e[0];let n=0,i="",o="";if("string"==typeof r){if(1===e.length)return r;let s,a=0;for(let o=0;o<r.length-1;o++)if(37===it(r,o)){const u=it(r,++o);if(n+1!==e.length){switch(u){case 115:const u=e[++n];s="number"==typeof u?Je(Ce,u):"bigint"==typeof u?`${u}n`:"object"==typeof u&&null!==u&&br(u)?Pe(u,{...t,compact:3,colors:!1,depth:0}):nt(u);break;case 106:s=_r(e[++n]);break;case 100:const l=e[++n];s="bigint"==typeof l?`${l}n`:"symbol"==typeof l?"NaN":Je(Ce,x(l));break;case 79:s=Pe(e[++n],t);break;case 111:s=Pe(e[++n],{...t,showHidden:!0,showProxy:!0,depth:4});break;case 105:const c=e[++n];s="bigint"==typeof c?`${c}n`:"symbol"==typeof c?"NaN":Je(Ce,L(c));break;case 102:const f=e[++n];s="symbol"==typeof f?"NaN":Je(Ce,N(f));break;case 99:n+=1,s="";break;case 37:i+=ht(r,a,o),a=o+1;continue;default:continue}a!==o-1&&(i+=ht(r,a,o-1)),i+=s,a=o+1}else 37===u&&(i+=ht(r,a,o),a=o+1)}0!==a&&(n++,o=" ",a<r.length&&(i+=ht(r,a)))}for(;n<e.length;){const r=e[n];i+=o,i+="string"!=typeof r?Pe(r,t):r,o=" ",n++}return i}if(i("config").hasIntl){const t=i("icu");Le=function(e,r=!0){let n=0;r&&(e=vr(e));for(let r=0;r<e.length;r++){const i=e.charCodeAt(r);if(i>=127){n+=t.getStringWidth(e.slice(r).normalize("NFC"));break}n+=i>=32?1:0}return n}}else{Le=function(r,n=!0){let i=0;n&&(r=vr(r)),r=at(r,"NFC");for(const n of new Z(r)){const r=ot(n,0);t(r)?i+=2:e(r)||i++}return i};const t=t=>t>=4352&&(t<=4447||9001===t||9002===t||t>=11904&&t<=12871&&12351!==t||t>=12880&&t<=19903||t>=19968&&t<=42182||t>=43360&&t<=43388||t>=44032&&t<=55203||t>=63744&&t<=64255||t>=65040&&t<=65049||t>=65072&&t<=65131||t>=65281&&t<=65376||t>=65504&&t<=65510||t>=110592&&t<=110593||t>=127488&&t<=127569||t>=127744&&t<=128591||t>=131072&&t<=262141),e=t=>t<=31||t>=127&&t<=159||t>=768&&t<=879||t>=8203&&t<=8207||t>=8400&&t<=8447||t>=65024&&t<=65039||t>=65056&&t<=65071||t>=917760&&t<=917999}function vr(t){return t.replace(Ne,"")}t.exports={inspect:Pe,format:function(...t){return Er(void 0,t)},formatWithOptions:function(t,...e){if("object"!=typeof t||null===t)throw new Dt("inspectOptions","object",t);return Er(t,e)},getStringWidth:Le,inspectDefaultOptions:me,stripVTControlCharacters:vr,stylizeWithColor:De,stylizeWithHTML(t,e){const r=Pe.styles[e];return void 0!==r?`<span style="color:${r};">${t}</span>`:t},Proxy:Ut}},183:t=>{t.exports=function(t){if(!t)throw new Error("Assertion failed")}},992:(t,e)=>{e.NativeModule={exists:t=>!t.startsWith("/")}},101:(t,e,r)=>{const{ArrayIsArray:n,ArrayPrototypeIncludes:i,ArrayPrototypeIndexOf:o,ArrayPrototypeJoin:s,ArrayPrototypePop:a,ArrayPrototypePush:u,ArrayPrototypeSplice:l,ErrorCaptureStackTrace:c,ObjectDefineProperty:f,ReflectApply:h,RegExpPrototypeTest:p,SafeMap:d,StringPrototypeEndsWith:y,StringPrototypeIncludes:g,StringPrototypeSlice:b,StringPrototypeToLowerCase:m}=r(765),w=new d,_={},E=/^([A-Z][a-z0-9]*)+$/,v=["string","function","number","object","Function","Object","boolean","bigint","symbol"];let S,A,T=null;function I(){return T||(T=r(48)),T}const B=O((function(t,e,r){(t=x(t)).name=`${e} [${r}]`,t.stack,delete t.name}));function O(t){const e="__node_internal_"+t.name;return f(t,"name",{value:e}),t}const x=O((function(t){return S=Error.stackTraceLimit,Error.stackTraceLimit=1/0,c(t),Error.stackTraceLimit=S,t}));let R,N;var L,P,M,U,j;t.exports={codes:_,hideStackFrames:O,isStackOverflowError:function(t){if(void 0===N)try{!function t(){t()}()}catch(t){N=t.message,R=t.name}return t&&t.name===R&&t.message===N}},L="ERR_INVALID_ARG_TYPE",P=(t,e,r)=>{A("string"==typeof t,"'name' must be a string"),n(e)||(e=[e]);let c="The ";y(t," argument")?c+=`${t} `:c+=`"${t}" ${g(t,".")?"property":"argument"} `,c+="must be ";const f=[],h=[],d=[];for(const t of e)A("string"==typeof t,"All expected entries have to be of type string"),i(v,t)?u(f,m(t)):p(E,t)?u(h,t):(A("object"!==t,'The value "object" should be written as "Object"'),u(d,t));if(h.length>0){const t=o(f,"object");-1!==t&&(l(f,t,1),u(h,"Object"))}if(f.length>0){if(f.length>2){const t=a(f);c+=`one of type ${s(f,", ")}, or ${t}`}else c+=2===f.length?`one of type ${f[0]} or ${f[1]}`:`of type ${f[0]}`;(h.length>0||d.length>0)&&(c+=" or ")}if(h.length>0){if(h.length>2){const t=a(h);c+=`an instance of ${s(h,", ")}, or ${t}`}else c+=`an instance of ${h[0]}`,2===h.length&&(c+=` or ${h[1]}`);d.length>0&&(c+=" or ")}if(d.length>0)if(d.length>2){const t=a(d);c+=`one of ${s(d,", ")}, or ${t}`}else 2===d.length?c+=`one of ${d[0]} or ${d[1]}`:(m(d[0])!==d[0]&&(c+="an "),c+=`${d[0]}`);if(null==r)c+=`. Received ${r}`;else if("function"==typeof r&&r.name)c+=`. Received function ${r.name}`;else if("object"==typeof r)r.constructor&&r.constructor.name?c+=`. Received an instance of ${r.constructor.name}`:c+=`. Received ${I().inspect(r,{depth:-1})}`;else{let t=I().inspect(r,{colors:!1});t.length>25&&(t=`${b(t,0,25)}...`),c+=`. Received type ${typeof r} (${t})`}return c},M=TypeError,w.set(L,P),_[L]=(U=M,j=L,function(...t){const e=Error.stackTraceLimit;Error.stackTraceLimit=0;const n=new U;Error.stackTraceLimit=e;const i=function(t,e,n){const i=w.get(t);return void 0===A&&(A=r(183)),A("function"==typeof i),A(i.length<=e.length,`Code: ${t}; The provided arguments length (${e.length}) does not match the required ones (${i.length}).`),h(i,n,e)}(j,t,n);return f(n,"message",{value:i,enumerable:!1,writable:!0,configurable:!0}),f(n,"toString",{value(){return`${this.name} [${j}]: ${this.message}`},enumerable:!1,writable:!0,configurable:!0}),B(n,U.name,j),n.code=j,n})},335:t=>{const e=/\u001b\[\d\d?m/g;t.exports={customInspectSymbol:Symbol.for("nodejs.util.inspect.custom"),isError:t=>t instanceof Error,join:Array.prototype.join.call.bind(Array.prototype.join),removeColors:t=>String.prototype.replace.call(t,e,"")}},63:(t,e,r)=>{const{getConstructorName:n}=r(891);function i(t,...e){for(const r of e){const e=globalThis[r];if(e&&t instanceof e)return!0}for(;t;){if("object"!=typeof t)return!1;if(e.indexOf(n(t))>=0)return!0;t=Object.getPrototypeOf(t)}return!1}function o(t){return e=>{if(!i(e,t.name))return!1;try{t.prototype.valueOf.call(e)}catch{return!1}return!0}}"object"!=typeof globalThis&&(Object.defineProperty(Object.prototype,"__magic__",{get:function(){return this},configurable:!0}),__magic__.globalThis=__magic__,delete Object.prototype.__magic__);const s=o(String),a=o(Number),u=o(Boolean),l=o(BigInt),c=o(Symbol);t.exports={isAsyncFunction:t=>"function"==typeof t&&Function.prototype.toString.call(t).startsWith("async"),isGeneratorFunction:t=>"function"==typeof t&&Function.prototype.toString.call(t).match(/^(async\s+)?function *\*/),isAnyArrayBuffer:t=>i(t,"ArrayBuffer","SharedArrayBuffer"),isArrayBuffer:t=>i(t,"ArrayBuffer"),isArgumentsObject:t=>!1,isBoxedPrimitive:t=>a(t)||s(t)||u(t)||l(t)||c(t),isDataView:t=>i(t,"DataView"),isExternal:t=>"object"==typeof t&&Object.isFrozen(t)&&null==Object.getPrototypeOf(t),isMap(t){if(!i(t,"Map"))return!1;try{t.has()}catch{return!1}return!0},isMapIterator:t=>"[object Map Iterator]"===Object.prototype.toString.call(Object.getPrototypeOf(t)),isModuleNamespaceObject:t=>t&&"object"==typeof t&&"Module"===t[Symbol.toStringTag],isNativeError:t=>t instanceof Error&&i(t,"Error","EvalError","RangeError","ReferenceError","SyntaxError","TypeError","URIError","AggregateError"),isPromise:t=>i(t,"Promise"),isSet(t){if(!i(t,"Set"))return!1;try{t.has()}catch{return!1}return!0},isSetIterator:t=>"[object Set Iterator]"===Object.prototype.toString.call(Object.getPrototypeOf(t)),isWeakMap:t=>i(t,"WeakMap"),isWeakSet:t=>i(t,"WeakSet"),isRegExp:t=>i(t,"RegExp"),isDate(t){if(i(t,"Date"))try{return Date.prototype.getTime.call(t),!0}catch{}return!1},isTypedArray:t=>i(t,"Int8Array","Uint8Array","Uint8ClampedArray","Int16Array","Uint16Array","Int32Array","Uint32Array","Float32Array","Float64Array","BigInt64Array","BigUint64Array"),isStringObject:s,isNumberObject:a,isBooleanObject:u,isBigIntObject:l,isSymbolObject:c}},356:(t,e,r)=>{const{hideStackFrames:n,codes:{ERR_INVALID_ARG_TYPE:i}}=r(101);e.validateObject=n(((t,e,{nullable:r=!1}={})=>{if(!r&&null===t||Array.isArray(t)||"object"!=typeof t)throw new i(e,"Object",t)}))},765:t=>{const e=(t,e)=>{class r{constructor(e){this._iterator=t(e)}next(){return e(this._iterator)}[Symbol.iterator](){return this}}return Object.setPrototypeOf(r.prototype,null),Object.freeze(r.prototype),Object.freeze(r),r};function r(t,e){return Function.prototype.call.bind(t.prototype.__lookupGetter__(e))}function n(t){return Function.prototype.call.bind(t)}const i=(t,e)=>{Array.prototype.forEach.call(Reflect.ownKeys(t),(r=>{Reflect.getOwnPropertyDescriptor(e,r)||Reflect.defineProperty(e,r,Reflect.getOwnPropertyDescriptor(t,r))}))},o=(t,r)=>{if(Symbol.iterator in t.prototype){const i=new t;let o;Array.prototype.forEach.call(Reflect.ownKeys(t.prototype),(s=>{if(!Reflect.getOwnPropertyDescriptor(r.prototype,s)){const a=Reflect.getOwnPropertyDescriptor(t.prototype,s);if("function"==typeof a.value&&0===a.value.length&&Symbol.iterator in(Function.prototype.call.call(a.value,i)||{})){const t=n(a.value);null==o&&(o=n(t(i).next));const r=e(t,o);a.value=function(){return new r(this)}}Reflect.defineProperty(r.prototype,s,a)}}))}else i(t.prototype,r.prototype);return i(t,r),Object.setPrototypeOf(r.prototype,null),Object.freeze(r.prototype),Object.freeze(r),r},s=Function.prototype.call.bind(String.prototype[Symbol.iterator]),a=Reflect.getPrototypeOf(s(""));t.exports={makeSafe:o,internalBinding(t){if("config"===t)return{hasIntl:!1};throw new Error(`unknown module: "${t}"`)},Array,ArrayIsArray:Array.isArray,ArrayPrototypeFilter:Function.prototype.call.bind(Array.prototype.filter),ArrayPrototypeForEach:Function.prototype.call.bind(Array.prototype.forEach),ArrayPrototypeIncludes:Function.prototype.call.bind(Array.prototype.includes),ArrayPrototypeIndexOf:Function.prototype.call.bind(Array.prototype.indexOf),ArrayPrototypeJoin:Function.prototype.call.bind(Array.prototype.join),ArrayPrototypePop:Function.prototype.call.bind(Array.prototype.pop),ArrayPrototypePush:Function.prototype.call.bind(Array.prototype.push),ArrayPrototypePushApply:Function.apply.bind(Array.prototype.push),ArrayPrototypeSort:Function.prototype.call.bind(Array.prototype.sort),ArrayPrototypeSplice:Function.prototype.call.bind(Array.prototype.slice),ArrayPrototypeUnshift:Function.prototype.call.bind(Array.prototype.unshift),BigIntPrototypeValueOf:Function.prototype.call.bind(BigInt.prototype.valueOf),BooleanPrototypeValueOf:Function.prototype.call.bind(Boolean.prototype.valueOf),DatePrototypeGetTime:Function.prototype.call.bind(Date.prototype.getTime),DatePrototypeToISOString:Function.prototype.call.bind(Date.prototype.toISOString),DatePrototypeToString:Function.prototype.call.bind(Date.prototype.toString),ErrorCaptureStackTrace:function(t){const e=(new Error).stack;t.stack=e.replace(/.*\n.*/,"$1")},ErrorPrototypeToString:Function.prototype.call.bind(Error.prototype.toString),FunctionPrototypeCall:Function.prototype.call.bind(Function.prototype.call),FunctionPrototypeToString:Function.prototype.call.bind(Function.prototype.toString),JSONStringify:JSON.stringify,MapPrototypeGetSize:r(Map,"size"),MapPrototypeEntries:Function.prototype.call.bind(Map.prototype.entries),MathFloor:Math.floor,MathMax:Math.max,MathMin:Math.min,MathRound:Math.round,MathSqrt:Math.sqrt,Number,NumberIsNaN:Number.isNaN,NumberParseFloat:Number.parseFloat,NumberParseInt:Number.parseInt,NumberPrototypeValueOf:Function.prototype.call.bind(Number.prototype.valueOf),Object,ObjectAssign:Object.assign,ObjectCreate:Object.create,ObjectDefineProperty:Object.defineProperty,ObjectGetOwnPropertyDescriptor:Object.getOwnPropertyDescriptor,ObjectGetOwnPropertyNames:Object.getOwnPropertyNames,ObjectGetOwnPropertySymbols:Object.getOwnPropertySymbols,ObjectGetPrototypeOf:Object.getPrototypeOf,ObjectIs:Object.is,ObjectKeys:Object.keys,ObjectPrototypeHasOwnProperty:Function.prototype.call.bind(Object.prototype.hasOwnProperty),ObjectPrototypePropertyIsEnumerable:Function.prototype.call.bind(Object.prototype.propertyIsEnumerable),ObjectSeal:Object.seal,ObjectSetPrototypeOf:Object.setPrototypeOf,ReflectApply:Reflect.apply,ReflectOwnKeys:Reflect.ownKeys,RegExp,RegExpPrototypeTest:Function.prototype.call.bind(RegExp.prototype.test),RegExpPrototypeToString:Function.prototype.call.bind(RegExp.prototype.toString),SafeStringIterator:e(s,Function.prototype.call.bind(a.next)),SafeMap:o(Map,class extends Map{constructor(t){super(t)}}),SafeSet:o(Set,class extends Set{constructor(t){super(t)}}),SetPrototypeGetSize:r(Set,"size"),SetPrototypeValues:Function.prototype.call.bind(Set.prototype.values),String,StringPrototypeCharCodeAt:Function.prototype.call.bind(String.prototype.charCodeAt),StringPrototypeCodePointAt:Function.prototype.call.bind(String.prototype.codePointAt),StringPrototypeEndsWith:Function.prototype.call.bind(String.prototype.endsWith),StringPrototypeIncludes:Function.prototype.call.bind(String.prototype.includes),StringPrototypeNormalize:Function.prototype.call.bind(String.prototype.normalize),StringPrototypePadEnd:Function.prototype.call.bind(String.prototype.padEnd),StringPrototypePadStart:Function.prototype.call.bind(String.prototype.padStart),StringPrototypeRepeat:Function.prototype.call.bind(String.prototype.repeat),StringPrototypeReplace:Function.prototype.call.bind(String.prototype.replace),StringPrototypeSlice:Function.prototype.call.bind(String.prototype.slice),StringPrototypeSplit:Function.prototype.call.bind(String.prototype.split),StringPrototypeToLowerCase:Function.prototype.call.bind(String.prototype.toLowerCase),StringPrototypeTrim:Function.prototype.call.bind(String.prototype.trim),StringPrototypeValueOf:Function.prototype.call.bind(String.prototype.valueOf),SymbolPrototypeToString:Function.prototype.call.bind(Symbol.prototype.toString),SymbolPrototypeValueOf:Function.prototype.call.bind(Symbol.prototype.valueOf),SymbolIterator:Symbol.iterator,SymbolFor:Symbol.for,SymbolToStringTag:Symbol.toStringTag,TypedArrayPrototypeGetLength:t=>t.constructor.prototype.__lookupGetter__("length").call(t),Uint8Array,uncurryThis:n}},161:t=>{const e=new WeakMap;class r{constructor(t,r){const n=new Proxy(t,r);return e.set(n,[t,r]),n}static getProxyDetails(t,r=!0){const n=e.get(t);if(n)return r?n:n[0]}}t.exports={getProxyDetails:r.getProxyDetails.bind(r),Proxy:r}},891:(t,e,r)=>{const n=r(161),i=Symbol("kPending"),o=Symbol("kRejected");t.exports={getOwnNonIndexProperties:function(t,e=2){const r=Object.getOwnPropertyDescriptors(t),n=[];for(const[t,i]of Object.entries(r))if(!/^(0|[1-9][0-9]*)$/.test(t)||parseInt(t,10)>=2**32-1){if(2===e&&!i.enumerable)continue;n.push(t)}for(const r of Object.getOwnPropertySymbols(t)){const i=Object.getOwnPropertyDescriptor(t,r);(2!==e||i.enumerable)&&n.push(r)}return n},getPromiseDetails:()=>[i,void 0],getProxyDetails:n.getProxyDetails,Proxy:n.Proxy,kPending:i,kRejected:o,previewEntries:t=>[[],!1],getConstructorName(t){if(!t||"object"!=typeof t)throw new Error("Invalid object");if(t.constructor&&t.constructor.name)return t.constructor.name;const e=Object.prototype.toString.call(t).match(/^\[object ([^\]]+)\]/);return e?e[1]:"Object"},getExternalValue:()=>BigInt(0),propertyFilter:{ALL_PROPERTIES:0,ONLY_ENUMERABLE:2}}}},e={};function r(n){var i=e[n];if(void 0!==i)return i.exports;var o=e[n]={exports:{}};return t[n](o,o.exports,r),o.exports}return r.g=function(){if("object"==typeof globalThis)return globalThis;try{return this||new Function("return this")()}catch(t){if("object"==typeof window)return window}}(),r(48)})()},155:t=>{var e,r,n=t.exports={};function i(){throw new Error("setTimeout has not been defined")}function o(){throw new Error("clearTimeout has not been defined")}function s(t){if(e===setTimeout)return setTimeout(t,0);if((e===i||!e)&&setTimeout)return e=setTimeout,setTimeout(t,0);try{return e(t,0)}catch(r){try{return e.call(null,t,0)}catch(r){return e.call(this,t,0)}}}!function(){try{e="function"==typeof setTimeout?setTimeout:i}catch(t){e=i}try{r="function"==typeof clearTimeout?clearTimeout:o}catch(t){r=o}}();var a,u=[],l=!1,c=-1;function f(){l&&a&&(l=!1,a.length?u=a.concat(u):c=-1,u.length&&h())}function h(){if(!l){var t=s(f);l=!0;for(var e=u.length;e;){for(a=u,u=[];++c<e;)a&&a[c].run();c=-1,e=u.length}a=null,l=!1,function(t){if(r===clearTimeout)return clearTimeout(t);if((r===o||!r)&&clearTimeout)return r=clearTimeout,clearTimeout(t);try{r(t)}catch(e){try{return r.call(null,t)}catch(e){return r.call(this,t)}}}(t)}}function p(t,e){this.fun=t,this.array=e}function d(){}n.nextTick=function(t){var e=new Array(arguments.length-1);if(arguments.length>1)for(var r=1;r<arguments.length;r++)e[r-1]=arguments[r];u.push(new p(t,e)),1!==u.length||l||s(h)},p.prototype.run=function(){this.fun.apply(null,this.array)},n.title="browser",n.browser=!0,n.env={},n.argv=[],n.version="",n.versions={},n.on=d,n.addListener=d,n.once=d,n.off=d,n.removeListener=d,n.removeAllListeners=d,n.emit=d,n.prependListener=d,n.prependOnceListener=d,n.listeners=function(t){return[]},n.binding=function(t){throw new Error("process.binding is not supported")},n.cwd=function(){return"/"},n.chdir=function(t){throw new Error("process.chdir is not supported")},n.umask=function(){return 0}},281:t=>{"use strict";var e={};function r(t,r,n){n||(n=Error);var i=function(t){var e,n;function i(e,n,i){return t.call(this,function(t,e,n){return"string"==typeof r?r:r(t,e,n)}(e,n,i))||this}return n=t,(e=i).prototype=Object.create(n.prototype),e.prototype.constructor=e,e.__proto__=n,i}(n);i.prototype.name=n.name,i.prototype.code=t,e[t]=i}function n(t,e){if(Array.isArray(t)){var r=t.length;return t=t.map((function(t){return String(t)})),r>2?"one of ".concat(e," ").concat(t.slice(0,r-1).join(", "),", or ")+t[r-1]:2===r?"one of ".concat(e," ").concat(t[0]," or ").concat(t[1]):"of ".concat(e," ").concat(t[0])}return"of ".concat(e," ").concat(String(t))}r("ERR_INVALID_OPT_VALUE",(function(t,e){return'The value "'+e+'" is invalid for option "'+t+'"'}),TypeError),r("ERR_INVALID_ARG_TYPE",(function(t,e,r){var i,o,s,a,u;if("string"==typeof e&&(o="not ",e.substr(0,o.length)===o)?(i="must not be",e=e.replace(/^not /,"")):i="must be",function(t,e,r){return(void 0===r||r>t.length)&&(r=t.length),t.substring(r-e.length,r)===e}(t," argument"))s="The ".concat(t," ").concat(i," ").concat(n(e,"type"));else{var l=("number"!=typeof u&&(u=0),u+".".length>(a=t).length||-1===a.indexOf(".",u)?"argument":"property");s='The "'.concat(t,'" ').concat(l," ").concat(i," ").concat(n(e,"type"))}return s+". Received type ".concat(typeof r)}),TypeError),r("ERR_STREAM_PUSH_AFTER_EOF","stream.push() after EOF"),r("ERR_METHOD_NOT_IMPLEMENTED",(function(t){return"The "+t+" method is not implemented"})),r("ERR_STREAM_PREMATURE_CLOSE","Premature close"),r("ERR_STREAM_DESTROYED",(function(t){return"Cannot call "+t+" after a stream was destroyed"})),r("ERR_MULTIPLE_CALLBACK","Callback called multiple times"),r("ERR_STREAM_CANNOT_PIPE","Cannot pipe, not readable"),r("ERR_STREAM_WRITE_AFTER_END","write after end"),r("ERR_STREAM_NULL_VALUES","May not write null values to stream",TypeError),r("ERR_UNKNOWN_ENCODING",(function(t){return"Unknown encoding: "+t}),TypeError),r("ERR_STREAM_UNSHIFT_AFTER_END_EVENT","stream.unshift() after end event"),t.exports.q=e},753:(t,e,r)=>{"use strict";var n=r(155),i=Object.keys||function(t){var e=[];for(var r in t)e.push(r);return e};t.exports=c;var o=r(481),s=r(229);r(717)(c,o);for(var a=i(s.prototype),u=0;u<a.length;u++){var l=a[u];c.prototype[l]||(c.prototype[l]=s.prototype[l])}function c(t){if(!(this instanceof c))return new c(t);o.call(this,t),s.call(this,t),this.allowHalfOpen=!0,t&&(!1===t.readable&&(this.readable=!1),!1===t.writable&&(this.writable=!1),!1===t.allowHalfOpen&&(this.allowHalfOpen=!1,this.once("end",f)))}function f(){this._writableState.ended||n.nextTick(h,this)}function h(t){t.end()}Object.defineProperty(c.prototype,"writableHighWaterMark",{enumerable:!1,get:function(){return this._writableState.highWaterMark}}),Object.defineProperty(c.prototype,"writableBuffer",{enumerable:!1,get:function(){return this._writableState&&this._writableState.getBuffer()}}),Object.defineProperty(c.prototype,"writableLength",{enumerable:!1,get:function(){return this._writableState.length}}),Object.defineProperty(c.prototype,"destroyed",{enumerable:!1,get:function(){return void 0!==this._readableState&&void 0!==this._writableState&&this._readableState.destroyed&&this._writableState.destroyed},set:function(t){void 0!==this._readableState&&void 0!==this._writableState&&(this._readableState.destroyed=t,this._writableState.destroyed=t)}})},725:(t,e,r)=>{"use strict";t.exports=i;var n=r(605);function i(t){if(!(this instanceof i))return new i(t);n.call(this,t)}r(717)(i,n),i.prototype._transform=function(t,e,r){r(null,t)}},481:(t,e,r)=>{"use strict";var n,i=r(155);t.exports=T,T.ReadableState=A,r(187).EventEmitter;var o,s=function(t,e){return t.listeners(e).length},a=r(503),u=r(764).Buffer,l=r.g.Uint8Array||function(){},c=r(669);o=c&&c.debuglog?c.debuglog("stream"):function(){};var f,h,p,d=r(327),y=r(195),g=r(457).getHighWaterMark,b=r(281).q,m=b.ERR_INVALID_ARG_TYPE,w=b.ERR_STREAM_PUSH_AFTER_EOF,_=b.ERR_METHOD_NOT_IMPLEMENTED,E=b.ERR_STREAM_UNSHIFT_AFTER_END_EVENT;r(717)(T,a);var v=y.errorOrDestroy,S=["error","close","destroy","pause","resume"];function A(t,e,i){n=n||r(753),t=t||{},"boolean"!=typeof i&&(i=e instanceof n),this.objectMode=!!t.objectMode,i&&(this.objectMode=this.objectMode||!!t.readableObjectMode),this.highWaterMark=g(this,t,"readableHighWaterMark",i),this.buffer=new d,this.length=0,this.pipes=null,this.pipesCount=0,this.flowing=null,this.ended=!1,this.endEmitted=!1,this.reading=!1,this.sync=!0,this.needReadable=!1,this.emittedReadable=!1,this.readableListening=!1,this.resumeScheduled=!1,this.paused=!0,this.emitClose=!1!==t.emitClose,this.autoDestroy=!!t.autoDestroy,this.destroyed=!1,this.defaultEncoding=t.defaultEncoding||"utf8",this.awaitDrain=0,this.readingMore=!1,this.decoder=null,this.encoding=null,t.encoding&&(f||(f=r(553).s),this.decoder=new f(t.encoding),this.encoding=t.encoding)}function T(t){if(n=n||r(753),!(this instanceof T))return new T(t);var e=this instanceof n;this._readableState=new A(t,this,e),this.readable=!0,t&&("function"==typeof t.read&&(this._read=t.read),"function"==typeof t.destroy&&(this._destroy=t.destroy)),a.call(this)}function I(t,e,r,n,i){o("readableAddChunk",e);var s,a=t._readableState;if(null===e)a.reading=!1,function(t,e){if(o("onEofChunk"),!e.ended){if(e.decoder){var r=e.decoder.end();r&&r.length&&(e.buffer.push(r),e.length+=e.objectMode?1:r.length)}e.ended=!0,e.sync?R(t):(e.needReadable=!1,e.emittedReadable||(e.emittedReadable=!0,N(t)))}}(t,a);else if(i||(s=function(t,e){var r,n;return n=e,u.isBuffer(n)||n instanceof l||"string"==typeof e||void 0===e||t.objectMode||(r=new m("chunk",["string","Buffer","Uint8Array"],e)),r}(a,e)),s)v(t,s);else if(a.objectMode||e&&e.length>0)if("string"==typeof e||a.objectMode||Object.getPrototypeOf(e)===u.prototype||(e=function(t){return u.from(t)}(e)),n)a.endEmitted?v(t,new E):B(t,a,e,!0);else if(a.ended)v(t,new w);else{if(a.destroyed)return!1;a.reading=!1,a.decoder&&!r?(e=a.decoder.write(e),a.objectMode||0!==e.length?B(t,a,e,!1):L(t,a)):B(t,a,e,!1)}else n||(a.reading=!1,L(t,a));return!a.ended&&(a.length<a.highWaterMark||0===a.length)}function B(t,e,r,n){e.flowing&&0===e.length&&!e.sync?(e.awaitDrain=0,t.emit("data",r)):(e.length+=e.objectMode?1:r.length,n?e.buffer.unshift(r):e.buffer.push(r),e.needReadable&&R(t)),L(t,e)}Object.defineProperty(T.prototype,"destroyed",{enumerable:!1,get:function(){return void 0!==this._readableState&&this._readableState.destroyed},set:function(t){this._readableState&&(this._readableState.destroyed=t)}}),T.prototype.destroy=y.destroy,T.prototype._undestroy=y.undestroy,T.prototype._destroy=function(t,e){e(t)},T.prototype.push=function(t,e){var r,n=this._readableState;return n.objectMode?r=!0:"string"==typeof t&&((e=e||n.defaultEncoding)!==n.encoding&&(t=u.from(t,e),e=""),r=!0),I(this,t,e,!1,r)},T.prototype.unshift=function(t){return I(this,t,null,!0,!1)},T.prototype.isPaused=function(){return!1===this._readableState.flowing},T.prototype.setEncoding=function(t){f||(f=r(553).s);var e=new f(t);this._readableState.decoder=e,this._readableState.encoding=this._readableState.decoder.encoding;for(var n=this._readableState.buffer.head,i="";null!==n;)i+=e.write(n.data),n=n.next;return this._readableState.buffer.clear(),""!==i&&this._readableState.buffer.push(i),this._readableState.length=i.length,this};var O=1073741824;function x(t,e){return t<=0||0===e.length&&e.ended?0:e.objectMode?1:t!=t?e.flowing&&e.length?e.buffer.head.data.length:e.length:(t>e.highWaterMark&&(e.highWaterMark=function(t){return t>=O?t=O:(t--,t|=t>>>1,t|=t>>>2,t|=t>>>4,t|=t>>>8,t|=t>>>16,t++),t}(t)),t<=e.length?t:e.ended?e.length:(e.needReadable=!0,0))}function R(t){var e=t._readableState;o("emitReadable",e.needReadable,e.emittedReadable),e.needReadable=!1,e.emittedReadable||(o("emitReadable",e.flowing),e.emittedReadable=!0,i.nextTick(N,t))}function N(t){var e=t._readableState;o("emitReadable_",e.destroyed,e.length,e.ended),e.destroyed||!e.length&&!e.ended||(t.emit("readable"),e.emittedReadable=!1),e.needReadable=!e.flowing&&!e.ended&&e.length<=e.highWaterMark,k(t)}function L(t,e){e.readingMore||(e.readingMore=!0,i.nextTick(P,t,e))}function P(t,e){for(;!e.reading&&!e.ended&&(e.length<e.highWaterMark||e.flowing&&0===e.length);){var r=e.length;if(o("maybeReadMore read 0"),t.read(0),r===e.length)break}e.readingMore=!1}function M(t){var e=t._readableState;e.readableListening=t.listenerCount("readable")>0,e.resumeScheduled&&!e.paused?e.flowing=!0:t.listenerCount("data")>0&&t.resume()}function U(t){o("readable nexttick read 0"),t.read(0)}function j(t,e){o("resume",e.reading),e.reading||t.read(0),e.resumeScheduled=!1,t.emit("resume"),k(t),e.flowing&&!e.reading&&t.read(0)}function k(t){var e=t._readableState;for(o("flow",e.flowing);e.flowing&&null!==t.read(););}function $(t,e){return 0===e.length?null:(e.objectMode?r=e.buffer.shift():!t||t>=e.length?(r=e.decoder?e.buffer.join(""):1===e.buffer.length?e.buffer.first():e.buffer.concat(e.length),e.buffer.clear()):r=e.buffer.consume(t,e.decoder),r);var r}function F(t){var e=t._readableState;o("endReadable",e.endEmitted),e.endEmitted||(e.ended=!0,i.nextTick(D,e,t))}function D(t,e){if(o("endReadableNT",t.endEmitted,t.length),!t.endEmitted&&0===t.length&&(t.endEmitted=!0,e.readable=!1,e.emit("end"),t.autoDestroy)){var r=e._writableState;(!r||r.autoDestroy&&r.finished)&&e.destroy()}}function C(t,e){for(var r=0,n=t.length;r<n;r++)if(t[r]===e)return r;return-1}T.prototype.read=function(t){o("read",t),t=parseInt(t,10);var e=this._readableState,r=t;if(0!==t&&(e.emittedReadable=!1),0===t&&e.needReadable&&((0!==e.highWaterMark?e.length>=e.highWaterMark:e.length>0)||e.ended))return o("read: emitReadable",e.length,e.ended),0===e.length&&e.ended?F(this):R(this),null;if(0===(t=x(t,e))&&e.ended)return 0===e.length&&F(this),null;var n,i=e.needReadable;return o("need readable",i),(0===e.length||e.length-t<e.highWaterMark)&&o("length less than watermark",i=!0),e.ended||e.reading?o("reading or ended",i=!1):i&&(o("do read"),e.reading=!0,e.sync=!0,0===e.length&&(e.needReadable=!0),this._read(e.highWaterMark),e.sync=!1,e.reading||(t=x(r,e))),null===(n=t>0?$(t,e):null)?(e.needReadable=e.length<=e.highWaterMark,t=0):(e.length-=t,e.awaitDrain=0),0===e.length&&(e.ended||(e.needReadable=!0),r!==t&&e.ended&&F(this)),null!==n&&this.emit("data",n),n},T.prototype._read=function(t){v(this,new _("_read()"))},T.prototype.pipe=function(t,e){var r=this,n=this._readableState;switch(n.pipesCount){case 0:n.pipes=t;break;case 1:n.pipes=[n.pipes,t];break;default:n.pipes.push(t)}n.pipesCount+=1,o("pipe count=%d opts=%j",n.pipesCount,e);var a=e&&!1===e.end||t===i.stdout||t===i.stderr?y:u;function u(){o("onend"),t.end()}n.endEmitted?i.nextTick(a):r.once("end",a),t.on("unpipe",(function e(i,s){o("onunpipe"),i===r&&s&&!1===s.hasUnpiped&&(s.hasUnpiped=!0,o("cleanup"),t.removeListener("close",p),t.removeListener("finish",d),t.removeListener("drain",l),t.removeListener("error",h),t.removeListener("unpipe",e),r.removeListener("end",u),r.removeListener("end",y),r.removeListener("data",f),c=!0,!n.awaitDrain||t._writableState&&!t._writableState.needDrain||l())}));var l=function(t){return function(){var e=t._readableState;o("pipeOnDrain",e.awaitDrain),e.awaitDrain&&e.awaitDrain--,0===e.awaitDrain&&s(t,"data")&&(e.flowing=!0,k(t))}}(r);t.on("drain",l);var c=!1;function f(e){o("ondata");var i=t.write(e);o("dest.write",i),!1===i&&((1===n.pipesCount&&n.pipes===t||n.pipesCount>1&&-1!==C(n.pipes,t))&&!c&&(o("false write response, pause",n.awaitDrain),n.awaitDrain++),r.pause())}function h(e){o("onerror",e),y(),t.removeListener("error",h),0===s(t,"error")&&v(t,e)}function p(){t.removeListener("finish",d),y()}function d(){o("onfinish"),t.removeListener("close",p),y()}function y(){o("unpipe"),r.unpipe(t)}return r.on("data",f),function(t,e,r){if("function"==typeof t.prependListener)return t.prependListener(e,r);t._events&&t._events.error?Array.isArray(t._events.error)?t._events.error.unshift(r):t._events.error=[r,t._events.error]:t.on(e,r)}(t,"error",h),t.once("close",p),t.once("finish",d),t.emit("pipe",r),n.flowing||(o("pipe resume"),r.resume()),t},T.prototype.unpipe=function(t){var e=this._readableState,r={hasUnpiped:!1};if(0===e.pipesCount)return this;if(1===e.pipesCount)return t&&t!==e.pipes||(t||(t=e.pipes),e.pipes=null,e.pipesCount=0,e.flowing=!1,t&&t.emit("unpipe",this,r)),this;if(!t){var n=e.pipes,i=e.pipesCount;e.pipes=null,e.pipesCount=0,e.flowing=!1;for(var o=0;o<i;o++)n[o].emit("unpipe",this,{hasUnpiped:!1});return this}var s=C(e.pipes,t);return-1===s||(e.pipes.splice(s,1),e.pipesCount-=1,1===e.pipesCount&&(e.pipes=e.pipes[0]),t.emit("unpipe",this,r)),this},T.prototype.on=function(t,e){var r=a.prototype.on.call(this,t,e),n=this._readableState;return"data"===t?(n.readableListening=this.listenerCount("readable")>0,!1!==n.flowing&&this.resume()):"readable"===t&&(n.endEmitted||n.readableListening||(n.readableListening=n.needReadable=!0,n.flowing=!1,n.emittedReadable=!1,o("on readable",n.length,n.reading),n.length?R(this):n.reading||i.nextTick(U,this))),r},T.prototype.addListener=T.prototype.on,T.prototype.removeListener=function(t,e){var r=a.prototype.removeListener.call(this,t,e);return"readable"===t&&i.nextTick(M,this),r},T.prototype.removeAllListeners=function(t){var e=a.prototype.removeAllListeners.apply(this,arguments);return"readable"!==t&&void 0!==t||i.nextTick(M,this),e},T.prototype.resume=function(){var t=this._readableState;return t.flowing||(o("resume"),t.flowing=!t.readableListening,function(t,e){e.resumeScheduled||(e.resumeScheduled=!0,i.nextTick(j,t,e))}(this,t)),t.paused=!1,this},T.prototype.pause=function(){return o("call pause flowing=%j",this._readableState.flowing),!1!==this._readableState.flowing&&(o("pause"),this._readableState.flowing=!1,this.emit("pause")),this._readableState.paused=!0,this},T.prototype.wrap=function(t){var e=this,r=this._readableState,n=!1;for(var i in t.on("end",(function(){if(o("wrapped end"),r.decoder&&!r.ended){var t=r.decoder.end();t&&t.length&&e.push(t)}e.push(null)})),t.on("data",(function(i){o("wrapped data"),r.decoder&&(i=r.decoder.write(i)),r.objectMode&&null==i||(r.objectMode||i&&i.length)&&(e.push(i)||(n=!0,t.pause()))})),t)void 0===this[i]&&"function"==typeof t[i]&&(this[i]=function(e){return function(){return t[e].apply(t,arguments)}}(i));for(var s=0;s<S.length;s++)t.on(S[s],this.emit.bind(this,S[s]));return this._read=function(e){o("wrapped _read",e),n&&(n=!1,t.resume())},this},"function"==typeof Symbol&&(T.prototype[Symbol.asyncIterator]=function(){return void 0===h&&(h=r(850)),h(this)}),Object.defineProperty(T.prototype,"readableHighWaterMark",{enumerable:!1,get:function(){return this._readableState.highWaterMark}}),Object.defineProperty(T.prototype,"readableBuffer",{enumerable:!1,get:function(){return this._readableState&&this._readableState.buffer}}),Object.defineProperty(T.prototype,"readableFlowing",{enumerable:!1,get:function(){return this._readableState.flowing},set:function(t){this._readableState&&(this._readableState.flowing=t)}}),T._fromList=$,Object.defineProperty(T.prototype,"readableLength",{enumerable:!1,get:function(){return this._readableState.length}}),"function"==typeof Symbol&&(T.from=function(t,e){return void 0===p&&(p=r(167)),p(T,t,e)})},605:(t,e,r)=>{"use strict";t.exports=c;var n=r(281).q,i=n.ERR_METHOD_NOT_IMPLEMENTED,o=n.ERR_MULTIPLE_CALLBACK,s=n.ERR_TRANSFORM_ALREADY_TRANSFORMING,a=n.ERR_TRANSFORM_WITH_LENGTH_0,u=r(753);function l(t,e){var r=this._transformState;r.transforming=!1;var n=r.writecb;if(null===n)return this.emit("error",new o);r.writechunk=null,r.writecb=null,null!=e&&this.push(e),n(t);var i=this._readableState;i.reading=!1,(i.needReadable||i.length<i.highWaterMark)&&this._read(i.highWaterMark)}function c(t){if(!(this instanceof c))return new c(t);u.call(this,t),this._transformState={afterTransform:l.bind(this),needTransform:!1,transforming:!1,writecb:null,writechunk:null,writeencoding:null},this._readableState.needReadable=!0,this._readableState.sync=!1,t&&("function"==typeof t.transform&&(this._transform=t.transform),"function"==typeof t.flush&&(this._flush=t.flush)),this.on("prefinish",f)}function f(){var t=this;"function"!=typeof this._flush||this._readableState.destroyed?h(this,null,null):this._flush((function(e,r){h(t,e,r)}))}function h(t,e,r){if(e)return t.emit("error",e);if(null!=r&&t.push(r),t._writableState.length)throw new a;if(t._transformState.transforming)throw new s;return t.push(null)}r(717)(c,u),c.prototype.push=function(t,e){return this._transformState.needTransform=!1,u.prototype.push.call(this,t,e)},c.prototype._transform=function(t,e,r){r(new i("_transform()"))},c.prototype._write=function(t,e,r){var n=this._transformState;if(n.writecb=r,n.writechunk=t,n.writeencoding=e,!n.transforming){var i=this._readableState;(n.needTransform||i.needReadable||i.length<i.highWaterMark)&&this._read(i.highWaterMark)}},c.prototype._read=function(t){var e=this._transformState;null===e.writechunk||e.transforming?e.needTransform=!0:(e.transforming=!0,this._transform(e.writechunk,e.writeencoding,e.afterTransform))},c.prototype._destroy=function(t,e){u.prototype._destroy.call(this,t,(function(t){e(t)}))}},229:(t,e,r)=>{"use strict";var n,i=r(155);function o(t){var e=this;this.next=null,this.entry=null,this.finish=function(){!function(t,e,r){var n=t.entry;for(t.entry=null;n;){var i=n.callback;e.pendingcb--,i(undefined),n=n.next}e.corkedRequestsFree.next=t}(e,t)}}t.exports=T,T.WritableState=A;var s,a={deprecate:r(927)},u=r(503),l=r(764).Buffer,c=r.g.Uint8Array||function(){},f=r(195),h=r(457).getHighWaterMark,p=r(281).q,d=p.ERR_INVALID_ARG_TYPE,y=p.ERR_METHOD_NOT_IMPLEMENTED,g=p.ERR_MULTIPLE_CALLBACK,b=p.ERR_STREAM_CANNOT_PIPE,m=p.ERR_STREAM_DESTROYED,w=p.ERR_STREAM_NULL_VALUES,_=p.ERR_STREAM_WRITE_AFTER_END,E=p.ERR_UNKNOWN_ENCODING,v=f.errorOrDestroy;function S(){}function A(t,e,s){n=n||r(753),t=t||{},"boolean"!=typeof s&&(s=e instanceof n),this.objectMode=!!t.objectMode,s&&(this.objectMode=this.objectMode||!!t.writableObjectMode),this.highWaterMark=h(this,t,"writableHighWaterMark",s),this.finalCalled=!1,this.needDrain=!1,this.ending=!1,this.ended=!1,this.finished=!1,this.destroyed=!1;var a=!1===t.decodeStrings;this.decodeStrings=!a,this.defaultEncoding=t.defaultEncoding||"utf8",this.length=0,this.writing=!1,this.corked=0,this.sync=!0,this.bufferProcessing=!1,this.onwrite=function(t){!function(t,e){var r=t._writableState,n=r.sync,o=r.writecb;if("function"!=typeof o)throw new g;if(function(t){t.writing=!1,t.writecb=null,t.length-=t.writelen,t.writelen=0}(r),e)!function(t,e,r,n,o){--e.pendingcb,r?(i.nextTick(o,n),i.nextTick(N,t,e),t._writableState.errorEmitted=!0,v(t,n)):(o(n),t._writableState.errorEmitted=!0,v(t,n),N(t,e))}(t,r,n,e,o);else{var s=x(r)||t.destroyed;s||r.corked||r.bufferProcessing||!r.bufferedRequest||O(t,r),n?i.nextTick(B,t,r,s,o):B(t,r,s,o)}}(e,t)},this.writecb=null,this.writelen=0,this.bufferedRequest=null,this.lastBufferedRequest=null,this.pendingcb=0,this.prefinished=!1,this.errorEmitted=!1,this.emitClose=!1!==t.emitClose,this.autoDestroy=!!t.autoDestroy,this.bufferedRequestCount=0,this.corkedRequestsFree=new o(this)}function T(t){var e=this instanceof(n=n||r(753));if(!e&&!s.call(T,this))return new T(t);this._writableState=new A(t,this,e),this.writable=!0,t&&("function"==typeof t.write&&(this._write=t.write),"function"==typeof t.writev&&(this._writev=t.writev),"function"==typeof t.destroy&&(this._destroy=t.destroy),"function"==typeof t.final&&(this._final=t.final)),u.call(this)}function I(t,e,r,n,i,o,s){e.writelen=n,e.writecb=s,e.writing=!0,e.sync=!0,e.destroyed?e.onwrite(new m("write")):r?t._writev(i,e.onwrite):t._write(i,o,e.onwrite),e.sync=!1}function B(t,e,r,n){r||function(t,e){0===e.length&&e.needDrain&&(e.needDrain=!1,t.emit("drain"))}(t,e),e.pendingcb--,n(),N(t,e)}function O(t,e){e.bufferProcessing=!0;var r=e.bufferedRequest;if(t._writev&&r&&r.next){var n=e.bufferedRequestCount,i=new Array(n),s=e.corkedRequestsFree;s.entry=r;for(var a=0,u=!0;r;)i[a]=r,r.isBuf||(u=!1),r=r.next,a+=1;i.allBuffers=u,I(t,e,!0,e.length,i,"",s.finish),e.pendingcb++,e.lastBufferedRequest=null,s.next?(e.corkedRequestsFree=s.next,s.next=null):e.corkedRequestsFree=new o(e),e.bufferedRequestCount=0}else{for(;r;){var l=r.chunk,c=r.encoding,f=r.callback;if(I(t,e,!1,e.objectMode?1:l.length,l,c,f),r=r.next,e.bufferedRequestCount--,e.writing)break}null===r&&(e.lastBufferedRequest=null)}e.bufferedRequest=r,e.bufferProcessing=!1}function x(t){return t.ending&&0===t.length&&null===t.bufferedRequest&&!t.finished&&!t.writing}function R(t,e){t._final((function(r){e.pendingcb--,r&&v(t,r),e.prefinished=!0,t.emit("prefinish"),N(t,e)}))}function N(t,e){var r=x(e);if(r&&(function(t,e){e.prefinished||e.finalCalled||("function"!=typeof t._final||e.destroyed?(e.prefinished=!0,t.emit("prefinish")):(e.pendingcb++,e.finalCalled=!0,i.nextTick(R,t,e)))}(t,e),0===e.pendingcb&&(e.finished=!0,t.emit("finish"),e.autoDestroy))){var n=t._readableState;(!n||n.autoDestroy&&n.endEmitted)&&t.destroy()}return r}r(717)(T,u),A.prototype.getBuffer=function(){for(var t=this.bufferedRequest,e=[];t;)e.push(t),t=t.next;return e},function(){try{Object.defineProperty(A.prototype,"buffer",{get:a.deprecate((function(){return this.getBuffer()}),"_writableState.buffer is deprecated. Use _writableState.getBuffer instead.","DEP0003")})}catch(t){}}(),"function"==typeof Symbol&&Symbol.hasInstance&&"function"==typeof Function.prototype[Symbol.hasInstance]?(s=Function.prototype[Symbol.hasInstance],Object.defineProperty(T,Symbol.hasInstance,{value:function(t){return!!s.call(this,t)||this===T&&t&&t._writableState instanceof A}})):s=function(t){return t instanceof this},T.prototype.pipe=function(){v(this,new b)},T.prototype.write=function(t,e,r){var n,o=this._writableState,s=!1,a=!o.objectMode&&(n=t,l.isBuffer(n)||n instanceof c);return a&&!l.isBuffer(t)&&(t=function(t){return l.from(t)}(t)),"function"==typeof e&&(r=e,e=null),a?e="buffer":e||(e=o.defaultEncoding),"function"!=typeof r&&(r=S),o.ending?function(t,e){var r=new _;v(t,r),i.nextTick(e,r)}(this,r):(a||function(t,e,r,n){var o;return null===r?o=new w:"string"==typeof r||e.objectMode||(o=new d("chunk",["string","Buffer"],r)),!o||(v(t,o),i.nextTick(n,o),!1)}(this,o,t,r))&&(o.pendingcb++,s=function(t,e,r,n,i,o){if(!r){var s=function(t,e,r){return t.objectMode||!1===t.decodeStrings||"string"!=typeof e||(e=l.from(e,r)),e}(e,n,i);n!==s&&(r=!0,i="buffer",n=s)}var a=e.objectMode?1:n.length;e.length+=a;var u=e.length<e.highWaterMark;if(u||(e.needDrain=!0),e.writing||e.corked){var c=e.lastBufferedRequest;e.lastBufferedRequest={chunk:n,encoding:i,isBuf:r,callback:o,next:null},c?c.next=e.lastBufferedRequest:e.bufferedRequest=e.lastBufferedRequest,e.bufferedRequestCount+=1}else I(t,e,!1,a,n,i,o);return u}(this,o,a,t,e,r)),s},T.prototype.cork=function(){this._writableState.corked++},T.prototype.uncork=function(){var t=this._writableState;t.corked&&(t.corked--,t.writing||t.corked||t.bufferProcessing||!t.bufferedRequest||O(this,t))},T.prototype.setDefaultEncoding=function(t){if("string"==typeof t&&(t=t.toLowerCase()),!(["hex","utf8","utf-8","ascii","binary","base64","ucs2","ucs-2","utf16le","utf-16le","raw"].indexOf((t+"").toLowerCase())>-1))throw new E(t);return this._writableState.defaultEncoding=t,this},Object.defineProperty(T.prototype,"writableBuffer",{enumerable:!1,get:function(){return this._writableState&&this._writableState.getBuffer()}}),Object.defineProperty(T.prototype,"writableHighWaterMark",{enumerable:!1,get:function(){return this._writableState.highWaterMark}}),T.prototype._write=function(t,e,r){r(new y("_write()"))},T.prototype._writev=null,T.prototype.end=function(t,e,r){var n=this._writableState;return"function"==typeof t?(r=t,t=null,e=null):"function"==typeof e&&(r=e,e=null),null!=t&&this.write(t,e),n.corked&&(n.corked=1,this.uncork()),n.ending||function(t,e,r){e.ending=!0,N(t,e),r&&(e.finished?i.nextTick(r):t.once("finish",r)),e.ended=!0,t.writable=!1}(this,n,r),this},Object.defineProperty(T.prototype,"writableLength",{enumerable:!1,get:function(){return this._writableState.length}}),Object.defineProperty(T.prototype,"destroyed",{enumerable:!1,get:function(){return void 0!==this._writableState&&this._writableState.destroyed},set:function(t){this._writableState&&(this._writableState.destroyed=t)}}),T.prototype.destroy=f.destroy,T.prototype._undestroy=f.undestroy,T.prototype._destroy=function(t,e){e(t)}},850:(t,e,r)=>{"use strict";var n,i=r(155);function o(t,e,r){return e in t?Object.defineProperty(t,e,{value:r,enumerable:!0,configurable:!0,writable:!0}):t[e]=r,t}var s=r(610),a=Symbol("lastResolve"),u=Symbol("lastReject"),l=Symbol("error"),c=Symbol("ended"),f=Symbol("lastPromise"),h=Symbol("handlePromise"),p=Symbol("stream");function d(t,e){return{value:t,done:e}}function y(t){var e=t[a];if(null!==e){var r=t[p].read();null!==r&&(t[f]=null,t[a]=null,t[u]=null,e(d(r,!1)))}}function g(t){i.nextTick(y,t)}var b=Object.getPrototypeOf((function(){})),m=Object.setPrototypeOf((o(n={get stream(){return this[p]},next:function(){var t=this,e=this[l];if(null!==e)return Promise.reject(e);if(this[c])return Promise.resolve(d(void 0,!0));if(this[p].destroyed)return new Promise((function(e,r){i.nextTick((function(){t[l]?r(t[l]):e(d(void 0,!0))}))}));var r,n=this[f];if(n)r=new Promise(function(t,e){return function(r,n){t.then((function(){e[c]?r(d(void 0,!0)):e[h](r,n)}),n)}}(n,this));else{var o=this[p].read();if(null!==o)return Promise.resolve(d(o,!1));r=new Promise(this[h])}return this[f]=r,r}},Symbol.asyncIterator,(function(){return this})),o(n,"return",(function(){var t=this;return new Promise((function(e,r){t[p].destroy(null,(function(t){t?r(t):e(d(void 0,!0))}))}))})),n),b);t.exports=function(t){var e,r=Object.create(m,(o(e={},p,{value:t,writable:!0}),o(e,a,{value:null,writable:!0}),o(e,u,{value:null,writable:!0}),o(e,l,{value:null,writable:!0}),o(e,c,{value:t._readableState.endEmitted,writable:!0}),o(e,h,{value:function(t,e){var n=r[p].read();n?(r[f]=null,r[a]=null,r[u]=null,t(d(n,!1))):(r[a]=t,r[u]=e)},writable:!0}),e));return r[f]=null,s(t,(function(t){if(t&&"ERR_STREAM_PREMATURE_CLOSE"!==t.code){var e=r[u];return null!==e&&(r[f]=null,r[a]=null,r[u]=null,e(t)),void(r[l]=t)}var n=r[a];null!==n&&(r[f]=null,r[a]=null,r[u]=null,n(d(void 0,!0))),r[c]=!0})),t.on("readable",g.bind(null,r)),r}},327:(t,e,r)=>{"use strict";function n(t,e){var r=Object.keys(t);if(Object.getOwnPropertySymbols){var n=Object.getOwnPropertySymbols(t);e&&(n=n.filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable}))),r.push.apply(r,n)}return r}function i(t,e,r){return e in t?Object.defineProperty(t,e,{value:r,enumerable:!0,configurable:!0,writable:!0}):t[e]=r,t}function o(t,e){for(var r=0;r<e.length;r++){var n=e[r];n.enumerable=n.enumerable||!1,n.configurable=!0,"value"in n&&(n.writable=!0),Object.defineProperty(t,n.key,n)}}var s=r(764).Buffer,a=r(669).inspect,u=a&&a.custom||"inspect";t.exports=function(){function t(){!function(t,e){if(!(t instanceof e))throw new TypeError("Cannot call a class as a function")}(this,t),this.head=null,this.tail=null,this.length=0}var e,r;return e=t,(r=[{key:"push",value:function(t){var e={data:t,next:null};this.length>0?this.tail.next=e:this.head=e,this.tail=e,++this.length}},{key:"unshift",value:function(t){var e={data:t,next:this.head};0===this.length&&(this.tail=e),this.head=e,++this.length}},{key:"shift",value:function(){if(0!==this.length){var t=this.head.data;return 1===this.length?this.head=this.tail=null:this.head=this.head.next,--this.length,t}}},{key:"clear",value:function(){this.head=this.tail=null,this.length=0}},{key:"join",value:function(t){if(0===this.length)return"";for(var e=this.head,r=""+e.data;e=e.next;)r+=t+e.data;return r}},{key:"concat",value:function(t){if(0===this.length)return s.alloc(0);for(var e,r,n,i=s.allocUnsafe(t>>>0),o=this.head,a=0;o;)e=o.data,r=i,n=a,s.prototype.copy.call(e,r,n),a+=o.data.length,o=o.next;return i}},{key:"consume",value:function(t,e){var r;return t<this.head.data.length?(r=this.head.data.slice(0,t),this.head.data=this.head.data.slice(t)):r=t===this.head.data.length?this.shift():e?this._getString(t):this._getBuffer(t),r}},{key:"first",value:function(){return this.head.data}},{key:"_getString",value:function(t){var e=this.head,r=1,n=e.data;for(t-=n.length;e=e.next;){var i=e.data,o=t>i.length?i.length:t;if(o===i.length?n+=i:n+=i.slice(0,t),0==(t-=o)){o===i.length?(++r,e.next?this.head=e.next:this.head=this.tail=null):(this.head=e,e.data=i.slice(o));break}++r}return this.length-=r,n}},{key:"_getBuffer",value:function(t){var e=s.allocUnsafe(t),r=this.head,n=1;for(r.data.copy(e),t-=r.data.length;r=r.next;){var i=r.data,o=t>i.length?i.length:t;if(i.copy(e,e.length-t,0,o),0==(t-=o)){o===i.length?(++n,r.next?this.head=r.next:this.head=this.tail=null):(this.head=r,r.data=i.slice(o));break}++n}return this.length-=n,e}},{key:u,value:function(t,e){return a(this,function(t){for(var e=1;e<arguments.length;e++){var r=null!=arguments[e]?arguments[e]:{};e%2?n(Object(r),!0).forEach((function(e){i(t,e,r[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(r)):n(Object(r)).forEach((function(e){Object.defineProperty(t,e,Object.getOwnPropertyDescriptor(r,e))}))}return t}({},e,{depth:0,customInspect:!1}))}}])&&o(e.prototype,r),t}()},195:(t,e,r)=>{"use strict";var n=r(155);function i(t,e){s(t,e),o(t)}function o(t){t._writableState&&!t._writableState.emitClose||t._readableState&&!t._readableState.emitClose||t.emit("close")}function s(t,e){t.emit("error",e)}t.exports={destroy:function(t,e){var r=this,a=this._readableState&&this._readableState.destroyed,u=this._writableState&&this._writableState.destroyed;return a||u?(e?e(t):t&&(this._writableState?this._writableState.errorEmitted||(this._writableState.errorEmitted=!0,n.nextTick(s,this,t)):n.nextTick(s,this,t)),this):(this._readableState&&(this._readableState.destroyed=!0),this._writableState&&(this._writableState.destroyed=!0),this._destroy(t||null,(function(t){!e&&t?r._writableState?r._writableState.errorEmitted?n.nextTick(o,r):(r._writableState.errorEmitted=!0,n.nextTick(i,r,t)):n.nextTick(i,r,t):e?(n.nextTick(o,r),e(t)):n.nextTick(o,r)})),this)},undestroy:function(){this._readableState&&(this._readableState.destroyed=!1,this._readableState.reading=!1,this._readableState.ended=!1,this._readableState.endEmitted=!1),this._writableState&&(this._writableState.destroyed=!1,this._writableState.ended=!1,this._writableState.ending=!1,this._writableState.finalCalled=!1,this._writableState.prefinished=!1,this._writableState.finished=!1,this._writableState.errorEmitted=!1)},errorOrDestroy:function(t,e){var r=t._readableState,n=t._writableState;r&&r.autoDestroy||n&&n.autoDestroy?t.destroy(e):t.emit("error",e)}}},610:(t,e,r)=>{"use strict";var n=r(281).q.ERR_STREAM_PREMATURE_CLOSE;function i(){}t.exports=function t(e,r,o){if("function"==typeof r)return t(e,null,r);r||(r={}),o=function(t){var e=!1;return function(){if(!e){e=!0;for(var r=arguments.length,n=new Array(r),i=0;i<r;i++)n[i]=arguments[i];t.apply(this,n)}}}(o||i);var s=r.readable||!1!==r.readable&&e.readable,a=r.writable||!1!==r.writable&&e.writable,u=function(){e.writable||c()},l=e._writableState&&e._writableState.finished,c=function(){a=!1,l=!0,s||o.call(e)},f=e._readableState&&e._readableState.endEmitted,h=function(){s=!1,f=!0,a||o.call(e)},p=function(t){o.call(e,t)},d=function(){var t;return s&&!f?(e._readableState&&e._readableState.ended||(t=new n),o.call(e,t)):a&&!l?(e._writableState&&e._writableState.ended||(t=new n),o.call(e,t)):void 0},y=function(){e.req.on("finish",c)};return function(t){return t.setHeader&&"function"==typeof t.abort}(e)?(e.on("complete",c),e.on("abort",d),e.req?y():e.on("request",y)):a&&!e._writableState&&(e.on("end",u),e.on("close",u)),e.on("end",h),e.on("finish",c),!1!==r.error&&e.on("error",p),e.on("close",d),function(){e.removeListener("complete",c),e.removeListener("abort",d),e.removeListener("request",y),e.req&&e.req.removeListener("finish",c),e.removeListener("end",u),e.removeListener("close",u),e.removeListener("finish",c),e.removeListener("end",h),e.removeListener("error",p),e.removeListener("close",d)}}},167:t=>{t.exports=function(){throw new Error("Readable.from is not available in the browser")}},946:(t,e,r)=>{"use strict";var n,i=r(281).q,o=i.ERR_MISSING_ARGS,s=i.ERR_STREAM_DESTROYED;function a(t){if(t)throw t}function u(t,e,i,o){o=function(t){var e=!1;return function(){e||(e=!0,t.apply(void 0,arguments))}}(o);var a=!1;t.on("close",(function(){a=!0})),void 0===n&&(n=r(610)),n(t,{readable:e,writable:i},(function(t){if(t)return o(t);a=!0,o()}));var u=!1;return function(e){if(!a&&!u)return u=!0,function(t){return t.setHeader&&"function"==typeof t.abort}(t)?t.abort():"function"==typeof t.destroy?t.destroy():void o(e||new s("pipe"))}}function l(t){t()}function c(t,e){return t.pipe(e)}function f(t){return t.length?"function"!=typeof t[t.length-1]?a:t.pop():a}t.exports=function(){for(var t=arguments.length,e=new Array(t),r=0;r<t;r++)e[r]=arguments[r];var n,i=f(e);if(Array.isArray(e[0])&&(e=e[0]),e.length<2)throw new o("streams");var s=e.map((function(t,r){var o=r<e.length-1;return u(t,o,r>0,(function(t){n||(n=t),t&&s.forEach(l),o||(s.forEach(l),i(n))}))}));return e.reduce(c)}},457:(t,e,r)=>{"use strict";var n=r(281).q.ERR_INVALID_OPT_VALUE;t.exports={getHighWaterMark:function(t,e,r,i){var o=function(t,e,r){return null!=t.highWaterMark?t.highWaterMark:e?t[r]:null}(e,i,r);if(null!=o){if(!isFinite(o)||Math.floor(o)!==o||o<0)throw new n(i?r:"highWaterMark",o);return Math.floor(o)}return t.objectMode?16:16384}}},503:(t,e,r)=>{t.exports=r(187).EventEmitter},509:(t,e,r)=>{var n=r(764),i=n.Buffer;function o(t,e){for(var r in t)e[r]=t[r]}function s(t,e,r){return i(t,e,r)}i.from&&i.alloc&&i.allocUnsafe&&i.allocUnsafeSlow?t.exports=n:(o(n,e),e.Buffer=s),s.prototype=Object.create(i.prototype),o(i,s),s.from=function(t,e,r){if("number"==typeof t)throw new TypeError("Argument must not be a number");return i(t,e,r)},s.alloc=function(t,e,r){if("number"!=typeof t)throw new TypeError("Argument must be a number");var n=i(t);return void 0!==e?"string"==typeof r?n.fill(e,r):n.fill(e):n.fill(0),n},s.allocUnsafe=function(t){if("number"!=typeof t)throw new TypeError("Argument must be a number");return i(t)},s.allocUnsafeSlow=function(t){if("number"!=typeof t)throw new TypeError("Argument must be a number");return n.SlowBuffer(t)}},830:(t,e,r)=>{t.exports=i;var n=r(187).EventEmitter;function i(){n.call(this)}r(717)(i,n),i.Readable=r(481),i.Writable=r(229),i.Duplex=r(753),i.Transform=r(605),i.PassThrough=r(725),i.finished=r(610),i.pipeline=r(946),i.Stream=i,i.prototype.pipe=function(t,e){var r=this;function i(e){t.writable&&!1===t.write(e)&&r.pause&&r.pause()}function o(){r.readable&&r.resume&&r.resume()}r.on("data",i),t.on("drain",o),t._isStdio||e&&!1===e.end||(r.on("end",a),r.on("close",u));var s=!1;function a(){s||(s=!0,t.end())}function u(){s||(s=!0,"function"==typeof t.destroy&&t.destroy())}function l(t){if(c(),0===n.listenerCount(this,"error"))throw t}function c(){r.removeListener("data",i),t.removeListener("drain",o),r.removeListener("end",a),r.removeListener("close",u),r.removeListener("error",l),t.removeListener("error",l),r.removeListener("end",c),r.removeListener("close",c),t.removeListener("close",c)}return r.on("error",l),t.on("error",l),r.on("end",c),r.on("close",c),t.on("close",c),t.emit("pipe",r),t}},553:(t,e,r)=>{"use strict";var n=r(509).Buffer,i=n.isEncoding||function(t){switch((t=""+t)&&t.toLowerCase()){case"hex":case"utf8":case"utf-8":case"ascii":case"binary":case"base64":case"ucs2":case"ucs-2":case"utf16le":case"utf-16le":case"raw":return!0;default:return!1}};function o(t){var e;switch(this.encoding=function(t){var e=function(t){if(!t)return"utf8";for(var e;;)switch(t){case"utf8":case"utf-8":return"utf8";case"ucs2":case"ucs-2":case"utf16le":case"utf-16le":return"utf16le";case"latin1":case"binary":return"latin1";case"base64":case"ascii":case"hex":return t;default:if(e)return;t=(""+t).toLowerCase(),e=!0}}(t);if("string"!=typeof e&&(n.isEncoding===i||!i(t)))throw new Error("Unknown encoding: "+t);return e||t}(t),this.encoding){case"utf16le":this.text=u,this.end=l,e=4;break;case"utf8":this.fillLast=a,e=4;break;case"base64":this.text=c,this.end=f,e=3;break;default:return this.write=h,void(this.end=p)}this.lastNeed=0,this.lastTotal=0,this.lastChar=n.allocUnsafe(e)}function s(t){return t<=127?0:t>>5==6?2:t>>4==14?3:t>>3==30?4:t>>6==2?-1:-2}function a(t){var e=this.lastTotal-this.lastNeed,r=function(t,e,r){if(128!=(192&e[0]))return t.lastNeed=0,"�";if(t.lastNeed>1&&e.length>1){if(128!=(192&e[1]))return t.lastNeed=1,"�";if(t.lastNeed>2&&e.length>2&&128!=(192&e[2]))return t.lastNeed=2,"�"}}(this,t);return void 0!==r?r:this.lastNeed<=t.length?(t.copy(this.lastChar,e,0,this.lastNeed),this.lastChar.toString(this.encoding,0,this.lastTotal)):(t.copy(this.lastChar,e,0,t.length),void(this.lastNeed-=t.length))}function u(t,e){if((t.length-e)%2==0){var r=t.toString("utf16le",e);if(r){var n=r.charCodeAt(r.length-1);if(n>=55296&&n<=56319)return this.lastNeed=2,this.lastTotal=4,this.lastChar[0]=t[t.length-2],this.lastChar[1]=t[t.length-1],r.slice(0,-1)}return r}return this.lastNeed=1,this.lastTotal=2,this.lastChar[0]=t[t.length-1],t.toString("utf16le",e,t.length-1)}function l(t){var e=t&&t.length?this.write(t):"";if(this.lastNeed){var r=this.lastTotal-this.lastNeed;return e+this.lastChar.toString("utf16le",0,r)}return e}function c(t,e){var r=(t.length-e)%3;return 0===r?t.toString("base64",e):(this.lastNeed=3-r,this.lastTotal=3,1===r?this.lastChar[0]=t[t.length-1]:(this.lastChar[0]=t[t.length-2],this.lastChar[1]=t[t.length-1]),t.toString("base64",e,t.length-r))}function f(t){var e=t&&t.length?this.write(t):"";return this.lastNeed?e+this.lastChar.toString("base64",0,3-this.lastNeed):e}function h(t){return t.toString(this.encoding)}function p(t){return t&&t.length?this.write(t):""}e.s=o,o.prototype.write=function(t){if(0===t.length)return"";var e,r;if(this.lastNeed){if(void 0===(e=this.fillLast(t)))return"";r=this.lastNeed,this.lastNeed=0}else r=0;return r<t.length?e?e+this.text(t,r):this.text(t,r):e||""},o.prototype.end=function(t){var e=t&&t.length?this.write(t):"";return this.lastNeed?e+"�":e},o.prototype.text=function(t,e){var r=function(t,e,r){var n=e.length-1;if(n<r)return 0;var i=s(e[n]);return i>=0?(i>0&&(t.lastNeed=i-1),i):--n<r||-2===i?0:(i=s(e[n]))>=0?(i>0&&(t.lastNeed=i-2),i):--n<r||-2===i?0:(i=s(e[n]))>=0?(i>0&&(2===i?i=0:t.lastNeed=i-3),i):0}(this,t,e);if(!this.lastNeed)return t.toString("utf8",e);this.lastTotal=r;var n=t.length-(r-this.lastNeed);return t.copy(this.lastChar,0,n),t.toString("utf8",e,n)},o.prototype.fillLast=function(t){if(this.lastNeed<=t.length)return t.copy(this.lastChar,this.lastTotal-this.lastNeed,0,this.lastNeed),this.lastChar.toString(this.encoding,0,this.lastTotal);t.copy(this.lastChar,this.lastTotal-this.lastNeed,0,t.length),this.lastNeed-=t.length}},927:(t,e,r)=>{function n(t){try{if(!r.g.localStorage)return!1}catch(t){return!1}var e=r.g.localStorage[t];return null!=e&&"true"===String(e).toLowerCase()}t.exports=function(t,e){if(n("noDeprecation"))return t;var r=!1;return function(){if(!r){if(n("throwDeprecation"))throw new Error(e);n("traceDeprecation")?console.trace(e):console.warn(e),r=!0}return t.apply(this,arguments)}}},669:t=>{"use strict";t.exports=e},937:e=>{"use strict";if(void 0===t){var r=new Error("Cannot find module 'undefined'");throw r.code="MODULE_NOT_FOUND",r}e.exports=t}},n={};function i(t){var e=n[t];if(void 0!==e)return e.exports;var o=n[t]={exports:{}};return r[t].call(o.exports,o,o.exports,i),o.exports}i.d=(t,e)=>{for(var r in e)i.o(e,r)&&!i.o(t,r)&&Object.defineProperty(t,r,{enumerable:!0,get:e[r]})},i.g=function(){if("object"==typeof globalThis)return globalThis;try{return this||new Function("return this")()}catch(t){if("object"==typeof window)return window}}(),i.o=(t,e)=>Object.prototype.hasOwnProperty.call(t,e),i.r=t=>{"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(t,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(t,"__esModule",{value:!0})};var o={};return(()=>{"use strict";i.r(o),i.d(o,{BigNumber:()=>t.BigNumber,Commented:()=>t.Commented,Decoder:()=>t.Decoder,Diagnose:()=>t.Diagnose,Encoder:()=>t.Encoder,Map:()=>t.Map,Simple:()=>t.Simple,Tagged:()=>t.Tagged,comment:()=>t.UI,decode:()=>t.Jx,decodeAll:()=>t.fI,decodeAllSync:()=>t.cc,decodeFirst:()=>t.h8,decodeFirstSync:()=>t.$u,diagnose:()=>t.M,encode:()=>t.cv,encodeAsync:()=>t.WR,encodeCanonical:()=>t.N2,encodeOne:()=>t.TG,hasBigInt:()=>t.vc,leveldb:()=>t.ww});var t=i(141)})(),o})()}));
},{"bignumber.js":22,"util":19}],22:[function(require,module,exports){
;(function (globalObject) {
  'use strict';

/*
 *      bignumber.js v9.0.1
 *      A JavaScript library for arbitrary-precision arithmetic.
 *      https://github.com/MikeMcl/bignumber.js
 *      Copyright (c) 2020 Michael Mclaughlin <M8ch88l@gmail.com>
 *      MIT Licensed.
 *
 *      BigNumber.prototype methods     |  BigNumber methods
 *                                      |
 *      absoluteValue            abs    |  clone
 *      comparedTo                      |  config               set
 *      decimalPlaces            dp     |      DECIMAL_PLACES
 *      dividedBy                div    |      ROUNDING_MODE
 *      dividedToIntegerBy       idiv   |      EXPONENTIAL_AT
 *      exponentiatedBy          pow    |      RANGE
 *      integerValue                    |      CRYPTO
 *      isEqualTo                eq     |      MODULO_MODE
 *      isFinite                        |      POW_PRECISION
 *      isGreaterThan            gt     |      FORMAT
 *      isGreaterThanOrEqualTo   gte    |      ALPHABET
 *      isInteger                       |  isBigNumber
 *      isLessThan               lt     |  maximum              max
 *      isLessThanOrEqualTo      lte    |  minimum              min
 *      isNaN                           |  random
 *      isNegative                      |  sum
 *      isPositive                      |
 *      isZero                          |
 *      minus                           |
 *      modulo                   mod    |
 *      multipliedBy             times  |
 *      negated                         |
 *      plus                            |
 *      precision                sd     |
 *      shiftedBy                       |
 *      squareRoot               sqrt   |
 *      toExponential                   |
 *      toFixed                         |
 *      toFormat                        |
 *      toFraction                      |
 *      toJSON                          |
 *      toNumber                        |
 *      toPrecision                     |
 *      toString                        |
 *      valueOf                         |
 *
 */


  var BigNumber,
    isNumeric = /^-?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?$/i,
    mathceil = Math.ceil,
    mathfloor = Math.floor,

    bignumberError = '[BigNumber Error] ',
    tooManyDigits = bignumberError + 'Number primitive has more than 15 significant digits: ',

    BASE = 1e14,
    LOG_BASE = 14,
    MAX_SAFE_INTEGER = 0x1fffffffffffff,         // 2^53 - 1
    // MAX_INT32 = 0x7fffffff,                   // 2^31 - 1
    POWS_TEN = [1, 10, 100, 1e3, 1e4, 1e5, 1e6, 1e7, 1e8, 1e9, 1e10, 1e11, 1e12, 1e13],
    SQRT_BASE = 1e7,

    // EDITABLE
    // The limit on the value of DECIMAL_PLACES, TO_EXP_NEG, TO_EXP_POS, MIN_EXP, MAX_EXP, and
    // the arguments to toExponential, toFixed, toFormat, and toPrecision.
    MAX = 1E9;                                   // 0 to MAX_INT32


  /*
   * Create and return a BigNumber constructor.
   */
  function clone(configObject) {
    var div, convertBase, parseNumeric,
      P = BigNumber.prototype = { constructor: BigNumber, toString: null, valueOf: null },
      ONE = new BigNumber(1),


      //----------------------------- EDITABLE CONFIG DEFAULTS -------------------------------


      // The default values below must be integers within the inclusive ranges stated.
      // The values can also be changed at run-time using BigNumber.set.

      // The maximum number of decimal places for operations involving division.
      DECIMAL_PLACES = 20,                     // 0 to MAX

      // The rounding mode used when rounding to the above decimal places, and when using
      // toExponential, toFixed, toFormat and toPrecision, and round (default value).
      // UP         0 Away from zero.
      // DOWN       1 Towards zero.
      // CEIL       2 Towards +Infinity.
      // FLOOR      3 Towards -Infinity.
      // HALF_UP    4 Towards nearest neighbour. If equidistant, up.
      // HALF_DOWN  5 Towards nearest neighbour. If equidistant, down.
      // HALF_EVEN  6 Towards nearest neighbour. If equidistant, towards even neighbour.
      // HALF_CEIL  7 Towards nearest neighbour. If equidistant, towards +Infinity.
      // HALF_FLOOR 8 Towards nearest neighbour. If equidistant, towards -Infinity.
      ROUNDING_MODE = 4,                       // 0 to 8

      // EXPONENTIAL_AT : [TO_EXP_NEG , TO_EXP_POS]

      // The exponent value at and beneath which toString returns exponential notation.
      // Number type: -7
      TO_EXP_NEG = -7,                         // 0 to -MAX

      // The exponent value at and above which toString returns exponential notation.
      // Number type: 21
      TO_EXP_POS = 21,                         // 0 to MAX

      // RANGE : [MIN_EXP, MAX_EXP]

      // The minimum exponent value, beneath which underflow to zero occurs.
      // Number type: -324  (5e-324)
      MIN_EXP = -1e7,                          // -1 to -MAX

      // The maximum exponent value, above which overflow to Infinity occurs.
      // Number type:  308  (1.7976931348623157e+308)
      // For MAX_EXP > 1e7, e.g. new BigNumber('1e100000000').plus(1) may be slow.
      MAX_EXP = 1e7,                           // 1 to MAX

      // Whether to use cryptographically-secure random number generation, if available.
      CRYPTO = false,                          // true or false

      // The modulo mode used when calculating the modulus: a mod n.
      // The quotient (q = a / n) is calculated according to the corresponding rounding mode.
      // The remainder (r) is calculated as: r = a - n * q.
      //
      // UP        0 The remainder is positive if the dividend is negative, else is negative.
      // DOWN      1 The remainder has the same sign as the dividend.
      //             This modulo mode is commonly known as 'truncated division' and is
      //             equivalent to (a % n) in JavaScript.
      // FLOOR     3 The remainder has the same sign as the divisor (Python %).
      // HALF_EVEN 6 This modulo mode implements the IEEE 754 remainder function.
      // EUCLID    9 Euclidian division. q = sign(n) * floor(a / abs(n)).
      //             The remainder is always positive.
      //
      // The truncated division, floored division, Euclidian division and IEEE 754 remainder
      // modes are commonly used for the modulus operation.
      // Although the other rounding modes can also be used, they may not give useful results.
      MODULO_MODE = 1,                         // 0 to 9

      // The maximum number of significant digits of the result of the exponentiatedBy operation.
      // If POW_PRECISION is 0, there will be unlimited significant digits.
      POW_PRECISION = 0,                    // 0 to MAX

      // The format specification used by the BigNumber.prototype.toFormat method.
      FORMAT = {
        prefix: '',
        groupSize: 3,
        secondaryGroupSize: 0,
        groupSeparator: ',',
        decimalSeparator: '.',
        fractionGroupSize: 0,
        fractionGroupSeparator: '\xA0',      // non-breaking space
        suffix: ''
      },

      // The alphabet used for base conversion. It must be at least 2 characters long, with no '+',
      // '-', '.', whitespace, or repeated character.
      // '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ$_'
      ALPHABET = '0123456789abcdefghijklmnopqrstuvwxyz';


    //------------------------------------------------------------------------------------------


    // CONSTRUCTOR


    /*
     * The BigNumber constructor and exported function.
     * Create and return a new instance of a BigNumber object.
     *
     * v {number|string|BigNumber} A numeric value.
     * [b] {number} The base of v. Integer, 2 to ALPHABET.length inclusive.
     */
    function BigNumber(v, b) {
      var alphabet, c, caseChanged, e, i, isNum, len, str,
        x = this;

      // Enable constructor call without `new`.
      if (!(x instanceof BigNumber)) return new BigNumber(v, b);

      if (b == null) {

        if (v && v._isBigNumber === true) {
          x.s = v.s;

          if (!v.c || v.e > MAX_EXP) {
            x.c = x.e = null;
          } else if (v.e < MIN_EXP) {
            x.c = [x.e = 0];
          } else {
            x.e = v.e;
            x.c = v.c.slice();
          }

          return;
        }

        if ((isNum = typeof v == 'number') && v * 0 == 0) {

          // Use `1 / n` to handle minus zero also.
          x.s = 1 / v < 0 ? (v = -v, -1) : 1;

          // Fast path for integers, where n < 2147483648 (2**31).
          if (v === ~~v) {
            for (e = 0, i = v; i >= 10; i /= 10, e++);

            if (e > MAX_EXP) {
              x.c = x.e = null;
            } else {
              x.e = e;
              x.c = [v];
            }

            return;
          }

          str = String(v);
        } else {

          if (!isNumeric.test(str = String(v))) return parseNumeric(x, str, isNum);

          x.s = str.charCodeAt(0) == 45 ? (str = str.slice(1), -1) : 1;
        }

        // Decimal point?
        if ((e = str.indexOf('.')) > -1) str = str.replace('.', '');

        // Exponential form?
        if ((i = str.search(/e/i)) > 0) {

          // Determine exponent.
          if (e < 0) e = i;
          e += +str.slice(i + 1);
          str = str.substring(0, i);
        } else if (e < 0) {

          // Integer.
          e = str.length;
        }

      } else {

        // '[BigNumber Error] Base {not a primitive number|not an integer|out of range}: {b}'
        intCheck(b, 2, ALPHABET.length, 'Base');

        // Allow exponential notation to be used with base 10 argument, while
        // also rounding to DECIMAL_PLACES as with other bases.
        if (b == 10) {
          x = new BigNumber(v);
          return round(x, DECIMAL_PLACES + x.e + 1, ROUNDING_MODE);
        }

        str = String(v);

        if (isNum = typeof v == 'number') {

          // Avoid potential interpretation of Infinity and NaN as base 44+ values.
          if (v * 0 != 0) return parseNumeric(x, str, isNum, b);

          x.s = 1 / v < 0 ? (str = str.slice(1), -1) : 1;

          // '[BigNumber Error] Number primitive has more than 15 significant digits: {n}'
          if (BigNumber.DEBUG && str.replace(/^0\.0*|\./, '').length > 15) {
            throw Error
             (tooManyDigits + v);
          }
        } else {
          x.s = str.charCodeAt(0) === 45 ? (str = str.slice(1), -1) : 1;
        }

        alphabet = ALPHABET.slice(0, b);
        e = i = 0;

        // Check that str is a valid base b number.
        // Don't use RegExp, so alphabet can contain special characters.
        for (len = str.length; i < len; i++) {
          if (alphabet.indexOf(c = str.charAt(i)) < 0) {
            if (c == '.') {

              // If '.' is not the first character and it has not be found before.
              if (i > e) {
                e = len;
                continue;
              }
            } else if (!caseChanged) {

              // Allow e.g. hexadecimal 'FF' as well as 'ff'.
              if (str == str.toUpperCase() && (str = str.toLowerCase()) ||
                  str == str.toLowerCase() && (str = str.toUpperCase())) {
                caseChanged = true;
                i = -1;
                e = 0;
                continue;
              }
            }

            return parseNumeric(x, String(v), isNum, b);
          }
        }

        // Prevent later check for length on converted number.
        isNum = false;
        str = convertBase(str, b, 10, x.s);

        // Decimal point?
        if ((e = str.indexOf('.')) > -1) str = str.replace('.', '');
        else e = str.length;
      }

      // Determine leading zeros.
      for (i = 0; str.charCodeAt(i) === 48; i++);

      // Determine trailing zeros.
      for (len = str.length; str.charCodeAt(--len) === 48;);

      if (str = str.slice(i, ++len)) {
        len -= i;

        // '[BigNumber Error] Number primitive has more than 15 significant digits: {n}'
        if (isNum && BigNumber.DEBUG &&
          len > 15 && (v > MAX_SAFE_INTEGER || v !== mathfloor(v))) {
            throw Error
             (tooManyDigits + (x.s * v));
        }

         // Overflow?
        if ((e = e - i - 1) > MAX_EXP) {

          // Infinity.
          x.c = x.e = null;

        // Underflow?
        } else if (e < MIN_EXP) {

          // Zero.
          x.c = [x.e = 0];
        } else {
          x.e = e;
          x.c = [];

          // Transform base

          // e is the base 10 exponent.
          // i is where to slice str to get the first element of the coefficient array.
          i = (e + 1) % LOG_BASE;
          if (e < 0) i += LOG_BASE;  // i < 1

          if (i < len) {
            if (i) x.c.push(+str.slice(0, i));

            for (len -= LOG_BASE; i < len;) {
              x.c.push(+str.slice(i, i += LOG_BASE));
            }

            i = LOG_BASE - (str = str.slice(i)).length;
          } else {
            i -= len;
          }

          for (; i--; str += '0');
          x.c.push(+str);
        }
      } else {

        // Zero.
        x.c = [x.e = 0];
      }
    }


    // CONSTRUCTOR PROPERTIES


    BigNumber.clone = clone;

    BigNumber.ROUND_UP = 0;
    BigNumber.ROUND_DOWN = 1;
    BigNumber.ROUND_CEIL = 2;
    BigNumber.ROUND_FLOOR = 3;
    BigNumber.ROUND_HALF_UP = 4;
    BigNumber.ROUND_HALF_DOWN = 5;
    BigNumber.ROUND_HALF_EVEN = 6;
    BigNumber.ROUND_HALF_CEIL = 7;
    BigNumber.ROUND_HALF_FLOOR = 8;
    BigNumber.EUCLID = 9;


    /*
     * Configure infrequently-changing library-wide settings.
     *
     * Accept an object with the following optional properties (if the value of a property is
     * a number, it must be an integer within the inclusive range stated):
     *
     *   DECIMAL_PLACES   {number}           0 to MAX
     *   ROUNDING_MODE    {number}           0 to 8
     *   EXPONENTIAL_AT   {number|number[]}  -MAX to MAX  or  [-MAX to 0, 0 to MAX]
     *   RANGE            {number|number[]}  -MAX to MAX (not zero)  or  [-MAX to -1, 1 to MAX]
     *   CRYPTO           {boolean}          true or false
     *   MODULO_MODE      {number}           0 to 9
     *   POW_PRECISION       {number}           0 to MAX
     *   ALPHABET         {string}           A string of two or more unique characters which does
     *                                       not contain '.'.
     *   FORMAT           {object}           An object with some of the following properties:
     *     prefix                 {string}
     *     groupSize              {number}
     *     secondaryGroupSize     {number}
     *     groupSeparator         {string}
     *     decimalSeparator       {string}
     *     fractionGroupSize      {number}
     *     fractionGroupSeparator {string}
     *     suffix                 {string}
     *
     * (The values assigned to the above FORMAT object properties are not checked for validity.)
     *
     * E.g.
     * BigNumber.config({ DECIMAL_PLACES : 20, ROUNDING_MODE : 4 })
     *
     * Ignore properties/parameters set to null or undefined, except for ALPHABET.
     *
     * Return an object with the properties current values.
     */
    BigNumber.config = BigNumber.set = function (obj) {
      var p, v;

      if (obj != null) {

        if (typeof obj == 'object') {

          // DECIMAL_PLACES {number} Integer, 0 to MAX inclusive.
          // '[BigNumber Error] DECIMAL_PLACES {not a primitive number|not an integer|out of range}: {v}'
          if (obj.hasOwnProperty(p = 'DECIMAL_PLACES')) {
            v = obj[p];
            intCheck(v, 0, MAX, p);
            DECIMAL_PLACES = v;
          }

          // ROUNDING_MODE {number} Integer, 0 to 8 inclusive.
          // '[BigNumber Error] ROUNDING_MODE {not a primitive number|not an integer|out of range}: {v}'
          if (obj.hasOwnProperty(p = 'ROUNDING_MODE')) {
            v = obj[p];
            intCheck(v, 0, 8, p);
            ROUNDING_MODE = v;
          }

          // EXPONENTIAL_AT {number|number[]}
          // Integer, -MAX to MAX inclusive or
          // [integer -MAX to 0 inclusive, 0 to MAX inclusive].
          // '[BigNumber Error] EXPONENTIAL_AT {not a primitive number|not an integer|out of range}: {v}'
          if (obj.hasOwnProperty(p = 'EXPONENTIAL_AT')) {
            v = obj[p];
            if (v && v.pop) {
              intCheck(v[0], -MAX, 0, p);
              intCheck(v[1], 0, MAX, p);
              TO_EXP_NEG = v[0];
              TO_EXP_POS = v[1];
            } else {
              intCheck(v, -MAX, MAX, p);
              TO_EXP_NEG = -(TO_EXP_POS = v < 0 ? -v : v);
            }
          }

          // RANGE {number|number[]} Non-zero integer, -MAX to MAX inclusive or
          // [integer -MAX to -1 inclusive, integer 1 to MAX inclusive].
          // '[BigNumber Error] RANGE {not a primitive number|not an integer|out of range|cannot be zero}: {v}'
          if (obj.hasOwnProperty(p = 'RANGE')) {
            v = obj[p];
            if (v && v.pop) {
              intCheck(v[0], -MAX, -1, p);
              intCheck(v[1], 1, MAX, p);
              MIN_EXP = v[0];
              MAX_EXP = v[1];
            } else {
              intCheck(v, -MAX, MAX, p);
              if (v) {
                MIN_EXP = -(MAX_EXP = v < 0 ? -v : v);
              } else {
                throw Error
                 (bignumberError + p + ' cannot be zero: ' + v);
              }
            }
          }

          // CRYPTO {boolean} true or false.
          // '[BigNumber Error] CRYPTO not true or false: {v}'
          // '[BigNumber Error] crypto unavailable'
          if (obj.hasOwnProperty(p = 'CRYPTO')) {
            v = obj[p];
            if (v === !!v) {
              if (v) {
                if (typeof crypto != 'undefined' && crypto &&
                 (crypto.getRandomValues || crypto.randomBytes)) {
                  CRYPTO = v;
                } else {
                  CRYPTO = !v;
                  throw Error
                   (bignumberError + 'crypto unavailable');
                }
              } else {
                CRYPTO = v;
              }
            } else {
              throw Error
               (bignumberError + p + ' not true or false: ' + v);
            }
          }

          // MODULO_MODE {number} Integer, 0 to 9 inclusive.
          // '[BigNumber Error] MODULO_MODE {not a primitive number|not an integer|out of range}: {v}'
          if (obj.hasOwnProperty(p = 'MODULO_MODE')) {
            v = obj[p];
            intCheck(v, 0, 9, p);
            MODULO_MODE = v;
          }

          // POW_PRECISION {number} Integer, 0 to MAX inclusive.
          // '[BigNumber Error] POW_PRECISION {not a primitive number|not an integer|out of range}: {v}'
          if (obj.hasOwnProperty(p = 'POW_PRECISION')) {
            v = obj[p];
            intCheck(v, 0, MAX, p);
            POW_PRECISION = v;
          }

          // FORMAT {object}
          // '[BigNumber Error] FORMAT not an object: {v}'
          if (obj.hasOwnProperty(p = 'FORMAT')) {
            v = obj[p];
            if (typeof v == 'object') FORMAT = v;
            else throw Error
             (bignumberError + p + ' not an object: ' + v);
          }

          // ALPHABET {string}
          // '[BigNumber Error] ALPHABET invalid: {v}'
          if (obj.hasOwnProperty(p = 'ALPHABET')) {
            v = obj[p];

            // Disallow if less than two characters,
            // or if it contains '+', '-', '.', whitespace, or a repeated character.
            if (typeof v == 'string' && !/^.?$|[+\-.\s]|(.).*\1/.test(v)) {
              ALPHABET = v;
            } else {
              throw Error
               (bignumberError + p + ' invalid: ' + v);
            }
          }

        } else {

          // '[BigNumber Error] Object expected: {v}'
          throw Error
           (bignumberError + 'Object expected: ' + obj);
        }
      }

      return {
        DECIMAL_PLACES: DECIMAL_PLACES,
        ROUNDING_MODE: ROUNDING_MODE,
        EXPONENTIAL_AT: [TO_EXP_NEG, TO_EXP_POS],
        RANGE: [MIN_EXP, MAX_EXP],
        CRYPTO: CRYPTO,
        MODULO_MODE: MODULO_MODE,
        POW_PRECISION: POW_PRECISION,
        FORMAT: FORMAT,
        ALPHABET: ALPHABET
      };
    };


    /*
     * Return true if v is a BigNumber instance, otherwise return false.
     *
     * If BigNumber.DEBUG is true, throw if a BigNumber instance is not well-formed.
     *
     * v {any}
     *
     * '[BigNumber Error] Invalid BigNumber: {v}'
     */
    BigNumber.isBigNumber = function (v) {
      if (!v || v._isBigNumber !== true) return false;
      if (!BigNumber.DEBUG) return true;

      var i, n,
        c = v.c,
        e = v.e,
        s = v.s;

      out: if ({}.toString.call(c) == '[object Array]') {

        if ((s === 1 || s === -1) && e >= -MAX && e <= MAX && e === mathfloor(e)) {

          // If the first element is zero, the BigNumber value must be zero.
          if (c[0] === 0) {
            if (e === 0 && c.length === 1) return true;
            break out;
          }

          // Calculate number of digits that c[0] should have, based on the exponent.
          i = (e + 1) % LOG_BASE;
          if (i < 1) i += LOG_BASE;

          // Calculate number of digits of c[0].
          //if (Math.ceil(Math.log(c[0] + 1) / Math.LN10) == i) {
          if (String(c[0]).length == i) {

            for (i = 0; i < c.length; i++) {
              n = c[i];
              if (n < 0 || n >= BASE || n !== mathfloor(n)) break out;
            }

            // Last element cannot be zero, unless it is the only element.
            if (n !== 0) return true;
          }
        }

      // Infinity/NaN
      } else if (c === null && e === null && (s === null || s === 1 || s === -1)) {
        return true;
      }

      throw Error
        (bignumberError + 'Invalid BigNumber: ' + v);
    };


    /*
     * Return a new BigNumber whose value is the maximum of the arguments.
     *
     * arguments {number|string|BigNumber}
     */
    BigNumber.maximum = BigNumber.max = function () {
      return maxOrMin(arguments, P.lt);
    };


    /*
     * Return a new BigNumber whose value is the minimum of the arguments.
     *
     * arguments {number|string|BigNumber}
     */
    BigNumber.minimum = BigNumber.min = function () {
      return maxOrMin(arguments, P.gt);
    };


    /*
     * Return a new BigNumber with a random value equal to or greater than 0 and less than 1,
     * and with dp, or DECIMAL_PLACES if dp is omitted, decimal places (or less if trailing
     * zeros are produced).
     *
     * [dp] {number} Decimal places. Integer, 0 to MAX inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {dp}'
     * '[BigNumber Error] crypto unavailable'
     */
    BigNumber.random = (function () {
      var pow2_53 = 0x20000000000000;

      // Return a 53 bit integer n, where 0 <= n < 9007199254740992.
      // Check if Math.random() produces more than 32 bits of randomness.
      // If it does, assume at least 53 bits are produced, otherwise assume at least 30 bits.
      // 0x40000000 is 2^30, 0x800000 is 2^23, 0x1fffff is 2^21 - 1.
      var random53bitInt = (Math.random() * pow2_53) & 0x1fffff
       ? function () { return mathfloor(Math.random() * pow2_53); }
       : function () { return ((Math.random() * 0x40000000 | 0) * 0x800000) +
         (Math.random() * 0x800000 | 0); };

      return function (dp) {
        var a, b, e, k, v,
          i = 0,
          c = [],
          rand = new BigNumber(ONE);

        if (dp == null) dp = DECIMAL_PLACES;
        else intCheck(dp, 0, MAX);

        k = mathceil(dp / LOG_BASE);

        if (CRYPTO) {

          // Browsers supporting crypto.getRandomValues.
          if (crypto.getRandomValues) {

            a = crypto.getRandomValues(new Uint32Array(k *= 2));

            for (; i < k;) {

              // 53 bits:
              // ((Math.pow(2, 32) - 1) * Math.pow(2, 21)).toString(2)
              // 11111 11111111 11111111 11111111 11100000 00000000 00000000
              // ((Math.pow(2, 32) - 1) >>> 11).toString(2)
              //                                     11111 11111111 11111111
              // 0x20000 is 2^21.
              v = a[i] * 0x20000 + (a[i + 1] >>> 11);

              // Rejection sampling:
              // 0 <= v < 9007199254740992
              // Probability that v >= 9e15, is
              // 7199254740992 / 9007199254740992 ~= 0.0008, i.e. 1 in 1251
              if (v >= 9e15) {
                b = crypto.getRandomValues(new Uint32Array(2));
                a[i] = b[0];
                a[i + 1] = b[1];
              } else {

                // 0 <= v <= 8999999999999999
                // 0 <= (v % 1e14) <= 99999999999999
                c.push(v % 1e14);
                i += 2;
              }
            }
            i = k / 2;

          // Node.js supporting crypto.randomBytes.
          } else if (crypto.randomBytes) {

            // buffer
            a = crypto.randomBytes(k *= 7);

            for (; i < k;) {

              // 0x1000000000000 is 2^48, 0x10000000000 is 2^40
              // 0x100000000 is 2^32, 0x1000000 is 2^24
              // 11111 11111111 11111111 11111111 11111111 11111111 11111111
              // 0 <= v < 9007199254740992
              v = ((a[i] & 31) * 0x1000000000000) + (a[i + 1] * 0x10000000000) +
                 (a[i + 2] * 0x100000000) + (a[i + 3] * 0x1000000) +
                 (a[i + 4] << 16) + (a[i + 5] << 8) + a[i + 6];

              if (v >= 9e15) {
                crypto.randomBytes(7).copy(a, i);
              } else {

                // 0 <= (v % 1e14) <= 99999999999999
                c.push(v % 1e14);
                i += 7;
              }
            }
            i = k / 7;
          } else {
            CRYPTO = false;
            throw Error
             (bignumberError + 'crypto unavailable');
          }
        }

        // Use Math.random.
        if (!CRYPTO) {

          for (; i < k;) {
            v = random53bitInt();
            if (v < 9e15) c[i++] = v % 1e14;
          }
        }

        k = c[--i];
        dp %= LOG_BASE;

        // Convert trailing digits to zeros according to dp.
        if (k && dp) {
          v = POWS_TEN[LOG_BASE - dp];
          c[i] = mathfloor(k / v) * v;
        }

        // Remove trailing elements which are zero.
        for (; c[i] === 0; c.pop(), i--);

        // Zero?
        if (i < 0) {
          c = [e = 0];
        } else {

          // Remove leading elements which are zero and adjust exponent accordingly.
          for (e = -1 ; c[0] === 0; c.splice(0, 1), e -= LOG_BASE);

          // Count the digits of the first element of c to determine leading zeros, and...
          for (i = 1, v = c[0]; v >= 10; v /= 10, i++);

          // adjust the exponent accordingly.
          if (i < LOG_BASE) e -= LOG_BASE - i;
        }

        rand.e = e;
        rand.c = c;
        return rand;
      };
    })();


    /*
     * Return a BigNumber whose value is the sum of the arguments.
     *
     * arguments {number|string|BigNumber}
     */
    BigNumber.sum = function () {
      var i = 1,
        args = arguments,
        sum = new BigNumber(args[0]);
      for (; i < args.length;) sum = sum.plus(args[i++]);
      return sum;
    };


    // PRIVATE FUNCTIONS


    // Called by BigNumber and BigNumber.prototype.toString.
    convertBase = (function () {
      var decimal = '0123456789';

      /*
       * Convert string of baseIn to an array of numbers of baseOut.
       * Eg. toBaseOut('255', 10, 16) returns [15, 15].
       * Eg. toBaseOut('ff', 16, 10) returns [2, 5, 5].
       */
      function toBaseOut(str, baseIn, baseOut, alphabet) {
        var j,
          arr = [0],
          arrL,
          i = 0,
          len = str.length;

        for (; i < len;) {
          for (arrL = arr.length; arrL--; arr[arrL] *= baseIn);

          arr[0] += alphabet.indexOf(str.charAt(i++));

          for (j = 0; j < arr.length; j++) {

            if (arr[j] > baseOut - 1) {
              if (arr[j + 1] == null) arr[j + 1] = 0;
              arr[j + 1] += arr[j] / baseOut | 0;
              arr[j] %= baseOut;
            }
          }
        }

        return arr.reverse();
      }

      // Convert a numeric string of baseIn to a numeric string of baseOut.
      // If the caller is toString, we are converting from base 10 to baseOut.
      // If the caller is BigNumber, we are converting from baseIn to base 10.
      return function (str, baseIn, baseOut, sign, callerIsToString) {
        var alphabet, d, e, k, r, x, xc, y,
          i = str.indexOf('.'),
          dp = DECIMAL_PLACES,
          rm = ROUNDING_MODE;

        // Non-integer.
        if (i >= 0) {
          k = POW_PRECISION;

          // Unlimited precision.
          POW_PRECISION = 0;
          str = str.replace('.', '');
          y = new BigNumber(baseIn);
          x = y.pow(str.length - i);
          POW_PRECISION = k;

          // Convert str as if an integer, then restore the fraction part by dividing the
          // result by its base raised to a power.

          y.c = toBaseOut(toFixedPoint(coeffToString(x.c), x.e, '0'),
           10, baseOut, decimal);
          y.e = y.c.length;
        }

        // Convert the number as integer.

        xc = toBaseOut(str, baseIn, baseOut, callerIsToString
         ? (alphabet = ALPHABET, decimal)
         : (alphabet = decimal, ALPHABET));

        // xc now represents str as an integer and converted to baseOut. e is the exponent.
        e = k = xc.length;

        // Remove trailing zeros.
        for (; xc[--k] == 0; xc.pop());

        // Zero?
        if (!xc[0]) return alphabet.charAt(0);

        // Does str represent an integer? If so, no need for the division.
        if (i < 0) {
          --e;
        } else {
          x.c = xc;
          x.e = e;

          // The sign is needed for correct rounding.
          x.s = sign;
          x = div(x, y, dp, rm, baseOut);
          xc = x.c;
          r = x.r;
          e = x.e;
        }

        // xc now represents str converted to baseOut.

        // THe index of the rounding digit.
        d = e + dp + 1;

        // The rounding digit: the digit to the right of the digit that may be rounded up.
        i = xc[d];

        // Look at the rounding digits and mode to determine whether to round up.

        k = baseOut / 2;
        r = r || d < 0 || xc[d + 1] != null;

        r = rm < 4 ? (i != null || r) && (rm == 0 || rm == (x.s < 0 ? 3 : 2))
              : i > k || i == k &&(rm == 4 || r || rm == 6 && xc[d - 1] & 1 ||
               rm == (x.s < 0 ? 8 : 7));

        // If the index of the rounding digit is not greater than zero, or xc represents
        // zero, then the result of the base conversion is zero or, if rounding up, a value
        // such as 0.00001.
        if (d < 1 || !xc[0]) {

          // 1^-dp or 0
          str = r ? toFixedPoint(alphabet.charAt(1), -dp, alphabet.charAt(0)) : alphabet.charAt(0);
        } else {

          // Truncate xc to the required number of decimal places.
          xc.length = d;

          // Round up?
          if (r) {

            // Rounding up may mean the previous digit has to be rounded up and so on.
            for (--baseOut; ++xc[--d] > baseOut;) {
              xc[d] = 0;

              if (!d) {
                ++e;
                xc = [1].concat(xc);
              }
            }
          }

          // Determine trailing zeros.
          for (k = xc.length; !xc[--k];);

          // E.g. [4, 11, 15] becomes 4bf.
          for (i = 0, str = ''; i <= k; str += alphabet.charAt(xc[i++]));

          // Add leading zeros, decimal point and trailing zeros as required.
          str = toFixedPoint(str, e, alphabet.charAt(0));
        }

        // The caller will add the sign.
        return str;
      };
    })();


    // Perform division in the specified base. Called by div and convertBase.
    div = (function () {

      // Assume non-zero x and k.
      function multiply(x, k, base) {
        var m, temp, xlo, xhi,
          carry = 0,
          i = x.length,
          klo = k % SQRT_BASE,
          khi = k / SQRT_BASE | 0;

        for (x = x.slice(); i--;) {
          xlo = x[i] % SQRT_BASE;
          xhi = x[i] / SQRT_BASE | 0;
          m = khi * xlo + xhi * klo;
          temp = klo * xlo + ((m % SQRT_BASE) * SQRT_BASE) + carry;
          carry = (temp / base | 0) + (m / SQRT_BASE | 0) + khi * xhi;
          x[i] = temp % base;
        }

        if (carry) x = [carry].concat(x);

        return x;
      }

      function compare(a, b, aL, bL) {
        var i, cmp;

        if (aL != bL) {
          cmp = aL > bL ? 1 : -1;
        } else {

          for (i = cmp = 0; i < aL; i++) {

            if (a[i] != b[i]) {
              cmp = a[i] > b[i] ? 1 : -1;
              break;
            }
          }
        }

        return cmp;
      }

      function subtract(a, b, aL, base) {
        var i = 0;

        // Subtract b from a.
        for (; aL--;) {
          a[aL] -= i;
          i = a[aL] < b[aL] ? 1 : 0;
          a[aL] = i * base + a[aL] - b[aL];
        }

        // Remove leading zeros.
        for (; !a[0] && a.length > 1; a.splice(0, 1));
      }

      // x: dividend, y: divisor.
      return function (x, y, dp, rm, base) {
        var cmp, e, i, more, n, prod, prodL, q, qc, rem, remL, rem0, xi, xL, yc0,
          yL, yz,
          s = x.s == y.s ? 1 : -1,
          xc = x.c,
          yc = y.c;

        // Either NaN, Infinity or 0?
        if (!xc || !xc[0] || !yc || !yc[0]) {

          return new BigNumber(

           // Return NaN if either NaN, or both Infinity or 0.
           !x.s || !y.s || (xc ? yc && xc[0] == yc[0] : !yc) ? NaN :

            // Return ±0 if x is ±0 or y is ±Infinity, or return ±Infinity as y is ±0.
            xc && xc[0] == 0 || !yc ? s * 0 : s / 0
         );
        }

        q = new BigNumber(s);
        qc = q.c = [];
        e = x.e - y.e;
        s = dp + e + 1;

        if (!base) {
          base = BASE;
          e = bitFloor(x.e / LOG_BASE) - bitFloor(y.e / LOG_BASE);
          s = s / LOG_BASE | 0;
        }

        // Result exponent may be one less then the current value of e.
        // The coefficients of the BigNumbers from convertBase may have trailing zeros.
        for (i = 0; yc[i] == (xc[i] || 0); i++);

        if (yc[i] > (xc[i] || 0)) e--;

        if (s < 0) {
          qc.push(1);
          more = true;
        } else {
          xL = xc.length;
          yL = yc.length;
          i = 0;
          s += 2;

          // Normalise xc and yc so highest order digit of yc is >= base / 2.

          n = mathfloor(base / (yc[0] + 1));

          // Not necessary, but to handle odd bases where yc[0] == (base / 2) - 1.
          // if (n > 1 || n++ == 1 && yc[0] < base / 2) {
          if (n > 1) {
            yc = multiply(yc, n, base);
            xc = multiply(xc, n, base);
            yL = yc.length;
            xL = xc.length;
          }

          xi = yL;
          rem = xc.slice(0, yL);
          remL = rem.length;

          // Add zeros to make remainder as long as divisor.
          for (; remL < yL; rem[remL++] = 0);
          yz = yc.slice();
          yz = [0].concat(yz);
          yc0 = yc[0];
          if (yc[1] >= base / 2) yc0++;
          // Not necessary, but to prevent trial digit n > base, when using base 3.
          // else if (base == 3 && yc0 == 1) yc0 = 1 + 1e-15;

          do {
            n = 0;

            // Compare divisor and remainder.
            cmp = compare(yc, rem, yL, remL);

            // If divisor < remainder.
            if (cmp < 0) {

              // Calculate trial digit, n.

              rem0 = rem[0];
              if (yL != remL) rem0 = rem0 * base + (rem[1] || 0);

              // n is how many times the divisor goes into the current remainder.
              n = mathfloor(rem0 / yc0);

              //  Algorithm:
              //  product = divisor multiplied by trial digit (n).
              //  Compare product and remainder.
              //  If product is greater than remainder:
              //    Subtract divisor from product, decrement trial digit.
              //  Subtract product from remainder.
              //  If product was less than remainder at the last compare:
              //    Compare new remainder and divisor.
              //    If remainder is greater than divisor:
              //      Subtract divisor from remainder, increment trial digit.

              if (n > 1) {

                // n may be > base only when base is 3.
                if (n >= base) n = base - 1;

                // product = divisor * trial digit.
                prod = multiply(yc, n, base);
                prodL = prod.length;
                remL = rem.length;

                // Compare product and remainder.
                // If product > remainder then trial digit n too high.
                // n is 1 too high about 5% of the time, and is not known to have
                // ever been more than 1 too high.
                while (compare(prod, rem, prodL, remL) == 1) {
                  n--;

                  // Subtract divisor from product.
                  subtract(prod, yL < prodL ? yz : yc, prodL, base);
                  prodL = prod.length;
                  cmp = 1;
                }
              } else {

                // n is 0 or 1, cmp is -1.
                // If n is 0, there is no need to compare yc and rem again below,
                // so change cmp to 1 to avoid it.
                // If n is 1, leave cmp as -1, so yc and rem are compared again.
                if (n == 0) {

                  // divisor < remainder, so n must be at least 1.
                  cmp = n = 1;
                }

                // product = divisor
                prod = yc.slice();
                prodL = prod.length;
              }

              if (prodL < remL) prod = [0].concat(prod);

              // Subtract product from remainder.
              subtract(rem, prod, remL, base);
              remL = rem.length;

               // If product was < remainder.
              if (cmp == -1) {

                // Compare divisor and new remainder.
                // If divisor < new remainder, subtract divisor from remainder.
                // Trial digit n too low.
                // n is 1 too low about 5% of the time, and very rarely 2 too low.
                while (compare(yc, rem, yL, remL) < 1) {
                  n++;

                  // Subtract divisor from remainder.
                  subtract(rem, yL < remL ? yz : yc, remL, base);
                  remL = rem.length;
                }
              }
            } else if (cmp === 0) {
              n++;
              rem = [0];
            } // else cmp === 1 and n will be 0

            // Add the next digit, n, to the result array.
            qc[i++] = n;

            // Update the remainder.
            if (rem[0]) {
              rem[remL++] = xc[xi] || 0;
            } else {
              rem = [xc[xi]];
              remL = 1;
            }
          } while ((xi++ < xL || rem[0] != null) && s--);

          more = rem[0] != null;

          // Leading zero?
          if (!qc[0]) qc.splice(0, 1);
        }

        if (base == BASE) {

          // To calculate q.e, first get the number of digits of qc[0].
          for (i = 1, s = qc[0]; s >= 10; s /= 10, i++);

          round(q, dp + (q.e = i + e * LOG_BASE - 1) + 1, rm, more);

        // Caller is convertBase.
        } else {
          q.e = e;
          q.r = +more;
        }

        return q;
      };
    })();


    /*
     * Return a string representing the value of BigNumber n in fixed-point or exponential
     * notation rounded to the specified decimal places or significant digits.
     *
     * n: a BigNumber.
     * i: the index of the last digit required (i.e. the digit that may be rounded up).
     * rm: the rounding mode.
     * id: 1 (toExponential) or 2 (toPrecision).
     */
    function format(n, i, rm, id) {
      var c0, e, ne, len, str;

      if (rm == null) rm = ROUNDING_MODE;
      else intCheck(rm, 0, 8);

      if (!n.c) return n.toString();

      c0 = n.c[0];
      ne = n.e;

      if (i == null) {
        str = coeffToString(n.c);
        str = id == 1 || id == 2 && (ne <= TO_EXP_NEG || ne >= TO_EXP_POS)
         ? toExponential(str, ne)
         : toFixedPoint(str, ne, '0');
      } else {
        n = round(new BigNumber(n), i, rm);

        // n.e may have changed if the value was rounded up.
        e = n.e;

        str = coeffToString(n.c);
        len = str.length;

        // toPrecision returns exponential notation if the number of significant digits
        // specified is less than the number of digits necessary to represent the integer
        // part of the value in fixed-point notation.

        // Exponential notation.
        if (id == 1 || id == 2 && (i <= e || e <= TO_EXP_NEG)) {

          // Append zeros?
          for (; len < i; str += '0', len++);
          str = toExponential(str, e);

        // Fixed-point notation.
        } else {
          i -= ne;
          str = toFixedPoint(str, e, '0');

          // Append zeros?
          if (e + 1 > len) {
            if (--i > 0) for (str += '.'; i--; str += '0');
          } else {
            i += e - len;
            if (i > 0) {
              if (e + 1 == len) str += '.';
              for (; i--; str += '0');
            }
          }
        }
      }

      return n.s < 0 && c0 ? '-' + str : str;
    }


    // Handle BigNumber.max and BigNumber.min.
    function maxOrMin(args, method) {
      var n,
        i = 1,
        m = new BigNumber(args[0]);

      for (; i < args.length; i++) {
        n = new BigNumber(args[i]);

        // If any number is NaN, return NaN.
        if (!n.s) {
          m = n;
          break;
        } else if (method.call(m, n)) {
          m = n;
        }
      }

      return m;
    }


    /*
     * Strip trailing zeros, calculate base 10 exponent and check against MIN_EXP and MAX_EXP.
     * Called by minus, plus and times.
     */
    function normalise(n, c, e) {
      var i = 1,
        j = c.length;

       // Remove trailing zeros.
      for (; !c[--j]; c.pop());

      // Calculate the base 10 exponent. First get the number of digits of c[0].
      for (j = c[0]; j >= 10; j /= 10, i++);

      // Overflow?
      if ((e = i + e * LOG_BASE - 1) > MAX_EXP) {

        // Infinity.
        n.c = n.e = null;

      // Underflow?
      } else if (e < MIN_EXP) {

        // Zero.
        n.c = [n.e = 0];
      } else {
        n.e = e;
        n.c = c;
      }

      return n;
    }


    // Handle values that fail the validity test in BigNumber.
    parseNumeric = (function () {
      var basePrefix = /^(-?)0([xbo])(?=\w[\w.]*$)/i,
        dotAfter = /^([^.]+)\.$/,
        dotBefore = /^\.([^.]+)$/,
        isInfinityOrNaN = /^-?(Infinity|NaN)$/,
        whitespaceOrPlus = /^\s*\+(?=[\w.])|^\s+|\s+$/g;

      return function (x, str, isNum, b) {
        var base,
          s = isNum ? str : str.replace(whitespaceOrPlus, '');

        // No exception on ±Infinity or NaN.
        if (isInfinityOrNaN.test(s)) {
          x.s = isNaN(s) ? null : s < 0 ? -1 : 1;
        } else {
          if (!isNum) {

            // basePrefix = /^(-?)0([xbo])(?=\w[\w.]*$)/i
            s = s.replace(basePrefix, function (m, p1, p2) {
              base = (p2 = p2.toLowerCase()) == 'x' ? 16 : p2 == 'b' ? 2 : 8;
              return !b || b == base ? p1 : m;
            });

            if (b) {
              base = b;

              // E.g. '1.' to '1', '.1' to '0.1'
              s = s.replace(dotAfter, '$1').replace(dotBefore, '0.$1');
            }

            if (str != s) return new BigNumber(s, base);
          }

          // '[BigNumber Error] Not a number: {n}'
          // '[BigNumber Error] Not a base {b} number: {n}'
          if (BigNumber.DEBUG) {
            throw Error
              (bignumberError + 'Not a' + (b ? ' base ' + b : '') + ' number: ' + str);
          }

          // NaN
          x.s = null;
        }

        x.c = x.e = null;
      }
    })();


    /*
     * Round x to sd significant digits using rounding mode rm. Check for over/under-flow.
     * If r is truthy, it is known that there are more digits after the rounding digit.
     */
    function round(x, sd, rm, r) {
      var d, i, j, k, n, ni, rd,
        xc = x.c,
        pows10 = POWS_TEN;

      // if x is not Infinity or NaN...
      if (xc) {

        // rd is the rounding digit, i.e. the digit after the digit that may be rounded up.
        // n is a base 1e14 number, the value of the element of array x.c containing rd.
        // ni is the index of n within x.c.
        // d is the number of digits of n.
        // i is the index of rd within n including leading zeros.
        // j is the actual index of rd within n (if < 0, rd is a leading zero).
        out: {

          // Get the number of digits of the first element of xc.
          for (d = 1, k = xc[0]; k >= 10; k /= 10, d++);
          i = sd - d;

          // If the rounding digit is in the first element of xc...
          if (i < 0) {
            i += LOG_BASE;
            j = sd;
            n = xc[ni = 0];

            // Get the rounding digit at index j of n.
            rd = n / pows10[d - j - 1] % 10 | 0;
          } else {
            ni = mathceil((i + 1) / LOG_BASE);

            if (ni >= xc.length) {

              if (r) {

                // Needed by sqrt.
                for (; xc.length <= ni; xc.push(0));
                n = rd = 0;
                d = 1;
                i %= LOG_BASE;
                j = i - LOG_BASE + 1;
              } else {
                break out;
              }
            } else {
              n = k = xc[ni];

              // Get the number of digits of n.
              for (d = 1; k >= 10; k /= 10, d++);

              // Get the index of rd within n.
              i %= LOG_BASE;

              // Get the index of rd within n, adjusted for leading zeros.
              // The number of leading zeros of n is given by LOG_BASE - d.
              j = i - LOG_BASE + d;

              // Get the rounding digit at index j of n.
              rd = j < 0 ? 0 : n / pows10[d - j - 1] % 10 | 0;
            }
          }

          r = r || sd < 0 ||

          // Are there any non-zero digits after the rounding digit?
          // The expression  n % pows10[d - j - 1]  returns all digits of n to the right
          // of the digit at j, e.g. if n is 908714 and j is 2, the expression gives 714.
           xc[ni + 1] != null || (j < 0 ? n : n % pows10[d - j - 1]);

          r = rm < 4
           ? (rd || r) && (rm == 0 || rm == (x.s < 0 ? 3 : 2))
           : rd > 5 || rd == 5 && (rm == 4 || r || rm == 6 &&

            // Check whether the digit to the left of the rounding digit is odd.
            ((i > 0 ? j > 0 ? n / pows10[d - j] : 0 : xc[ni - 1]) % 10) & 1 ||
             rm == (x.s < 0 ? 8 : 7));

          if (sd < 1 || !xc[0]) {
            xc.length = 0;

            if (r) {

              // Convert sd to decimal places.
              sd -= x.e + 1;

              // 1, 0.1, 0.01, 0.001, 0.0001 etc.
              xc[0] = pows10[(LOG_BASE - sd % LOG_BASE) % LOG_BASE];
              x.e = -sd || 0;
            } else {

              // Zero.
              xc[0] = x.e = 0;
            }

            return x;
          }

          // Remove excess digits.
          if (i == 0) {
            xc.length = ni;
            k = 1;
            ni--;
          } else {
            xc.length = ni + 1;
            k = pows10[LOG_BASE - i];

            // E.g. 56700 becomes 56000 if 7 is the rounding digit.
            // j > 0 means i > number of leading zeros of n.
            xc[ni] = j > 0 ? mathfloor(n / pows10[d - j] % pows10[j]) * k : 0;
          }

          // Round up?
          if (r) {

            for (; ;) {

              // If the digit to be rounded up is in the first element of xc...
              if (ni == 0) {

                // i will be the length of xc[0] before k is added.
                for (i = 1, j = xc[0]; j >= 10; j /= 10, i++);
                j = xc[0] += k;
                for (k = 1; j >= 10; j /= 10, k++);

                // if i != k the length has increased.
                if (i != k) {
                  x.e++;
                  if (xc[0] == BASE) xc[0] = 1;
                }

                break;
              } else {
                xc[ni] += k;
                if (xc[ni] != BASE) break;
                xc[ni--] = 0;
                k = 1;
              }
            }
          }

          // Remove trailing zeros.
          for (i = xc.length; xc[--i] === 0; xc.pop());
        }

        // Overflow? Infinity.
        if (x.e > MAX_EXP) {
          x.c = x.e = null;

        // Underflow? Zero.
        } else if (x.e < MIN_EXP) {
          x.c = [x.e = 0];
        }
      }

      return x;
    }


    function valueOf(n) {
      var str,
        e = n.e;

      if (e === null) return n.toString();

      str = coeffToString(n.c);

      str = e <= TO_EXP_NEG || e >= TO_EXP_POS
        ? toExponential(str, e)
        : toFixedPoint(str, e, '0');

      return n.s < 0 ? '-' + str : str;
    }


    // PROTOTYPE/INSTANCE METHODS


    /*
     * Return a new BigNumber whose value is the absolute value of this BigNumber.
     */
    P.absoluteValue = P.abs = function () {
      var x = new BigNumber(this);
      if (x.s < 0) x.s = 1;
      return x;
    };


    /*
     * Return
     *   1 if the value of this BigNumber is greater than the value of BigNumber(y, b),
     *   -1 if the value of this BigNumber is less than the value of BigNumber(y, b),
     *   0 if they have the same value,
     *   or null if the value of either is NaN.
     */
    P.comparedTo = function (y, b) {
      return compare(this, new BigNumber(y, b));
    };


    /*
     * If dp is undefined or null or true or false, return the number of decimal places of the
     * value of this BigNumber, or null if the value of this BigNumber is ±Infinity or NaN.
     *
     * Otherwise, if dp is a number, return a new BigNumber whose value is the value of this
     * BigNumber rounded to a maximum of dp decimal places using rounding mode rm, or
     * ROUNDING_MODE if rm is omitted.
     *
     * [dp] {number} Decimal places: integer, 0 to MAX inclusive.
     * [rm] {number} Rounding mode. Integer, 0 to 8 inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {dp|rm}'
     */
    P.decimalPlaces = P.dp = function (dp, rm) {
      var c, n, v,
        x = this;

      if (dp != null) {
        intCheck(dp, 0, MAX);
        if (rm == null) rm = ROUNDING_MODE;
        else intCheck(rm, 0, 8);

        return round(new BigNumber(x), dp + x.e + 1, rm);
      }

      if (!(c = x.c)) return null;
      n = ((v = c.length - 1) - bitFloor(this.e / LOG_BASE)) * LOG_BASE;

      // Subtract the number of trailing zeros of the last number.
      if (v = c[v]) for (; v % 10 == 0; v /= 10, n--);
      if (n < 0) n = 0;

      return n;
    };


    /*
     *  n / 0 = I
     *  n / N = N
     *  n / I = 0
     *  0 / n = 0
     *  0 / 0 = N
     *  0 / N = N
     *  0 / I = 0
     *  N / n = N
     *  N / 0 = N
     *  N / N = N
     *  N / I = N
     *  I / n = I
     *  I / 0 = I
     *  I / N = N
     *  I / I = N
     *
     * Return a new BigNumber whose value is the value of this BigNumber divided by the value of
     * BigNumber(y, b), rounded according to DECIMAL_PLACES and ROUNDING_MODE.
     */
    P.dividedBy = P.div = function (y, b) {
      return div(this, new BigNumber(y, b), DECIMAL_PLACES, ROUNDING_MODE);
    };


    /*
     * Return a new BigNumber whose value is the integer part of dividing the value of this
     * BigNumber by the value of BigNumber(y, b).
     */
    P.dividedToIntegerBy = P.idiv = function (y, b) {
      return div(this, new BigNumber(y, b), 0, 1);
    };


    /*
     * Return a BigNumber whose value is the value of this BigNumber exponentiated by n.
     *
     * If m is present, return the result modulo m.
     * If n is negative round according to DECIMAL_PLACES and ROUNDING_MODE.
     * If POW_PRECISION is non-zero and m is not present, round to POW_PRECISION using ROUNDING_MODE.
     *
     * The modular power operation works efficiently when x, n, and m are integers, otherwise it
     * is equivalent to calculating x.exponentiatedBy(n).modulo(m) with a POW_PRECISION of 0.
     *
     * n {number|string|BigNumber} The exponent. An integer.
     * [m] {number|string|BigNumber} The modulus.
     *
     * '[BigNumber Error] Exponent not an integer: {n}'
     */
    P.exponentiatedBy = P.pow = function (n, m) {
      var half, isModExp, i, k, more, nIsBig, nIsNeg, nIsOdd, y,
        x = this;

      n = new BigNumber(n);

      // Allow NaN and ±Infinity, but not other non-integers.
      if (n.c && !n.isInteger()) {
        throw Error
          (bignumberError + 'Exponent not an integer: ' + valueOf(n));
      }

      if (m != null) m = new BigNumber(m);

      // Exponent of MAX_SAFE_INTEGER is 15.
      nIsBig = n.e > 14;

      // If x is NaN, ±Infinity, ±0 or ±1, or n is ±Infinity, NaN or ±0.
      if (!x.c || !x.c[0] || x.c[0] == 1 && !x.e && x.c.length == 1 || !n.c || !n.c[0]) {

        // The sign of the result of pow when x is negative depends on the evenness of n.
        // If +n overflows to ±Infinity, the evenness of n would be not be known.
        y = new BigNumber(Math.pow(+valueOf(x), nIsBig ? 2 - isOdd(n) : +valueOf(n)));
        return m ? y.mod(m) : y;
      }

      nIsNeg = n.s < 0;

      if (m) {

        // x % m returns NaN if abs(m) is zero, or m is NaN.
        if (m.c ? !m.c[0] : !m.s) return new BigNumber(NaN);

        isModExp = !nIsNeg && x.isInteger() && m.isInteger();

        if (isModExp) x = x.mod(m);

      // Overflow to ±Infinity: >=2**1e10 or >=1.0000024**1e15.
      // Underflow to ±0: <=0.79**1e10 or <=0.9999975**1e15.
      } else if (n.e > 9 && (x.e > 0 || x.e < -1 || (x.e == 0
        // [1, 240000000]
        ? x.c[0] > 1 || nIsBig && x.c[1] >= 24e7
        // [80000000000000]  [99999750000000]
        : x.c[0] < 8e13 || nIsBig && x.c[0] <= 9999975e7))) {

        // If x is negative and n is odd, k = -0, else k = 0.
        k = x.s < 0 && isOdd(n) ? -0 : 0;

        // If x >= 1, k = ±Infinity.
        if (x.e > -1) k = 1 / k;

        // If n is negative return ±0, else return ±Infinity.
        return new BigNumber(nIsNeg ? 1 / k : k);

      } else if (POW_PRECISION) {

        // Truncating each coefficient array to a length of k after each multiplication
        // equates to truncating significant digits to POW_PRECISION + [28, 41],
        // i.e. there will be a minimum of 28 guard digits retained.
        k = mathceil(POW_PRECISION / LOG_BASE + 2);
      }

      if (nIsBig) {
        half = new BigNumber(0.5);
        if (nIsNeg) n.s = 1;
        nIsOdd = isOdd(n);
      } else {
        i = Math.abs(+valueOf(n));
        nIsOdd = i % 2;
      }

      y = new BigNumber(ONE);

      // Performs 54 loop iterations for n of 9007199254740991.
      for (; ;) {

        if (nIsOdd) {
          y = y.times(x);
          if (!y.c) break;

          if (k) {
            if (y.c.length > k) y.c.length = k;
          } else if (isModExp) {
            y = y.mod(m);    //y = y.minus(div(y, m, 0, MODULO_MODE).times(m));
          }
        }

        if (i) {
          i = mathfloor(i / 2);
          if (i === 0) break;
          nIsOdd = i % 2;
        } else {
          n = n.times(half);
          round(n, n.e + 1, 1);

          if (n.e > 14) {
            nIsOdd = isOdd(n);
          } else {
            i = +valueOf(n);
            if (i === 0) break;
            nIsOdd = i % 2;
          }
        }

        x = x.times(x);

        if (k) {
          if (x.c && x.c.length > k) x.c.length = k;
        } else if (isModExp) {
          x = x.mod(m);    //x = x.minus(div(x, m, 0, MODULO_MODE).times(m));
        }
      }

      if (isModExp) return y;
      if (nIsNeg) y = ONE.div(y);

      return m ? y.mod(m) : k ? round(y, POW_PRECISION, ROUNDING_MODE, more) : y;
    };


    /*
     * Return a new BigNumber whose value is the value of this BigNumber rounded to an integer
     * using rounding mode rm, or ROUNDING_MODE if rm is omitted.
     *
     * [rm] {number} Rounding mode. Integer, 0 to 8 inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {rm}'
     */
    P.integerValue = function (rm) {
      var n = new BigNumber(this);
      if (rm == null) rm = ROUNDING_MODE;
      else intCheck(rm, 0, 8);
      return round(n, n.e + 1, rm);
    };


    /*
     * Return true if the value of this BigNumber is equal to the value of BigNumber(y, b),
     * otherwise return false.
     */
    P.isEqualTo = P.eq = function (y, b) {
      return compare(this, new BigNumber(y, b)) === 0;
    };


    /*
     * Return true if the value of this BigNumber is a finite number, otherwise return false.
     */
    P.isFinite = function () {
      return !!this.c;
    };


    /*
     * Return true if the value of this BigNumber is greater than the value of BigNumber(y, b),
     * otherwise return false.
     */
    P.isGreaterThan = P.gt = function (y, b) {
      return compare(this, new BigNumber(y, b)) > 0;
    };


    /*
     * Return true if the value of this BigNumber is greater than or equal to the value of
     * BigNumber(y, b), otherwise return false.
     */
    P.isGreaterThanOrEqualTo = P.gte = function (y, b) {
      return (b = compare(this, new BigNumber(y, b))) === 1 || b === 0;

    };


    /*
     * Return true if the value of this BigNumber is an integer, otherwise return false.
     */
    P.isInteger = function () {
      return !!this.c && bitFloor(this.e / LOG_BASE) > this.c.length - 2;
    };


    /*
     * Return true if the value of this BigNumber is less than the value of BigNumber(y, b),
     * otherwise return false.
     */
    P.isLessThan = P.lt = function (y, b) {
      return compare(this, new BigNumber(y, b)) < 0;
    };


    /*
     * Return true if the value of this BigNumber is less than or equal to the value of
     * BigNumber(y, b), otherwise return false.
     */
    P.isLessThanOrEqualTo = P.lte = function (y, b) {
      return (b = compare(this, new BigNumber(y, b))) === -1 || b === 0;
    };


    /*
     * Return true if the value of this BigNumber is NaN, otherwise return false.
     */
    P.isNaN = function () {
      return !this.s;
    };


    /*
     * Return true if the value of this BigNumber is negative, otherwise return false.
     */
    P.isNegative = function () {
      return this.s < 0;
    };


    /*
     * Return true if the value of this BigNumber is positive, otherwise return false.
     */
    P.isPositive = function () {
      return this.s > 0;
    };


    /*
     * Return true if the value of this BigNumber is 0 or -0, otherwise return false.
     */
    P.isZero = function () {
      return !!this.c && this.c[0] == 0;
    };


    /*
     *  n - 0 = n
     *  n - N = N
     *  n - I = -I
     *  0 - n = -n
     *  0 - 0 = 0
     *  0 - N = N
     *  0 - I = -I
     *  N - n = N
     *  N - 0 = N
     *  N - N = N
     *  N - I = N
     *  I - n = I
     *  I - 0 = I
     *  I - N = N
     *  I - I = N
     *
     * Return a new BigNumber whose value is the value of this BigNumber minus the value of
     * BigNumber(y, b).
     */
    P.minus = function (y, b) {
      var i, j, t, xLTy,
        x = this,
        a = x.s;

      y = new BigNumber(y, b);
      b = y.s;

      // Either NaN?
      if (!a || !b) return new BigNumber(NaN);

      // Signs differ?
      if (a != b) {
        y.s = -b;
        return x.plus(y);
      }

      var xe = x.e / LOG_BASE,
        ye = y.e / LOG_BASE,
        xc = x.c,
        yc = y.c;

      if (!xe || !ye) {

        // Either Infinity?
        if (!xc || !yc) return xc ? (y.s = -b, y) : new BigNumber(yc ? x : NaN);

        // Either zero?
        if (!xc[0] || !yc[0]) {

          // Return y if y is non-zero, x if x is non-zero, or zero if both are zero.
          return yc[0] ? (y.s = -b, y) : new BigNumber(xc[0] ? x :

           // IEEE 754 (2008) 6.3: n - n = -0 when rounding to -Infinity
           ROUNDING_MODE == 3 ? -0 : 0);
        }
      }

      xe = bitFloor(xe);
      ye = bitFloor(ye);
      xc = xc.slice();

      // Determine which is the bigger number.
      if (a = xe - ye) {

        if (xLTy = a < 0) {
          a = -a;
          t = xc;
        } else {
          ye = xe;
          t = yc;
        }

        t.reverse();

        // Prepend zeros to equalise exponents.
        for (b = a; b--; t.push(0));
        t.reverse();
      } else {

        // Exponents equal. Check digit by digit.
        j = (xLTy = (a = xc.length) < (b = yc.length)) ? a : b;

        for (a = b = 0; b < j; b++) {

          if (xc[b] != yc[b]) {
            xLTy = xc[b] < yc[b];
            break;
          }
        }
      }

      // x < y? Point xc to the array of the bigger number.
      if (xLTy) t = xc, xc = yc, yc = t, y.s = -y.s;

      b = (j = yc.length) - (i = xc.length);

      // Append zeros to xc if shorter.
      // No need to add zeros to yc if shorter as subtract only needs to start at yc.length.
      if (b > 0) for (; b--; xc[i++] = 0);
      b = BASE - 1;

      // Subtract yc from xc.
      for (; j > a;) {

        if (xc[--j] < yc[j]) {
          for (i = j; i && !xc[--i]; xc[i] = b);
          --xc[i];
          xc[j] += BASE;
        }

        xc[j] -= yc[j];
      }

      // Remove leading zeros and adjust exponent accordingly.
      for (; xc[0] == 0; xc.splice(0, 1), --ye);

      // Zero?
      if (!xc[0]) {

        // Following IEEE 754 (2008) 6.3,
        // n - n = +0  but  n - n = -0  when rounding towards -Infinity.
        y.s = ROUNDING_MODE == 3 ? -1 : 1;
        y.c = [y.e = 0];
        return y;
      }

      // No need to check for Infinity as +x - +y != Infinity && -x - -y != Infinity
      // for finite x and y.
      return normalise(y, xc, ye);
    };


    /*
     *   n % 0 =  N
     *   n % N =  N
     *   n % I =  n
     *   0 % n =  0
     *  -0 % n = -0
     *   0 % 0 =  N
     *   0 % N =  N
     *   0 % I =  0
     *   N % n =  N
     *   N % 0 =  N
     *   N % N =  N
     *   N % I =  N
     *   I % n =  N
     *   I % 0 =  N
     *   I % N =  N
     *   I % I =  N
     *
     * Return a new BigNumber whose value is the value of this BigNumber modulo the value of
     * BigNumber(y, b). The result depends on the value of MODULO_MODE.
     */
    P.modulo = P.mod = function (y, b) {
      var q, s,
        x = this;

      y = new BigNumber(y, b);

      // Return NaN if x is Infinity or NaN, or y is NaN or zero.
      if (!x.c || !y.s || y.c && !y.c[0]) {
        return new BigNumber(NaN);

      // Return x if y is Infinity or x is zero.
      } else if (!y.c || x.c && !x.c[0]) {
        return new BigNumber(x);
      }

      if (MODULO_MODE == 9) {

        // Euclidian division: q = sign(y) * floor(x / abs(y))
        // r = x - qy    where  0 <= r < abs(y)
        s = y.s;
        y.s = 1;
        q = div(x, y, 0, 3);
        y.s = s;
        q.s *= s;
      } else {
        q = div(x, y, 0, MODULO_MODE);
      }

      y = x.minus(q.times(y));

      // To match JavaScript %, ensure sign of zero is sign of dividend.
      if (!y.c[0] && MODULO_MODE == 1) y.s = x.s;

      return y;
    };


    /*
     *  n * 0 = 0
     *  n * N = N
     *  n * I = I
     *  0 * n = 0
     *  0 * 0 = 0
     *  0 * N = N
     *  0 * I = N
     *  N * n = N
     *  N * 0 = N
     *  N * N = N
     *  N * I = N
     *  I * n = I
     *  I * 0 = N
     *  I * N = N
     *  I * I = I
     *
     * Return a new BigNumber whose value is the value of this BigNumber multiplied by the value
     * of BigNumber(y, b).
     */
    P.multipliedBy = P.times = function (y, b) {
      var c, e, i, j, k, m, xcL, xlo, xhi, ycL, ylo, yhi, zc,
        base, sqrtBase,
        x = this,
        xc = x.c,
        yc = (y = new BigNumber(y, b)).c;

      // Either NaN, ±Infinity or ±0?
      if (!xc || !yc || !xc[0] || !yc[0]) {

        // Return NaN if either is NaN, or one is 0 and the other is Infinity.
        if (!x.s || !y.s || xc && !xc[0] && !yc || yc && !yc[0] && !xc) {
          y.c = y.e = y.s = null;
        } else {
          y.s *= x.s;

          // Return ±Infinity if either is ±Infinity.
          if (!xc || !yc) {
            y.c = y.e = null;

          // Return ±0 if either is ±0.
          } else {
            y.c = [0];
            y.e = 0;
          }
        }

        return y;
      }

      e = bitFloor(x.e / LOG_BASE) + bitFloor(y.e / LOG_BASE);
      y.s *= x.s;
      xcL = xc.length;
      ycL = yc.length;

      // Ensure xc points to longer array and xcL to its length.
      if (xcL < ycL) zc = xc, xc = yc, yc = zc, i = xcL, xcL = ycL, ycL = i;

      // Initialise the result array with zeros.
      for (i = xcL + ycL, zc = []; i--; zc.push(0));

      base = BASE;
      sqrtBase = SQRT_BASE;

      for (i = ycL; --i >= 0;) {
        c = 0;
        ylo = yc[i] % sqrtBase;
        yhi = yc[i] / sqrtBase | 0;

        for (k = xcL, j = i + k; j > i;) {
          xlo = xc[--k] % sqrtBase;
          xhi = xc[k] / sqrtBase | 0;
          m = yhi * xlo + xhi * ylo;
          xlo = ylo * xlo + ((m % sqrtBase) * sqrtBase) + zc[j] + c;
          c = (xlo / base | 0) + (m / sqrtBase | 0) + yhi * xhi;
          zc[j--] = xlo % base;
        }

        zc[j] = c;
      }

      if (c) {
        ++e;
      } else {
        zc.splice(0, 1);
      }

      return normalise(y, zc, e);
    };


    /*
     * Return a new BigNumber whose value is the value of this BigNumber negated,
     * i.e. multiplied by -1.
     */
    P.negated = function () {
      var x = new BigNumber(this);
      x.s = -x.s || null;
      return x;
    };


    /*
     *  n + 0 = n
     *  n + N = N
     *  n + I = I
     *  0 + n = n
     *  0 + 0 = 0
     *  0 + N = N
     *  0 + I = I
     *  N + n = N
     *  N + 0 = N
     *  N + N = N
     *  N + I = N
     *  I + n = I
     *  I + 0 = I
     *  I + N = N
     *  I + I = I
     *
     * Return a new BigNumber whose value is the value of this BigNumber plus the value of
     * BigNumber(y, b).
     */
    P.plus = function (y, b) {
      var t,
        x = this,
        a = x.s;

      y = new BigNumber(y, b);
      b = y.s;

      // Either NaN?
      if (!a || !b) return new BigNumber(NaN);

      // Signs differ?
       if (a != b) {
        y.s = -b;
        return x.minus(y);
      }

      var xe = x.e / LOG_BASE,
        ye = y.e / LOG_BASE,
        xc = x.c,
        yc = y.c;

      if (!xe || !ye) {

        // Return ±Infinity if either ±Infinity.
        if (!xc || !yc) return new BigNumber(a / 0);

        // Either zero?
        // Return y if y is non-zero, x if x is non-zero, or zero if both are zero.
        if (!xc[0] || !yc[0]) return yc[0] ? y : new BigNumber(xc[0] ? x : a * 0);
      }

      xe = bitFloor(xe);
      ye = bitFloor(ye);
      xc = xc.slice();

      // Prepend zeros to equalise exponents. Faster to use reverse then do unshifts.
      if (a = xe - ye) {
        if (a > 0) {
          ye = xe;
          t = yc;
        } else {
          a = -a;
          t = xc;
        }

        t.reverse();
        for (; a--; t.push(0));
        t.reverse();
      }

      a = xc.length;
      b = yc.length;

      // Point xc to the longer array, and b to the shorter length.
      if (a - b < 0) t = yc, yc = xc, xc = t, b = a;

      // Only start adding at yc.length - 1 as the further digits of xc can be ignored.
      for (a = 0; b;) {
        a = (xc[--b] = xc[b] + yc[b] + a) / BASE | 0;
        xc[b] = BASE === xc[b] ? 0 : xc[b] % BASE;
      }

      if (a) {
        xc = [a].concat(xc);
        ++ye;
      }

      // No need to check for zero, as +x + +y != 0 && -x + -y != 0
      // ye = MAX_EXP + 1 possible
      return normalise(y, xc, ye);
    };


    /*
     * If sd is undefined or null or true or false, return the number of significant digits of
     * the value of this BigNumber, or null if the value of this BigNumber is ±Infinity or NaN.
     * If sd is true include integer-part trailing zeros in the count.
     *
     * Otherwise, if sd is a number, return a new BigNumber whose value is the value of this
     * BigNumber rounded to a maximum of sd significant digits using rounding mode rm, or
     * ROUNDING_MODE if rm is omitted.
     *
     * sd {number|boolean} number: significant digits: integer, 1 to MAX inclusive.
     *                     boolean: whether to count integer-part trailing zeros: true or false.
     * [rm] {number} Rounding mode. Integer, 0 to 8 inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {sd|rm}'
     */
    P.precision = P.sd = function (sd, rm) {
      var c, n, v,
        x = this;

      if (sd != null && sd !== !!sd) {
        intCheck(sd, 1, MAX);
        if (rm == null) rm = ROUNDING_MODE;
        else intCheck(rm, 0, 8);

        return round(new BigNumber(x), sd, rm);
      }

      if (!(c = x.c)) return null;
      v = c.length - 1;
      n = v * LOG_BASE + 1;

      if (v = c[v]) {

        // Subtract the number of trailing zeros of the last element.
        for (; v % 10 == 0; v /= 10, n--);

        // Add the number of digits of the first element.
        for (v = c[0]; v >= 10; v /= 10, n++);
      }

      if (sd && x.e + 1 > n) n = x.e + 1;

      return n;
    };


    /*
     * Return a new BigNumber whose value is the value of this BigNumber shifted by k places
     * (powers of 10). Shift to the right if n > 0, and to the left if n < 0.
     *
     * k {number} Integer, -MAX_SAFE_INTEGER to MAX_SAFE_INTEGER inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {k}'
     */
    P.shiftedBy = function (k) {
      intCheck(k, -MAX_SAFE_INTEGER, MAX_SAFE_INTEGER);
      return this.times('1e' + k);
    };


    /*
     *  sqrt(-n) =  N
     *  sqrt(N) =  N
     *  sqrt(-I) =  N
     *  sqrt(I) =  I
     *  sqrt(0) =  0
     *  sqrt(-0) = -0
     *
     * Return a new BigNumber whose value is the square root of the value of this BigNumber,
     * rounded according to DECIMAL_PLACES and ROUNDING_MODE.
     */
    P.squareRoot = P.sqrt = function () {
      var m, n, r, rep, t,
        x = this,
        c = x.c,
        s = x.s,
        e = x.e,
        dp = DECIMAL_PLACES + 4,
        half = new BigNumber('0.5');

      // Negative/NaN/Infinity/zero?
      if (s !== 1 || !c || !c[0]) {
        return new BigNumber(!s || s < 0 && (!c || c[0]) ? NaN : c ? x : 1 / 0);
      }

      // Initial estimate.
      s = Math.sqrt(+valueOf(x));

      // Math.sqrt underflow/overflow?
      // Pass x to Math.sqrt as integer, then adjust the exponent of the result.
      if (s == 0 || s == 1 / 0) {
        n = coeffToString(c);
        if ((n.length + e) % 2 == 0) n += '0';
        s = Math.sqrt(+n);
        e = bitFloor((e + 1) / 2) - (e < 0 || e % 2);

        if (s == 1 / 0) {
          n = '5e' + e;
        } else {
          n = s.toExponential();
          n = n.slice(0, n.indexOf('e') + 1) + e;
        }

        r = new BigNumber(n);
      } else {
        r = new BigNumber(s + '');
      }

      // Check for zero.
      // r could be zero if MIN_EXP is changed after the this value was created.
      // This would cause a division by zero (x/t) and hence Infinity below, which would cause
      // coeffToString to throw.
      if (r.c[0]) {
        e = r.e;
        s = e + dp;
        if (s < 3) s = 0;

        // Newton-Raphson iteration.
        for (; ;) {
          t = r;
          r = half.times(t.plus(div(x, t, dp, 1)));

          if (coeffToString(t.c).slice(0, s) === (n = coeffToString(r.c)).slice(0, s)) {

            // The exponent of r may here be one less than the final result exponent,
            // e.g 0.0009999 (e-4) --> 0.001 (e-3), so adjust s so the rounding digits
            // are indexed correctly.
            if (r.e < e) --s;
            n = n.slice(s - 3, s + 1);

            // The 4th rounding digit may be in error by -1 so if the 4 rounding digits
            // are 9999 or 4999 (i.e. approaching a rounding boundary) continue the
            // iteration.
            if (n == '9999' || !rep && n == '4999') {

              // On the first iteration only, check to see if rounding up gives the
              // exact result as the nines may infinitely repeat.
              if (!rep) {
                round(t, t.e + DECIMAL_PLACES + 2, 0);

                if (t.times(t).eq(x)) {
                  r = t;
                  break;
                }
              }

              dp += 4;
              s += 4;
              rep = 1;
            } else {

              // If rounding digits are null, 0{0,4} or 50{0,3}, check for exact
              // result. If not, then there are further digits and m will be truthy.
              if (!+n || !+n.slice(1) && n.charAt(0) == '5') {

                // Truncate to the first rounding digit.
                round(r, r.e + DECIMAL_PLACES + 2, 1);
                m = !r.times(r).eq(x);
              }

              break;
            }
          }
        }
      }

      return round(r, r.e + DECIMAL_PLACES + 1, ROUNDING_MODE, m);
    };


    /*
     * Return a string representing the value of this BigNumber in exponential notation and
     * rounded using ROUNDING_MODE to dp fixed decimal places.
     *
     * [dp] {number} Decimal places. Integer, 0 to MAX inclusive.
     * [rm] {number} Rounding mode. Integer, 0 to 8 inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {dp|rm}'
     */
    P.toExponential = function (dp, rm) {
      if (dp != null) {
        intCheck(dp, 0, MAX);
        dp++;
      }
      return format(this, dp, rm, 1);
    };


    /*
     * Return a string representing the value of this BigNumber in fixed-point notation rounding
     * to dp fixed decimal places using rounding mode rm, or ROUNDING_MODE if rm is omitted.
     *
     * Note: as with JavaScript's number type, (-0).toFixed(0) is '0',
     * but e.g. (-0.00001).toFixed(0) is '-0'.
     *
     * [dp] {number} Decimal places. Integer, 0 to MAX inclusive.
     * [rm] {number} Rounding mode. Integer, 0 to 8 inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {dp|rm}'
     */
    P.toFixed = function (dp, rm) {
      if (dp != null) {
        intCheck(dp, 0, MAX);
        dp = dp + this.e + 1;
      }
      return format(this, dp, rm);
    };


    /*
     * Return a string representing the value of this BigNumber in fixed-point notation rounded
     * using rm or ROUNDING_MODE to dp decimal places, and formatted according to the properties
     * of the format or FORMAT object (see BigNumber.set).
     *
     * The formatting object may contain some or all of the properties shown below.
     *
     * FORMAT = {
     *   prefix: '',
     *   groupSize: 3,
     *   secondaryGroupSize: 0,
     *   groupSeparator: ',',
     *   decimalSeparator: '.',
     *   fractionGroupSize: 0,
     *   fractionGroupSeparator: '\xA0',      // non-breaking space
     *   suffix: ''
     * };
     *
     * [dp] {number} Decimal places. Integer, 0 to MAX inclusive.
     * [rm] {number} Rounding mode. Integer, 0 to 8 inclusive.
     * [format] {object} Formatting options. See FORMAT pbject above.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {dp|rm}'
     * '[BigNumber Error] Argument not an object: {format}'
     */
    P.toFormat = function (dp, rm, format) {
      var str,
        x = this;

      if (format == null) {
        if (dp != null && rm && typeof rm == 'object') {
          format = rm;
          rm = null;
        } else if (dp && typeof dp == 'object') {
          format = dp;
          dp = rm = null;
        } else {
          format = FORMAT;
        }
      } else if (typeof format != 'object') {
        throw Error
          (bignumberError + 'Argument not an object: ' + format);
      }

      str = x.toFixed(dp, rm);

      if (x.c) {
        var i,
          arr = str.split('.'),
          g1 = +format.groupSize,
          g2 = +format.secondaryGroupSize,
          groupSeparator = format.groupSeparator || '',
          intPart = arr[0],
          fractionPart = arr[1],
          isNeg = x.s < 0,
          intDigits = isNeg ? intPart.slice(1) : intPart,
          len = intDigits.length;

        if (g2) i = g1, g1 = g2, g2 = i, len -= i;

        if (g1 > 0 && len > 0) {
          i = len % g1 || g1;
          intPart = intDigits.substr(0, i);
          for (; i < len; i += g1) intPart += groupSeparator + intDigits.substr(i, g1);
          if (g2 > 0) intPart += groupSeparator + intDigits.slice(i);
          if (isNeg) intPart = '-' + intPart;
        }

        str = fractionPart
         ? intPart + (format.decimalSeparator || '') + ((g2 = +format.fractionGroupSize)
          ? fractionPart.replace(new RegExp('\\d{' + g2 + '}\\B', 'g'),
           '$&' + (format.fractionGroupSeparator || ''))
          : fractionPart)
         : intPart;
      }

      return (format.prefix || '') + str + (format.suffix || '');
    };


    /*
     * Return an array of two BigNumbers representing the value of this BigNumber as a simple
     * fraction with an integer numerator and an integer denominator.
     * The denominator will be a positive non-zero value less than or equal to the specified
     * maximum denominator. If a maximum denominator is not specified, the denominator will be
     * the lowest value necessary to represent the number exactly.
     *
     * [md] {number|string|BigNumber} Integer >= 1, or Infinity. The maximum denominator.
     *
     * '[BigNumber Error] Argument {not an integer|out of range} : {md}'
     */
    P.toFraction = function (md) {
      var d, d0, d1, d2, e, exp, n, n0, n1, q, r, s,
        x = this,
        xc = x.c;

      if (md != null) {
        n = new BigNumber(md);

        // Throw if md is less than one or is not an integer, unless it is Infinity.
        if (!n.isInteger() && (n.c || n.s !== 1) || n.lt(ONE)) {
          throw Error
            (bignumberError + 'Argument ' +
              (n.isInteger() ? 'out of range: ' : 'not an integer: ') + valueOf(n));
        }
      }

      if (!xc) return new BigNumber(x);

      d = new BigNumber(ONE);
      n1 = d0 = new BigNumber(ONE);
      d1 = n0 = new BigNumber(ONE);
      s = coeffToString(xc);

      // Determine initial denominator.
      // d is a power of 10 and the minimum max denominator that specifies the value exactly.
      e = d.e = s.length - x.e - 1;
      d.c[0] = POWS_TEN[(exp = e % LOG_BASE) < 0 ? LOG_BASE + exp : exp];
      md = !md || n.comparedTo(d) > 0 ? (e > 0 ? d : n1) : n;

      exp = MAX_EXP;
      MAX_EXP = 1 / 0;
      n = new BigNumber(s);

      // n0 = d1 = 0
      n0.c[0] = 0;

      for (; ;)  {
        q = div(n, d, 0, 1);
        d2 = d0.plus(q.times(d1));
        if (d2.comparedTo(md) == 1) break;
        d0 = d1;
        d1 = d2;
        n1 = n0.plus(q.times(d2 = n1));
        n0 = d2;
        d = n.minus(q.times(d2 = d));
        n = d2;
      }

      d2 = div(md.minus(d0), d1, 0, 1);
      n0 = n0.plus(d2.times(n1));
      d0 = d0.plus(d2.times(d1));
      n0.s = n1.s = x.s;
      e = e * 2;

      // Determine which fraction is closer to x, n0/d0 or n1/d1
      r = div(n1, d1, e, ROUNDING_MODE).minus(x).abs().comparedTo(
          div(n0, d0, e, ROUNDING_MODE).minus(x).abs()) < 1 ? [n1, d1] : [n0, d0];

      MAX_EXP = exp;

      return r;
    };


    /*
     * Return the value of this BigNumber converted to a number primitive.
     */
    P.toNumber = function () {
      return +valueOf(this);
    };


    /*
     * Return a string representing the value of this BigNumber rounded to sd significant digits
     * using rounding mode rm or ROUNDING_MODE. If sd is less than the number of digits
     * necessary to represent the integer part of the value in fixed-point notation, then use
     * exponential notation.
     *
     * [sd] {number} Significant digits. Integer, 1 to MAX inclusive.
     * [rm] {number} Rounding mode. Integer, 0 to 8 inclusive.
     *
     * '[BigNumber Error] Argument {not a primitive number|not an integer|out of range}: {sd|rm}'
     */
    P.toPrecision = function (sd, rm) {
      if (sd != null) intCheck(sd, 1, MAX);
      return format(this, sd, rm, 2);
    };


    /*
     * Return a string representing the value of this BigNumber in base b, or base 10 if b is
     * omitted. If a base is specified, including base 10, round according to DECIMAL_PLACES and
     * ROUNDING_MODE. If a base is not specified, and this BigNumber has a positive exponent
     * that is equal to or greater than TO_EXP_POS, or a negative exponent equal to or less than
     * TO_EXP_NEG, return exponential notation.
     *
     * [b] {number} Integer, 2 to ALPHABET.length inclusive.
     *
     * '[BigNumber Error] Base {not a primitive number|not an integer|out of range}: {b}'
     */
    P.toString = function (b) {
      var str,
        n = this,
        s = n.s,
        e = n.e;

      // Infinity or NaN?
      if (e === null) {
        if (s) {
          str = 'Infinity';
          if (s < 0) str = '-' + str;
        } else {
          str = 'NaN';
        }
      } else {
        if (b == null) {
          str = e <= TO_EXP_NEG || e >= TO_EXP_POS
           ? toExponential(coeffToString(n.c), e)
           : toFixedPoint(coeffToString(n.c), e, '0');
        } else if (b === 10) {
          n = round(new BigNumber(n), DECIMAL_PLACES + e + 1, ROUNDING_MODE);
          str = toFixedPoint(coeffToString(n.c), n.e, '0');
        } else {
          intCheck(b, 2, ALPHABET.length, 'Base');
          str = convertBase(toFixedPoint(coeffToString(n.c), e, '0'), 10, b, s, true);
        }

        if (s < 0 && n.c[0]) str = '-' + str;
      }

      return str;
    };


    /*
     * Return as toString, but do not accept a base argument, and include the minus sign for
     * negative zero.
     */
    P.valueOf = P.toJSON = function () {
      return valueOf(this);
    };


    P._isBigNumber = true;

    if (configObject != null) BigNumber.set(configObject);

    return BigNumber;
  }


  // PRIVATE HELPER FUNCTIONS

  // These functions don't need access to variables,
  // e.g. DECIMAL_PLACES, in the scope of the `clone` function above.


  function bitFloor(n) {
    var i = n | 0;
    return n > 0 || n === i ? i : i - 1;
  }


  // Return a coefficient array as a string of base 10 digits.
  function coeffToString(a) {
    var s, z,
      i = 1,
      j = a.length,
      r = a[0] + '';

    for (; i < j;) {
      s = a[i++] + '';
      z = LOG_BASE - s.length;
      for (; z--; s = '0' + s);
      r += s;
    }

    // Determine trailing zeros.
    for (j = r.length; r.charCodeAt(--j) === 48;);

    return r.slice(0, j + 1 || 1);
  }


  // Compare the value of BigNumbers x and y.
  function compare(x, y) {
    var a, b,
      xc = x.c,
      yc = y.c,
      i = x.s,
      j = y.s,
      k = x.e,
      l = y.e;

    // Either NaN?
    if (!i || !j) return null;

    a = xc && !xc[0];
    b = yc && !yc[0];

    // Either zero?
    if (a || b) return a ? b ? 0 : -j : i;

    // Signs differ?
    if (i != j) return i;

    a = i < 0;
    b = k == l;

    // Either Infinity?
    if (!xc || !yc) return b ? 0 : !xc ^ a ? 1 : -1;

    // Compare exponents.
    if (!b) return k > l ^ a ? 1 : -1;

    j = (k = xc.length) < (l = yc.length) ? k : l;

    // Compare digit by digit.
    for (i = 0; i < j; i++) if (xc[i] != yc[i]) return xc[i] > yc[i] ^ a ? 1 : -1;

    // Compare lengths.
    return k == l ? 0 : k > l ^ a ? 1 : -1;
  }


  /*
   * Check that n is a primitive number, an integer, and in range, otherwise throw.
   */
  function intCheck(n, min, max, name) {
    if (n < min || n > max || n !== mathfloor(n)) {
      throw Error
       (bignumberError + (name || 'Argument') + (typeof n == 'number'
         ? n < min || n > max ? ' out of range: ' : ' not an integer: '
         : ' not a primitive number: ') + String(n));
    }
  }


  // Assumes finite n.
  function isOdd(n) {
    var k = n.c.length - 1;
    return bitFloor(n.e / LOG_BASE) == k && n.c[k] % 2 != 0;
  }


  function toExponential(str, e) {
    return (str.length > 1 ? str.charAt(0) + '.' + str.slice(1) : str) +
     (e < 0 ? 'e' : 'e+') + e;
  }


  function toFixedPoint(str, e, z) {
    var len, zs;

    // Negative exponent?
    if (e < 0) {

      // Prepend zeros.
      for (zs = z + '.'; ++e; zs += z);
      str = zs + str;

    // Positive exponent
    } else {
      len = str.length;

      // Append zeros.
      if (++e > len) {
        for (zs = z, e -= len; --e; zs += z);
        str += zs;
      } else if (e < len) {
        str = str.slice(0, e) + '.' + str.slice(e);
      }
    }

    return str;
  }


  // EXPORT


  BigNumber = clone();
  BigNumber['default'] = BigNumber.BigNumber = BigNumber;

  // AMD.
  if (typeof define == 'function' && define.amd) {
    define(function () { return BigNumber; });

  // Node.js and other environments that support module.exports.
  } else if (typeof module != 'undefined' && module.exports) {
    module.exports = BigNumber;

  // Browser.
  } else {
    if (!globalObject) {
      globalObject = typeof self != 'undefined' && self ? self : window;
    }

    globalObject.BigNumber = BigNumber;
  }
})(this);

},{}]},{},[21])(21)
});
