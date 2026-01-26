// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;

page 7000077 "Docs. in Closed PO Subform"
{
    Caption = 'Lines';
    Editable = false;
    PageType = ListPart;
    SourceTable = "Closed Cartera Doc.";
    SourceTableView = where("Bill Gr./Pmt. Order No." = filter(<> ''),
                            Type = const(Payable));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document in question.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date this closed document was created and posted.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of this closed document.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the closed document.';
                }
                field("Honored/Rejtd. at Date"; Rec."Honored/Rejtd. at Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of payment or rejection of this closed document.';
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the payment method code defined for the document number.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the document that is the source of this closed document.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the closed bill.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this closed document.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the initial amount of this closed document.';
                }
                field("Original Amount (LCY)"; Rec."Original Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the initial amount of this document, in LCY.';
                    Visible = false;
                }
                field("Amount for Collection"; Rec."Amount for Collection")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount for which this closed document was originally drawn.';
                }
                field("Amt. for Collection (LCY)"; Rec."Amt. for Collection (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount for which this closed document was originally sent.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding for this closed document to be fully applied.';
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount outstanding, in order for this closed document to be fully settled.';
                    Visible = false;
                }
                field(Redrawn; Rec.Redrawn)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this document, which has come due and is now rejected, has been recirculated.';
                }
                field(Place; Rec.Place)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the company bank and customer bank are in the same area.';
                    Visible = false;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number of the customer/vendor associated with this closed document.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ledger entry number associated with the posting of this closed document.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("&Docs.")
            {
                Caption = '&Docs.';
                action(Redraw)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Redraw';
                    Ellipsis = true;
                    Image = RefreshVoucher;
                    ToolTip = 'Create a new copy of the old bill or order, with the possibility of creating it with a new, later due date and a different payment method.';

                    trigger OnAction()
                    begin
                        RedrawDoc();
                    end;
                }
                action("Dime&nsions")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dime&nsions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action(Navigate)
                {
                    ApplicationArea = Basic, Suite;
                    Image = Navigate;

                    trigger OnAction()
                    begin
                        NavigateDoc();
                    end;
                }
            }
        }
    }

    var
        Text1100000: Label 'Only bills can be redrawn.';
        ClosedDoc: Record "Closed Cartera Doc.";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CarteraManagement: Codeunit CarteraManagement;

    [Scope('OnPrem')]
    procedure NavigateDoc()
    begin
        CarteraManagement.NavigateClosedDoc(Rec);
    end;

    local procedure RedrawDoc()
    begin
        CurrPage.SetSelectionFilter(ClosedDoc);
        if not ClosedDoc.Find('=><') then
            exit;

        ClosedDoc.SetFilter("Document Type", '<>%1', ClosedDoc."Document Type"::Bill);
        if ClosedDoc.Find('-') then
            Error(Text1100000);
        ClosedDoc.SetRange("Document Type");

        VendLedgEntry.Reset();
        repeat
            VendLedgEntry.Get(ClosedDoc."Entry No.");
            VendLedgEntry.Mark(true);
        until ClosedDoc.Next() = 0;

        VendLedgEntry.MarkedOnly(true);
        REPORT.RunModal(REPORT::"Redraw Payable Bills", true, false, VendLedgEntry);
        CurrPage.Update(false);
    end;
}

