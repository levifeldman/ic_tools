## 2.1.1
* Fix README sample


## 2.1.0
* Verify that the certificate is valid for the canister and subnet
* Verify query signatures
* `verify_certificate` now takes a SubnetOrCanister and subnet_id_or_canister_id
* Make public `lookup_path_branches_in_an_ic_certificate_tree`
* New method extension method `chunks` on T extends List.


## 2.0.2
* use Completer for the indexdb api. 
* IICaller .indexdx_delete
* common update


## 2.0.1
* `fetch_root_key` function for a local replica.
* `provisional_create_canister_with_cycles` function for a local replica.
* `provisional_top_up_canister` function for a local replica.
* Set the [effective-canister-id](https://internetcomputer.org/docs/current/references/ic-interface-spec/#http-effective-canister-id) as the management-canister-id when calling the `provisional_create_canister_with_cycles` function. 
 

## 2.0.0
* New documentation for the libraries.
* Make some library items private.
* New candid functions `c_forwards_one` and `c_backwards_one`.
* Use the `Principal` type for the candid library since the opaque `PrincipalReference` type is not being used.
* Common lib `CanisterInstallMode` enum for the `put_code_on_the_canister` function `mode` parameter.
* Fix typo in the `Tokens.oftheDoubleString` function.
* `check_icrc1_balance` function in the common lib.
* `CandidType.as_option` is a static method instead of an inherited method.
* `Icrc1Account` `id` method, and static method `of_the_id` for the current icrc1-account [textual-representation](https://github.com/dfinity/ICRC-1/blob/599ea75be8f94e69d7a498bdfdde27a34712645e/standards/ICRC-1/TextualEncoding.md).
* New `Keys` class, a key-pair that can sign messages.
* `Caller` class, a pair of keys with possible delegations.
* `List<Legation>` parameter removed from the `Canister.call` function. Delegations included in the `Caller` class.
* Consistent casing accross the library.
* `CallException` `reject_code` is a `BigInt`.
* Fix return type of `Canister.module_hash` to account for the case when the canister is empty and has no module.
* Fix return type of `Canister.metadata` and `Canister.candid_service_metadata` to account for the case when the metadata section is empty.
* `common_web` library is back within this package.


## 1.1.4
* New use cbor dart lib for the web.
* Update Canister .call with the changes of https://github.com/dfinity/interface-spec/pull/143. /call requests can now return http 200 with a reject response map.


## 1.1.3
* SubtleCrypto Caller for the web is in a new package [ic_tools_web](https://pub.dev/packages/ic_tools_web)
* common system canisters are now static properties of the `SYSTEM_CANISTERS` class
* Temp workaround for `read_state` `request_status` paths while [this commit](https://github.com/dfinity/ic/commit/6d47900d7dc34cbce76b50923ae67fa594b94c0b) waits for the next network upgrade.


## 1.1.2
* `IcpTokens.oftheDoubleString` function without using doubles
* `IcpTokens round_decimal_places` function without using doubles
* common lib `transfer_icp` returns the Ok/Err variant
* common lib `create_canister`, `topup_canister`, `transfer_icp`, and `check_icp_balance` use the IcpTokens class
* `CandidType.asOption<T extends CandidType>()` for the candid option subtyping rules.
* candid `cast_option<T extends CandidType>()`


## 1.1.1
* import 'dart:math'; in the common-lib


## 1.1.0
* IcpTokens extends Record type in the common lib


## 1.0.95
* general clean up
* new catchable CallException with the reject code and reject message
* new SubtleCrypto Caller with exctractable = false for secure legation on the web
* new candid match_variant function
* new Record.find_option method, since a candid option that is null within a record can be left out of the record or can be put into an option-type with a null value, this function checks for both of those possibilties in one function. 
* icp_id standalone function
```dart 
String icp_id(Principal principal, {List<int>? subaccount_bytes})
```


## 1.0.94
* make public constructicsystemstatetreeroothash
* re-try read_state calls when http error
* clean-up


## 1.0.93
* principal_af_an_icp_id common lib function now is an extension method on Principal 
```dart 
String icp_id({List<int>? subaccount_bytes})
```
* send_dfx common function is now 'transfer_icp'


## 1.0.92
* new timeout_duration parameter on the canister.call method


## 1.0.91
* take-out dart:io import in the common-lib, put_code_on_the_canister now takes a Uint8List wasm_canister_bytes instead of a file-path


## 1.0.9
* Legation class 


## 1.0.8
* new common-lib top-up canister method 
* updates the create_canister common-lib function with the ledger's-update of the to_canister-field on the notify_dfx method for a principal-type (used to be a blob type)


## 1.0.7 
* candid ServiceReference now sorts the methods by the name per the spec
* Principal('...').as_a_candid() now is Principal('...').candid


## 1.0.6
* PrincipalReference serializes as a candid primtype
* new common management functions: `check_canister_status` and `put_code_on_the_canister`


## 1.0.5
* Principal class now has a new method: .as_a_candid() and does not extend the CandidType: PrincipalReference.


## 1.0.4
* :change of the crypto-libraries, now crypto and ed25519_edwards


## 1.0.3
* new .cast_vector<C>() method on the Vector , for the cast of a vector< Candidtype > for a specific vector < specific-candidtype >, like .cast< T >() on a List.
* new getter .principal on a candid PrincipalReference  
* The Principal class now extends the CandidType: PrincipalReference.
* You can now set the icbaseurl variable and it is now a Uri type. local on the port: 8000 -> 
```dart 
icbaseurl = Uri.parse('http://127.0.0.1:8000'); 
```


## 1.0.2
* Timization of the c_backwards on a Vector< Nat8 > , so we can serialize big blobs fast. 
* empty Blob() c_forwards fix


## 1.0.1
* :version: 1.0.1 .





----------------------

## 0.9.0

* :first-version.

## 0.9.01

* ingress_expiry on the web cbor bug-fix, and README update.

## 0.9.2

* Docs-fix , candid reference-types-fix

## 0.9.21

* cbor namespace fix on the web

## 0.9.22

* README change

## 0.9.23

* Structions on the Linux

## 0.9.24

* candid Vector T_backwards isTypeStance fix and forwards bytes lists fixs.  

## 0.9.25

* calls to the management canister now are with the correct fective_canister_id.

## 0.9.26

* new create_canister-function in the common-library.

## 0.9.27

* :fix: comma in the lib/common.dart.

## 0.9.28

* :fix: exports of the common.dart.
