// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Workflow;

using Microsoft.CRM.Team;
using Microsoft.HumanResources.Employee;
using Microsoft.QualityManagement.Document;
using System.Automation;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.User;

/// <summary>
/// Functions to handle and integrate with Business Central's approval mechanism.
/// </summary>
codeunit 20425 "Qlty. Workflow Approvals"
{
    Permissions =
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
        ActionApprovedTxt: Label 'request has been approved and will move to the next step.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnRejectApprovalRequest', '', true, true)]
    local procedure RunWorkflowOnRejectTimeCardApproval(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(QltyWorkflowSetup.GetInspectionRejectEventTok(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnDelegateApprovalRequest', '', true, true)]
    local procedure RunWorkflowOnDelegateTimeCardApproval(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(QltyWorkflowSetup.GetInspectionDelegateEventTok(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnApproveApprovalRequest', '', true, true)]
    local procedure HandleOnApproveTheApprovalRequestOnApproveTimeCardApproval(var ApprovalEntry: Record "Approval Entry")
    begin
        WorkflowManagement.HandleEventOnKnownWorkflowInstance(QltyWorkflowSetup.GetInspectionApproveEventTok(), ApprovalEntry, ApprovalEntry."Workflow Step Instance ID");
    end;

    /// <summary>
    /// Populates the Salesperson/Purchaser Code field on approval entries for Quality Inspections.
    /// This field is required by Business Central's approval system to function correctly.
    /// 
    /// The procedure attempts to find the Salesperson/Purchaser Code in this order:
    /// 1. From User Setup for the Assigned User ID
    /// 2. From Employee record for the Assigned User ID
    /// 3. From Salesperson/Purchaser record matching the Assigned User ID
    /// 
    /// This subscriber is triggered during the approval entry creation process.
    /// </summary>
    /// <param name="RecRef">The record reference being processed (must be Quality Inspection Header)</param>
    /// <param name="ApprovalEntryArgument">The approval entry being populated with document information</param>
    /// <param name="WorkflowStepInstance">The workflow step instance triggering this action</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Approvals Mgmt.", 'OnPopulateApprovalEntryArgument', '', true, true)]
    local procedure HandleOnPopulateApprovalEntryArgument(var RecRef: RecordRef; var ApprovalEntryArgument: Record "Approval Entry"; WorkflowStepInstance: Record "Workflow Step Instance")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        Employee: Record "Employee";
        UserSetup: Record "User Setup";
        SSalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        if RecRef.Number() <> Database::"Qlty. Inspection Header" then
            exit;

        RecRef.SetTable(QltyInspectionHeader);
        ApprovalEntryArgument."Document Type" := "Approval Document Type"::"Quality Inspection";
        ApprovalEntryArgument."Document No." := QltyInspectionHeader."No.";

        if ApprovalEntryArgument."Salespers./Purch. Code" = '' then
            if QltyInspectionHeader."Assigned User ID" <> '' then
                if UserSetup.Get(QltyInspectionHeader."Assigned User ID") then
                    ApprovalEntryArgument."Salespers./Purch. Code" := UserSetup."Salespers./Purch. Code";

        if (ApprovalEntryArgument."Salespers./Purch. Code" = '') and (QltyInspectionHeader."Assigned User ID" <> '') then
            if Employee.Get(QltyInspectionHeader."Assigned User ID") then
                if Employee."Salespers./Purch. Code" <> '' then
                    ApprovalEntryArgument."Salespers./Purch. Code" := Employee."Salespers./Purch. Code";

        if (ApprovalEntryArgument."Salespers./Purch. Code" = '') and (QltyInspectionHeader."Assigned User ID" <> '') then
            if SSalespersonPurchaser.Get(QltyInspectionHeader."Assigned User ID") then
                ApprovalEntryArgument."Salespers./Purch. Code" := SSalespersonPurchaser.Code;
    end;

    /// <summary>
    /// Provides document type and number for Quality Inspection records in notification contexts.
    /// Required for Business Central's workflow approval integration to correctly identify and display
    /// Quality Inspections in approval notifications and entries.
    /// 
    /// Handles both:
    /// - Quality Inspection Header: Returns table caption and "No." field
    /// - Quality Inspection Line: Returns header table caption and "Inspection No." field
    /// 
    /// Without this handler, Quality Inspections would not be properly recognized in the approval system.
    /// </summary>
    /// <param name="RecRef">The record reference to extract document information from</param>
    /// <param name="DocumentType">Output: The document type description (table caption)</param>
    /// <param name="DocumentNo">Output: The document number identifier</param>
    /// <param name="IsHandled">Output: Set to true if this handler processed the record</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Notification Management", 'OnGetDocumentTypeAndNumber', '', true, true)]
    local procedure HandleOnGetDocumentTypeAndNumber(var RecRef: RecordRef; var DocumentType: Text; var DocumentNo: Text; var IsHandled: Boolean)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
    begin
        if RecRef.IsTemporary() then
            exit;

        case RecRef.Number() of
            Database::"Qlty. Inspection Header":
                begin
                    DocumentType := QltyInspectionHeader.TableCaption();
                    DocumentNo := Format(RecRef.Field(QltyInspectionHeader.FieldNo("No.")).Value());
                    IsHandled := true;
                end;
            Database::"Qlty. Inspection Line":
                begin
                    DocumentType := QltyInspectionHeader.TableCaption();
                    DocumentNo := Format(RecRef.Field(QltyInspectionLine.FieldNo("Inspection No.")).Value());
                    IsHandled := true;
                end;
        end;
    end;

    /// <summary>
    /// Customizes the approval notification text for Quality Inspection approvals.
    /// Overrides the default notification message to provide clearer, more accurate terminology for Inspection approval status.
    /// 
    /// Without this customization, the default message would incorrectly state that the entire
    /// Inspection has been approved, when actually it's only the approval request that has been approved and the inspection will proceed to the next workflow step.
    /// 
    /// Only applies when notification type is Approval and document type is Quality Inspection with status Approved.
    /// </summary>
    /// <param name="NotificationEntry">The notification entry being processed</param>
    /// <param name="CustomText">Output: The customized notification text to display</param>
    /// <param name="IsHandled">Output: Set to true if this handler provided custom text</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Notification Management", 'OnBeforeGetActionTextFor', '', true, true)]
    local procedure HandleOnBeforeGetActionTextFor(var NotificationEntry: Record "Notification Entry"; var CustomText: Text; var IsHandled: Boolean)
    var
        ApprovalEntry: Record "Approval Entry";
        DataTypeManagement: Codeunit "Data Type Management";
        RecordToGetApprovalFor: RecordRef;
    begin
        if NotificationEntry.Type <> NotificationEntry.Type::Approval then
            exit;

        DataTypeManagement.GetRecordRef(NotificationEntry."Triggered By Record", RecordToGetApprovalFor);
        RecordToGetApprovalFor.SetTable(ApprovalEntry);
        if (ApprovalEntry."Document Type" = "Approval Document Type"::"Quality Inspection") and (ApprovalEntry.Status = ApprovalEntry.Status::Approved) then begin
            CustomText := ActionApprovedTxt;
            IsHandled := true;
        end;
    end;

    /// <summary>
    /// Releases (approves and finalizes) a Quality Inspection as part of workflow approval process.
    /// Required for workflow approval integration - 'Release' is equivalent to completing the Inspection.
    /// 
    /// When a workflow reaches the "Release Document" response step, this handler:
    /// 1. Validates the record is a Quality Inspection Header
    /// 2. Changes the inspection status to Finished
    /// 3. Persists the change
    /// 
    /// This represents the final approval action, marking the Inspection as complete and approved.
    /// </summary>
    /// <param name="RecRef">The record reference to be released (must be Quality Inspection Header)</param>
    /// <param name="Handled">Output: Set to true if this handler successfully released the document</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnReleaseDocument', '', true, true)]
    local procedure HandleOnReleaseDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        if RecRef.IsTemporary() then
            exit;

        if RecRef.Number() <> Database::"Qlty. Inspection Header" then
            exit;

        RecRef.SetTable(QltyInspectionHeader);
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Finished);
        QltyInspectionHeader.Modify();

        Handled := true;
    end;

    /// <summary>
    /// Reopens a Quality Inspection as part of workflow approval process.
    /// Required for workflow approval integration - 'Open Document' reverses a release or rejection.
    /// 
    /// When a workflow reaches the "Open Document" response step (typically after rejection or
    /// when needing to restart), this handler:
    /// 1. Validates the record is a Quality Inspection Header
    /// 2. Changes the inspection status to Open
    /// 3. Persists the change
    /// 
    /// This allows the Inspection to be modified and resubmitted for approval.
    /// </summary>
    /// <param name="RecRef">The record reference to be opened (must be Quality Inspection Header)</param>
    /// <param name="Handled">Output: Set to true if this handler successfully opened the document</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Workflow Response Handling", 'OnOpenDocument', '', true, true)]
    local procedure HandleOnOpenDocument(RecRef: RecordRef; var Handled: Boolean)
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
    begin
        if RecRef.IsTemporary() then
            exit;

        if RecRef.Number() <> Database::"Qlty. Inspection Header" then
            exit;

        RecRef.SetTable(QltyInspectionHeader);
        QltyInspectionHeader.Validate(Status, QltyInspectionHeader.Status::Open);
        QltyInspectionHeader.Modify();

        Handled := true;
    end;
}
