Class Cosmian.Cloudproof.BaseAdapter Extends Ens.OutboundAdapter
{

Property PolicyJsonFile As %String(MAXLEN = 200) [ Required ];

Property AccessPolicy As %String(MAXLEN = 200) [ Required ];

Property Policy As %SYS.Python;

Parameter SETTINGS = "PolicyJsonFile:Basic,AccessPolicy:Basic";

Method OnInit() As %Status
{
   #dim sc As %Status = $$$OK
   try {
      do ..PyOnInit()
   } catch ex {
      set sc = ex.AsStatus()
   }
   quit sc
}

Method PyOnInit() [ Language = python ]
{
   return 1
}

}
