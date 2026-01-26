// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 3010830 "LSV Setup List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'LSV Setup List';
    CardPageID = "LSV Setup";
    Editable = false;
    PageType = List;
    SourceTable = "LSV Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1150000)
            {
                ShowCaption = false;
                field("Bank Code"; Rec."Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID for the bank account.';
                }
                field("LSV Payment Method Code"; Rec."LSV Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code for a customer.';
                }
                field("LSV Bank Name"; Rec."LSV Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name as specified in the bank address.';
                }
                field("LSV Currency Code"; Rec."LSV Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for LSV+ payments.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Print")
            {
                Caption = '&Print';
                action("Collection Authorisation")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Collection Authorisation';
                    Image = "Report";
                    RunObject = Report "LSV Collection Authorisation";
                    ToolTip = 'View the collection authorizations that are sent to your customers. Collection authorizations are an agreement with customers so that you can collect the invoice amounts in the future. Customers provide bank account information, sign the collection authorization, and return it.';
                }
                action("LSV Customerbank List")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'LSV Customerbank List';
                    Image = "Report";
                    RunObject = Report "LSV Customerbank List";
                    ToolTip = 'View the collection authorizations that are sent to your customers. Collection authorizations are an agreement with customers so that you can collect the invoice amounts in the future. Customers provide bank account information, sign the collection authorization, and return it.';
                }
            }
        }
    }
}

