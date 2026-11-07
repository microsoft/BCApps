#pragma warning disable AA0247
page 12431 "Advance Statement"
{
    Caption = 'Advance Statement';
    PageType = Document;
    PopulateAllFields = true;
    RefreshOnActivate = true;
    SourceTable = "Purchase Header";
    SourceTableView = where("Document Type" = filter(Invoice),
                            "Empl. Purchase" = const(true));

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
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field("Buy-from Vendor No."; Rec."Buy-from Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee No.';
                    Importance = Promoted;
                    LookupPageID = "Responsible Employees";

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Buy-from Vendor Name"; Rec."Buy-from Vendor Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Employee Name';
                    Importance = Promoted;
                }
                field("Advance Purpose"; Rec."Advance Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the advance associated with the purchase header.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies any text that is entered to accompany the posting, for example for information to auditors.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Vendor Invoice No."; Rec."Vendor Invoice No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the document number of the original document you received from the vendor. You can require the document number for posting, or let it be optional. By default, it''s required, so that this document references the original. Making document numbers optional removes a step from the posting process. For example, if you attach the original invoice as a PDF, you might not need to enter the document number. To specify whether document numbers are required, in the Purchases & Payables Setup window, select or clear the Ext. Doc. No. Mandatory field.';
                }
                field("Prices Including VAT"; Rec."Prices Including VAT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the Unit Price and Line Amount fields on document lines should be shown with or without VAT.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the status of the record.';
                }
            }
            part(PurchLines; "Advance Statement Subform")
            {
                ApplicationArea = Basic, Suite;
                SubPageLink = "Document No." = field("No.");
            }
            group(Statement)
            {
                Caption = 'Statement';
                field("No. of Documents"; Rec."No. of Documents")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of documents associated with the purchase header.';
                }
                field("No. of Pages"; Rec."No. of Pages")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the number of pages associated with the purchase header.';
                }
                field("Remaining/Overdraft Doc. No."; Rec."Remaining/Overdraft Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the remaining or overdraft document number associated with the purchase header.';
                }
            }
            group("Foreign Trade")
            {
                Caption = 'Foreign Trade';
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                    ToolTip = 'Specifies the currency code for the record.';

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then begin
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                            CurrPage.Update();
                        end;
                        Clear(ChangeExchangeRate);
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Advance")
            {
                Caption = '&Advance';
                action(Statistics)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Statistics';
                    Image = Statistics;
                    ShortCutKey = 'F7';
                    ToolTip = 'View statistical information, such as the value of posted entries, for the record.';

                    trigger OnAction()
                    begin
                        Rec.CalcInvDiscForHeader();
                        Commit();
                        PAGE.RunModal(PAGE::"Purchase Statistics", Rec);
                    end;
                }
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Page "Vendor Card";
                    RunPageLink = "No." = field("Buy-from Vendor No.");
                    ShortCutKey = 'Shift+F7';
                }
                action("Co&mments")
                {
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Purch. Comment Sheet";
                    RunPageLink = "Document Type" = field("Document Type"),
                                  "No." = field("No.");
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;

                    trigger OnAction()
                    begin
                        Rec.ShowDocDim();
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Calculate &Invoice Discount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Calculate &Invoice Discount';
                    Image = CalculateInvoiceDiscount;

                    trigger OnAction()
                    begin
                        ApproveCalcInvDisc();
                    end;
                }
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Ellipsis = true;
                    Image = CopyDocument;

                    trigger OnAction()
                    begin
                        CopyPurchDoc.SetPurchHeader(Rec);
                        CopyPurchDoc.RunModal();
                        Clear(CopyPurchDoc);
                    end;
                }
                action("Move Negative Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Move Negative Lines';
                    Ellipsis = true;
                    Image = MoveNegativeLines;
                    ToolTip = 'Prepare to create a replacement sales order in a sales return process.';

                    trigger OnAction()
                    begin
                        Clear(MoveNegPurchLines);
                        MoveNegPurchLines.SetPurchHeader(Rec);
                        MoveNegPurchLines.RunModal();
                        MoveNegPurchLines.ShowDocument();
                    end;
                }
                action("Re&lease")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&lease';
                    Image = ReleaseDoc;
                    RunObject = Codeunit "Release Purchase Document";
                    ShortCutKey = 'Ctrl+F9';
                    ToolTip = 'Enable the record for the next stage of processing. ';
                }
                action("Re&open")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Re&open';
                    Image = ReOpen;
                    ToolTip = 'Open the closed or released record.';

                    trigger OnAction()
                    var
                        ReleasePurchDoc: Codeunit "Release Purchase Document";
                    begin
                        ReleasePurchDoc.Reopen(Rec);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintPurchHeader(Rec);
                    end;
                }
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    begin
                        CheckAdvStmtPostingDate();
                        CODEUNIT.Run(CODEUNIT::"Purch.-Post (Yes/No)", Rec);
                    end;
                }
                action("Post and &Print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post and &Print';
                    Image = PostPrint;
                    ShortCutKey = 'Shift+F9';
                    ToolTip = 'Finalize and prepare to print the document or journal. The values and quantities are posted to the related accounts. A report request window where you can specify what to include on the print-out.';

                    trigger OnAction()
                    begin
                        CheckAdvStmtPostingDate();
                        CODEUNIT.Run(CODEUNIT::"Purch.-Post + Print", Rec);
                    end;
                }
                action("Post &Batch")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post &Batch';
                    Ellipsis = true;
                    Image = PostBatch;
                    ToolTip = 'Post several documents at once. A report request window opens where you can specify which documents to post.';

                    trigger OnAction()
                    begin
                        REPORT.RunModal(REPORT::"Batch Post Purchase Invoices", true, true, Rec);
                        CurrPage.Update(false);
                    end;
                }
            }
            action("&Print")
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;

                trigger OnAction()
                begin
                    DocPrint.PrintAdvStmt(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Copy Document_Promoted"; "Copy Document")
                {
                }
                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
                actionref("&Print_Promoted"; "&Print")
                {
                }
                actionref("Re&lease_Promoted"; "Re&lease")
                {
                }
                actionref("Re&open_Promoted"; "Re&open")
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
        exit(Rec.ConfirmDeletion());
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        NoSeries: Codeunit "No. Series";
    begin
        PurchSetup.Get();
        if Rec."No." = '' then begin
            PurchSetup.TestField("Advance Statement Nos.");
                Rec."No. Series" := PurchSetup."Advance Statement Nos.";
                if NoSeries.AreRelated(Rec."No. Series", xRec."No. Series") then
                    Rec."No. Series" := xRec."No. Series";
                Rec."No." := NoSeries.GetNextNo(Rec."No. Series", Rec."Posting Date");
        end;
        if Rec."Posting No. Series" = '' then begin
            Rec."Posting No. Series" := Rec."No. Series";
            Rec."Posting No." := Rec."No.";
        end;
        if Rec."Receiving No. Series" = '' then begin
            Rec."Receiving No. Series" := Rec."No. Series";
            Rec."Receiving No." := Rec."No.";
        end;

        if Rec."Empl. Purchase" = true then
            Rec."Vendor Invoice No." := Rec."No.";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Responsibility Center" := UserMgt.GetPurchasesFilter();
    end;

    trigger OnOpenPage()
    begin
        if UserMgt.GetPurchasesFilter() <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Responsibility Center", UserMgt.GetPurchasesFilter());
            Rec.FilterGroup(0);
        end;
    end;

    var
        PurchSetup: Record "Purchases & Payables Setup";
        CopyPurchDoc: Report "Copy Purchase Document";
        MoveNegPurchLines: Report "Move Negative Purchase Lines";
        ReportPrint: Codeunit "Test Report-Print";
        UserMgt: Codeunit "User Setup Management";
        DocPrint: Codeunit "Document-Print";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text12401: Label 'Posting Date %1 in Advance Statement No. %2 must not be less than Posting Date in Empl. Purchase Entry No. %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ChangeExchangeRate: Page "Change Exchange Rate";

    local procedure ApproveCalcInvDisc()
    begin
        CurrPage.PurchLines.PAGE.ApproveCalcInvDisc();
    end;


    [Scope('OnPrem')]
    procedure CheckAdvStmtPostingDate()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        PurchHeader.Get(Rec."Document Type", Rec."No.");
        PurchLine.Reset();
        PurchLine.SetRange("Document Type", Rec."Document Type");
        PurchLine.SetRange("Document No.", Rec."No.");
        PurchLine.SetRange(Type, PurchLine.Type::"Empl. Purchase");
        if PurchLine.Find('-') then
            repeat
                if VendLedgerEntry.Get(PurchLine."Empl. Purchase Entry No.") then
                    if PurchHeader."Posting Date" < VendLedgerEntry."Posting Date" then
                        Error(Text12401, PurchHeader."Posting Date", PurchHeader."No.", VendLedgerEntry."Entry No.");
            until PurchLine.Next() = 0;
    end;
}
