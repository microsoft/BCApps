// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

codeunit 6968 "Expense Audit Subscribers"
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    [EventSubscriber(ObjectType::Table, Database::"Expense Agent Setup", OnAfterValidateEvent, 'Enable Agent', false, false)]
    local procedure OnAfterValidateEnableAgent(var Rec: Record "Expense Agent Setup"; xRec: Record "Expense Agent Setup")
    begin
        if Rec."Enable Agent" = xRec."Enable Agent" then
            exit;

        Session.LogMessage('0000TN8', StrSubstNo(AgentSetupTelemetryMsg, Rec."Enable Agent"), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(AgentSetupAuditMsg, Rec."Enable Agent", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 5, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Agent Setup", OnAfterValidateEvent, 'Email Account ID', false, false)]
    local procedure OnAfterValidateEmailAccountId(var Rec: Record "Expense Agent Setup"; xRec: Record "Expense Agent Setup")
    begin
        if (Rec."Email Account ID" = xRec."Email Account ID") and (Rec."Email Connector" = xRec."Email Connector") then
            exit;

        Session.LogMessage('0000TN9', EmailAccountTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(EmailAccountAuditMsg, Rec."Email Account ID", Rec."Email Connector", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 5, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Agent Access Control", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertAccessControl(var Rec: Record "Expense Agent Access Control")
    begin
        Session.LogMessage('0000TNA', StrSubstNo(AccessControlOperationTelemetryMsg, InsertedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(AccessControlOperationAuditMsg, Rec."User Security ID", InsertedTok, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::Authorization, 2, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Agent Access Control", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyAccessControl(var Rec: Record "Expense Agent Access Control")
    begin
        Session.LogMessage('0000TNB', StrSubstNo(AccessControlOperationTelemetryMsg, ModifiedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(AccessControlOperationAuditMsg, Rec."User Security ID", ModifiedTok, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::Authorization, 2, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Agent Access Control", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteAccessControl(var Rec: Record "Expense Agent Access Control")
    begin
        Session.LogMessage('0000TNC', StrSubstNo(AccessControlOperationTelemetryMsg, DeletedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(AccessControlOperationAuditMsg, Rec."User Security ID", DeletedTok, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::Authorization, 2, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Agent Access Control", OnAfterRenameEvent, '', false, false)]
    local procedure OnAfterRenameAccessControl(var Rec: Record "Expense Agent Access Control"; var xRec: Record "Expense Agent Access Control")
    begin
        Session.LogMessage('0000TND', StrSubstNo(AccessControlOperationTelemetryMsg, RenamedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(AccessControlRenameAuditMsg, xRec."User Security ID", Rec."User Security ID", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::Authorization, 2, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Approval Setup", OnAfterInsertEvent, '', false, false)]
    local procedure OnAfterInsertApprovalSetup(var Rec: Record "Expense Approval Setup")
    begin
        Session.LogMessage('0000TNE', StrSubstNo(ApprovalSetupOperationTelemetryMsg, InsertedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(ApprovalSetupOperationAuditMsg, Rec."Expense User No.", InsertedTok, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 5, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Approval Setup", OnAfterModifyEvent, '', false, false)]
    local procedure OnAfterModifyApprovalSetup(var Rec: Record "Expense Approval Setup")
    begin
        Session.LogMessage('0000TNF', StrSubstNo(ApprovalSetupOperationTelemetryMsg, ModifiedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(ApprovalSetupOperationAuditMsg, Rec."Expense User No.", ModifiedTok, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 5, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Approval Setup", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteApprovalSetup(var Rec: Record "Expense Approval Setup")
    begin
        Session.LogMessage('0000TNG', StrSubstNo(ApprovalSetupOperationTelemetryMsg, DeletedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(ApprovalSetupOperationAuditMsg, Rec."Expense User No.", DeletedTok, UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 5, 0);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Expense Approval Setup", OnAfterRenameEvent, '', false, false)]
    local procedure OnAfterRenameApprovalSetup(var Rec: Record "Expense Approval Setup"; var xRec: Record "Expense Approval Setup")
    begin
        Session.LogMessage('0000TNH', StrSubstNo(ApprovalSetupOperationTelemetryMsg, RenamedTok), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAgentTelemetryCategoryTok);
        Session.LogAuditMessage(StrSubstNo(ApprovalSetupRenameAuditMsg, xRec."Expense User No.", Rec."Expense User No.", UserSecurityId()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 5, 0);
    end;

    internal procedure TelemetryCategory(): Text
    begin
        exit(ExpenseAgentTelemetryCategoryTok);
    end;

    var
        AgentSetupAuditMsg: Label 'Expense Agent enabled status was changed to "%1" by UserSecurityId %2.', Locked = true;
        AgentSetupTelemetryMsg: Label 'Expense Agent enabled status was changed to "%1".', Locked = true;
        EmailAccountAuditMsg: Label 'Expense Agent email account was changed to Account ID "%1" with Connector "%2" by UserSecurityId %3.', Locked = true;
        EmailAccountTelemetryMsg: Label 'Expense Agent email account was changed.', Locked = true;
        AccessControlOperationAuditMsg: Label 'Expense Agent Access Control record for UserSecurityId %1 was %2 by UserSecurityId %3.', Locked = true;
        AccessControlRenameAuditMsg: Label 'Expense Agent Access Control record was renamed from UserSecurityId %1 to UserSecurityId %2 by UserSecurityId %3.', Locked = true;
        AccessControlOperationTelemetryMsg: Label 'Expense Agent Access Control record was %1.', Locked = true;
        ApprovalSetupOperationAuditMsg: Label 'Expense Approval Setup record for Expense User No. %1 was %2 by UserSecurityId %3.', Locked = true;
        ApprovalSetupRenameAuditMsg: Label 'Expense Approval Setup record was renamed from Expense User No. %1 to Expense User No. %2 by UserSecurityId %3.', Locked = true;
        ApprovalSetupOperationTelemetryMsg: Label 'Expense Approval Setup record was %1.', Locked = true;
        InsertedTok: Label 'inserted', Locked = true;
        ModifiedTok: Label 'modified', Locked = true;
        DeletedTok: Label 'deleted', Locked = true;
        RenamedTok: Label 'renamed', Locked = true;
        ExpenseAgentTelemetryCategoryTok: Label 'AL Expense Agent', Locked = true;

}
