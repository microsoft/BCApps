// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Purchases.Vendor;

page 15000000 "Remittance Info"
{
    Caption = 'Remittance Info';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = Vendor;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Remittance Account Code"; Rec."Remittance Account Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remittance account code that will be used for the vendor.';
                }
                field("Remittance Agreement Code"; Rec."Remittance Agreement Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the agreement to which the account is linked.';
                }
                field("Recipient Bank Account No."; Rec."Recipient Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s account number that is used for remittance.';
                }
            }
            group(Domestic)
            {
                Caption = 'Domestic';
                field("Own Vendor Recipient Ref."; Rec."Own Vendor Recipient Ref.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Own vendor recipient ref.';
                    ToolTip = 'Specifies if you want to use the recipient reference from the vendor.';
                }
                field("Recipient ref. 1 - inv."; Rec."Recipient ref. 1 - inv.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the payment invoice.';
                }
                field("Recipient ref. 2 - inv."; Rec."Recipient ref. 2 - inv.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the payment invoice.';
                }
                field("Recipient ref. 3 - inv."; Rec."Recipient ref. 3 - inv.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the payment invoice.';
                }
                field("Recipient ref. 1 - cred."; Rec."Recipient ref. 1 - cred.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the payment invoice when deducting a credit memo.';
                }
                field("Recipient ref. 2 - cred."; Rec."Recipient ref. 2 - cred.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the payment invoice when deducting a credit memo.';
                }
                field("Recipient ref. 3 - cred."; Rec."Recipient ref. 3 - cred.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the payment invoice when deducting a credit memo.';
                }
            }
            group("Payment abroad")
            {
                Caption = 'Payment abroad';
                field("Recipient Ref. Abroad"; Rec."Recipient Ref. Abroad")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the text that will print on the payment invoice.';
                }
                field("Warning Notice"; Rec."Warning Notice")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how a warning notice is sent from the recipient''s bank to the recipient.';
                }
                field("Warning Text"; Rec."Warning Text")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the warning text that is used if the Warning Notice field is set to Other.';
                }
                field("Recipient Confirmation"; Rec."Recipient Confirmation")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the recipient confirmation method.';
                }
                field("Telex Country/Region Code"; Rec."Telex Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code for the telex.';
                }
                field("Telex/Fax No."; Rec."Telex/Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the recipient''s telex or fax number.';
                }
                field("Recipient Contact"; Rec."Recipient Contact")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the contact person''s name if a telex or fax confirmation is sent to the recipient.';
                }
                field("Charges Domestic"; Rec."Charges Domestic")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who is charged for foreign payments.';
                }
                field("Charges Abroad"; Rec."Charges Abroad")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who is charged the domestic charges in connection with the payment.';
                }
                field("Payment Type Code Abroad"; Rec."Payment Type Code Abroad")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a two-digit code for the payment type.';
                }
                field("Specification (Norges Bank)"; Rec."Specification (Norges Bank)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies information for your local government bank.';
                }
            }
            group("Bank abroad")
            {
                Caption = 'Bank abroad';
                field(SWIFT; Rec.SWIFT)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT address by which the recipient''s bank is identified.';
                }
                field("Bank Name"; Rec."Bank Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank name.';
                }
                field("Bank Address 1"; Rec."Bank Address 1")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the recipient''s bank.';
                }
                field("Bank Address 2"; Rec."Bank Address 2")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the recipient''s bank.';
                }
                field("Bank Address 3"; Rec."Bank Address 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the recipient''s bank.';
                }
                field("Rcpt. Bank Country/Region Code"; Rec."Rcpt. Bank Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code for the recipient.';
                }
                field("SWIFT Remb. Bank"; Rec."SWIFT Remb. Bank")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the SWIFT address by which the recipient''s bank is identified.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(0);
    end;
}

