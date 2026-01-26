// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Vendor;

using System.Diagnostics;

page 426 "Vendor Bank Account List"
{
    Caption = 'Vendor Bank Account List';
    CardPageID = "Vendor Bank Account Card";
    DataCaptionFields = "Vendor No.";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Bank Account";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code to identify this vendor bank account.';
                }
                field("Vendor.Name"; Vendor.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor Name';
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s name.';
                }
                field("Vendor.City"; Vendor.City)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor City';
                    ToolTip = 'Specifies the city of the vendor''s address.';
                }
                field("Payment Form"; Rec."Payment Form")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how payments are made. The different payment forms are used for different types of payment.';
                }
                field("ESR Type"; Rec."ESR Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the format of account numbers and reference numbers for this vendor. The account number can have 5 or 9 digits, the reference number can have 15, 16, or 27 digits.';
                }
                field("ESR Account No."; Rec."ESR Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s ESR account number.';
                }
                field("Balance Account No."; Rec."Balance Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that when processing an invoice, for this bank account, the balance account you enter here will be suggested.';
                }
                field("Invoice No. Startposition"; Rec."Invoice No. Startposition")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the position of the invoice number within the reference number.';
                }
                field("Invoice No. Length"; Rec."Invoice No. Length")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the length of the invoice number in the reference number.';
                }
                field("Clearing No."; Rec."Clearing No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the clearing number for the supplier''s bank.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the bank account.';
                }
                field("Giro Account No."; Rec."Giro Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor''s giro account no.';
                }
                field("SWIFT Code"; Rec."SWIFT Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the international bank identifier code (SWIFT) of the bank where you have the account.';
                }
                field(IBAN; Rec.IBAN)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the bank account''s international bank account number.';
                }
                field("Bank Identifier Code"; Rec."Bank Identifier Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies this is used if a payment is made to a foreign bank.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank where the vendor has this bank account.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the postal code.';
                    Visible = false;
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region of the address.';
                    Visible = false;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the telephone number of the bank where the vendor has the bank account.';
                }
                field("Fax No."; Rec."Fax No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the fax number associated with the address.';
                    Visible = false;
                }
                field(Contact; Rec.Contact)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the bank employee regularly contacted in connection with this bank account.';
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

    trigger OnAfterGetRecord()
    begin
        Vendor.Get(Rec."Vendor No.");
    end;

    trigger OnOpenPage()
    var
        MonitorSensitiveField: Codeunit "Monitor Sensitive Field";
    begin
        MonitorSensitiveField.ShowPromoteMonitorSensitiveFieldNotification();
    end;

    var
        Vendor: Record Vendor;
}

