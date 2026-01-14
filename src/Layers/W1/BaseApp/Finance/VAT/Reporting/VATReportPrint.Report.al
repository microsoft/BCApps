// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

/// <summary>
/// Provides printing functionality for VAT reports with formatted output layout.
/// Serves as base report structure for VAT report printing and customization.
/// </summary>
report 740 "VAT Report Print"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/VATReportPrint.rdlc';
    Caption = 'VAT Report Print';

    dataset
    {
        dataitem("VAT Report Header"; "VAT Report Header")
        {
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        Error('');
    end;
}

