namespace System.Environment.Configuration;

table 9177 "Experience Tier Buffer"
{
    Caption = 'Experience Tier Buffer';
    LookupPageID = "Experience Tiers";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Field No."; Integer)
        {
            Caption = 'Field No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(2; "Experience Tier"; Text[30])
        {
            Caption = 'Experience Tier';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; Selected; Boolean)
        {
            Caption = 'Selected';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Field No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

