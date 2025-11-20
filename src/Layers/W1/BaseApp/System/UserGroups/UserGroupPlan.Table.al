#if not CLEANSCHEMA25 
namespace System.Security.AccessControl;

table 9007 "User Group Plan"
{
    Caption = 'User Group Plan';
    DataPerCompany = false;
    ReplicateData = false;
    ObsoleteState = Removed;
    ObsoleteTag = '25.0';
    ObsoleteReason = '[220_UserGroups] The user groups functionality is deprecated. Default permission sets per plan are defined using the Plan Configuration codeunit. To learn more, go to https://go.microsoft.com/fwlink/?linkid=2245709.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Plan ID"; Guid)
        {
            Caption = 'Plan ID';
            TableRelation = System.Azure.Identity.Plan."Plan ID";
        }
        field(2; "User Group Code"; Code[20])
        {
            Caption = 'User Group Code';
            TableRelation = "User Group".Code;
        }
        field(10; "Plan Name"; Text[50])
        {
            CalcFormula = lookup(System.Azure.Identity.Plan.Name where("Plan ID" = field("Plan ID")));
            Caption = 'Plan Name';
            FieldClass = FlowField;
        }
        field(11; "User Group Name"; Text[50])
        {
            CalcFormula = lookup("User Group".Name where(Code = field("User Group Code")));
            Caption = 'User Group Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Plan ID", "User Group Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

 
#endif
