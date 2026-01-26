// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Sales.Receivables;

page 7000007 "Closed Cartera Documents"
{
    Caption = 'Closed Cartera Documents';
    Editable = false;
    PageType = List;
    SourceTable = "Closed Cartera Doc.";

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
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the closed bill.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this closed document.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code in which this closed document was generated.';
                    Visible = false;
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
        area(navigation)
        {
            group("&Docs.")
            {
                Caption = '&Docs.';
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';

                    trigger OnAction()
                    begin
                        ClosedDoc.Copy(Rec);
                        PAGE.Run(PAGE::"Closed Documents Analysis", ClosedDoc);
                    end;
                }
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
                separator(Action1100000)
                {
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
            }
        }
        area(processing)
        {
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    CarteraManagement.NavigateClosedDoc(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
            }
        }
    }

    var
        Text1100000: Label 'Only bills can be redrawn.';
        Text1100001: Label 'Only receivable bills can be redrawn.';
        Text1100002: Label 'No bills have been found that can be redrawn. \';
        Text1100003: Label 'Please check that at least one rejected bill was selected.';
        ClosedDoc: Record "Closed Cartera Doc.";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CarteraManagement: Codeunit CarteraManagement;

    [Scope('OnPrem')]
    procedure RedrawDoc()
    begin
        CurrPage.SetSelectionFilter(ClosedDoc);
        if not ClosedDoc.Find('=><') then
            exit;

        ClosedDoc.SetRange("Document Type", ClosedDoc."Document Type"::Bill);
        if not ClosedDoc.Find('-') then
            Error(
              Text1100000);

        ClosedDoc.SetRange(Type, ClosedDoc.Type::Receivable);
        if not ClosedDoc.Find('-') then
            Error(
              Text1100001);

        ClosedDoc.SetRange(Status, ClosedDoc.Status::Rejected);
        if not ClosedDoc.Find('-') then
            Error(
              Text1100002 +
              Text1100003);

        CustLedgEntry.Reset();
        repeat
            CustLedgEntry.Get(ClosedDoc."Entry No.");
            CustLedgEntry.Mark(true);
        until ClosedDoc.Next() = 0;

        CustLedgEntry.MarkedOnly(true);
        REPORT.RunModal(REPORT::"Redraw Receivable Bills", true, false, CustLedgEntry);
    end;
}

