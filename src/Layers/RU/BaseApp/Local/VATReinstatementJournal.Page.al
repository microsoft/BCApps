#pragma warning disable AA0247
page 14946 "VAT Reinstatement Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'VAT Reinstatement Journal';
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
                field("Reinstatement VAT Entry No."; Rec."Reinstatement VAT Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the reinstatement VAT entry number associated with the general journal line.';
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
                field("Initial VAT Entry No."; Rec."Initial VAT Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the initial VAT entry number associated with the general journal line.';
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
                action(Dimensions)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    ShortCutKey = 'Shift+Ctrl+D';

                    trigger OnAction()
                    begin
                        Rec.ShowDimensions();
                        CurrPage.SaveRecord();
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
                    Image = LedgerEntries;
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
                        GenJnlPost.SetJnlType(3); // 3 = VAT Reinstatement
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
                    GenJnlPost.SetJnlType(3); // 3 = VAT Reinstatement
                    GenJnlPost.Preview(Rec);
                end;
            }
            action("&Navigate")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;

                trigger OnAction()
                begin
                    NavigateSourceDocument();
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
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.TestField("Reinstatement VAT Entry No.");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        GLSetup.Get();
        GenJnlTemplate.Get(Rec."Journal Template Name");
        GenJnlBatch.Get(Rec."Journal Template Name", Rec."Journal Batch Name");
        Rec."Source Code" := GenJnlTemplate."Source Code";
        Rec."Reason Code" := GenJnlBatch."Reason Code";
        Rec.Correction := GLSetup."Red Storno VAT Reinstatement";

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
        GenJnlManagement.TemplateSelection(PAGE::"VAT Reinstatement Journal", "Gen. Journal Template Type"::"VAT Reinstatement", false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        GLSetup: Record "General Ledger Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlManagement: Codeunit GenJnlManagement;
        CurrentJnlBatchName: Code[10];
        ShortcutDimCode: array[8] of Code[20];
        OpenedFromBatch: Boolean;

    [Scope('OnPrem')]
    procedure NavigateSourceDocument()
    var
        SourceVATEntry: Record "VAT Entry";
        VATEntry: Record "VAT Entry";
        Navigate: Page Navigate;
    begin
        if Rec."Reinstatement VAT Entry No." <> 0 then begin
            VATEntry.Get(Rec."Reinstatement VAT Entry No.");
            SourceVATEntry.Get(VATEntry."Unrealized VAT Entry No.");
            Navigate.SetDoc(SourceVATEntry."Posting Date", Rec."Document No.");
        end;
        Navigate.Run();
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

