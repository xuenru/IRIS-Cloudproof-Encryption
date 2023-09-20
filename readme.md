# IRIS Cloudproof Encryption
# This project implements the data Encryption in IRIS by cloudproof_py from [Cosmian](https://docs.cosmian.com/cloudproof_encryption/how_it_works/).

## Installation
```shell
$ git clone https://github.com/xuenru/IRIS-Cloudproof-Encryption.git
$ cd IRIS-Cloudproof-Encryption
$ pip install -r requirements.txt
$ cp src/python/cosmian/ ${mgrdir}python/cosmian/
# then import and compile classes in src/Cosmian/Cloudproof
```

### Install with ZPM
```
$ pip install cloudproof-py
> zpm "install iris-cloudproof-encryption"
```
> If ZPM is not installed, you can install it using the following command.
```
> s r=##class(%Net.HttpRequest).%New(),r.Server="pm.community.intersystems.com",r.SSLConfiguration="ISC.FeatureTracker.SSL.Config" d r.Get("/packages/zpm/latest/installer"),$system.OBJ.LoadStream(r.HttpResponse.Data,"c")
```

## Application Level Encryption in Interoperability
Apply the following adapters in the business processes
- `Cosmian.Cloudproof.CoverCryptAdapter` : encrypt locally
- `Cosmian.Cloudproof.KmsAdapter` : encrypt from a remote cosmian [KMS server](https://docs.cosmian.com/cosmian_key_management_system/)

## Configuration and Examples
### Open IRIS terminal
### Encryption / Decryption
```shell
# Load the policy
> s policy =  ##class("Cosmian.Cloudproof.Utils").GetPolicy("/path/cosmian_policy.json")
```

##### For KMS encryption
```shell
# Get KmsClient
> s kmsClient = ##Class(EncryptionFhir.Util.FunctionSet).GetKMSClient("kms url","token")

# Generate private and public key pair ids 
> d ##Class(EncryptionFhir.Util.FunctionSet).GenerateKeyPair(kmsClient, policy)

# Generate decryption key uid
> s decryptionKeyUid = ##class("Cosmian.Cloudproof.Utils").GenerateKMSDecryptionKeyUid(kmsClient, privateKeyUid, accessPolicy)

# Decryption
> s plaintext = ##class("Cosmian.Cloudproof.Utils").KMSDecrpt(kmsClient, userDecryptionUid, base64CipherText)
```
##### For local encryption
```shell
# Generate private and public key pair file for local encryption
> d ##class("Cosmian.Cloudproof.Utils").GenerateKeyPair(policy, "key path")

# Generate decryption key
> d ##class("Cosmian.Cloudproof.Utils").GenerateDecryptionKey(masterPrivateKey, policy, accessPolicy, "key path")

# Decryption
> s plaintext = ##class("Cosmian.Cloudproof.Utils").CloudProofDecrpt(userDecryptionKey, base64CipherText)
```
### Findex Encrypted Search API
```shell
# Generate findex master key
> s masterKey = ##class("Cosmian.Cloudproof.Utils").FindexGenerateMasterKey("key path name")

# Get existing findex master key
> s masterKey = ##class("Cosmian.Cloudproof.Utils").FindexGetMasterKey("/pathto/findex_master.key")

# Generate findex label for salt
> s label = ##class("Cosmian.Cloudproof.Utils").FindexGenerateLabel("label")

# Get findex interface instance
> s findexInterface = ##class("Cosmian.Cloudproof.Utils").FindexGetInterface("path to db sqlite file")

# Update or insert keywords index value in Findex database
# data example : Set data = {"1": ["Martin", "Shepherd"], "2": ["Martial", "Wilkins"], "3": ["John", "Shepherd"]}.%ToJSON()
> d ##class("Cosmian.Cloudproof.Utils").FindexUpsert(masterKey, label, findexInterface, data)

# search index by keywords
# keywords example : set keywords = ["She","Shepherd","John"].%ToJSON()
> w ##class("Cosmian.Cloudproof.Utils").FindexSearch(masterKey, label, findexInterface, keywords)
```
### Docs:
https://docs.cosmian.com/cloudproof_encryption/how_it_works/
