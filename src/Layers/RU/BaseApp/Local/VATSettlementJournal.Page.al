#pragma warning disable AA0247
page 12437 "VAT Settlement Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'VAT Settlement Journal';
    DataCaptionFields = "Journal Batch Name";
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Gen. Journal Line";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(CurrentJnlBatchName; CurrentJnlBatchName)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Batch Name';
                Lookup = true;
                ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                trigger OnLookup(var Text: Text): Boolean
                begin
                    CurrPage.SaveRecord();
                    GenJnlManagement.LookupName(CurrentJnlBatchName, Rec);
                    CurrPage.Update(false);
                end;

                trigger OnValidate()
                begin
                    GenJnlManagement.CheckName(CurrentJnlBatchName, Rec);
                    CurrentJnlBatchNameOnAfterVali();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Unrealized VAT Entry No."; Rec."Unrealized VAT Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the unrealized VAT entry number associated with the general journal line.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date when the related document was created.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the related document.';
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ToolTip = 'Specifies a document number that refers to the customer''s or vendor''s numbering system.';
                    Visible = false;
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the purpose of the account.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the G/L account number.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field(Correction; Rec.Correction)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry as a corrective entry. You can use the field if you need to post a corrective entry to an account.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                }
                field("Unrealized Amount"; Rec."Unrealized Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the unrealized VAT amount for this line if you use unrealized VAT.';
                }
                field("Paid Amount"; Rec."Paid Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remaining VAT Amount';
                    Editable = false;
                    ToolTip = 'Specifies the VAT amount that remains to be processed.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount.';

                    trigger OnValidate()
                    begin
                        AmountOnAfterValidate();
                    end;
                }
                field("Allocated VAT Amount"; Rec."Allocated VAT Amount")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the allocated VAT amount associated with the general journal line.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        LookupVATAllocation();
                        CurrPage.Update(true);
                    end;
                }
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the object type associated with the general journal line.';
                }
                field("Object No."; Rec."Object No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the object number associated with the general journal line.';
                }
                field("Corrected Document Date"; Rec."Corrected Document Date")
                {
                    ToolTip = 'Specifies the corrected document date associated with the general journal line.';
                    Visible = false;
                }
                field("Prepmt. Diff."; Rec."Prepmt. Diff.")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment difference associated with the general journal line.';
                }
                field("Initial VAT Entry No."; Rec."Initial VAT Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the initial VAT entry number associated with the general journal line.';
                }
            }
            group(Control16)
            {
                ShowCaption = false;
                field(CalcDate; CalculatedDate)
                {
                    ApplicationArea = All;
                    Caption = 'Date';
                    Editable = false;
                    ToolTip = 'Specifies the date when VAT was settled.';
                    Visible = CalcDateVisible;
                }
                field(Desc; LineDescription)
                {
                    ApplicationArea = All;
                    Caption = 'Line Description';
                    Editable = false;
                    ToolTip = 'Specifies the description on the related document line.';
                    Visible = DescVisible;
                }
                field(Balance; Balance + Rec."Balance (LCY)" - xRec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'VAT Balance';
                    Editable = false;
                    ToolTip = 'Specifies the VAT amount.';
                    Visible = BalanceVisible;
                }
                field(TotalBalance; TotalBalance + Rec."Balance (LCY)" - xRec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Total VAT Balance';
                    Editable = false;
                    ToolTip = 'Specifies the total VAT amount.';
                    Visible = TotalBalanceVisible;
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
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("VAT Allocations")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'VAT Allocations';
                    Image = Track;
                    ToolTip = 'Allocate amounts to VAT entries.';

                    trigger OnAction()
                    begin
                        LookupVATAllocation();
                        CurrPage.Update(true);
                    end;
                }
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.Update();
                    end;
                }
            }
            group("A&ccount")
            {
                Caption = 'A&ccount';
                Image = ChartOfAccounts;
                action(Card)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Card';
                    Image = EditLines;
                    RunObject = Codeunit "Gen. Jnl.-Show Card";
                    ShortCutKey = 'Shift+F7';
                }
                action("Ledger E&ntries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Ledger E&ntries';
                    Image = VendorLedger;
                    //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                    //PromotedCategory = Process;
                    RunObject = Codeunit "Gen. Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
        }
        area(processing)
        {
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action("P&ost")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&ost';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the related transaction in your books.';

                    trigger OnAction()
                    var
                        GenJnlPost: Codeunit "Gen. Jnl.-Post";
                    begin
                        Clear(GenJnlPost);
                        GenJnlPost.SetJnlType(1); // 1 = Deferred VAT Settlement
                        GenJnlPost.Run(Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
            action(Preview)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Preview Posting';
                Image = ViewPostedOrder;
                ShortCutKey = 'Ctrl+Alt+F9';
                ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                trigger OnAction()
                var
                    GenJnlPost: Codeunit "Gen. Jnl.-Post";
                begin
                    Clear(GenJnlPost);
                    GenJnlPost.SetJnlType(1); // 1 = Deferred VAT Settlement
                    GenJnlPost.Preview(Rec);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;

                trigger OnAction()
                var
                    Navigate: Page Navigate;
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

                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("&Navigate_Promoted"; "&Navigate")
                {
                }
                actionref("VAT Allocations_Promoted"; "VAT Allocations")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateBalance();
        UpdateInfo();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        DescVisible := true;
        CalcDateVisible := true;
        TotalBalanceVisible := true;
        BalanceVisible := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.TestField("Unrealized VAT Entry No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        OpenedFromBatch := (Rec."Journal Batch Name" <> '') and (Rec."Journal Template Name" = '');
        if OpenedFromBatch then begin
            CurrentJnlBatchName := Rec."Journal Batch Name";
            GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
            exit;
        end;
        GenJnlManagement.TemplateSelection(PAGE::"VAT Settlement Journal", "Gen. Journal Template Type"::"VAT Settlement", false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        GenJnlManagement: Codeunit GenJnlManagement;
        CurrentJnlBatchName: Code[10];
        LineDescription: Text[100];
        ShortcutDimCode: array[8] of Code[20];
        CalculatedDate: Date;
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        InitialAmount: Decimal;
        OpenedFromBatch: Boolean;
        BalanceVisible: Boolean;
        TotalBalanceVisible: Boolean;
        CalcDateVisible: Boolean;
        DescVisible: Boolean;

    [Scope('OnPrem')]
    procedure UpdateInfo()
    var
        VATEntry: Record "VAT Entry";
        FA: Record "Fixed Asset";
    begin
        InitialAmount := 0;
        CalculatedDate := 0D;
        if VATEntry.Get(Rec."Unrealized VAT Entry No.") then
            InitialAmount := VATEntry."Unrealized Amount";
        LineDescription := '';
        CalculatedDate := 0D;
        if Rec."Object Type" = Rec."Object Type"::"Fixed Asset" then
            if FA.Get(Rec."Object No.") then begin
                LineDescription := FA.Description;
                CalculatedDate := FA."Initial Release Date";
            end else
                case Rec."VAT Settlement Part" of
                    Rec."VAT Settlement Part"::Custom:
                        if InitialAmount <> 0 then begin
                            LineDescription := Format(InitialAmount, 0, '<Precision,2:2><Standard Format,0>');
                            CalculatedDate := VATEntry."Posting Date";
                        end;
                end;
    end;

    local procedure UpdateBalance()
    begin
        GenJnlManagement.CalcBalance(Rec, xRec, Balance, TotalBalance, ShowBalance, ShowTotalBalance);
        BalanceVisible := ShowBalance;
        TotalBalanceVisible := ShowTotalBalance;
        CalcDateVisible := ShowBalance;
        DescVisible := ShowBalance;
    end;

    [Scope('OnPrem')]
    procedure LookupVATAllocation()
    var
        VATAllocation: Record "VAT Allocation Line";
        VATAllocForm: Page "VAT Allocation";
    begin
        VATAllocation.Reset();
        VATAllocation.SetRange("VAT Entry No.", Rec."Unrealized VAT Entry No.");
        VATAllocForm.SetTableView(VATAllocation);
        VATAllocForm.SetCurrGenJnlLine(Rec);
        VATAllocForm.RunModal();

        Rec.CalcFields("Allocated VAT Amount");
        Rec.Amount := -Rec."Allocated VAT Amount";
    end;

    local procedure AmountOnAfterValidate()
    begin
        CurrPage.Update(true);
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        GenJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

