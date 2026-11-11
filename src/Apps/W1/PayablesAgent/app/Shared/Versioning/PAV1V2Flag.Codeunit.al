// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

#if not CLEAN30
using System.Azure.Identity;
#endif

codeunit 3339 "PA V1V2 Flag"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Payables Agent Setup" = R;

    var
        AmbiguousIdentityErr: Label 'Work item %1 is stored as both a version 1 and a version 2 work item.', Comment = '%1 = Work Item ID';
#if not CLEAN30
        PreviewTenantIdTok: Label 'f0ac72d1-c1b3-4c2a-a196-8fb82cac5934', Locked = true;
        V2PreviewNotAllowedErr: Label 'The Payables Agent version 2 preview can only be selected in the designated preview tenant.';
#endif

    internal procedure IsV2Active(): Boolean
    begin
#if not CLEAN30
        exit(IsV2PreviewSelected());
#else
        exit(false);
#endif
    end;

#if not CLEAN30
    internal procedure CheckV2PreviewSelectable()
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        TenantId: Text;
    begin
        TenantId := LowerCase(DelChr(AzureADTenant.GetAadTenantId(), '=', '{}'));
        if not (TenantId in [PreviewTenantIdTok, 'common', '']) then
            Error(V2PreviewNotAllowedErr);
    end;
#endif

    internal procedure GetVersion(WorkItemId: Guid): Integer
    var
        StoredWorkItem: Record "Payables Agent Work Item";
        DraftBasedWorkItem: Codeunit "PA Draft Based Work Item";
        HasV2: Boolean;
        HasV1: Boolean;
    begin
        HasV2 := StoredWorkItem.GetBySystemId(WorkItemId);
        HasV1 := DraftBasedWorkItem.Load(WorkItemId);
        if HasV2 and HasV1 then
            Error(AmbiguousIdentityErr, WorkItemId);
        if HasV2 then
            exit(2);
        if HasV1 then
            exit(1);
        exit(0);
    end;

#if not CLEAN30
#pragma warning disable AL0432
    local procedure IsV2PreviewSelected(): Boolean
    var
        Setup: Record "Payables Agent Setup";
    begin
        if not Setup.TryGetSetup() then
            exit(false);
        exit(Setup."Preview Version" = Setup."Preview Version"::"V2 Preview");
    end;
#pragma warning restore AL0432
#endif
}
