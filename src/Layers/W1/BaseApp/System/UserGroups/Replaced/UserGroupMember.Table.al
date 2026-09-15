#if not CLEANSCHEMA25 
namespace System.Security.AccessControl;

using System.Environment;

table 9001 "User Group Member"
{
    Caption = 'User Group Member';
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    ObsoleteReason = '[220_UserGroups] Replaced by the Security Group Member Buffer table and Security Group codeunit in the security groups system; by Access Control table in the permission sets system. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    InherentEntitlements = X;
    InherentPermissions = X;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User Group Code"; Code[20])
        {
            Caption = 'User Group Code';
            DataClassification = EndUserIdentifiableInformation;
            NotBlank = true;
            TableRelation = "User Group";
        }
        field(2; "User Security ID"; Guid)
        {
            Caption = 'User Security ID';
            DataClassification = EndUserPseudonymousIdentifiers;
            NotBlank = true;
            TableRelation = User;
        }
        field(3; "Company Name"; Text[30])
        {
            Caption = 'Company Name';
            TableRelation = Company;
        }
        field(4; "User Name"; Code[50])
        {
            CalcFormula = lookup(User."User Name" where("User Security ID" = field("User Security ID")));
            Caption = 'User Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "User Full Name"; Text[80])
        {
            CalcFormula = lookup(User."Full Name" where("User Security ID" = field("User Security ID")));
            Caption = 'User Full Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6; "User Group Name"; Text[50])
        {
            CalcFormula = lookup("User Group".Name where(Code = field("User Group Code")));
            Caption = 'User Group Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User Group Code", "User Security ID", "Company Name")
        {
            Clustered = true;
        }
    }
}

 
#endif
