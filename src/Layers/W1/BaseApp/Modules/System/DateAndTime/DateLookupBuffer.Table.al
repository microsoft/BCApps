namespace System.DateTime;

table 749 "Date Lookup Buffer"
{
    Caption = 'Date Lookup Buffer';
    LookupPageID = "Date Lookup";
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Period Type"; Option)
        {
            Caption = 'Period Type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Day,Week,Month,Quarter,Year';
            OptionMembers = Day,Week,Month,Quarter,Year;
        }
        field(2; "Period Start"; Date)
        {
            Caption = 'Period Start';
            DataClassification = SystemMetadata;
        }
        field(3; "Period End"; Date)
        {
            Caption = 'Period End';
            DataClassification = SystemMetadata;
        }
        field(4; "Period No."; Integer)
        {
            Caption = 'Period No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Period Name"; Text[30])
        {
            Caption = 'Period Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Period Type", "Period Start")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Period Name")
        {
        }
    }
}

