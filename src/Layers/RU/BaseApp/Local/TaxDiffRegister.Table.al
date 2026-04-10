#pragma warning disable AA0247
table 17302 "Tax Diff. Register"
{
    Caption = 'Tax Diff. Register';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "Tax Diff. Ledger Entry"."Entry No.";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "Tax Diff. Ledger Entry"."Entry No.";
        }
        field(4; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(5; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;
}

