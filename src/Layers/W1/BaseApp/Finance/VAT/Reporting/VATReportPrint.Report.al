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
    Caption = 'VAT Report Print';
    DefaultRenderingLayout = RDLCLayout;

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

    rendering
    {
        layout(RDLCLayout)
        {
            Type = RDLC;
            LayoutFile = './Finance/VAT/Reporting/VATReportPrint.rdlc';
            Summary = 'Report layout made in the legacy RDLC format. Use an RDLC editor to modify the layout.';
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

