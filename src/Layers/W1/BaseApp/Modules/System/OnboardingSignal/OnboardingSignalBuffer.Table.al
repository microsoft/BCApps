namespace System.Feedback;



table 5491 "Onboarding Signal Buffer"
{
    Access = Public;
    Caption = 'Buffer table for Onboarding Signal';
    DataClassification = OrganizationIdentifiableInformation;
    Extensible = false;
    ReplicateData = false;
    Scope = Cloud;
    InherentPermissions = R;
    InherentEntitlements = R;
    TableType = Temporary;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'Used as primary key';
            AutoIncrement = true;
        }
        field(2; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
        }
        field(3; "Onboarding Completed"; Boolean)
        {
            Caption = 'Onboarding Completed';
            Description = 'Whether the onboarding criteria has been met for this entry';
        }
        field(4; "Onboarding Signal Type"; Enum "Onboarding Signal Type")
        {
            Caption = 'Onboarding Signal Type';
        }
        field(5; "Onboarding Start Date"; Date)
        {
            Caption = 'Onboarding Start Date';
        }
        field(6; "Onboarding Complete Date"; Date)
        {
            Caption = 'Onboarding Complete Date';
        }
        field(7; "Extension ID"; Guid)
        {
            Caption = 'Extension ID';
            Description = 'The Extension that registered the signal';
        }
    }

    keys
    {
        key(key1; "No.")
        {
        }
    }
}