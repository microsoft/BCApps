// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;
using System.Telemetry;

report 960 "Copy Column Layout"
{
    Caption = 'Copy Column Layout';
    ProcessingOnly = true;

    dataset
    {
        dataitem(SourceColumnLayoutName; "Column Layout Name")
        {
            DataItemTableView = sorting(Name) order(ascending);

            trigger OnAfterGetRecord()
            var
                SourceColumnLayout: Record "Column Layout";
                ColumnLayoutName: Record "Column Layout Name";
            begin
                ColumnLayoutName.Get(CopySourceColumnLayoutName);
                CreateNewColumnLayoutName(NewColumnLayoutName, ColumnLayoutName);

                SourceColumnLayout.SetRange("Column Layout Name", ColumnLayoutName.Name);
                if SourceColumnLayout.FindSet() then
                    repeat
                        CreateNewColumnLayout(NewColumnLayoutName, SourceColumnLayout);
                    until SourceColumnLayout.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                AssertNewColumnLayoutNameNotEmpty();
                AssertNewColumnLayoutNameNotExisting();
                AssertSourceColumnLayoutNameNotEmpty();
                AssertSourceColumnLayoutNameExists(SourceColumnLayoutName);
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(NewColumnLayout; NewColumnLayoutName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Column Layout Name';
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the new column layout after copying.';
                    }
                    field(SourceColumnLayout; CopySourceColumnLayoutName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Column Layout Name';
                        Enabled = false;
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the existing column layout to copy from.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        begin
            AssertSourceColumnLayoutNameOnlyOne(SourceColumnLayoutName);

            if SourceColumnLayoutName.FindFirst() then
                CopySourceColumnLayoutName := SourceColumnLayoutName.Name;
        end;
    }


    trigger OnPostReport()
    begin
        Message(CopySuccessMsg);
    end;

    var
        NewColumnLayoutName: Code[10];
        CopySuccessMsg: Label 'The new column layout has been created.';
        MissingSourceErr: Label 'Could not find a column layout with the specified name.';
        NewNameExistsErr: Label 'A column layout with the specified name already exists. The names of column layouts must be unique.';
        NewNameMissingErr: Label 'You must specify a name for the new column layout.';
        CopySourceColumnLayoutName: Code[10];
        CopySourceNameMissingErr: Label 'You must specify a valid name for the column layout that you want to copy.';
        MultipleSourcesErr: Label 'You can only copy one column layout at a time.';
        CopyEventTxt: Label 'Financial Report Column Definition copied: %1', Comment = '%1 = column layout name', Locked = true;

    procedure GetNewColumnLayoutName(): Code[10]
    begin
        exit(NewColumnLayoutName);
    end;

    local procedure AssertNewColumnLayoutNameNotEmpty()
    begin
        if IsEmptyName(NewColumnLayoutName) then
            Error(NewNameMissingErr);
    end;

    local procedure AssertNewColumnLayoutNameNotExisting()
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        if ColumnLayoutName.Get(NewColumnLayoutName) then
            Error(NewNameExistsErr);
    end;

    local procedure CreateNewColumnLayoutName(NewName: Code[10]; FromColumnLayoutName: Record "Column Layout Name")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        if ColumnLayoutName.Get(NewName) then
            exit;

        ColumnLayoutName.Init();
        ColumnLayoutName.TransferFields(FromColumnLayoutName);
        ColumnLayoutName.Name := NewName;
        ColumnLayoutName.Insert();

        LogUsageTelemetry(FromColumnLayoutName.Name, NewName);
    end;

    local procedure CreateNewColumnLayout(NewName: Code[10]; FromColumnLayout: Record "Column Layout")
    var
        ColumnLayout: Record "Column Layout";
    begin
        if ColumnLayout.Get(NewName, FromColumnLayout."Line No.") then
            exit;

        ColumnLayout.Init();
        ColumnLayout.TransferFields(FromColumnLayout);
        ColumnLayout."Column Layout Name" := NewName;
        ColumnLayout.Insert();
    end;

    local procedure IsEmptyName(ColumnLayoutName: Code[10]) IsEmpty: Boolean
    begin
        IsEmpty := ColumnLayoutName = '';
    end;

    local procedure AssertSourceColumnLayoutNameNotEmpty()
    begin
        if IsEmptyName(CopySourceColumnLayoutName) then
            Error(CopySourceNameMissingErr);
    end;

    local procedure AssertSourceColumnLayoutNameExists(FromColumnLayoutName: Record "Column Layout Name")
    begin
        if not FromColumnLayoutName.Get(CopySourceColumnLayoutName) then
            Error(MissingSourceErr);
    end;

    local procedure AssertSourceColumnLayoutNameOnlyOne(var FromColumnLayoutName: Record "Column Layout Name")
    var
        ColumnLayoutName: Record "Column Layout Name";
    begin
        ColumnLayoutName.CopyFilters(FromColumnLayoutName);

        if ColumnLayoutName.Count > 1 then
            Error(MultipleSourcesErr);
    end;

    local procedure LogUsageTelemetry(SourceCode: Code[10]; NewCode: Code[10])
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('ReportId', Format(CurrReport.ObjectId(false), 0, 9));
        TelemetryDimensions.Add('ReportName', CurrReport.ObjectId(true));
        TelemetryDimensions.Add('UseRequestPage', Format(CurrReport.UseRequestPage()));
        TelemetryDimensions.Add('SourceColDefinitionCode', SourceCode);
        TelemetryDimensions.Add('NewColDefinitionCode', NewCode);
        FeatureTelemetry.LogUsage('0000OKW', 'Financial Report', StrSubstNo(CopyEventTxt, SourceCode), TelemetryDimensions);
    end;
}
