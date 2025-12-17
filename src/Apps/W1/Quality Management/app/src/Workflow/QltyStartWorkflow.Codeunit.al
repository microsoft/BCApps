// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.QualityManagement.Utilities;
using System.Automation;
using System.Environment.Configuration;
using System.Security.User;

/// <summary>
/// This codeunit is intended to help with starting a Business Central workflow.
/// </summary>
codeunit 20426 "Qlty. Start Workflow"
{
    Permissions =
        tabledata "Qlty. Management Setup" = r,
        tabledata "Qlty. Inspection Test Header" = rimd,
        tabledata "Qlty. Inspection Test Line" = rimd,
        tabledata "Workflow Step Instance" = r,
        tabledata "Employee" = r,
        tabledata "User Setup" = r,
        tabledata "Approval Entry" = r,
        tabledata "Notification Entry" = r,
        tabledata "Salesperson/Purchaser" = r,
        tabledata "Workflow Step Argument" = r;

    var
        WorkflowManagement: Codeunit "Workflow Management";
        QltyWorkflowSetup: Codeunit "Qlty. Workflow Setup";

    internal procedure StartWorkflowTestCreated(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetTestCreatedEvent(), QltyInspectionTestHeader);
    end;

    internal procedure StartWorkflowTestFinished(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetTestFinishedEvent(), QltyInspectionTestHeader);
    end;

    internal procedure StartWorkflowTestReopens(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetTestReopensEvent(), QltyInspectionTestHeader);
    end;

    internal procedure StartWorkflowTestChanged(var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; xQltyInspectionTestHeader: Record "Qlty. Inspection Test Header")
    var
        RecursionDetectionQltySessionHelper: Codeunit "Qlty. Session Helper";
        Temp: Text;
        TestDateTime: DateTime;
    begin
        if QltyInspectionTestHeader.IsTemporary() then
            exit;

        Temp := RecursionDetectionQltySessionHelper.GetSessionValue('StartWorkflowTestChanged-Record');
        if Temp <> '' then
            if Temp = QltyInspectionTestHeader."No." then begin
                Temp := RecursionDetectionQltySessionHelper.GetSessionValue('StartWorkflowTestChanged-Time');
                if Temp <> '' then
                    if Evaluate(TestDateTime, Temp) then
                        if (CurrentDateTime() - TestDateTime) < 5000 then begin
                            RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Time', '');
                            RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Record', '');
                            exit;
                        end;
            end;

        Temp := Format(CurrentDateTime());
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Record', QltyInspectionTestHeader."No.");
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Time', Temp);
        WorkflowManagement.HandleEventWithxRec(CopyStr(QltyWorkflowSetup.GetTestHasChangedEvent(), 1, 128), QltyInspectionTestHeader, xQltyInspectionTestHeader);
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Time', '');
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Record', '');
    end;
}
