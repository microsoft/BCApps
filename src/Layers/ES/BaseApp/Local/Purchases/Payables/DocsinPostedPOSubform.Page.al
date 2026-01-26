// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Finance.ReceivablesPayables;

page 7000076 "Docs. in Posted PO Subform"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Posted Cartera Doc.";
    SourceTableView = where(Type = const(Payable));

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the creation of this document was posted.';
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document in question.';
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the due date of this document in a posted bill group/payment order.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the status of this document in a posted bill group/payment order.';
                }
                field("Honored/Rejtd. at Date"; Rec."Honored/Rejtd. at Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when this document in a posted bill group/payment order is settled or rejected.';
                    Visible = false;
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment method code for the document number.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the document in a posted bill group/payment order, from which this document was generated.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the number of a bill in a posted bill group/payment order.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with this posted document.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the initial amount of this document in a posted bill group/payment order.';
                    Visible = false;
                }
                field("Original Amt. (LCY)"; Rec."Original Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the initial amount of this document in a posted bill group/payment order.';
                    Visible = false;
                }
                field("Amount for Collection"; Rec."Amount for Collection")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount for which this document in a posted bill group/payment order was created.';
                }
                field("Amt. for Collection (LCY)"; Rec."Amt. for Collection (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount due for this document in a posted bill group/payment order.';
                    Visible = false;
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the pending amount for this document, in a posted bill group/payment order, to be settled in full.';
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the pending amount in order for this document, in a posted bill group/payment order, to be settled in full.';
                    Visible = false;
                }
                field(Redrawn; Rec.Redrawn)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a check mark to indicate that the bill has been redrawn since it was rejected when its due date arrived.';
                }
                field(Place; Rec.Place)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies if the company bank and customer bank are in the same area.';
                    Visible = false;
                }
                field("Category Code"; Rec."Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a filter for the categories for which documents are shown.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the account type associated with this document in a posted bill group/payment order.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the ledger entry number associated with this posted document.';
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
                action(Dimensions)
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
                action(Categorize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Categorize';
                    Ellipsis = true;
                    Image = Category;
                    ToolTip = 'Insert categories on one or more Cartera documents to facilitate analysis. For example, to count or add only some documents, to analyze their due dates, to simulate scenarios for creating bill groups, to mark documents with your initials to indicate to other accountants that you are managing them personally.';

                    trigger OnAction()
                    begin
                        CategorizeDocs();
                    end;
                }
                action(Decategorize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Decategorize';
                    Image = UndoCategory;
                    ToolTip = 'Remove categories applied to one or more Cartera documents to facilitate analysis.';

                    trigger OnAction()
                    begin
                        DecategorizeDocs();
                    end;
                }
                group(Settle)
                {
                    Caption = 'Settle';
                    Enabled = true;
                    Image = SettleOpenTransactions;
                    action(TotalSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Total Settlement';
                        Ellipsis = true;
                        ToolTip = 'View posted documents that were settled fully.';

                        trigger OnAction()
                        begin
                            SettleDocs();
                        end;
                    }
                    action(PartialSettlement)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'P&artial Settlement';
                        Ellipsis = true;
                        ToolTip = 'View posted documents that were settled partially.';

                        trigger OnAction()
                        begin
                            PartialSettle();
                        end;
                    }
                }
                action(Redraw)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Redraw';
                    Ellipsis = true;
                    Enabled = true;
                    Image = RefreshVoucher;
                    ToolTip = 'Create a new copy of the old bill or order, with the possibility of creating it with a new, later due date and a different payment method.';

                    trigger OnAction()
                    begin
                        RedrawDocs();
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

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Posted Cartera Doc.- Edit", Rec);
        exit(false);
    end;

    var
        Text1100000: Label 'No documents have been found that can be settled. \';
        Text1100001: Label 'Please check that at least one open document was selected.';
        Text1100004: Label 'No documents have been found that can be redrawn. \';
        Text1100005: Label 'Please check that at least one rejected or honored document was selected.';
        Text1100006: Label 'Only bills can be redrawn.';
        Text1100007: Label 'Please check that one open document was selected.';
        Text1100008: Label 'Only one open document can be selected';
        PostedDoc: Record "Posted Cartera Doc.";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CarteraManagement: Codeunit CarteraManagement;

    local procedure CategorizeDocs()
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        CarteraManagement.CategorizePostedDocs(PostedDoc);
    end;

    local procedure DecategorizeDocs()
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        CarteraManagement.DecategorizePostedDocs(PostedDoc);
    end;

    local procedure SettleDocs()
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        if not PostedDoc.Find('=><') then
            exit;

        PostedDoc.SetRange(Status, PostedDoc.Status::Open);
        if not PostedDoc.Find('-') then
            Error(
              Text1100000 +
              Text1100001);

        REPORT.RunModal(REPORT::"Settle Docs. in Posted PO", true, false, PostedDoc);
        CurrPage.Update(false);
    end;

    local procedure RedrawDocs()
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        if not PostedDoc.Find('=><') then
            exit;

        PostedDoc.SetFilter(Status, '<>%1', PostedDoc.Status::Open);
        if not PostedDoc.Find('-') then
            Error(
              Text1100004 +
              Text1100005);

        PostedDoc.SetFilter("Document Type", '<>%1', PostedDoc."Document Type"::Bill);
        if PostedDoc.Find('-') then
            Error(Text1100006);
        PostedDoc.SetRange("Document Type");

        VendLedgEntry.Reset();
        repeat
            VendLedgEntry.Get(PostedDoc."Entry No.");
            VendLedgEntry.Mark(true);
        until PostedDoc.Next() = 0;

        VendLedgEntry.MarkedOnly(true);
        REPORT.RunModal(REPORT::"Redraw Payable Bills", true, false, VendLedgEntry);
        CurrPage.Update(false);
    end;

    local procedure NavigateDoc()
    begin
        CarteraManagement.NavigatePostedDoc(Rec);
    end;

    local procedure PartialSettle()
    var
        VendLedgEntry2: Record "Vendor Ledger Entry";
        PartialSettlePayable: Report "Partial Settl. - Payable";
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        if not PostedDoc.Find('=><') then
            exit;

        PostedDoc.SetRange(Status, PostedDoc.Status::Open);
        if not PostedDoc.Find('-') then
            Error(
              Text1100000 +
              Text1100007);
        if PostedDoc.Count > 1 then
            Error(Text1100008);

        Clear(PartialSettlePayable);
        VendLedgEntry2.Get(PostedDoc."Entry No.");
        if (WorkDate() <= VendLedgEntry2."Pmt. Discount Date") and
           (PostedDoc."Document Type" = PostedDoc."Document Type"::Invoice)
        then
            PartialSettlePayable.SetInitValue(PostedDoc."Remaining Amount" + VendLedgEntry2."Remaining Pmt. Disc. Possible",
              PostedDoc."Currency Code", PostedDoc."Entry No.")
        else
            PartialSettlePayable.SetInitValue(PostedDoc."Remaining Amount",
              PostedDoc."Currency Code", PostedDoc."Entry No.");
        PartialSettlePayable.SetTableView(PostedDoc);
        PartialSettlePayable.RunModal();
        CurrPage.Update(false);
    end;
}

