namespace System.Azure.Identity;

using System.Reflection;

table 6303 "Azure AD Mgt. Setup"
{
    Caption = 'Microsoft Entra ID Mgt. Setup';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "Auth Flow Codeunit ID"; Integer)
        {
            Caption = 'Auth Flow Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(3; "Azure AD User Mgt. Codeunit ID"; Integer)
        {
            Caption = 'Azure AD User Mgt. Codeunit ID';
            TableRelation = "CodeUnit Metadata".ID;
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

    procedure ResetToDefault()
    begin
        Validate("Auth Flow Codeunit ID", CODEUNIT::"Azure AD Auth Flow");
        Validate("Azure AD User Mgt. Codeunit ID", CODEUNIT::"Azure AD User Management");
    end;

    internal procedure IsSetupDifferentFromDefault(): Boolean
    begin
        exit(("Auth Flow Codeunit ID" <> CODEUNIT::"Azure AD Auth Flow") or
             ("Azure AD User Mgt. Codeunit ID" <> CODEUNIT::"Azure AD User Management"));
    end;
}
