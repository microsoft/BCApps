// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Reflection;
using System.Privacy;

pageextension 1758 "Data Classification Wiz. Ext." extends "Data Classification Wizard"
{
    layout
    {
        modify(ExportModeSelected)
        {
            trigger OnAfterValidate()
            begin
                if IsExportModeSelected() then begin
                    SetExpertModeSelected(false);
                    SetImportModeSelected(false);
                end;
                ShouldNextBeEnabled := ShouldEnableNext();
            end;
        }

        modify(ImportModeSelected)
        {
            trigger OnAfterValidate()
            begin
                if IsImportModeSelected() then begin
                    SetExpertModeSelected(false);
                    SetExportModeSelected(false);
                end;
                ShouldNextBeEnabled := ShouldEnableNext();
            end;
        }

        modify(ExpertModeSelected)
        {
            trigger OnAfterValidate()
            begin
                if IsExpertModeSelected() then begin
                    SetExportModeSelected(false);
                    SetImportModeSelected(false);
                end;
                ShouldNextBeEnabled := ShouldEnableNext();
            end;
        }
    }

    actions
    {
        addafter(ActionBack)
        {
            action(ActionNext)
            {
                ApplicationArea = All;
                Caption = 'Next';
                Enabled = ShouldNextBeEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    GoNext();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        ShouldNextBeEnabled := true;
    end;

    var
        StepValues: Option Welcome,"Choose Mode","Set Rules",Apply,Verify,"Verify Related Fields",Finish;
        ShouldNextBeEnabled: Boolean;

    local procedure GoNext()
    begin
        case GetStep() of
            StepValues::"Choose Mode":
                ChooseModeStep();
            StepValues::Apply:
                ApplyStep();
            StepValues::"Set Rules":
                SetRulesStep();
            else
                NextStep(false);
        end;

        ShouldNextBeEnabled := IsNextEnabled();
    end;

    local procedure ChooseModeStep()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
        DataClassifImportExport: Codeunit "Data Classif. Import/Export";
    begin
        if IsImportModeSelected() then begin
            DataClassifImportExport.ImportExcelSheet();
            SetStepToFinishAndResetControls();
        end;
        if IsExportModeSelected() then begin
            DataClassifImportExport.ExportToExcelSheet();
            SetStepToFinishAndResetControls();
        end;
        if IsExpertModeSelected() then begin
            DataSensitivity.SetRange("Company Name", CompanyName);
            if DataSensitivity.IsEmpty() then
                DataClassificationMgt.PopulateDataSensitivityTable();

            NextStep(false);
        end;
    end;

    local procedure SetStepToFinishAndResetControls()
    begin
        SetStep(StepValues::Finish);
        ResetControls();
    end;

    local procedure ApplyStep()
    var
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataClassificationMgt.SetDefaultDataSensitivity(Rec);
        Rec.SetRange(Include, true);

        NextStep(false);
    end;

    local procedure SetRulesStep()
    var
        DataSensitivity: Record "Data Sensitivity";
        DataClassificationMgt: Codeunit "Data Classification Mgt.";
    begin
        DataSensitivity.SetRange("Company Name", CompanyName);
        DataSensitivity.SetRange("Data Sensitivity", DataSensitivity."Data Sensitivity"::Unclassified);
        DataSensitivity.SetFilter("Table No", GetTableNoFilterForTablesWhoseNameContains('Entry'));
        DataClassificationMgt.SetSensitivities(DataSensitivity, GetLedgerEntriesDefaultClassification());
        DataSensitivity.SetFilter("Table No", GetTableNoFilterForTablesWhoseNameContains('Template'));
        DataClassificationMgt.SetSensitivities(DataSensitivity, GetTemplatesDefaultClassification());
        DataSensitivity.SetFilter("Table No", GetTableNoFilterForTablesWhoseNameContains('Setup'));
        DataClassificationMgt.SetSensitivities(DataSensitivity, GetSetupTablesDefaultClassification());

        NextStep(false);
    end;

    local procedure GetTableNoFilterForTablesWhoseNameContains(Name: Text): Text
    var
        "Field": Record "Field";
        RecRef: RecordRef;
    begin
        Field.SetRange(DataClassification, Field.DataClassification::CustomerContent);
        Field.SetFilter(ObsoleteState, '<>%1', Field.ObsoleteState::Removed);
        Field.SetFilter(TableName, StrSubstNo('*%1*', Name));

        RecRef.GetTable(Field);
        exit(GetFilterTextForFieldValuesInTable(RecRef, Field.FieldNo(TableNo)));
    end;

    local procedure GetFilterTextForFieldValuesInTable(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FilterText: Text;
    begin
        if RecRef.FindSet() then begin
            repeat
                FilterText := StrSubstNo('%1|%2', FilterText, RecRef.Field(FieldNo));
            until RecRef.Next() = 0;

            // remove the first vertical bar from the filter text
            FilterText := DelChr(FilterText, '<', '|');
        end;

        exit(FilterText);
    end;
}