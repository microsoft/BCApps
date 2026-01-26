// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

page 12187 "VAT Plafond Periods"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Plafond Periods';
    PageType = List;
    SourceTable = "VAT Plafond Period";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1130000)
            {
                ShowCaption = false;
                field(Year; Rec.Year)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the year of the VAT plafond amounts.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum amount VAT that can be exempt during the period, based on a plafond arrangement.';
                }
                field("Calculated Amount"; Rec."Calculated Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the calculated amount of VAT that is exempt during the period, based on a plafond arrangement.';
                }
            }
        }
    }

    actions
    {
    }
}

