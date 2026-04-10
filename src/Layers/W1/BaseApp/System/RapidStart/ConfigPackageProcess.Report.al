namespace System.IO;

using System.Reflection;

report 8621 "Config. Package - Process"
{
    Caption = 'Config. Package - Process';
    ProcessingOnly = true;
    TransactionType = UpdateNoLocks;

    dataset
    {
        dataitem("Config. Package Table"; "Config. Package Table")
        {
            DataItemTableView = sorting("Package Code", "Table ID") order(ascending);

            trigger OnAfterGetRecord()
            var
                TempTransformationRule: Record "Transformation Rule" temporary;
                TempField: Record "Field" temporary;
            begin
                OnBeforeTextTransformation("Config. Package Table", TempField, TempTransformationRule);
                TempField.SetRange(TableNo, "Table ID");
                if TempField.FindSet() then
                    repeat
                        TempTransformationRule.Get(Format(TempField."No."));
                        ApplyTextTransformation("Config. Package Table", TempField."No.", TempTransformationRule);
                    until TempField.Next() = 0
                else
                    Message(StrSubstNo(ImplementProcessingLogicMsg, "Table ID"))
            end;
        }
    }

    requestpage
    {
        SaveValues = true;
        SourceTable = "Config. Package Table";

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        ImplementProcessingLogicMsg: Label 'Implement processing logic for Table %1 in Report 8621 - Config. Package - Process.', Comment = '%1 - a table Id.';

    procedure AddRuleForField(TableNo: Integer; FieldNo: Integer; TransformationType: Option; var TempField: Record "Field" temporary; var TempTransformationRule: Record "Transformation Rule" temporary)
    begin
        TempField.Init();
        TempField.TableNo := TableNo;
        TempField."No." := FieldNo;
        TempField.Insert();
        TempTransformationRule.Init();
        TempTransformationRule.Code := Format(TempField."No.");
        TempTransformationRule."Transformation Type" := Enum::"Transformation Rule Type".FromInteger(TransformationType);
        TempTransformationRule.Insert();
    end;

    local procedure ApplyTextTransformation(ConfigPackageTable: Record "Config. Package Table"; FieldNo: Integer; TransformationRule: Record "Transformation Rule")
    var
        ConfigPackageData: Record "Config. Package Data";
    begin
        if GetConfigPackageData(ConfigPackageData, ConfigPackageTable, FieldNo) then
            repeat
                ConfigPackageData.Value := CopyStr(TransformationRule.TransformText(ConfigPackageData.Value), 1, 250);
                ConfigPackageData.Modify();
            until ConfigPackageData.Next() = 0;
    end;

    local procedure GetConfigPackageData(var ConfigPackageData: Record "Config. Package Data"; ConfigPackageTable: Record "Config. Package Table"; FieldId: Integer): Boolean
    begin
        ConfigPackageData.SetRange("Package Code", ConfigPackageTable."Package Code");
        ConfigPackageData.SetRange("Table ID", ConfigPackageTable."Table ID");
        ConfigPackageData.SetRange("Field ID", FieldId);
        exit(ConfigPackageData.FindSet(true));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTextTransformation(ConfigPackageTable: Record "Config. Package Table"; var TempField: Record "Field" temporary; var TempTransformationRule: Record "Transformation Rule" temporary)
    begin
    end;
}

