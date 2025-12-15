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
        tabledata "Qlty. Inspection Header" = rimd,
        tabledata "Qlty. Inspection Line" = rimd,
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

    internal procedure StartWorkflowTestCreated(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        if not QltyWorkflowSetup.IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetTestCreatedEvent(), QltyInspectionHeader);
    end;

    internal procedure StartWorkflowTestFinished(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        if not QltyWorkflowSetup.IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetTestFinishedEvent(), QltyInspectionHeader);
    end;

    internal procedure StartWorkflowTestReopens(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        if not QltyWorkflowSetup.IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetTestReopensEvent(), QltyInspectionHeader);
    end;

    internal procedure StartWorkflowTestChanged(var QltyInspectionHeader: Record "Qlty. Inspection Header"; xQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        RecursionDetectionQltySessionHelper: Codeunit "Qlty. Session Helper";
        Temp: Text;
        TestDateTime: DateTime;
    begin
        if QltyInspectionHeader.IsTemporary() then
            exit;

        if not QltyWorkflowSetup.IsWorkflowIntegrationEnabledAndSufficientPermission() then
            exit;

        Temp := RecursionDetectionQltySessionHelper.GetSessionValue('StartWorkflowTestChanged-Record');
        if Temp <> '' then
            if Temp = QltyInspectionHeader."No." then begin
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
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Record', QltyInspectionHeader."No.");
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Time', Temp);
        WorkflowManagement.HandleEventWithxRec(CopyStr(QltyWorkflowSetup.GetTestHasChangedEvent(), 1, 128), QltyInspectionHeader, xQltyInspectionHeader);
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Time', '');
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowTestChanged-Record', '');
    end;
}
