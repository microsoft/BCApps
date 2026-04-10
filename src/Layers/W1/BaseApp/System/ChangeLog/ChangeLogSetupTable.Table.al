namespace System.Diagnostics;

using System.Reflection;
using System.Utilities;

table 403 "Change Log Setup (Table)"
{
    Caption = 'Change Log Setup (Table)';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table No."; Integer)
        {
            Caption = 'Table No.';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(2; "Table Caption"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table),
                                                                           "Object ID" = field("Table No.")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
        field(3; "Log Insertion"; Option)
        {
            Caption = 'Log Insertion';
            OptionCaption = ' ,Some Fields,All Fields';
            OptionMembers = " ","Some Fields","All Fields";

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if (xRec."Log Insertion" = xRec."Log Insertion"::"Some Fields") and (xRec."Log Insertion" <> "Log Insertion") then
                    if ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(
                           RemoveFieldSelectionQst, xRec.FieldCaption("Log Insertion"), xRec."Log Insertion"), true)
                    then
                        DelChangeLogFields(0);
            end;
        }
        field(4; "Log Modification"; Option)
        {
            Caption = 'Log Modification';
            OptionCaption = ' ,Some Fields,All Fields';
            OptionMembers = " ","Some Fields","All Fields";

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if (xRec."Log Modification" = xRec."Log Modification"::"Some Fields") and (xRec."Log Modification" <> "Log Modification") then
                    if ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(
                           RemoveFieldSelectionQst, xRec.FieldCaption("Log Modification"), xRec."Log Modification"), true)
                    then
                        DelChangeLogFields(1);
            end;
        }
        field(5; "Log Deletion"; Option)
        {
            Caption = 'Log Deletion';
            OptionCaption = ' ,Some Fields,All Fields';
            OptionMembers = " ","Some Fields","All Fields";

            trigger OnValidate()
            var
                ConfirmManagement: Codeunit "Confirm Management";
            begin
                if (xRec."Log Deletion" = xRec."Log Deletion"::"Some Fields") and (xRec."Log Deletion" <> "Log Deletion") then
                    if ConfirmManagement.GetResponseOrDefault(
                         StrSubstNo(
                           RemoveFieldSelectionQst, xRec.FieldCaption("Log Deletion"), xRec."Log Deletion"),
                         true)
                    then
                        DelChangeLogFields(2);
            end;
        }
        field(6; "Monitor Sensitive Field"; Boolean)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Table No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        RemoveFieldSelectionQst: Label 'You have changed the %1 field to no longer be %2. Do you want to remove the field selections?', Comment = '%1: Field caption, %2: The selected log action. Example: You have changed the Log Modification field to no longer be Some Fields';

    procedure DelChangeLogFields(InsModDel: Integer)
    var
        ChangeLogSetupField: Record "Change Log Setup (Field)";
    begin
        ChangeLogSetupField.SetRange("Table No.", "Table No.");
        case InsModDel of
            0:
                ChangeLogSetupField.SetRange("Log Insertion", true);
            1:
                ChangeLogSetupField.SetRange("Log Modification", true);
            2:
                ChangeLogSetupField.SetRange("Log Deletion", true);
        end;
        if ChangeLogSetupField.Find('-') then
            repeat
                case InsModDel of
                    0:
                        ChangeLogSetupField."Log Insertion" := false;
                    1:
                        ChangeLogSetupField."Log Modification" := false;
                    2:
                        ChangeLogSetupField."Log Deletion" := false;
                end;
                if ChangeLogSetupField."Log Insertion" or ChangeLogSetupField."Log Modification" or ChangeLogSetupField."Log Deletion" then
                    ChangeLogSetupField.Modify()
                else
                    ChangeLogSetupField.Delete();
            until ChangeLogSetupField.Next() = 0;
    end;
}
