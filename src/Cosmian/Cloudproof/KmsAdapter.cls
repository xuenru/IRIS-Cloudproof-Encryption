Class Cosmian.Cloudproof.KmsAdapter Extends Cosmian.Cloudproof.BaseAdapter
{

Property KmsServerUrl As %String(MAXLEN = 200) [ Required ];

Property KmsDatabaseSecretCredentials As %String [ Required ];

Property KmsPublicKeyUidCredentials As %String [ Required ];

Property KmsClient As %SYS.Python;

Property KmsPublicKeyUid As %String;

Parameter SETTINGS = "KmsServerUrl:Basic,KmsDatabaseSecretCredentials:Basic:credentialsSelector,KmsPublicKeyUidCredentials:Basic:credentialsSelector";

XData %import [ MimeType = application/python ]
{
import iris
from cloudproof_py.kms import KmsClient
import base64
import asyncio
}

/// init kms client
Method PyOnInit() [ Language = python ]
{
    kms_database_secret = iris.cls("Ens.Config.Credentials")._OpenId(self.KmsDatabaseSecretCredentials).Password
    self.KmsPublicKeyUid = iris.cls("Ens.Config.Credentials")._OpenId(self.KmsPublicKeyUidCredentials).Password

    self.KmsClient = KmsClient(server_url=self.KmsServerUrl, database_secret=kms_database_secret)
}

/// encrypt text to base64 encoded ciphertext with cloudproof_py
Method Encrypt(text As %String) As %String [ Language = python ]
{
	text_encoded = text.encode()

	protected_ciphertext =  asyncio.run(self.KmsClient.cover_crypt_encryption(self.KmsPublicKeyUid, self.AccessPolicy, text_encoded))

	return base64.b64encode(protected_ciphertext).decode()
}

}
