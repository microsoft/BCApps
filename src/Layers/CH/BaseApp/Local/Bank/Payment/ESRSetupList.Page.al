// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

page 3010532 "ESR Setup List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'ESR Setup List';
    CardPageID = "ESR Setup";
    Editable = false;
    PageType = List;
    SourceTable = "ESR Setup";
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
                    ToolTip = 'Specifies the ESR bank is identified by the bank code.';
                }
                field("ESR System"; Rec."ESR System")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the invoice amount will be printed and no deduction can be made with the payment.';
                }
                field("ESR Payment Method Code"; Rec."ESR Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that vendors are linked with the ESR bank using the payment method code.';
                }
                field("ESR Currency Code"; Rec."ESR Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that ESR can be used for CHF and EUR.';
                }
            }
        }
    }

    actions
    {
    }
}

