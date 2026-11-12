// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 13584 "Banking Payments Tags FI"
{
    Access = Internal;

    procedure GetMigrationTag(): Code[250]
    begin
        exit('MS-BankingAndPaymentsFIUpgradeTag-20261110');
    end;

    procedure GetRequestMarkerTag(): Code[250]
    begin
        exit('MS-BankingAndPaymentsFIUpgradeRequest-20261110');
    end;

    procedure GetRequestTag(TargetVersion: Version): Code[250]
    begin
        exit(CopyStr(GetRequestMarkerTag() + '-' + Format(TargetVersion), 1, 250));
    end;
}
