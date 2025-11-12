#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Upgrade;

codeunit 104021 "Upgrade Item Cross Reference"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';
    ObsoleteReason = 'The table Item Cross Reference deleted in version 26.';

    trigger OnUpgradePerCompany()
    begin
    end;

    procedure UpdateData();
    begin
    end;
}
#endif