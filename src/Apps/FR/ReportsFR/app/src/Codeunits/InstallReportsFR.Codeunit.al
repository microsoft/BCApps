// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

codeunit 10823 "Install Reports FR"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        ReportLayoutsFR: Codeunit "Report Layouts FR";
    begin
        ReportLayoutsFR.InitializeCompany();
    end;
}
