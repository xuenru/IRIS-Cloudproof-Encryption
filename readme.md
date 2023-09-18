# IRIS Cloudproof Encryption
# This project implements the data Encryption in IRIS by cloudproof_py from [Cosmian](https://docs.cosmian.com/cloudproof_encryption/how_it_works/).

## Instalation
```shell
pip3 install --target /durable/iris/mgr/python cloudproof_py
cp src/python/cosmian /durable/iris/mgr/python
```
## Application Level Encryption in Interoperability
Apply the following adapters in the business processes
- `Cosmian.Cloudproof.CoverCryptAdapter` : encrypt locally
- `Cosmian.Cloudproof.KmsAdapter` : encrypt from a remote cosmian [KMS server](https://docs.cosmian.com/cosmian_key_management_system/)

## Configuration
### Open IRIS terminal
```shell
# Load the policy
s policy =  ##class("Cosmian.Cloudproof.Utils").GetPolicy("/path/cosmian_policy.json")
```

#### For KMS encryption
```shell
# Get KmsClient
s kmsClient = ##Class(EncryptionFhir.Util.FunctionSet).GetKMSClient("kms url","token")

# Generate private and public key pair ids 
d ##Class(EncryptionFhir.Util.FunctionSet).GenerateKeyPair(kmsClient, policy)

# Generate decryption key uid
s decryptionKeyUid = ##class("Cosmian.Cloudproof.Utils").GenerateKMSDecryptionKeyUid(kmsClient, privateKeyUid, accessPolicy)
```
#### For local encryption
```shell
# Generate private and public key pair file for local encryption
d ##class("Cosmian.Cloudproof.Utils").GenerateKeyPair(policy, "key path")

# Generate decryption key
d ##class("Cosmian.Cloudproof.Utils").GenerateDecryptionKey(masterPrivateKey, policy, accessPolicy, "key path")
```
### Findex Encrypted Search API
```shell
# Generate findex master key
s masterKey = ##class("Cosmian.Cloudproof.Utils").FindexGenerateMasterKey("key path name")

# Generate findex label for salt
s label = ##class("Cosmian.Cloudproof.Utils").FindexGenerateLabel("label")

# Get findex interface instance
s findexInterface = ##class("Cosmian.Cloudproof.Utils").FindexGetInterface("path to db sqlite")

# Update or insert keywords index value in Findex database
d ##class("Cosmian.Cloudproof.Utils").FindexUpsert(masterKey, label, findexInterface, "data")

# search index by keywords
w ##class("Cosmian.Cloudproof.Utils").FindexSearch(masterKey, label, findexInterface, "keywords")
```
### Docs:
https://docs.cosmian.com/cloudproof_encryption/how_it_works/
