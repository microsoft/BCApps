#pragma warning disable AS0088
#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

codeunit 104054 "Upgrade Custom Report Layouts"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Runs the upgrade of layouts stored in the Custom Report Layout table, which is replaced by the system tables Tenant Report Layout and Report Layout Selection.';
    ObsoleteTag = '29.0';
    Subtype = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        Codeunit.Run(Codeunit::"Upgrade Custom Report Impl.");
    end;
}
#endif
#pragma warning restore AS0088
