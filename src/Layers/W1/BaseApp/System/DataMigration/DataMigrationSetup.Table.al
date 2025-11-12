namespace System.Integration;

using System.IO;

table 1806 "Data Migration Setup"
{
    Caption = 'Data Migration Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Default Customer Template"; Code[10])
        {
            Caption = 'Default Customer Template';
            TableRelation = "Config. Template Header" where("Table ID" = const(18));
        }
        field(3; "Default Vendor Template"; Code[10])
        {
            Caption = 'Default Vendor Template';
            TableRelation = "Config. Template Header" where("Table ID" = const(23));
        }
        field(4; "Default Item Template"; Code[10])
        {
            Caption = 'Default Item Template';
            TableRelation = "Config. Template Header" where("Table ID" = const(27));
        }
        field(5; "Default Account Template"; Code[10])
        {
            Caption = 'Default Account Template';
        }
        field(6; "Default Posting Group Template"; Code[10])
        {
            Caption = 'Default Posting Group Template';
        }
        field(7; "Default Cust. Posting Template"; Code[10])
        {
            Caption = 'Default Cust. Posting Template';
        }
        field(8; "Default Vend. Posting Template"; Code[10])
        {
            Caption = 'Default Vend. Posting Template';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

