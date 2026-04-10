// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

page 28 "Vend. Invoice Discounts"
{
    Caption = 'Vend. Invoice Discounts';
    DataCaptionFields = "Code";
    PageType = List;
    SourceTable = "Vendor Invoice Disc.";

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
                    ApplicationArea = Suite;
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = Suite;
                }
                field("Service Charge"; Rec."Service Charge")
                {
                    ApplicationArea = Suite;
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

