// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

/// <summary>
/// Provides methods to log audit messages.
/// </summary>
codeunit 8714 "Audit Log"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        AuditLogImplementation: Codeunit "Audit Log Implementation";
        CallerModuleInfo: ModuleInfo;

    /// <summary>
    /// Logs a message to an audit account. Note, these logs are accessible to customers and will also be logged to a security audit account.
    /// </summary>
    /// <param name="SecurityAuditDescription">The description of the audit message.</param>
    /// <param name="SecurityAuditOperationResult">The result of the operation.</param>
    /// <param name="SecurityAuditCategory">The category of the audit message.</param>
    /// <param name="AuditMessageOperation">The operation of the audit message.</param>
    /// <param name="AuditMessageOperationResult">The result of the operation.</param>
    procedure LogAuditMessage(SecurityAuditDescription: Text; SecurityAuditOperationResult: SecurityOperationResult; SecurityAuditCategory: AuditCategory; AuditMessageOperation: Integer; AuditMessageOperationResult: Integer)
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        AuditLogImplementation.LogAuditMessage(SecurityAuditDescription, SecurityAuditOperationResult, SecurityAuditCategory, AuditMessageOperation, AuditMessageOperationResult, CallerModuleInfo);
    end;

    /// <summary>
    /// Logs a message to an audit account. Note, these logs are accessible to customers and will also be logged to a security audit account.
    /// </summary>
    /// <param name="SecurityAuditDescription">The description of the audit message.</param>
    /// <param name="SecurityAuditOperationResult">The result of the operation.</param>
    /// <param name="SecurityAuditCategory">The category of the audit message.</param>
    /// <param name="AuditMessageOperation">The operation of the audit message.</param>
    /// <param name="AuditMessageOperationResult">The result of the operation.</param>
    /// <param name="CustomDimensions">The custom dimensions to be logged.</param>
    procedure LogAuditMessage(SecurityAuditDescription: Text; SecurityAuditOperationResult: SecurityOperationResult; SecurityAuditCategory: AuditCategory; AuditMessageOperation: Integer; AuditMessageOperationResult: Integer; CustomDimensions: Dictionary of [Text, Text])
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        AuditLogImplementation.LogAuditMessage(SecurityAuditDescription, SecurityAuditOperationResult, SecurityAuditCategory, AuditMessageOperation, AuditMessageOperationResult, CustomDimensions, CallerModuleInfo);
    end;
}