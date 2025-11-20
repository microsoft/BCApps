// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.BankAccount;

/// <summary>
/// Specialized bank account card focused on payment processing configuration.
/// Provides interface for setting up bank accounts for electronic payments and fund transfers.
/// </summary>
/// <remarks>
/// Source Table: Bank Account (270). Emphasizes payment export settings and electronic banking configuration.
/// Used in payment processing workflows for account setup and configuration.
/// </remarks>
page 1283 "Payment Bank Account Card"
{
    Caption = 'Payment Bank Account Card';
    SourceTable = "Bank Account";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = Basic, Suite;
                    NotBlank = true;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where you have the bank account.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number used by the bank for the bank account.';
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field("Bank Acc. Posting Group"; Rec."Bank Acc. Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies a code for the bank account posting group for the bank account.';
                }
                group("Payment Match Tolerance")
                {
                    Caption = 'Payment Match Tolerance';
                    field("Match Tolerance Type"; Rec."Match Tolerance Type")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies by which tolerance the automatic payment application function will apply the Amount Incl. Tolerance Matched rule for this bank account.';
                    }
                    field("Match Tolerance Value"; Rec."Match Tolerance Value")
                    {
                        ApplicationArea = Basic, Suite;
                        DecimalPlaces = 0 : 2;
                        ToolTip = 'Specifies if the automatic payment application function will apply the Amount Incl. Tolerance Matched rule by Percentage or Amount.';
                    }
                }
                field("Bank Statement Import Format"; Rec."Bank Statement Import Format")
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the format of the bank statement file that can be imported into this bank account.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the relevant currency code for the bank account.';
                }
                field("Last Payment Statement No."; Rec."Last Payment Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the last bank statement that was imported, either as a feed or a file.';
                }
            }
            group(Address)
            {
                Caption = 'Address';
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where you have the bank account.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = Basic, Suite;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address associated with the bank account.';
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Information)
            {
                Caption = 'Information';
                Image = Customer;
                action("Detailed Information")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed Information';
                    Image = ViewDetails;
                    RunObject = Page "Bank Account Card";
                    RunPageLink = "No." = field("No.");
                    ToolTip = 'View or edit additional information about the bank account, such as the account. You can also check the balance on the account.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Detailed Information_Promoted"; "Detailed Information")
                {
                }
            }
        }
    }
}

