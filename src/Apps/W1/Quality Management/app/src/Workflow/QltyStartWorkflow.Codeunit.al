// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Setup;
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

    internal procedure StartWorkflowInspectionCreated(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetInspectionCreatedEvent(), QltyInspectionHeader);
    end;

    internal procedure StartWorkflowInspectionFinished(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetInspectionFinishedEvent(), QltyInspectionHeader);
    end;

    internal procedure StartWorkflowInspectionReopens(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetInspectionReopenedEvent(), QltyInspectionHeader);
    end;

    internal procedure StartWorkflowInspectionChanged(var QltyInspectionHeader: Record "Qlty. Inspection Header"; xQltyInspectionHeader: Record "Qlty. Inspection Header")
    var
        RecursionDetectionQltySessionHelper: Codeunit "Qlty. Session Helper";
        Temp: Text;
        TestDateTime: DateTime;
    begin
        if QltyInspectionHeader.IsTemporary() then
            exit;

        Temp := RecursionDetectionQltySessionHelper.GetSessionValue('StartWorkflowInspectionChanged-Record');
        if Temp <> '' then
            if Temp = QltyInspectionHeader."No." then begin
                Temp := RecursionDetectionQltySessionHelper.GetSessionValue('StartWorkflowInspectionChanged-Time');
                if Temp <> '' then
                    if Evaluate(TestDateTime, Temp) then
                        if (CurrentDateTime() - TestDateTime) < RecursionThrottleMilliseconds() then begin
                            RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowInspectionChanged-Time', '');
                            RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowInspectionChanged-Record', '');
                            exit;
                        end;
            end;

        Temp := Format(CurrentDateTime());
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowInspectionChanged-Record', QltyInspectionHeader."No.");
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowInspectionChanged-Time', Temp);
        WorkflowManagement.HandleEventWithxRec(CopyStr(QltyWorkflowSetup.GetInspectionHasChangedEvent(), 1, 128), QltyInspectionHeader, xQltyInspectionHeader);
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowInspectionChanged-Time', '');
        RecursionDetectionQltySessionHelper.SetSessionValue('StartWorkflowInspectionChanged-Record', '');
    end;

    local procedure RecursionThrottleMilliseconds(): Integer
    begin
        exit(5000);
    end;
}
