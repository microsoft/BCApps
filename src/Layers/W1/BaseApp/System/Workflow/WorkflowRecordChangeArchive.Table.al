namespace System.Automation;

table 1526 "Workflow Record Change Archive"
{
    Caption = 'Workflow Record Change Archive';
    ReplicateData = true;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(2; "Table No."; Integer)
        {
            Caption = 'Table No.';
        }
        field(3; "Field No."; Integer)
        {
            Caption = 'Field No.';
        }
        field(4; "Old Value"; Text[250])
        {
            Caption = 'Old Value';
        }
        field(5; "New Value"; Text[250])
        {
            Caption = 'New Value';
        }
        field(6; "Record ID"; RecordID)
        {
            Caption = 'Record ID';
            DataClassification = CustomerContent;
        }
        field(7; "Workflow Step Instance ID"; Guid)
        {
            Caption = 'Workflow Step Instance ID';
        }
        field(9; Inactive; Boolean)
        {
            Caption = 'Inactive';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

