namespace System.Device;

using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;

table 78 "Printer Selection"
{
    Caption = 'Printer Selection';
    DataPerCompany = false;
    LookupPageID = "Printer Selections";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;

            trigger OnValidate()
            var
                UserSelection: Codeunit "User Selection";
            begin
                UserSelection.ValidateUserName("User ID");
            end;
        }
        field(2; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
        }
        field(3; "Printer Name"; Text[250])
        {
            Caption = 'Printer Name';
            TableRelation = Printer;
        }
        field(4; "Report Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Report ID")));
            Caption = 'Report Caption';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "User ID", "Report ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

