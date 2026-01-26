// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 12184 Bill
{
    Caption = 'Bill';
    PageType = List;
    SourceTable = Bill;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a bill code.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description for the bill.';
                }
                field("Allow Issue"; Rec."Allow Issue")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if documents related to the bill code are automatically issued.';
                }
                field("Bank Receipt"; Rec."Bank Receipt")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the bill code automatically creates bank receipts that you can use to manage customer bills.';
                }
                field("Bills for Coll. Temp. Acc. No."; Rec."Bills for Coll. Temp. Acc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a temporary general ledger account number where the bills for collection will be posted.';
                }
                field("Temporary Bill No."; Rec."Temporary Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a temporary identification number for the customer bill.';
                }
                field("Final Bill No."; Rec."Final Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a final identification number for the customer bill.';
                }
                field("List No."; Rec."List No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bill list identification number.';
                }
                field("Bill Source Code"; Rec."Bill Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code linked to identify bank transfer entries for customers.';
                }
                field("Vendor Bill List"; Rec."Vendor Bill List")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bill lists.';
                }
                field("Vendor Bill No."; Rec."Vendor Bill No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the number series that will be used to assign numbers to bill that will be send out.';
                }
                field("Vend. Bill Source Code"; Rec."Vend. Bill Source Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the source code linked to identify bank transfers entries for vendors.';
                }
            }
        }
    }

    actions
    {
    }
}

