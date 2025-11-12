// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;
using System.Telemetry;

report 26 "Copy Account Schedule"
{
    Caption = 'Copy Rows';
    ProcessingOnly = true;

    dataset
    {
        dataitem(SourceAccScheduleName; "Acc. Schedule Name")
        {
            DataItemTableView = sorting(Name) order(ascending);

            trigger OnAfterGetRecord()
            var
                SourceAccScheduleLine: Record "Acc. Schedule Line";
                AccScheduleName: Record "Acc. Schedule Name";
            begin
                AccScheduleName.Get(CopySourceAccScheduleName);
                CreateNewAccountScheduleName(NewAccScheduleName, AccScheduleName);

                SourceAccScheduleLine.SetRange("Schedule Name", AccScheduleName.Name);
                if SourceAccScheduleLine.FindSet() then
                    repeat
                        CreateNewAccountScheduleLine(NewAccScheduleName, SourceAccScheduleLine);
                    until SourceAccScheduleLine.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                AssertNewAccountScheduleNameNotEmpty();
                AssertNewAccountScheduleNameNotExisting();
                AssertSourceAccountScheduleNameNotEmpty();
                AssertSourceAccountScheduleNameExists(SourceAccScheduleName);
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
                    field(NewAccountScheduleName; NewAccScheduleName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'New Rows Definition Name';
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the new rows definition after copying.';
                    }
                    field(SourceAccountScheduleName; CopySourceAccScheduleName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Rows Definition Name';
                        Enabled = false;
                        NotBlank = true;
                        ToolTip = 'Specifies the name of the existing rows definition to copy from.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            AssertSourceAccountScheduleNameOnlyOne(SourceAccScheduleName);

            if SourceAccScheduleName.FindFirst() then
                CopySourceAccScheduleName := SourceAccScheduleName.Name;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(CopySuccessMsg);
    end;

    var
        NewAccScheduleName: Code[10];
        CopySuccessMsg: Label 'The new rows definition has been created successfully.';
        MissingSourceErr: Label 'Could not find a rows definition with the specified name to copy from.';
        NewNameExistsErr: Label 'The new rows definition already exists.';
        NewNameMissingErr: Label 'You must specify a name for the new rows definition.';
        CopySourceAccScheduleName: Code[10];
        CopySourceNameMissingErr: Label 'You must specify a valid name for the source rows definition to copy from.';
        MultipleSourcesErr: Label 'You can only copy one rows definition at a time.';
        CopyEventTxt: Label 'Financial Report Row Definition copied: %1', Comment = '%1 = rows definition name', Locked = true;

    procedure GetNewAccountScheduleName(): Code[10]
    begin
        exit(NewAccScheduleName);
    end;

    local procedure AssertNewAccountScheduleNameNotEmpty()
    begin
        if IsEmptyName(NewAccScheduleName) then
            Error(NewNameMissingErr);
    end;

    local procedure AssertNewAccountScheduleNameNotExisting()
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if AccScheduleName.Get(NewAccScheduleName) then
            Error(NewNameExistsErr);
    end;

    local procedure CreateNewAccountScheduleName(NewName: Code[10]; FromAccScheduleName: Record "Acc. Schedule Name")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        if AccScheduleName.Get(NewName) then
            exit;

        AccScheduleName.Init();
        AccScheduleName.TransferFields(FromAccScheduleName);
        AccScheduleName.Name := NewName;
        AccScheduleName.Insert();

        LogUsageTelemetry(FromAccScheduleName.Name, NewName);
    end;

    local procedure CreateNewAccountScheduleLine(NewName: Code[10]; FromAccScheduleLine: Record "Acc. Schedule Line")
    var
        AccScheduleLine: Record "Acc. Schedule Line";
    begin
        if AccScheduleLine.Get(NewName, FromAccScheduleLine."Line No.") then
            exit;

        AccScheduleLine.Init();
        AccScheduleLine.TransferFields(FromAccScheduleLine);
        AccScheduleLine."Schedule Name" := NewName;
        AccScheduleLine.Insert();
    end;

    local procedure IsEmptyName(ScheduleName: Code[10]) IsEmpty: Boolean
    begin
        IsEmpty := ScheduleName = '';
    end;

    local procedure AssertSourceAccountScheduleNameNotEmpty()
    begin
        if IsEmptyName(CopySourceAccScheduleName) then
            Error(CopySourceNameMissingErr);
    end;

    local procedure AssertSourceAccountScheduleNameExists(FromAccScheduleName: Record "Acc. Schedule Name")
    begin
        if not FromAccScheduleName.Get(CopySourceAccScheduleName) then
            Error(MissingSourceErr);
    end;

    local procedure AssertSourceAccountScheduleNameOnlyOne(var FromAccScheduleName: Record "Acc. Schedule Name")
    var
        AccScheduleName: Record "Acc. Schedule Name";
    begin
        AccScheduleName.CopyFilters(FromAccScheduleName);

        if AccScheduleName.Count > 1 then
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
        TelemetryDimensions.Add('SourceRowDefinitionCode', SourceCode);
        TelemetryDimensions.Add('NewRowDefinitionCode', NewCode);
        FeatureTelemetry.LogUsage('0000OKV', 'Financial Report', StrSubstNo(CopyEventTxt, SourceCode), TelemetryDimensions);
    end;
}

