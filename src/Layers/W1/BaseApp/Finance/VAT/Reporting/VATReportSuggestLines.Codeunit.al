// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Provides line suggestion functionality for VAT reports through request page interface.
/// Launches the VAT report request page for configuring and generating VAT statement lines.
/// </summary>
codeunit 745 "VAT Report Suggest Lines"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        REPORT.RunModal(REPORT::"VAT Report Request Page", true, false, Rec);
    end;
}

