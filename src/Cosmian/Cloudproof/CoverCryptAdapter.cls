Class Cosmian.Cloudproof.CoverCryptAdapter Extends Cosmian.Cloudproof.BaseAdapter
{

Property PublicKeyPath As %String(MAXLEN = 200) [ Required ];

Property CoverCrypt As %SYS.Python;

Property PublicKey As %SYS.Python;

Parameter SETTINGS = "PublicKeyPath:Basic";

XData %import [ MimeType = application/python ]
{
from cloudproof_py.cover_crypt import CoverCrypt, PublicKey
import iris
import base64
}

/// init python
Method PyOnInit() As %Status [ Language = python ]
{
    self.Policy = iris.cls("Cosmian.Cloudproof.Utils").GetPolicy(self.PolicyJsonFile)
    self.CoverCrypt = CoverCrypt()

    with open(self.PublicKeyPath, 'rb') as f:
        self.PublicKey = PublicKey.from_bytes(f.read())
}

/// encrypt text to base64 encoded ciphertext with cloudproof_py
/// accessPolicy example:
/// "Department::MKG && Security Level::Protected"
Method Encrypt(text As %String) As %String [ Language = python ]
{
    text_encoded = text.encode()

    protected_ciphertext = self.CoverCrypt.encrypt(
        self.Policy,
        self.AccessPolicy,
        self.PublicKey,
        text_encoded,
    )

    return base64.b64encode(protected_ciphertext).decode()
}

}
