// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Navigate;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

page 7000067 "Posted Bills"
{
    Caption = 'Posted Bills';
    DataCaptionExpression = Rec.Caption();
    DataCaptionFields = Type;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Posted Cartera Doc.";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field(ClasFilter; CategoryFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Category Filter';
                    Editable = ClasFilterEditable;
                    TableRelation = "Category Code";
                    ToolTip = 'Specifies the categories that the data is included for.';

                    trigger OnValidate()
                    begin
                        CategoryFilterOnAfterValidate();
                    end;
                }
                field(StatusFilter; StatusFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status Filter';
                    Editable = StatusFilterEditable;
                    ToolTip = 'Specifies a filter for the status of bills that will be included.';

                    trigger OnValidate()
                    begin
                        StatusFilterOnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
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
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the due date of this document in a posted bill group/payment order.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of this document in a posted bill group/payment order.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of document in question.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the description associated with this posted document.';
                }
                field("Amt. for Collection (LCY)"; Rec."Amt. for Collection (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the amount due for this document in a posted bill group/payment order.';
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the pending amount in order for this document, in a posted bill group/payment order, to be settled in full.';
                }
                field("Payment Method Code"; Rec."Payment Method Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the payment method code for the document number.';
                    Visible = false;
                }
                field(Accepted; Rec.Accepted)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the Acceptance status required for this bill in a posted bill group.';
                }
                field("Collection Agent"; Rec."Collection Agent")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the agent to which this document in a posted bill group/payment order was sent.';
                }
                field("Bank Account No."; Rec."Bank Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number or code of the bank to which the bill group/payment order was delivered.';
                }
                field("Bill Gr./Pmt. Order No."; Rec."Bill Gr./Pmt. Order No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number assigned to this document in a bill group/payment order.';
                }
                field("Honored/Rejtd. at Date"; Rec."Honored/Rejtd. at Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when this document in a posted bill group/payment order is settled or rejected.';
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
            group(Control49)
            {
                ShowCaption = false;
                field("TotalCurrAmt "; TotalCurrAmtLCY)
                {
                    ApplicationArea = Basic, Suite;
                    AutoFormatType = 1;
                    Caption = 'Total Remaining Amt. (LCY)';
                    Editable = false;
                    ToolTip = 'Specifies the sum of amounts that remain to be paid.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Bill)
            {
                Caption = '&Bill';
                Image = Voucher;
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
                separator(Action1100001)
                {
                }
                action(BGPO)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'B&G/PO';
                    Image = VoucherGroup;
                    ToolTip = 'View related bill groups or payment orders.';

                    trigger OnAction()
                    var
                        SalesPostedGroup: Record "Posted Bill Group";
                        PurchasePostedGroup: Record "Posted Payment Order";
                    begin
                        if Rec.Type = Rec.Type::Receivable then begin
                            SalesPostedGroup.SetRange("No.", Rec."Bill Gr./Pmt. Order No.");
                            PAGE.Run(PAGE::"Posted Bill Groups", SalesPostedGroup)
                        end else begin
                            PurchasePostedGroup.SetRange("No.", Rec."Bill Gr./Pmt. Order No.");
                            PAGE.Run(PAGE::"Posted Payment Orders", PurchasePostedGroup);
                        end;
                    end;
                }
                separator(Action43)
                {
                }
                action(Analysis)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Analysis';
                    Image = "Report";
                    ToolTip = 'View details about the related documents. First you define which document category and currency you want to analyze documents for.';

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Posted Bills Analysis", Rec);
                    end;
                }
                action(Maturity)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Maturity';
                    Image = Aging;
                    ToolTip = 'View the document lines that have matured. Maturity information can be viewed by period start date.';

                    trigger OnAction()
                    begin
                        if Rec.Type = Rec.Type::Receivable then
                            PAGE.RunModal(PAGE::"Posted Receiv. Bills Maturity")
                        else
                            PAGE.RunModal(PAGE::"Posted Payable Bills Maturity");
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(Categorize)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Categorize';
                    Ellipsis = true;
                    Image = Category;
                    ToolTip = 'Insert categories on one or more Cartera documents to facilitate analysis. For example, to count or add only some documents, to analyze their due dates, to simulate scenarios for creating bill groups, to mark documents with your initials to indicate to other accountants that you are managing them personally.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(PostedDoc);
                        CarteraManagement.CategorizePostedDocs(PostedDoc);
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
                        CurrPage.SetSelectionFilter(PostedDoc);
                        CarteraManagement.DecategorizePostedDocs(PostedDoc);
                    end;
                }
                separator(Action37)
                {
                }
                action(Settle)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Settle';
                    Image = SettleOpenTransactions;
                    ToolTip = 'Fully settle documents included in the posted bill group.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(PostedDoc);
                        if not PostedDoc.Find('=><') then
                            exit;

                        PostedDoc.SetRange(Status, PostedDoc.Status::Open);
                        if not PostedDoc.Find('-') then
                            Error(
                              Text1100000 +
                              Text1100001);

                        if PostedDoc.Type = PostedDoc.Type::Receivable then
                            REPORT.RunModal(REPORT::"Settle Docs. in Post. Bill Gr.", true, false, PostedDoc)
                        else
                            REPORT.RunModal(REPORT::"Settle Docs. in Posted PO", true, false, PostedDoc);
                    end;
                }
                action(Reject)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reject';
                    Ellipsis = true;
                    Image = Reject;
                    ToolTip = 'Post document rejections.';

                    trigger OnAction()
                    begin
                        RejectDocs();
                    end;
                }
                action(Redraw)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Redraw';
                    Image = RefreshVoucher;
                    ToolTip = 'Create a new copy of the old bill or order, with the possibility of creating it with a new, later due date and a different payment method.';

                    trigger OnAction()
                    begin
                        RedrawDocs();
                    end;
                }
                separator(Action39)
                {
                }
                action(Print)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print';
                    Ellipsis = true;
                    Image = Print;
                    ToolTip = 'Print the document.';

                    trigger OnAction()
                    begin
                        PrintBillRec();
                    end;
                }
            }
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Ellipsis = true;
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    Option := StrMenu(Text1100002);
                    case Option of
                        0:
                            exit;
                        1:
                            CarteraManagement.NavigatePostedDoc(Rec);
                        2:
                            begin
                                Navigate.SetDoc(Rec."Posting Date", Rec."Bill Gr./Pmt. Order No.");
                                Navigate.Run();
                            end;
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        UpdateStatistics();
    end;

    trigger OnInit()
    begin
        StatusFilterEditable := true;
        ClasFilterEditable := true;
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CODEUNIT.Run(CODEUNIT::"Posted Cartera Doc.- Edit", Rec);
        UpdateStatistics();
        exit(false);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        AfterGetCurrentRecord();
    end;

    trigger OnOpenPage()
    begin
        UpdateStatistics();
    end;

    var
        Text1100000: Label 'No bills have been found that can be settled. \';
        Text1100001: Label 'Please check that at least one open bill was selected.';
        Text1100002: Label 'Related to Bill,Related to Bill Group';
        Text1100003: Label 'Open|Honored|Rejected';
        Text1100004: Label 'Only Receivable Bills can be printed.';
        Text1100005: Label 'Only Receivable Bills can be rejected.';
        Text1100006: Label 'No bills have been found that can be rejected. \';
        Text1100007: Label 'No bills have been found that can be redrawn. \';
        Text1100008: Label 'Please check that at least one rejected or honored bill was selected.';
        Text1100009: Label 'Only bills can be redrawn.';
        PostedDoc: Record "Posted Cartera Doc.";
        CustLedgEntry: Record "Cust. Ledger Entry";
        VendLedgEntry: Record "Vendor Ledger Entry";
        Navigate: Page Navigate;
        CarteraManagement: Codeunit CarteraManagement;
        CategoryFilter: Code[250];
        ActiveFilter: Text[250];
        TotalCurrAmtLCY: Decimal;
        StatusFilter: Option Open,Honored,Rejected,All;
        Option: Option "0","1","2";
        Call: Boolean;
        ClasFilterEditable: Boolean;
        StatusFilterEditable: Boolean;

    [Scope('OnPrem')]
    procedure UpdateStatistics()
    begin
        PostedDoc.Reset();
        PostedDoc.SetCurrentKey("Bank Account No.", "Bill Gr./Pmt. Order No.", Status,
          "Category Code", Redrawn, "Due Date", "Document Type");
        PostedDoc.CopyFilters(Rec);
        PostedDoc.SetRange("Document Type", PostedDoc."Document Type"::Bill);
        PostedDoc.SetFilter("Category Code", CategoryFilter);
        PostedDoc.CalcSums(PostedDoc."Remaining Amt. (LCY)");
        TotalCurrAmtLCY := PostedDoc."Remaining Amt. (LCY)";

        ActiveFilter := Rec.GetFilter(Status);
        case ActiveFilter of
            '':
                StatusFilter := StatusFilter::All;
            Text1100003:
                StatusFilter := StatusFilter::All
            else
                StatusFilter := Rec.Status.AsInteger();
        end;

        if Call = true then
            CategoryFilter := Rec.GetFilter("Category Code");
    end;

    [Scope('OnPrem')]
    procedure GetSelect(var NewPostedDoc: Record "Posted Cartera Doc.")
    begin
        CurrPage.SetSelectionFilter(NewPostedDoc);
    end;

    [Scope('OnPrem')]
    procedure PrintBillRec()
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        if not PostedDoc.Find('-') then
            exit;

        if PostedDoc.Type <> PostedDoc.Type::Receivable then
            Error(Text1100004);

        CustLedgEntry.Reset();
        repeat
            CustLedgEntry.Get(PostedDoc."Entry No.");
            CustLedgEntry.Mark(true);
        until PostedDoc.Next() = 0;

        CustLedgEntry.MarkedOnly(true);
        CustLedgEntry.PrintBill(true);
    end;

    [Scope('OnPrem')]
    procedure RejectDocs()
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        if not PostedDoc.Find('=><') then
            exit;

        if PostedDoc.Type <> PostedDoc.Type::Receivable then
            Error(Text1100005);

        PostedDoc.SetRange(Status, PostedDoc.Status::Open);
        if not PostedDoc.Find('-') then
            Error(
              Text1100006 +
              Text1100001);
        CustLedgEntry.Reset();
        repeat
            CustLedgEntry.Get(PostedDoc."Entry No.");
            CustLedgEntry.Mark(true);
        until PostedDoc.Next() = 0;

        CustLedgEntry.MarkedOnly(true);
        REPORT.RunModal(REPORT::"Reject Docs.", true, false, CustLedgEntry);
    end;

    [Scope('OnPrem')]
    procedure RedrawDocs()
    begin
        CurrPage.SetSelectionFilter(PostedDoc);
        if not PostedDoc.Find('=><') then
            exit;

        PostedDoc.SetFilter(Status, '<>%1', PostedDoc.Status::Open);
        if not PostedDoc.Find('-') then
            Error(
              Text1100007 +
              Text1100008);

        PostedDoc.SetFilter("Document Type", '<>%1', PostedDoc."Document Type"::Bill);
        if PostedDoc.Find('-') then
            Error(Text1100009);
        PostedDoc.SetRange("Document Type");

        if Rec.Type = Rec.Type::Receivable then begin
            CustLedgEntry.Reset();
            repeat
                CustLedgEntry.Get(PostedDoc."Entry No.");
                CustLedgEntry.Mark(true);
            until PostedDoc.Next() = 0;

            CustLedgEntry.MarkedOnly(true);
            REPORT.RunModal(REPORT::"Redraw Receivable Bills", true, false, CustLedgEntry);
        end else begin
            VendLedgEntry.Reset();
            repeat
                VendLedgEntry.Get(PostedDoc."Entry No.");
                VendLedgEntry.Mark(true);
            until PostedDoc.Next() = 0;

            VendLedgEntry.MarkedOnly(true);
            REPORT.RunModal(REPORT::"Redraw Payable Bills", true, false, VendLedgEntry);
        end;
    end;

    [Scope('OnPrem')]
    procedure Called()
    begin
        Call := true;
        ClasFilterEditable := false;
        StatusFilterEditable := false;
    end;

    local procedure CategoryFilterOnAfterValidate()
    begin
        UpdateStatistics();
    end;

    local procedure StatusFilterOnAfterValidate()
    begin
        if StatusFilter = StatusFilter::All then
            Rec.SetRange(Status)
        else
            Rec.SetRange(Status, StatusFilter);
        UpdateStatistics();
        CurrPage.Update();
    end;

    local procedure AfterGetCurrentRecord()
    begin
        xRec := Rec;
        UpdateStatistics();
    end;
}

