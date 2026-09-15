#pragma warning disable AA0247
page 12423 "Ingoing Cash Order"
{
    Caption = 'Ingoing Cash Order';
    DataCaptionFields = "Document No.", Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SaveValues = true;
    SourceTable = "Gen. Journal Line";

    layout
    {
        area(content)
        {
            group("Cash Order")
            {
                Caption = 'Cash Order';
                field("Bal. Account No."; Rec."Bal. Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the number of the general ledger, customer, vendor, or bank account to which a balancing entry will posted, such as a cash account for cash purchases.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the entry''s posting date.';
                }
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = DocumentTypeEditable;
                    ToolTip = 'Specifies the type of the related document.';

                    trigger OnValidate()
                    begin
                        if not (Rec."Document Type" in [Rec."Document Type"::Payment, Rec."Document Type"::Refund]) then
                            error(DocumentTypeErr);

                        DocumentTypeOnAfterValidate();
                    end;
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
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the purpose of the account.';

                    trigger OnValidate()
                    begin
                        CalcPayment();
                    end;
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Account Code';

                    trigger OnValidate()
                    begin
                        AccountNoOnAfterValidate();
                    end;
                }
                field("Agreement No."; Rec."Agreement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the agreement number associated with the general journal line.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency code for the record.';
                }
                field("Credit Amount"; Rec."Credit Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Amount';
                    ToolTip = 'Specifies the amount.';

                    trigger OnValidate()
                    begin
                        CreditAmountOnAfterValidate();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'From to';
                    ToolTip = 'Specifies fields that are filled in automatically and show the starting and ending dates of the chosen period.';
                }
                field("Payment Purpose"; Rec."Payment Purpose")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reason';
                    ToolTip = 'Specifies the payment purpose associated with the general journal line.';
                }
                field("Cash Order Supplement"; Rec."Cash Order Supplement")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Supplement';
                    ToolTip = 'Specifies the cash order supplement associated with the general journal line.';
                }
                field("Text 2"; Rec."Cash Order Including")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Including';
                    ToolTip = 'Specifies the cash order including a standard text code, such as travel expenses, associated with the general journal line.';
                }
                field("Check Printed"; Rec."Check Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if a check has been printed for the amount on the document or journal line.';
                }
                field(BankAccNo; BankAccNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Debit Account';
                }
                field(CorrAccNo; CorrAccNo)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Credit Account';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        PostingGroupOnAfterValidate();
                    end;
                }
                field("Bank Payment Type"; Rec."Bank Payment Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for the payment type to be used for the entry on the journal line.';
                }
                field("Reason Code"; Rec."Reason Code")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
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
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 1, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code for Shortcut Dimension 2, which is one of two global dimension codes that you set up in the General Ledger Setup window.';
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
        area(processing)
        {
            group(Functions)
            {
                Caption = 'Functions';
                Image = "Action";
                action("Copy Document")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Copy Document';
                    Image = CopyDocument;

                    trigger OnAction()
                    begin
                        if Rec."Line No." = 0 then
                            Rec.FieldError("Line No.");
                        GenJnlLine.Reset();
                        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", Rec."Line No.");
                        if GenJnlLine.FindFirst() then
                            REPORT.RunModal(REPORT::"Copy Payment Document", true, true, GenJnlLine);
                    end;
                }
                action("Void check print")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Void check print';
                    Image = VoidCheck;
                    ToolTip = 'Change the status of the ingoing cash order from Check Printed to No. If there is a corresponding record in a check ledger entries table, the value in the Entry Status field in that record will be changed from Printed to Voided.';

                    trigger OnAction()
                    begin
                        GenJnlLine := Rec;
                        Clear(CheckManagment);
                        CheckManagment.VoidCheck(GenJnlLine);
                        CurrPage.Update(false);
                        Rec."Bank Payment Type" := "Bank Payment Type"::"Manual Check";
                        Rec.Modify();
                        Commit();
                    end;
                }
            }
            action(Print)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Print';
                Image = Print;
                ToolTip = 'Print the information in the window. A print request window opens where you can specify what to include on the print-out.';

                trigger OnAction()
                begin
                    if (BankAccNo <> '') and (CorrAccNo <> '') then begin
                        GenJnlLine.Reset();
                        GenJnlLine.Copy(Rec);
                        GenJnlLine.SetRange("Journal Template Name", Rec."Journal Template Name");
                        GenJnlLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
                        GenJnlLine.SetRange("Line No.", Rec."Line No.");
                        DocumentPrint.PrintCashOrder(GenJnlLine);
                    end;
                end;
            }
            group(Posting)
            {
                Caption = 'Posting';
                Image = Post;
                action(Post)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post';
                    Image = Post;
                    ShortCutKey = 'F9';
                    ToolTip = 'Record the cash receipt in your books.';

                    trigger OnAction()
                    begin
                        CurrPage.SetSelectionFilter(GenJnlLine);
                        GenJnlLine.FindFirst();
                        if Rec."Bal. Account Type" = Rec."Bal. Account Type"::"Bank Account" then
                            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);
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
                        CurrPage.SetSelectionFilter(GenJnlLine);
                        GenJnlLine.FindFirst();
                        if Rec."Bal. Account Type" = Rec."Bal. Account Type"::"Bank Account" then
                            GenJnlPost.Preview(GenJnlLine);
                    end;
                }
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
                actionref("Void check print_Promoted"; "Void check print")
                {
                }
                actionref(Print_Promoted; Print)
                {
                }
                actionref(Post_Promoted; Post)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CalcPayment();
    end;

    trigger OnInit()
    begin
        DocumentTypeEditable := true;
    end;

    var
        Cust: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        Vend: Record Vendor;
        VendPostGroup: Record "Vendor Posting Group";
        BankAccPostingGr: Record "Bank Account Posting Group";
        CashAcc: Record "Bank Account";
        GenJnlLine: Record "Gen. Journal Line";
        DocumentPrint: Codeunit "Document-Print";
        CheckManagment: Codeunit CheckManagement;
        CorrAccNo: Code[20];
        BankAccNo: Code[20];
        DocumentTypeEditable: Boolean;
        DocumentTypeErr: Label 'Document Type should be Payment or Refund.';

    [Scope('OnPrem')]
    procedure CalcPayment()
    begin
        CashAcc.Init();
        BankAccNo := '';

        CashAcc.Get(Rec."Bal. Account No.");
        BankAccPostingGr.Get(CashAcc."Bank Acc. Posting Group");
        BankAccNo := BankAccPostingGr."G/L Account No.";

        if Rec."Debit Amount" <> 0 then
            Rec.Validate("Credit Amount", -Rec."Debit Amount");

        CorrAccNo := '';
        if Rec."Account No." <> '' then
            case Rec."Account Type" of
                Rec."Account Type"::Customer:
                    begin
                        Cust.Get(Rec."Account No.");
                        CustPostGroup.Get(Rec."Posting Group");
                        if Rec.Prepayment then begin
                            CustPostGroup.TestField("Prepayment Account");
                            CorrAccNo := CustPostGroup."Prepayment Account";
                        end else begin
                            CustPostGroup.TestField("Receivables Account");
                            CorrAccNo := CustPostGroup."Receivables Account";
                        end;
                        DocumentTypeEditable := false;
                    end;
                Rec."Account Type"::Vendor:
                    begin
                        Vend.Get(Rec."Account No.");
                        VendPostGroup.Get(Rec."Posting Group");
                        if Rec.Prepayment then begin
                            VendPostGroup.TestField("Prepayment Account");
                            CorrAccNo := VendPostGroup."Prepayment Account";
                        end else begin
                            VendPostGroup.TestField("Payables Account");
                            CorrAccNo := VendPostGroup."Payables Account";
                        end;
                        DocumentTypeEditable := false;
                    end;
                Rec."Account Type"::"G/L Account":
                    CorrAccNo := Rec."Account No.";
                Rec."Account Type"::"Bank Account":
                    begin
                        CashAcc.Get(Rec."Account No.");
                        BankAccPostingGr.Get(CashAcc."Bank Acc. Posting Group");
                        BankAccPostingGr.TestField("G/L Account No.");
                        CorrAccNo := BankAccPostingGr."G/L Account No.";
                        DocumentTypeEditable := false;
                    end;
            end;
    end;

    local procedure CreditAmountOnAfterValidate()
    begin
        CalcPayment();
    end;

    local procedure AccountNoOnAfterValidate()
    begin
        CalcPayment();
    end;

    local procedure DocumentTypeOnAfterValidate()
    begin
        CalcPayment();
    end;

    local procedure PostingGroupOnAfterValidate()
    begin
        CalcPayment();
    end;
}

