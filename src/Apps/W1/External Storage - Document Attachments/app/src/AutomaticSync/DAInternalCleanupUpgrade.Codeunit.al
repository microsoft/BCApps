// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExternalStorage.DocumentAttachments;

codeunit 8758 "DA Internal Cleanup Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "DA External Storage Setup" = rm;

    trigger OnUpgradePerCompany()
    var
        Setup: Record "DA External Storage Setup";
    begin
        if not Setup.Get() then
            exit;
        if Setup."Cleanup Batch Size" = 0 then
            Setup."Cleanup Batch Size" := 100;
        if Setup."Cleanup Run Minutes" = 0 then
            Setup."Cleanup Run Minutes" := 5;
        Setup.Modify();
    end;
}
