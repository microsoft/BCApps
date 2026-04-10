#pragma warning disable AA0247
page 17244 "Tax Vendor Ledger Entries"
{
    Caption = 'Tax Vendor Ledger Entries';
    DataCaptionFields = "Vendor No.";
    Editable = false;
    PageType = List;
    SourceTable = "Vendor Ledger Entry";

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
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the vendor that is associated with the person.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Purchaser Code"; Rec."Purchaser Code")
                {
                    ToolTip = 'Specifies which purchaser is assigned to the vendor.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Original Amount"; Rec."Original Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Original Amt. (LCY)"; Rec."Original Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the amount.';
                    Visible = false;
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount of the ledger entry.';
                }
                field("Remaining Amount"; Rec."Remaining Amount")
                {
                    ToolTip = 'Specifies the amount that remains to be paid.';
                    Visible = false;
                }
                field("Remaining Amt. (LCY)"; Rec."Remaining Amt. (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount that remains to be paid, expressed in LCY.';
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                    Visible = false;
                }
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the related invoice must be paid.';
                }
                field("Pmt. Discount Date"; Rec."Pmt. Discount Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date on which the amount in the entry must be paid for a payment discount to be granted.';
                }
                field("Pmt. Disc. Tolerance Date"; Rec."Pmt. Disc. Tolerance Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest date the amount in the entry must be paid in order for payment discount tolerance to be granted.';
                }
                field("Original Pmt. Disc. Possible"; Rec."Original Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Remaining Pmt. Disc. Possible"; Rec."Remaining Pmt. Disc. Possible")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the remaining payment discount which can be received if the payment is made before the payment discount date.';
                }
                field("Max. Payment Tolerance"; Rec."Max. Payment Tolerance")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Open; Rec.Open)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("On Hold"; Rec."On Hold")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                }
                field("User ID"; Rec."User ID")
                {
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Ent&ry")
            {
                Caption = 'Ent&ry';
                Image = Entry;
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to journal lines to distribute costs and analyze transaction history.';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                    end;
                }
                action("Detailed &Ledger Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Detailed &Ledger Entries';
                    Image = View;
                    RunObject = Page "Detailed Vendor Ledg. Entries";
                    RunPageLink = "Vendor Ledger Entry No." = field("Entry No."),
                                  "Vendor No." = field("Vendor No.");
                    RunPageView = sorting("Vendor Ledger Entry No.", "Posting Date");
                    ShortCutKey = 'Ctrl+F7';
                }
            }
            group("&Application")
            {
                Caption = '&Application';
                Image = Apply;
                action("Applied E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Applied E&ntries';
                    Image = Approve;
                    RunObject = Page "Applied Vendor Entries";
                    RunPageOnRec = true;
                }
                action("Apply Entries")
                {
                    Caption = 'Apply Entries';
                    Image = ApplyEntries;
                    RunObject = Page "Apply Vendor Entries";
                    RunPageLink = "Vendor No." = field("Vendor No."),
                                  Open = const(true);
                    RunPageView = sorting("Vendor No.", Open);
                    ShortCutKey = 'Shift+F11';
                    Visible = false;
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
                    Navigate.SetDoc(Rec."Posting Date", Rec."Document No.");
                    Navigate.Run();
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

    trigger OnAfterGetRecord()
    begin
        DocumentNoOnFormat();
        VendorNoOnFormat();
        DescriptionOnFormat();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        if not UseTmpVendLedgerEntry then
            exit(Rec.Find(Which));
        TmpVendLedgerEntry.Copy(Rec);
        FindResult := TmpVendLedgerEntry.Find(Which);
        if FindResult then
            Rec := TmpVendLedgerEntry;
        exit(FindResult);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        if not UseTmpVendLedgerEntry then
            exit(Rec.Next(Steps));
        TmpVendLedgerEntry := Rec;
        NextResult := TmpVendLedgerEntry.Next(Steps);
        if NextResult <> 0 then
            Rec := TmpVendLedgerEntry;
        exit(NextResult);
    end;

    var
        TmpVendLedgerEntry: Record "Vendor Ledger Entry" temporary;
        Navigate: Page Navigate;
        UseTmpVendLedgerEntry: Boolean;
        FindResult: Boolean;
        NextResult: Integer;

    [Scope('OnPrem')]
    procedure BuildTmpVendLedgerEntry(VendNo: Code[20]; DateBegin: Date; DateEnd: Date; DueFilter: Text[30]; PositiveEntry: Boolean)
    begin
        Rec.Reset();
        Rec.SetCurrentKey("Vendor No.", "Posting Date");
        Rec.SetRange("Vendor No.", VendNo);
        Rec.SetRange("Posting Date", DateBegin, DateEnd);
        Rec.SetRange(Positive, PositiveEntry);
        if Rec.FindSet() then
            repeat
                TmpVendLedgerEntry := Rec;
                TmpVendLedgerEntry.Insert();
            until Rec.Next() = 0;

        Rec.Reset();
        Rec.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        Rec.SetRange("Vendor No.", VendNo);
        Rec.SetRange(Positive, PositiveEntry);
        Rec.SetFilter("Due Date", DueFilter);
        Rec.SetFilter("Date Filter", '..%1', DateBegin - 1);
        if Rec.FindSet() then
            repeat
                Rec.CalcFields("Remaining Amt. (LCY)");
                if Rec."Remaining Amt. (LCY)" <> 0 then begin
                    TmpVendLedgerEntry := Rec;
                    if TmpVendLedgerEntry.Insert() then;
                end;
            until Rec.Next() = 0;

        Rec.Reset();
        Rec.SetCurrentKey("Vendor No.", Open, Positive, "Due Date");
        Rec.SetRange("Vendor No.", VendNo);
        Rec.SetRange(Positive, PositiveEntry);
        Rec.SetFilter("Due Date", DueFilter);
        Rec.SetFilter("Date Filter", '..%1', DateEnd);
        if Rec.FindSet() then
            repeat
                Rec.CalcFields("Remaining Amt. (LCY)");
                if Rec."Remaining Amt. (LCY)" <> 0 then begin
                    TmpVendLedgerEntry := Rec;
                    if TmpVendLedgerEntry.Insert() then;
                end;
            until Rec.Next() = 0;
        Rec.Reset();
        Rec.SetFilter("Date Filter", DueFilter);
        UseTmpVendLedgerEntry := true;
    end;

    local procedure DocumentNoOnFormat()
    begin
        if Rec.Open = true then begin
            Rec.CalcFields(Amount);
            if Rec.Amount < 0 then;
        end;
    end;

    local procedure VendorNoOnFormat()
    begin
        if Rec.Open = true then begin
            Rec.CalcFields(Amount);
            if Rec.Amount < 0 then;
        end;
    end;

    local procedure DescriptionOnFormat()
    begin
        if Rec.Open = true then begin
            Rec.CalcFields(Amount);
            if Rec.Amount < 0 then;
        end;
    end;
}

