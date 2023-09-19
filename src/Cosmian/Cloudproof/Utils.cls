Class Cosmian.Cloudproof.Utils
{

XData %import [ MimeType = application/python ]
{
import json
import base64
import asyncio
import os
import iris
from cloudproof_py.cover_crypt import Policy, PolicyAxis
from cloudproof_py.kms import KmsClient
from cloudproof_py.cover_crypt import CoverCrypt
from cloudproof_py.cover_crypt import UserSecretKey
from cloudproof_py.cover_crypt import MasterSecretKey
from cloudproof_py.findex import Findex, Keyword, Label, Location, MasterKey
from cloudproof_py.findex.utils import generate_auto_completion
from cosmian.Findex import FindexSQLite
}

/// get policy
ClassMethod GetPolicy(jsonFile As %String) As %SYS.Python [ Language = python ]
{
    with open(jsonFile, 'r') as f:
        policy_json = json.load(f)
	
    policy = Policy()

    for ax_name, ax in policy_json['axis'].items():
        axis_attributes = [(att['name'],att['isHybridized']) for att in ax['attributes']]
        policyAxis = PolicyAxis(ax_name, axis_attributes, ax['hierarchical'])
        policy.add_axis(policyAxis)

    return policy
}

/// **************************** KMS ************************************
/// get KMS cloudproof_py client
ClassMethod GetKMSClient(serverUrl, dbSecret) As %String [ Language = python ]
{
	return KmsClient(server_url=serverUrl, database_secret=dbSecret)
}

ClassMethod KMSDecrpt(kmsClient As %SYS.Python, userDecryptionUid As %String, base64CipherText As %String) As %String [ Language = python ]
{
	ciphertext = base64.b64decode(base64CipherText.encode())

	plaintext, _ =  asyncio.run(kmsClient.cover_crypt_decryption(userDecryptionUid, ciphertext))

	return plaintext.decode()
}

/// Generate KMS public and private key Pair
ClassMethod GenerateKMSKeyPair(kmsClient, policy) [ Language = python ]
{
	(publicKeyUid, privateKeyUid) = asyncio.run(kmsClient.create_cover_crypt_master_key_pair(policy))

	print("publicKeyUid: ",publicKeyUid)
	print("privateKeyUid: ",privateKeyUid)

	return (publicKeyUid, privateKeyUid)
}

/// **************************** Local CloudProof ************************************
/// The master authority possesses the master key pair:
/// a master secret key which is used to generate user keys;
/// and a public key which is used for encryption. Since it cannot decrypt, the public key can be freely distributed to encrypting systems.
ClassMethod GenerateKeyPair(policy, keyPath) [ Language = python ]
{
    cover_crypt = CoverCrypt()
    master_private_key, public_key = cover_crypt.generate_master_keys(policy)

    with open(os.path.join(keyPath, 'master_private.key'), 'wb') as f:
        f.write(master_private_key.to_bytes())
        print("master_private.key saved")
	
    with open(os.path.join(keyPath, 'public.key'), 'wb') as f:
        f.write(public_key.to_bytes())
        print("public.key saved")

    return (public_key, master_private_key)
}

ClassMethod GetMasterPrivateKey(masterPrivateKeyPath As %String) As %SYS.Python [ Language = python ]
{
    with open(masterPrivateKeyPath, 'rb') as f:
        masterPrivateKey = MasterSecretKey.from_bytes(f.read())

    return masterPrivateKey
}

ClassMethod GetCloudProofDecrptKey(userDecryptionKeyPath As %String) As %SYS.Python [ Language = python ]
{
    with open(userDecryptionKeyPath, 'rb') as f:
        userDecryptionKey = UserSecretKey.from_bytes(f.read())

    return userDecryptionKey
}

ClassMethod CloudProofDecrpt(userDecryptionKey As %SYS.Python, base64CipherText As %String) As %String [ Language = python ]
{

    cover_crypt = CoverCrypt()

    ciphertext = base64.b64decode(base64CipherText.encode())

    plaintext, _ = cover_crypt.decrypt(userDecryptionKey, ciphertext)

    return plaintext.decode()
}

ClassMethod GenerateDecryptionKey(masterPrivateKey, policy, accessPolicy, keyPath, decryptionKeyName = "user_decryption.key") [ Language = python ]
{
    cover_crypt = CoverCrypt()

    decryption_key = cover_crypt.generate_user_secret_key(
        masterPrivateKey,
        accessPolicy,
        policy
        )

    with open(os.path.join(keyPath, decryptionKeyName), 'wb') as f:
        f.write(decryption_key.to_bytes())
        print(f"{decryptionKeyName} saved")
}

ClassMethod GenerateKMSDecryptionKeyUid(kmsClient, privateKeyUid, accessPolicy) [ Language = python ]
{
    async def get_decrptionKey():
        return await kmsClient.create_cover_crypt_user_decryption_key(accessPolicy, privateKeyUid)

    decryptionKeyUid = asyncio.run(get_decrptionKey())

    print("decryptionKeyUid : ", decryptionKeyUid)

    return decryptionKeyUid
}

/// a demo method for decrypting FHIR patient names
ClassMethod DecrptFhirPatient(FhirPatientJson, isKMS = 0) [ Language = python ]
{
    FhirPatient = json.loads(FhirPatientJson)

    if FhirPatient['resourceType'] == "OperationOutcome":
        return json.dumps(FhirPatient)

    def updatePatientResource(resource):
        names = []
        for name in resource['name']:
            familyName = name['family']
            if isKMS:
                familyName = iris.cls(__name__).KMSDecrpt(kmsClient, userDecryptionUid, familyName)
            else:
                familyName = iris.cls(__name__).CloudProofDecrpt(userDecryptionKey, familyName)
                
            
            name['family'] = familyName

            givenNames = []
            for givenName in name['given']:
                if isKMS:
                    givenName = iris.cls(__name__).KMSDecrpt(kmsClient, userDecryptionUid, givenName)
                else:
                    givenName = iris.cls(__name__).CloudProofDecrpt(userDecryptionKey, givenName)
                    

                givenNames.append(givenName)
            
            # update givennames
            name['given'] = givenNames

            # update text
            name['text'] =f"{' '.join(name.get('prefix',''))} { ' '.join(name['given'])} {name['family']}"

            names.append(name)

        #update names
        resource['name'] = names

        return resource

    #; for remote KMS encription
    kmsDbSerect = iris.cls("Ens.Config.Credentials")._OpenId("kms_database_secret").Password

    kmsClient = iris.cls("Cosmian.Cloudproof.Utils").GetKMSClient(os.environ['COSMIAN_KMS_SERVER'], kmsDbSerect)

    userDecryptionUid = iris.cls("Ens.Config.Credentials")._OpenId("kms_confidential_mkg_user_decrypt_uid").Password
    
    #; for local cloudproof encryption
    userDecryptionKey = iris.cls("Cosmian.Cloudproof.Utils").GetCloudProofDecrptKey(os.environ['COSMIAN_DECRYPTION_KEY_PATH'])

    if 'entry' in FhirPatient:
        entrys = FhirPatient['entry']
        for e in entrys:
            #update names
            e['resource'] = updatePatientResource(e['resource'])

        # update entry
        FhirPatient['entry'] = entrys
    else:
        FhirPatient = updatePatientResource(FhirPatient)
    
    return json.dumps(FhirPatient)
}

/// Generate Findex Master Key
ClassMethod FindexGenerateMasterKey(keyPath) [ Language = python ]
{
    findex_master_key = MasterKey.random()
    with open(keyPath, 'wb') as f:
        f.write(findex_master_key.to_bytes())
        print("findexmaster key saved")
    
    return findex_master_key
}

/// Load Findex Master Key
ClassMethod FindexGetMasterKey(findexMasterKeyPath As %String) As %SYS.Python [ Language = python ]
{
    with open(findexMasterKeyPath, 'rb') as f:
        findexMasterKey = MasterKey.from_bytes(f.read())

    return findexMasterKey
}

ClassMethod FindexGenerateLabel(label As %String) [ Language = python ]
{
    return Label.from_string(label)
}

ClassMethod FindexGetInterface(dbPath As %String) [ Language = python ]
{
    return FindexSQLite(dbPath)
}

/// Update or insert data
/// We can index the patient's ID and names
/// example:
/// dataJson = {
/// "1": ["Martin", "Shepherd"],
/// "2": ["Martial", "Wilkins"],
/// "3": ["John", "Shepherd"],
/// }
ClassMethod FindexUpsert(masterKey, label, findexInterface, dataJson) [ Language = python ]
{
    data = json.loads(dataJson)
    # Create the index
    indexed_values_and_keywords: IndexedValuesAndKeywords = {}
    for uid, keywords in data.items():
        # Convert database UIDs to IndexedValue expected by Findex
        location = Location.from_string(uid)
        # This location has 2 keywords associated: example : the firstname and lastname
        indexed_values_and_keywords[location] = keywords

        # optional, create the keywords for search like: "Mar", "Mart", "Marti" for "Martin"
        indexed_values_and_keywords.update(generate_auto_completion(keywords))
    
    findexInterface.upsert(masterKey, label, indexed_values_and_keywords, {})
}

/// keywords to search example : keywords = ["She", "Shepherd", "John"]
ClassMethod FindexSearch(masterKey, label, findexInterface, keywords) [ Language = python ]
{
    keywords = json.loads(keywords)
    found_locations = findexInterface.search(masterKey, label, keywords)

    print("Locations found by keywords:")
    for keyword, locations in found_locations.items():
        print("\t", keyword, ":", locations)

    return json.dumps({str(k):[str(vv) for vv in v] for k, v in found_locations.items()})
}

}
