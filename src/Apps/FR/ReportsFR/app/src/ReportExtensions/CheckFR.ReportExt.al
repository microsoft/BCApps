// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.Check;

reportextension 10821 "Check FR" extends Check
{
    rendering
    {
        layout(CheckFR)
        {
            Type = RDLC;
            LayoutFile = './src/ReportExtensions/Layouts/CheckFR.rdlc';
            Caption = 'Check FR (RDLC)';
            Summary = 'The French check layout preserves the positioning for French check stock.';
        }
    }
}
