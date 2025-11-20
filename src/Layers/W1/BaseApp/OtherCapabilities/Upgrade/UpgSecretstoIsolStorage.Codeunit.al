#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

codeunit 104020 "Upg Secrets to Isol. Storage"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';
    ObsoleteReason = 'The table Service Password deleted in version 26.';
    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    begin
    end;
}
#endif