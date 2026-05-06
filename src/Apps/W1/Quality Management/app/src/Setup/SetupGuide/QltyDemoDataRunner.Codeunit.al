// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Setup;

/// <summary>
/// Public codeunit used by the Guided Experience checklist to install or open demo data.
/// </summary>
codeunit 20457 "Qlty. Demo Data Runner"
{
    Access = Public;
    TableNo = "Qlty. Management Setup";

    trigger OnRun()
    var
        QltyDemoDataMgmt: Codeunit "Qlty. Demo Data Mgmt.";
    begin
        QltyDemoDataMgmt.InstallOrOpenDemoData();
    end;
}
