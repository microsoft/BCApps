#pragma warning disable AA0247
page 12424 "Payment Order List"
{
    Caption = 'Payment Order List';
    DataCaptionFields = "Journal Batch Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
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
                        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
                    end;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the G/L account number.';

                    trigger OnValidate()
                    begin
                        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description associated with this line.';
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
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ToolTip = 'Specifies the code for the business unit, in a company group structure.';
                    Visible = false;
                }
                field("Salespers./Purch. Code"; Rec."Salespers./Purch. Code")
                {
                    ToolTip = 'Specifies the code for the salesperson or purchaser who is linked to the sale or purchase on the journal line.';
                    Visible = false;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    AssistEdit = true;
                    ToolTip = 'Specifies the currency code for the record.';
                    Visible = false;

                    trigger OnAssistEdit()
                    begin
                        ChangeCurrencyFactor.SetParameter(Rec."Currency Code", Rec."Currency Factor", Rec."Posting Date");
                        if ChangeCurrencyFactor.RunModal() = ACTION::OK then
                            Rec.Validate("Currency Factor", ChangeCurrencyFactor.GetParameter());
                        Clear(ChangeCurrencyFactor);
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
                field("Debit Amount"; Rec."Debit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expenses';
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Income';
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ToolTip = 'Specifies the payment amount.';
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
                        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
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
                field("Applies-to Doc. Type"; Rec."Applies-to Doc. Type")
                {
                    ToolTip = 'Specifies the type of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-to Doc. No."; Rec."Applies-to Doc. No.")
                {
                    ToolTip = 'Specifies the number of the posted document that this document or journal line will be applied to when you post, for example to register payment.';
                    Visible = false;
                }
                field("Applies-to ID"; Rec."Applies-to ID")
                {
                    ToolTip = 'Specifies the ID of entries that will be applied to when you choose the Apply Entries action.';
                    Visible = false;
                }
                field("On Hold"; Rec."On Hold")
                {
                    ToolTip = 'Specifies that the related entry represents an unpaid invoice for which either a payment suggestion, a reminder, or a finance charge memo exists.';
                    Visible = false;
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
                    Visible = false;
                }
                field("Export Status"; Rec."Export Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of a bank payment order. This value is set automatically.';
                }
            }
            group(Control30)
            {
                ShowCaption = false;
                field(AccountName; AccountName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Name';
                    Editable = false;
                }
                field(BalAccountName; BalAccountName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Bal. Account Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the balancing account that has been entered on the journal line.';
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
            group("&Document")
            {
                Caption = '&Document';
                Image = Document;
                Visible = false;
                action(List)
                {
                    Caption = 'List';
                    Image = OpportunitiesList;
                    RunObject = Page "Ingoing Cash Order";
                    RunPageLink = "Document No." = field("Document No."),
                                  "Journal Template Name" = field("Journal Template Name"),
                                  "Journal Batch Name" = field("Journal Batch Name");
                    ToolTip = 'Open the list of ongoing cash orders.';
                }
                action("Payment Order")
                {
                    Caption = 'Payment Order';
                    Image = "Order";
                    RunObject = Page "Bank Payment Order";
                    RunPageLink = "Document No." = field("Document No."),
                                  "Journal Template Name" = field("Journal Template Name"),
                                  "Journal Batch Name" = field("Journal Batch Name");
                }
                action(Dimensions)
                {
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
        }
        area(processing)
        {
            action(Printing)
            {
                Caption = 'Printing';
                Image = Print;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';
                Visible = false;

                trigger OnAction()
                begin
                    Rec.TestField("Bal. Account No.");

                    BankAccount.Reset();
                    BankAccount.SetRange("No.", Rec."Bal. Account No.");
                    if BankAccount.FindFirst() then
                        if BankAccount."Account Type" <> BankAccount."Account Type"::"Bank Account" then begin
                            GenJnlLine.Reset();
                            GenJnlLine.Copy(Rec);
                            GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                            GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                            GenJnlLine.SetRange("Line No.", Rec."Line No.");
                            DocumentPrint.PrintCashOrder(GenJnlLine);
                        end else
                            DocumentPrint.PrintCheck(Rec);
                end;
            }
            group(Posting)
            {
                Caption = 'Posting';
                Image = Post;
                Visible = false;
                action(Reconcile)
                {
                    Caption = 'Reconcile';
                    Image = Reconcile;
                    ShortCutKey = 'Ctrl+F11';
                    ToolTip = 'View the balances on bank accounts that are marked for reconciliation, usually liquid accounts.';

                    trigger OnAction()
                    begin
                        Reconciliation.SetGenJnlLine(Rec);
                        Reconciliation.Run();
                    end;
                }
                action("Test Report")
                {
                    Caption = 'Test Report';
                    Ellipsis = true;
                    Image = TestReport;
                    ToolTip = 'View a test report so that you can find and correct any errors before you perform the actual posting of the journal or document.';

                    trigger OnAction()
                    begin
                        TestPrint.PrintGenJnlLine(Rec);
                    end;
                }
                action(Action38)
                {
                    Caption = 'Posting';
                    Image = Post;
                    ShortCutKey = 'F9';

                    trigger OnAction()
                    begin
                        CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(Preview)
                {
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
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Printing_Promoted; Printing)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GenJnlMgt.GetAccounts(Rec, AccountName, BalAccountName);
    end;

    trigger OnOpenPage()
    begin
        ExportStatusFilter := Rec."Export Status";
        SetExportStatusFilter();

        Rec.FilterGroup(4);
        if (Rec.GetFilter("Journal Template Name") = '') or (Rec.GetFilter("Journal Batch Name") = '') then
            Error('');
        Rec.FilterGroup(0);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GenJnlMgt: Codeunit GenJnlManagement;
        TestPrint: Codeunit "Test Report-Print";
        DocumentPrint: Codeunit "Document-Print";
        ChangeCurrencyFactor: Page "Change Exchange Rate";
        Reconciliation: Page Reconciliation;
        AccountName: Text[50];
        BalAccountName: Text[50];
        ExportStatusFilter: Option " ",New,Exported,"Bank Statement Found";

    local procedure SetExportStatusFilter()
    begin
        Rec.FilterGroup(2);
        if ExportStatusFilter = ExportStatusFilter::" " then
            Rec.SetRange("Export Status")
        else
            Rec.SetRange("Export Status", ExportStatusFilter);
        Rec.FilterGroup(0);
    end;
}

