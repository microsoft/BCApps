namespace System.Threading;
using System.Security.AccessControl;

table 9065 "Job Queue Role Center Cue"
{
    Caption = 'Job Queue Role Center Cue';
    DataClassification = CustomerContent;
    ReplicateData = false;
    Permissions = TableData "Job Queue Role Center Cue" = rimd;
    InherentPermissions = rimx;
    Extensible = false;
    Access = Internal;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
        }
        field(2; "User ID"; Text[65])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(3; "Job Queue - Tasks Failed"; Integer)
        {
            Caption = 'Job Queue - Tasks Failed';
        }
        field(4; "Job Queue - Tasks In Process"; Integer)
        {
            Caption = 'Job Queue - Tasks In Process';
        }
        field(5; "Job Queue - Tasks In Queue"; Integer)
        {
            Caption = 'Job Queue - Tasks In Queue';
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }
}

