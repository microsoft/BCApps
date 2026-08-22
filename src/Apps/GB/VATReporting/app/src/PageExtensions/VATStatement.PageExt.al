// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace VATReporting.VATReporting;

using Microsoft.Finance.VAT.Reporting;

pageextension 10548 "VAT Statement" extends "VAT Statement"
{
    actions
    {
        addfirst(reporting)
        {
            action("VAT Audit Report GB")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Audit Report';
                Image = "Report";
                RunObject = Report "VAT Audit GB";
                ToolTip = 'Export the data required for auditing in a comma-separated value (CSV) file format.';
            }
            action("VAT Entry Exception Report GB")
            {
                ApplicationArea = VAT;
                Caption = 'VAT Entry Exception Report';
                Image = "Report";
                RunObject = Report "VAT Entry Exception Report GB";
                ToolTip = 'Print the Exception report so that you can document and show differences in VAT amounts to tax authorities.';
            }
        }
        addfirst(Category_Report)
        {
            actionref("VAT Audit Report_Promoted_GB"; "VAT Audit Report GB")
            {
            }
            actionref("VAT Entry Exception Report_Promoted_GB"; "VAT Entry Exception Report GB")
            {
            }
        }
    }


}