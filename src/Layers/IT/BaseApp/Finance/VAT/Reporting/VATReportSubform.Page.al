// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.VAT.Ledger;

/// <summary>
/// Displays VAT report lines in a list format for reviewing and modifying VAT entry data.
/// Provides editable view of VAT entries included in VAT report calculations.
/// </summary>
page 741 "VAT Report Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = ListPart;
    SourceTable = "VAT Report Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Incl. in Report"; Rec."Incl. in Report")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies whether to include a VAT report line in the exported version of the report that will be submitted to the tax authority.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the line number.';
                }
                field("Operation Occurred Date"; Rec."Operation Occurred Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the date when the VAT operation occurred on the transaction.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the posting date of the document that resulted in the VAT entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the document number that resulted in the VAT entry.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the type of the document that resulted in the VAT entry.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the type of the VAT entry.';
                }
                field(Base; Rec.Base)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount that the VAT amount in the Amount is calculated from.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT amount for the report line. This is calculated based on the value of the Base field.';

                    trigger OnAssistEdit()
                    var
                        VATEntry: Record "VAT Entry";
                    begin
                        VATEntry.SetRange("Document No.", Rec."Document No.");
                        VATEntry.SetRange("Document Type", Rec."Document Type");
                        VATEntry.SetRange("Include in VAT Transac. Rep.", true);
                        VATEntry.SetRange(VATEntry."Unrealized VAT Entry No.", 0);
                        PAGE.RunModal(0, VATEntry);
                    end;
                }
                field("Amount Incl. VAT"; Rec."Amount Incl. VAT")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the amount including VAT for this report line.';
                }
                field("Bill-to/Pay-to No."; Rec."Bill-to/Pay-to No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the number of the bill-to customer or pay-to vendor that the entry is linked to.';
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the country/region of the address.';
                }
                field("Internal Ref. No."; Rec."Internal Ref. No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the internal reference number of the VAT entry.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("VAT Registration No."; Rec."VAT Registration No.")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies the VAT registration number of the customer or vendor that the VAT entry is linked to.';
                }
                field("VAT Transaction Nature"; Rec."VAT Transaction Nature")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies operation nature. The specific reason why the vendor should not indicate tax in the invoice.';
                }
                field("Fattura Document Type"; Rec."Fattura Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value to export in TipoDocument XML node of the Fattura document.';
                }
            }
        }
    }

    actions
    {
    }
}

