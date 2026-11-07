#pragma warning disable AA0247
page 12438 "Cash Order Journal"
{
    ApplicationArea = Basic, Suite;
    AutoSplitKey = true;
    Caption = 'Cash Order Journal';
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
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Date"; Rec."Document Date")
                {
                    ToolTip = 'Specifies the date when the related document was created.';
                    Visible = false;
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the related document.';
                }
                field(Prepayment; Rec.Prepayment)
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies if the related payment is a prepayment.';
                }
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Basic, Suite;
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
                    ToolTip = 'Specifies the purpose of the account.';

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                    end;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Beneficiary Bank Code"; Rec."Beneficiary Bank Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the beneficiary bank code associated with the general journal line.';
                    Visible = true;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
                }
                field("Prepayment Document No."; Rec."Prepayment Document No.")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment document number associated with the general journal line.';
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with the general journal line.';

                    trigger OnValidate()
                    begin
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ToolTip = 'Specifies the code for the salesperson or purchaser who is linked to the sale or purchase on the journal line.';
                    Visible = false;
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ToolTip = 'Specifies the number of the campaign that the journal line is linked to.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    AssistEdit = true;
                    ToolTip = 'Specifies the currency code for the record.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeExchangeRate.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeExchangeRate.RunModal() = ACTION::OK then
                            Rec.Validate("Currency Factor", ChangeExchangeRate.GetParameter());
                        Clear(ChangeExchangeRate);
                    end;
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ToolTip = 'Specifies the type of transaction.';
                    Visible = false;
                }
                field("Gen. Bus. Posting Group"; Rec."Gen. Bus. Posting Group")
                {
                    ToolTip = 'Specifies the vendor''s or customer''s trade type to link transactions made for this business partner with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ToolTip = 'Specifies the item''s product type to link transactions made for this item with the appropriate general ledger account according to the general posting setup.';
                    Visible = false;
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the VAT specification of the involved customer or vendor to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent debits.';
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total of the ledger entries that represent credits.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                    Visible = false;
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the amount.';
                    Visible = false;
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                    ToolTip = 'Specifies the amount of VAT that is included in the total amount.';
                    Visible = false;
                }
                field("VAT Difference"; Rec."VAT Difference")
                {
                    ToolTip = 'Specifies the difference between the calculated VAT amount and a VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Bal. VAT Amount"; Rec."Bal. VAT Amount")
                {
                    ToolTip = 'Specifies the amount of Bal. VAT included in the total amount.';
                    Visible = false;
                }
                field("Bal. VAT Difference"; Rec."Bal. VAT Difference")
                {
                    ToolTip = 'Specifies the difference between the calculate VAT amount and the VAT amount that you have entered manually.';
                    Visible = false;
                }
                field("Bal. Account Type"; Rec."Bal. Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of account that a balancing entry is posted to, such as BANK for a cash account.';
                }
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';

                    trigger OnValidate()
                    begin
                        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
                        Rec.ShowShortcutDimCode(ShortcutDimCode);
                    end;
                }
                field("Bal. Gen. Posting Type"; Rec."Bal. Gen. Posting Type")
                {
                    ToolTip = 'Specifies the general posting type associated with the balancing account that will be used when you post the entry on the journal line.';
                    Visible = false;
                }
                field("Bal. Gen. Bus. Posting Group"; Rec."Bal. Gen. Bus. Posting Group")
                {
                    ToolTip = 'Specifies the general business posting group code associated with the balancing account that will be used when you post the entry.';
                    Visible = false;
                }
                field("Bal. Gen. Prod. Posting Group"; Rec."Bal. Gen. Prod. Posting Group")
                {
                    ToolTip = 'Specifies the general product posting group code associated with the balancing account that will be used when you post the entry.';
                    Visible = false;
                }
                field("Bal. VAT Bus. Posting Group"; Rec."Bal. VAT Bus. Posting Group")
                {
                    ToolTip = 'Specifies the code of the VAT business posting group that will be used when you post the entry on the journal line.';
                    Visible = false;
                }
                field("Bal. VAT Prod. Posting Group"; Rec."Bal. VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the code of the VAT product posting group that will be used when you post the entry on the journal line.';
                    Visible = false;
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
                field("ShortcutDimCode[3]"; ShortcutDimCode[3])
                {
                    CaptionClass = '1,2,3';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(3),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(3, ShortcutDimCode[3]);
                    end;
                }
                field("ShortcutDimCode[4]"; ShortcutDimCode[4])
                {
                    CaptionClass = '1,2,4';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(4),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(4, ShortcutDimCode[4]);
                    end;
                }
                field("ShortcutDimCode[5]"; ShortcutDimCode[5])
                {
                    CaptionClass = '1,2,5';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(5),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(5, ShortcutDimCode[5]);
                    end;
                }
                field("ShortcutDimCode[6]"; ShortcutDimCode[6])
                {
                    CaptionClass = '1,2,6';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(6),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(6, ShortcutDimCode[6]);
                    end;
                }
                field("ShortcutDimCode[7]"; ShortcutDimCode[7])
                {
                    CaptionClass = '1,2,7';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(7),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(7, ShortcutDimCode[7]);
                    end;
                }
                field("ShortcutDimCode[8]"; ShortcutDimCode[8])
                {
                    CaptionClass = '1,2,8';
                    TableRelation = "Dimension Value".Code where("Global Dimension No." = const(8),
                                                                  "Dimension Value Type" = const(Standard),
                                                                  Blocked = const(false));
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.ValidateShortcutDimCode(8, ShortcutDimCode[8]);
                    end;
                }
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = false;
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("VAT Entry Type"; Rec."VAT Entry Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a VAT entry code according to Russian legislation. Some types of documents, such as corrective or revision invoices, must have multiple VAT entry type codes.';
                }
            }
            group(Control24)
            {
                ShowCaption = false;
                field(AccName; AccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                }
                field(BalAccName; BalAccName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bal. Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the balancing account that has been entered on the journal line.';
                }
                field(Balance; Balance + Rec."Balance (LCY)" - xRec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Balance';
                    Editable = false;
                    ToolTip = 'Specifies the balance that has accumulated in the journal on the line where the cursor is.';
                    Visible = BalanceVisible;
                }
                field(TotalBalance; TotalBalance + Rec."Balance (LCY)" - xRec."Balance (LCY)")
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    Caption = 'Total Balance';
                    Editable = false;
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
                    Image = LedgerEntries;
                    RunObject = Codeunit "Gen. Jnl.-Show Entries";
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the history of transactions that have been posted for the selected record.';
                }
            }
            group("&Payments")
            {
                Caption = '&Payments';
                Image = Payment;
                action("P&review Cash Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'P&review Cash Order';
                    Image = View;
                    ToolTip = 'Review the different types of entries that will be created when you post the document or journal.';

                    trigger OnAction()
                    begin
                        CheckManagement.ShowPaymentDocument(Rec);
                        CODEUNIT.Run(CODEUNIT::"Adjust Gen. Journal Balance", Rec);
                        CurrPage.Update(false);
                    end;
                }
                action("Print Cash Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Print Cash Order';
                    Ellipsis = true;
                    Image = PrintDocument;

                    trigger OnAction()
                    var
                        BankAcc: Record "Bank Account";
                        DocPrint: Codeunit "Document-Print";
                    begin
                        GenJnlLine.Reset();
                        GenJnlLine.Copy(Rec);
                        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", Rec."Line No.");
                        GenJnlLine.TestField("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
                        BankAcc.Get(GenJnlLine."Bal. Account No.");
                        case BankAcc."Account Type" of
                            BankAcc."Account Type"::"Bank Account":
                                DocPrint.PrintCheck(GenJnlLine);
                            BankAcc."Account Type"::"Cash Account":
                                DocPrint.PrintCashOrder(GenJnlLine);
                        end;
                        CODEUNIT.Run(CODEUNIT::"Adjust Gen. Journal Balance", Rec);
                    end;
                }
                action("Void Cash Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void Cash Order';
                    Image = VoidElectronicDocument;
                    ToolTip = 'Void the check that is related to the cash order.';

                    trigger OnAction()
                    begin
                        Rec.TestField("Bank Payment Type", "Bank Payment Type"::"Computer Check");
                        Rec.TestField("Check Printed", true);
                        if Confirm(Text000, false, Rec."Document No.") then
                            CheckManagement.VoidCheck(Rec);
                    end;
                }
                action("Void &All Orders")
                {
                    Caption = 'Void &All Orders';
                    Image = VoidAllElectronicDocuments;
                    ToolTip = 'Void all checks that are related to cash orders.';
                    Visible = false;

                    trigger OnAction()
                    begin
                        if Confirm(Text001, false) then begin
                            GenJnlLine.Reset();
                            GenJnlLine.Copy(Rec);
                            GenJnlLine.SetRange("Bank Payment Type", "Bank Payment Type"::"Computer Check");
                            GenJnlLine.SetRange("Check Printed", true);
                            if GenJnlLine.Find('-') then
                                repeat
                                    GenJnlLine2 := GenJnlLine;
                                    CheckManagement.VoidCheck(GenJnlLine2);
                                until GenJnlLine.Next() = 0;
                        end;
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
                action("Apply Entries")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Apply Entries';
                    Ellipsis = true;
                    Image = ApplyEntries;
                    RunObject = Codeunit "Gen. Jnl.-Apply";
                    ShortCutKey = 'Shift+F11';
                }
                action("Insert Conv. LCY Rndg. Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Insert Conv. LCY Rndg. Lines';
                    Image = InsertCurrency;
                    RunObject = Codeunit "Adjust Gen. Journal Balance";
                    ToolTip = 'Insert a rounding correction line in the journal. This rounding correction line will balance in LCY when amounts in the foreign currency also balance. You can then post the journal.';
                }
                action("Copy Cash Order")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Cash Order';
                    Image = CopyDocument;

                    trigger OnAction()
                    begin
                        if Rec."Line No." = 0 then
                            Rec.FieldError("Line No.");
                        GenJnlLine.Reset();
                        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", Rec."Line No.");
                        if GenJnlLine.Find('-') then
                            REPORT.RunModal(REPORT::"Copy Payment Document", true, true, GenJnlLine);
                    end;
                }
            }
            group("P&osting")
            {
                Caption = 'P&osting';
                Image = Post;
                action(Reconcile)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reconcile';
                    Image = Reconcile;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'View the balances on bank accounts that are marked for reconciliation, usually liquid accounts.';

                    trigger OnAction()
                    begin
                        GLReconcile.SetGenJnlLine(Rec);
                        GLReconcile.Run();
                    end;
                }
                action("Test Report")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        ReportPrint.PrintGenJnlLine(Rec);
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
                        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
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
                        GenJnlPost.Preview(Rec);
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
                        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post+Print", Rec);
                        CurrentJnlBatchName := Rec.GetRangeMax("Journal Batch Name");
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Apply Entries_Promoted"; "Apply Entries")
                {
                }
                actionref("P&ost_Promoted"; "P&ost")
                {
                }
                actionref("Post and &Print_Promoted"; "Post and &Print")
                {
                }
                actionref("Print Cash Order_Promoted"; "Print Cash Order")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref("P&review Cash Order_Promoted"; "P&review Cash Order")
                {
                }
                actionref("Void Cash Order_Promoted"; "Void Cash Order")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GenJnlManagement.GetAccounts(Rec, AccName, BalAccName);
        UpdateBalance();
    end;

    trigger OnAfterGetRecord()
    begin
        Rec.ShowShortcutDimCode(ShortcutDimCode);
    end;

    trigger OnInit()
    begin
        TotalBalanceVisible := true;
        BalanceVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        UpdateBalance();
        Rec.SetUpNewLine(xRec, Balance, BelowxRec);
        Clear(ShortcutDimCode);
    end;

    trigger OnOpenPage()
    var
        JnlSelected: Boolean;
    begin
        GenJnlManagement.TemplateSelection(
            PAGE::"Cash Order Journal", "Gen. Journal Template Type"::"Cash Order Payments", false, Rec, JnlSelected);
        if not JnlSelected then
            Error('');
        GenJnlManagement.OpenJnl(CurrentJnlBatchName, Rec);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
        GenJnlManagement: Codeunit GenJnlManagement;
        ReportPrint: Codeunit "Test Report-Print";
        CheckManagement: Codeunit CheckManagement;
        ChangeExchangeRate: Page "Change Exchange Rate";
        GLReconcile: Page Reconciliation;
        CurrentJnlBatchName: Code[10];
        AccName: Text[100];
        BalAccName: Text[100];
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
        ShortcutDimCode: array[8] of Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Void Check %1?';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
        Text001: Label 'Void all printed checks?';
#pragma warning restore AA0074
        BalanceVisible: Boolean;
        TotalBalanceVisible: Boolean;

    local procedure UpdateBalance()
    begin
        GenJnlManagement.CalcBalance(
          Rec, xRec, Balance, TotalBalance, ShowBalance, ShowTotalBalance);
        BalanceVisible := ShowBalance;
        TotalBalanceVisible := ShowTotalBalance;
    end;

    local procedure CurrentJnlBatchNameOnAfterVali()
    begin
        CurrPage.SaveRecord();
        GenJnlManagement.SetName(CurrentJnlBatchName, Rec);
        CurrPage.Update(false);
    end;
}

