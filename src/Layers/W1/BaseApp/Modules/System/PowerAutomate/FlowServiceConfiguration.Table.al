namespace System.Automation;

table 1543 "Flow Service Configuration"
{
    Caption = 'Power Automate Service Configuration';
    DataPerCompany = false;
    ReplicateData = false;
    InherentEntitlements = r;
    InherentPermissions = r;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Flow Service"; Option)
        {
            Caption = 'Power Automate Service';
            OptionCaption = 'Production Service,Testing Service (TIP 1),Testing Service (TIP 2)';
            OptionMembers = "Production Service","Testing Service (TIP 1)","Testing Service (TIP 2)";
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

