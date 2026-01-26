// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

page 7000026 "Operation Fees"
{
    Caption = 'Operation Fees';
    DataCaptionExpression = Rec.Caption();
    DataCaptionFields = "Currency Code";
    PageType = List;
    SourceTable = "Operation Fee";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Type of Fee"; Rec."Type of Fee")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of operation for which the commission is being charged.';
                }
                field("Charge Amt. per Operation"; Rec."Charge Amt. per Operation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of commission charged for each type of commission-based operation.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Fee")
            {
                Caption = '&Fee';
                Image = Costs;
                action("&Fee Ranges")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Fee Ranges';
                    Image = Ranges;
                    RunObject = Page "Fee Ranges";
                    RunPageLink = Code = field(Code),
                                  "Currency Code" = field("Currency Code"),
                                  "Type of Fee" = field("Type of Fee");
                    ToolTip = 'View itemized bank charges for document management. There are seven different types of operations in the Cartera module: receivables management, discount management, discount interests, management of outstanding debt, payment orders management, factoring without risk management, and factoring with risk management.';
                }
            }
        }
    }
}

