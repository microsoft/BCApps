// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 10846 "Install Payment Management FR"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.UpgradeCheckLayout();
    end;
}
