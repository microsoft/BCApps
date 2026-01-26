// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 11301 "VAT VIES Correction"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'VAT VIES Correction';
    DelayedInsert = true;
    PageType = List;
    SourceTable = "VAT VIES Correction";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Period Type"; Rec."Period Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the period type for the VAT entry.';
                }
                field("Declaration Period No."; Rec."Declaration Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original accounting period number for the uncorrected VAT entry.';
                }
                field("Declaration Period Year"; Rec."Declaration Period Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the original year for the uncorrected VAT entry.';
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the customer the VAT correction applies to.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code that identifies the country/region of the corrected VAT entry.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT registration number the VAT correction applies to.';
                }
                field("EU Service"; Rec."EU Service")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT correction entry originates from the sale of services to other European Union (EU) countries/regions.';
                }
                field("EU 3-Party Trade"; Rec."EU 3-Party Trade")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT correction applies to a 3-party trade transaction between EU countries/regions.';
                }
                field("Correction Date"; Rec."Correction Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the VAT correction.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT correction.';
                }
                field("Additional-Currency Amount"; Rec."Additional-Currency Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the VAT correction in the additional reporting currency.';
                }
                field("Correction Period No."; Rec."Correction Period No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corrected accounting period number for the VAT entry.';
                }
                field("Correction Period Year"; Rec."Correction Period Year")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corrected year for the VAT entry.';
                }
            }
        }
    }

    actions
    {
    }
}

