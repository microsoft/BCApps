// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Telemetry;

codeunit 8715 "Audit Log Implementation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CallExternalErr: Label 'Audit module can only be called by Microsoft.';

    procedure LogAuditMessage(SecurityAuditDescription: Text; SecurityAuditOperationResult: SecurityOperationResult; SecurityAuditCategory: AuditCategory; AuditMessageOperation: Integer; AuditMessageOperationResult: Integer; CallerModuleInfo: ModuleInfo)
    begin
        AssertInternalCall(CallerModuleInfo);
        Session.LogAuditMessage(SecurityAuditDescription, SecurityAuditOperationResult, SecurityAuditCategory, AuditMessageOperation, AuditMessageOperationResult);
    end;

    procedure LogAuditMessage(SecurityAuditDescription: Text; SecurityAuditOperationResult: SecurityOperationResult; SecurityAuditCategory: AuditCategory; AuditMessageOperation: Integer; AuditMessageOperationResult: Integer; CustomDimensions: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    begin
        AssertInternalCall(CallerModuleInfo);
        Session.LogAuditMessage(SecurityAuditDescription, SecurityAuditOperationResult, SecurityAuditCategory, AuditMessageOperation, AuditMessageOperationResult, CustomDimensions);
    end;

    local procedure AssertInternalCall(CallerModuleInfo: ModuleInfo)
    begin
        if CallerModuleInfo.Publisher <> 'Microsoft' then
            Error(CallExternalErr);
    end;
}