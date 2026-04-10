namespace System.Automation;

table 1522 "Workflow Event Queue"
{
    Caption = 'Workflow Event Queue';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(2; "Session ID"; Integer)
        {
            Caption = 'Session ID';
        }
        field(3; "Step Record ID"; RecordID)
        {
            Caption = 'Step Record ID';
            DataClassification = CustomerContent;
        }
        field(4; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Queued,Executing,Executed';
            OptionMembers = Queued,Executing,Executed;
        }
        field(6; "Record Index"; Integer)
        {
            Caption = 'Record Index';
        }
        field(7; "xRecord Index"; Integer)
        {
            Caption = 'xRecord Index', Locked = true;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

