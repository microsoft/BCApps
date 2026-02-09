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
using System.Integration;
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
        OnInspectionCreated(
            QltyInspectionHeader.SystemId,
            QltyInspectionHeader."No.",
            QltyInspectionHeader.GetReferenceRecordId(),
            QltyInspectionHeader."Source Document No.",
            QltyInspectionHeader."Source Item No.",
            QltyInspectionHeader."Source Variant Code",
            QltyInspectionHeader."Source Lot No.",
            QltyInspectionHeader."Source Serial No.",
            QltyInspectionHeader."Result Code");
    end;

    internal procedure StartWorkflowInspectionFinished(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetInspectionFinishedEvent(), QltyInspectionHeader);
        OnInspectionFinished(
            QltyInspectionHeader.SystemId,
            QltyInspectionHeader."No.",
            QltyInspectionHeader.GetReferenceRecordId(),
            QltyInspectionHeader."Source Document No.",
            QltyInspectionHeader."Source Item No.",
            QltyInspectionHeader."Source Variant Code",
            QltyInspectionHeader."Source Lot No.",
            QltyInspectionHeader."Source Serial No.",
            QltyInspectionHeader."Result Code");
    end;

    internal procedure StartWorkflowInspectionReopens(var QltyInspectionHeader: Record "Qlty. Inspection Header")
    begin
        WorkflowManagement.HandleEvent(QltyWorkflowSetup.GetInspectionReopenedEvent(), QltyInspectionHeader);
        OnInspectionReOpened(
                    QltyInspectionHeader.SystemId,
                    QltyInspectionHeader."No.",
                    QltyInspectionHeader.GetReferenceRecordId(),
                    QltyInspectionHeader."Source Document No.",
                    QltyInspectionHeader."Source Item No.",
                    QltyInspectionHeader."Source Variant Code",
                    QltyInspectionHeader."Source Lot No.",
                    QltyInspectionHeader."Source Serial No.",
                    QltyInspectionHeader."Result Code");
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

        OnInspectionChanged(
                    QltyInspectionHeader.SystemId,
                    QltyInspectionHeader."No.",
                    QltyInspectionHeader.GetReferenceRecordId(),
                    QltyInspectionHeader."Source Document No.",
                    QltyInspectionHeader."Source Item No.",
                    QltyInspectionHeader."Source Variant Code",
                    QltyInspectionHeader."Source Lot No.",
                    QltyInspectionHeader."Source Serial No.",
                    QltyInspectionHeader."Result Code");
    end;

    local procedure RecursionThrottleMilliseconds(): Integer
    begin
        exit(5000);
    end;

    /// <summary>
    /// This action will occur when a new Quality Inspection has been created.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system record id of the newly created test</param>
    /// <param name="inspectionNo">The test document no.</param>
    /// <param name="sourceRecordIdentifier">The source record id of the record that triggered the test</param>
    /// <param name="sourceDocumentNo">The source document no.</param>
    /// <param name="sourceItemNo">The source item no.</param>
    /// <param name="sourceVariantCode">The source variant code.</param>
    /// <param name="sourceLotNo">The source lot number.</param>
    /// <param name="sourceSerialNo">The source serial number.</param>
    /// <param name="resultCode">The current grade of the test</param>
    [ExternalBusinessEvent('QltyOnInspectionCreated', 'Quality Inspection Created', 'This action will occur when a new Quality Inspection has been created.', EventCategory::QltyEventCategory)]
    procedure OnInspectionCreated(inspectionIdentifier: guid; inspectionNo: code[20]; sourceRecordIdentifier: Guid; sourceDocumentNo: code[20]; sourceItemNo: Code[20]; sourceVariantCode: code[10]; sourceLotNo: Code[50]; sourceSerialNo: Code[50]; resultCode: Code[20])
    begin
    end;

    /// <summary>
    /// This action will occur when a Quality Inspection has changed to the finished state.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system ID of the quality inspection test</param>
    /// <param name="inspectionNo">The quality inspection test no.</param>
    /// <param name="sourceRecordIdentifier">The system ID of the source record</param>
    /// <param name="sourceDocumentNo">The source document no. from the test</param>
    /// <param name="sourceItemNo">The source item no. associated with the test</param>
    /// <param name="sourceVariantCode">If variants are used then the source variant on the test</param>
    /// <param name="sourceLotNo">The lot number associated with the test</param>
    /// <param name="sourceSerialNo">The serial number associated with the test</param>
    /// <param name="resultCode">The current grade of the test</param>
    [ExternalBusinessEvent('QltyOnInspectionFinished', 'Quality Inspection Finished', 'This action will occur when a Quality Inspection has changed to the finished state.', EventCategory::QltyEventCategory)]
    procedure OnInspectionFinished(inspectionIdentifier: guid; inspectionNo: code[20]; sourceRecordIdentifier: Guid; sourceDocumentNo: code[20]; sourceItemNo: Code[20]; sourceVariantCode: code[10]; sourceLotNo: Code[50]; sourceSerialNo: Code[50]; resultCode: Code[20])
    begin
    end;

    /// <summary>
    /// This action will occur when a Quality Inspection has been re-opened.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system ID of the quality inspection test</param>
    /// <param name="inspectionNo">The quality inspection test no.</param>
    /// <param name="sourceRecordIdentifier">The system ID of the source record</param>
    /// <param name="sourceDocumentNo">The source document no. from the test</param>
    /// <param name="sourceItemNo">The source item no. associated with the test</param>
    /// <param name="sourceVariantCode">If variants are used then the source variant on the test</param>
    /// <param name="sourceLotNo">The lot number associated with the test</param>
    /// <param name="sourceSerialNo">The serial number associated with the test</param>
    /// <param name="resultCode">The current grade of the test</param>
    [ExternalBusinessEvent('QltyOnInspectionReOpened', 'Quality Inspection Re-Opened', 'This action will occur when a Quality Inspection has been re-opened.', EventCategory::QltyEventCategory)]
    procedure OnInspectionReOpened(inspectionIdentifier: guid; inspectionNo: code[20]; sourceRecordIdentifier: Guid; sourceDocumentNo: code[20]; sourceItemNo: Code[20]; sourceVariantCode: code[10]; sourceLotNo: Code[50]; sourceSerialNo: Code[50]; resultCode: Code[20])
    begin
    end;

    /// <summary>
    /// This action will occur when a Quality Inspection has changed.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system ID of the quality inspection test</param>
    /// <param name="inspectionNo">The quality inspection test no.</param>
    /// <param name="sourceRecordIdentifier">The system ID of the source record</param>
    /// <param name="sourceDocumentNo">The source document no. from the test</param>
    /// <param name="sourceItemNo">The source item no. associated with the test</param>
    /// <param name="sourceVariantCode">If variants are used then the source variant on the test</param>
    /// <param name="sourceLotNo">The lot number associated with the test</param>
    /// <param name="sourceSerialNo">The serial number associated with the test</param>
    /// <param name="resultCode">The current grade of the test</param>
    [ExternalBusinessEvent('QltyOnTestChanged', 'Quality Inspection Changed', 'This action will occur when a Quality Inspection has changed.', EventCategory::QltyEventCategory)]
    procedure OnInspectionChanged(inspectionIdentifier: guid; inspectionNo: code[20]; sourceRecordIdentifier: Guid; sourceDocumentNo: code[20]; sourceItemNo: Code[20]; sourceVariantCode: code[10]; sourceLotNo: Code[50]; sourceSerialNo: Code[50]; resultCode: Code[20])
    begin
    end;
}
