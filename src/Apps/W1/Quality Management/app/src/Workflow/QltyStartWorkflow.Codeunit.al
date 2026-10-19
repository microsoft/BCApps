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

    /// <summary>
    /// Starts the inspection-created workflow event and publishes the corresponding external business event.
    /// </summary>
    /// <param name="QltyInspectionHeader">The newly created inspection.</param>
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

    /// <summary>
    /// Starts the inspection-finished workflow event and publishes the corresponding external business event.
    /// </summary>
    /// <param name="QltyInspectionHeader">The finished inspection.</param>
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

    /// <summary>
    /// Starts the inspection-reopened workflow event and publishes the corresponding external business event.
    /// </summary>
    /// <param name="QltyInspectionHeader">The reopened inspection.</param>
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

    /// <summary>
    /// Starts the inspection-changed workflow event with recursion throttling and publishes the external business event.
    /// </summary>
    /// <param name="QltyInspectionHeader">The current inspection state.</param>
    /// <param name="xQltyInspectionHeader">The previous inspection state.</param>
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

    /// <summary>
    /// Gets the interval used to suppress recursive inspection-changed workflow handling.
    /// </summary>
    /// <returns>The recursion throttle interval in milliseconds.</returns>
    local procedure RecursionThrottleMilliseconds(): Integer
    begin
        exit(5000);
    end;

    /// <summary>
    /// This action will occur when a new Quality Inspection has been created.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system identifier of the newly created inspection.</param>
    /// <param name="inspectionNo">The inspection number.</param>
    /// <param name="sourceRecordIdentifier">The source record identifier that triggered the inspection.</param>
    /// <param name="sourceDocumentNo">The source document number.</param>
    /// <param name="sourceItemNo">The source item number.</param>
    /// <param name="sourceVariantCode">The source variant code.</param>
    /// <param name="sourceLotNo">The source lot number.</param>
    /// <param name="sourceSerialNo">The source serial number.</param>
    /// <param name="resultCode">The current inspection result code.</param>
    [ExternalBusinessEvent('QualityInspectionCreated', 'Quality Inspection Created', 'This action will occur when a new Quality Inspection has been created.', EventCategory::QltyEventCategory, '1.0')]
    procedure OnInspectionCreated(InspectionIdentifier: Guid; InspectionNo: Code[20]; SourceRecordIdentifier: Guid; SourceDocumentNo: Code[20]; SourceItemNo: Code[20]; SourceVariantCode: Code[10]; SourceLotNo: Code[50]; SourceSerialNo: Code[50]; ResultCode: Code[20])
    begin
    end;

    /// <summary>
    /// This action will occur when a Quality Inspection has changed to the finished state.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system identifier of the inspection.</param>
    /// <param name="inspectionNo">The inspection number.</param>
    /// <param name="sourceRecordIdentifier">The source record identifier.</param>
    /// <param name="sourceDocumentNo">The source document number.</param>
    /// <param name="sourceItemNo">The source item number.</param>
    /// <param name="sourceVariantCode">The source variant code.</param>
    /// <param name="sourceLotNo">The source lot number.</param>
    /// <param name="sourceSerialNo">The source serial number.</param>
    /// <param name="resultCode">The current inspection result code.</param>
    [ExternalBusinessEvent('QualityInspectionFinished', 'Quality Inspection Finished', 'This action will occur when a Quality Inspection has changed to the finished state.', EventCategory::QltyEventCategory, '1.0')]
    procedure OnInspectionFinished(InspectionIdentifier: Guid; InspectionNo: Code[20]; SourceRecordIdentifier: Guid; SourceDocumentNo: Code[20]; SourceItemNo: Code[20]; SourceVariantCode: Code[10]; SourceLotNo: Code[50]; SourceSerialNo: Code[50]; ResultCode: Code[20])
    begin
    end;

    /// <summary>
    /// This action will occur when a Quality Inspection has been re-opened.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system identifier of the inspection.</param>
    /// <param name="inspectionNo">The inspection number.</param>
    /// <param name="sourceRecordIdentifier">The source record identifier.</param>
    /// <param name="sourceDocumentNo">The source document number.</param>
    /// <param name="sourceItemNo">The source item number.</param>
    /// <param name="sourceVariantCode">The source variant code.</param>
    /// <param name="sourceLotNo">The source lot number.</param>
    /// <param name="sourceSerialNo">The source serial number.</param>
    /// <param name="resultCode">The current inspection result code.</param>
    [ExternalBusinessEvent('QualityInspectionReOpened', 'Quality Inspection Re-Opened', 'This action will occur when a Quality Inspection has been re-opened.', EventCategory::QltyEventCategory, '1.0')]
    procedure OnInspectionReOpened(InspectionIdentifier: Guid; InspectionNo: Code[20]; SourceRecordIdentifier: Guid; SourceDocumentNo: Code[20]; SourceItemNo: Code[20]; SourceVariantCode: Code[10]; SourceLotNo: Code[50]; SourceSerialNo: Code[50]; ResultCode: Code[20])
    begin
    end;

    /// <summary>
    /// This action will occur when a Quality Inspection has changed.
    /// This is exposed with ExternalBusinessEvent and intended to be used in PowerAutomate
    /// </summary>
    /// <param name="inspectionIdentifier">The system identifier of the inspection.</param>
    /// <param name="inspectionNo">The inspection number.</param>
    /// <param name="sourceRecordIdentifier">The source record identifier.</param>
    /// <param name="sourceDocumentNo">The source document number.</param>
    /// <param name="sourceItemNo">The source item number.</param>
    /// <param name="sourceVariantCode">The source variant code.</param>
    /// <param name="sourceLotNo">The source lot number.</param>
    /// <param name="sourceSerialNo">The source serial number.</param>
    /// <param name="resultCode">The current inspection result code.</param>
    [ExternalBusinessEvent('QualityInspectionChanged', 'Quality Inspection Changed', 'This action will occur when a Quality Inspection has changed.', EventCategory::QltyEventCategory, '1.0')]
    procedure OnInspectionChanged(InspectionIdentifier: Guid; InspectionNo: Code[20]; SourceRecordIdentifier: Guid; SourceDocumentNo: Code[20]; SourceItemNo: Code[20]; SourceVariantCode: Code[10]; SourceLotNo: Code[50]; SourceSerialNo: Code[50]; ResultCode: Code[20])
    begin
    end;
}
