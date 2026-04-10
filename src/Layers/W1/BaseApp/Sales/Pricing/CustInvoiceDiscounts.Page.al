// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

/// <summary>
/// Displays and manages customer invoice discount terms including minimum amounts, discount percentages, and service charges.
/// </summary>
page 23 "Cust. Invoice Discounts"
{
    Caption = 'Cust. Invoice Discounts';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Cust. Invoice Disc.";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                }
                field("Minimum Amount"; Rec."Minimum Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Service Charge"; Rec."Service Charge")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

