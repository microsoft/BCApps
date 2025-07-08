// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

codeunit 8715 "Purview Implementation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CallExternalErr: Label 'Purview module can only be called by Microsoft.';

    internal procedure AssertInternalCall(CallerModuleInfo: ModuleInfo)
    begin
        if CallerModuleInfo.Publisher <> 'Microsoft' then
            Error(CallExternalErr);
    end;

    internal procedure LogAuditMessage(SecurityAuditDescription: Text; SecurityAuditOperationResult: SecurityOperationResult; SecurityAuditCategory: AuditCategory; AuditMessageOperation: Integer; AuditMessageOperationResult: Integer)
    begin
        Session.LogAuditMessage(SecurityAuditDescription, SecurityAuditOperationResult, SecurityAuditCategory, AuditMessageOperation, AuditMessageOperationResult);
    end;

    internal procedure LogAuditMessage(SecurityAuditDescription: Text; SecurityAuditOperationResult: SecurityOperationResult; SecurityAuditCategory: AuditCategory; AuditMessageOperation: Integer; AuditMessageOperationResult: Integer; CustomDimensions: Dictionary of [Text, Text])
    begin
        Session.LogAuditMessage(SecurityAuditDescription, SecurityAuditOperationResult, SecurityAuditCategory, AuditMessageOperation, AuditMessageOperationResult, CustomDimensions);
    end;
}