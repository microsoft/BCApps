// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Interface for managing multi-language translations of payment method descriptions.
/// Allows users to define localized payment method names for international operations.
/// </summary>
/// <remarks>
/// Source Table: Payment Method Translation (466). Accessed from Payment Method setup.
/// Supports translation management for payment methods across different languages.
/// </remarks>
page 758 "Payment Method Translations"
{
    Caption = 'Payment Method Translations';
    DataCaptionFields = "Payment Method Code";
    PageType = List;
    SourceTable = "Payment Method Translation";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to business partners abroad, such as an item description on an order confirmation.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the translation of the payment method.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control6; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control7; Notes)
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

