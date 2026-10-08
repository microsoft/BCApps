#pragma warning disable AA0247
table 12430 "Document Print Buffer"
{
    Caption = 'Document Print Buffer';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
        }
        field(2; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            DataClassification = SystemMetadata;
        }
        field(3; "Document Type"; Option)
        {
            Caption = 'Document Type';
            DataClassification = SystemMetadata;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9";
        }
        field(4; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
        }
        field(5; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = SystemMetadata;
        }
        field(6; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "User ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

