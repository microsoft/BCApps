namespace System.Environment.Configuration;

table 1519 "Notification Context"
{
    Caption = 'Notification Context';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Notification ID"; Guid)
        {
            Caption = 'Notification ID';
        }
        field(2; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(3; "Additional Context ID"; Guid)
        {
            Caption = 'Additional Context ID';
        }
        field(4; Created; DateTime)
        {
            Caption = 'Created';
        }
    }

    keys
    {
        key(Key1; "Notification ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Created := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        Created := CurrentDateTime;
    end;
}

