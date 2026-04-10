namespace System.Automation;

using Microsoft.Utilities;

table 1550 "Restricted Record"
{
    Caption = 'Restricted Record';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; BigInteger)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(3; Details; Text[250])
        {
            Caption = 'Details';
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; "Record ID")
        {
        }
    }

    fieldgroups
    {
    }

    procedure ShowRecord()
    var
        PageManagement: Codeunit "Page Management";
        RecRef: RecordRef;
    begin
        if not RecRef.Get("Record ID") then
            exit;
        PageManagement.PageRun(RecRef);
    end;
}

