let rust_wasm_bls12381;
(function() {
    const __exports = {};
    let wasm;

    /**
    * @returns {boolean}
    */
    __exports.bls_stantiate = function() {
        var ret = wasm.bls_stantiate();
        return ret !== 0;
    };

    let cachegetUint8Memory0 = null;
    function getUint8Memory0() {
        if (cachegetUint8Memory0 === null || cachegetUint8Memory0.buffer !== wasm.memory.buffer) {
            cachegetUint8Memory0 = new Uint8Array(wasm.memory.buffer);
        }
        return cachegetUint8Memory0;
    }

    let WASM_VECTOR_LEN = 0;

    function passArray8ToWasm0(arg, malloc) {
        const ptr = malloc(arg.length * 1);
        getUint8Memory0().set(arg, ptr / 1);
        WASM_VECTOR_LEN = arg.length;
        return ptr;
    }
    /**
    * @param {Uint8Array} autograph
    * @param {Uint8Array} message
    * @param {Uint8Array} public_key
    * @returns {boolean}
    */
    __exports.bls_verify = function(autograph, message, public_key) {
        var ptr0 = passArray8ToWasm0(autograph, wasm.__wbindgen_malloc);
        var len0 = WASM_VECTOR_LEN;
        var ptr1 = passArray8ToWasm0(message, wasm.__wbindgen_malloc);
        var len1 = WASM_VECTOR_LEN;
        var ptr2 = passArray8ToWasm0(public_key, wasm.__wbindgen_malloc);
        var len2 = WASM_VECTOR_LEN;
        var ret = wasm.bls_verify(ptr0, len0, ptr1, len1, ptr2, len2);
        return ret !== 0;
    };

    async function load(module, imports) {
        if (typeof Response === 'function' && module instanceof Response) {
            if (typeof WebAssembly.instantiateStreaming === 'function') {
                try {
                    return await WebAssembly.instantiateStreaming(module, imports);

                } catch (e) {
                    if (module.headers.get('Content-Type') != 'application/wasm') {
                        console.warn("`WebAssembly.instantiateStreaming` failed because your server does not serve wasm with `application/wasm` MIME type. Falling back to `WebAssembly.instantiate` which is slower. Original error:\n", e);

                    } else {
                        throw e;
                    }
                }
            }

            const bytes = await module.arrayBuffer();
            return await WebAssembly.instantiate(bytes, imports);

        } else {
            const instance = await WebAssembly.instantiate(module, imports);

            if (instance instanceof WebAssembly.Instance) {
                return { instance, module };

            } else {
                return instance;
            }
        }
    }

    async function init(input) {
        if (typeof input === 'undefined') {
            let src;
            if (typeof document === 'undefined') {
                src = location.href;
            } else {
                src = document.currentScript.src;
            }
            input = src.replace(/\.js$/, '_bg.wasm');
        }
        const imports = {};


        if (typeof input === 'string' || (typeof Request === 'function' && input instanceof Request) || (typeof URL === 'function' && input instanceof URL)) {
            input = fetch(input);
        }



        const { instance, module } = await load(await input, imports);

        wasm = instance.exports;
        init.__wbindgen_wasm_module = module;

        return wasm;
    }

    rust_wasm_bls12381 = Object.assign(init, __exports);

})();


async function rust_wasm_bls12381_load(wasm_path) {
    await rust_wasm_bls12381(wasm_path);
    bls_stantiate = rust_wasm_bls12381.bls_stantiate;
    bls_verify = rust_wasm_bls12381.bls_verify;
}
