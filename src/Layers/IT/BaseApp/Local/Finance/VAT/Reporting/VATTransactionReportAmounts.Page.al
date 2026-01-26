// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 12199 "VAT Transaction Report Amounts"
{
    Caption = 'VAT Transaction Report Amounts';
    PageType = Card;
    SourceTable = "VAT Transaction Report Amount";

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the start date for the threshold amounts.';
                }
                field("Threshold Amount Incl. VAT"; Rec."Threshold Amount Incl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum invoice amount, including VAT, that will be included in the VAT transaction report.';
                }
                field("Threshold Amount Excl. VAT"; Rec."Threshold Amount Excl. VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum invoice base amount that will be included in the VAT transaction report.';
                }
            }
        }
    }

    actions
    {
    }
}

