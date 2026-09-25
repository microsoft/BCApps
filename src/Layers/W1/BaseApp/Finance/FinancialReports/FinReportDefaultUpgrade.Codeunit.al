// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

#if not CLEAN30
codeunit 1081 "Fin. Report Default Upgrade"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnUpgradePerCompany()
    begin
    end;

    procedure UpdateData()
    begin
    end;

    procedure SetUpgradeTag(DataUpgradeExecuted: Boolean)
    begin
    end;
}
#endif