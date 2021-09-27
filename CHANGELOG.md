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

## 1.0.1

* :version: 1.0.1 .

## 1.0.2

* Timization of the c_backwards on a Vector< Nat8 > , so we can serialize big blobs fast. 
* empty Blob() c_forwards fix

## 1.0.3

* new .cast_vector<C>() method on the Vector , for the cast of a vector< Candidtype > for a specific vector < specific-candidtype >, like .cast< T >() on a List.
* new getter .principal on a candid PrincipalReference  
* The Principal class now extends the CandidType: PrincipalReference.
* You can now set the icbaseurl variable and it is now a Uri type. local on the port: 8000 -> 
```dart 
icbaseurl = Uri.parse('http://127.0.0.1:8000'); 
```