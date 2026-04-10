#pragma warning disable AA0247
report 12424 "Copy Payment Document"
{
    Caption = 'Copy Payment Document';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                TestField("Check Printed", false);

                CheckLedgerEntry.Reset();
                CheckLedgerEntry.SetRange("Document No.", DocumentNo);
                CheckLedgerEntry.SetRange("Posting Date", PostingDate);
                if CheckLedgerEntry.Find('-') then begin

                    BankAccount.Get("Bal. Account No.");
                    SourceAccType := BankAccount."Account Type";
                    BankAccount.Get(CheckLedgerEntry."Bank Account No.");
                    if BankAccount."Account Type" <> SourceAccType then
                        BankAccount.FieldError("Account Type");

                    "Posting Date" := PostingDate;
                    "Document Type" := CheckLedgerEntry."Document Type";
                    "Document No." := '';
                    "Account Type" := CheckLedgerEntry."Bal. Account Type";
                    Validate("Account No.", CheckLedgerEntry."Bal. Account No.");
                    Description := CheckLedgerEntry.Description;
                    Correction :=
                      (CheckLedgerEntry."Debit Amount" < 0) or (CheckLedgerEntry."Credit Amount" < 0);
                    Validate(Amount, -CheckLedgerEntry.Amount);
                    "Payment Purpose" := CheckLedgerEntry."Payment Purpose";
                    "Cash Order Including" := CheckLedgerEntry."Cash Order Including";
                    "Cash Order Supplement" := CheckLedgerEntry."Cash Order Supplement";
                    "Payment Method" := CheckLedgerEntry."Payment Method";
                    "Payment Date" := CheckLedgerEntry."Payment Before Date";
                    "Payment Subsequence" := CheckLedgerEntry."Payment Subsequence";
                    "Payment Code" := CheckLedgerEntry."Payment Code";
                    "Payment Assignment" := CheckLedgerEntry."Payment Assignment";
                    "Payment Type" := CheckLedgerEntry."Payment Type";
                    "Beneficiary Bank Code" := CheckLedgerEntry."Beneficiary Bank Code";

                    KBK := CheckLedgerEntry.KBK;
                    OKATO := CheckLedgerEntry.OKATO;
                    "Payment Reason Code" := CheckLedgerEntry."Payment Reason Code";
                    "Reason Document Type" := CheckLedgerEntry."Reason Document Type";
                    "Reason Document No." := CheckLedgerEntry."Reason Document No.";
                    "Reason Document Date" := CheckLedgerEntry."Reason Document Date";
                    "Tax Payment Type" := CheckLedgerEntry."Tax Payment Type";
                    "Period Code" := CheckLedgerEntry."Period Code";
                    "Tax Period" := CheckLedgerEntry."Tax Period";
                    "Taxpayer Status" := CheckLedgerEntry."Taxpayer Status";

                    case CheckLedgerEntry."Entry Status" of
                        CheckLedgerEntry."Entry Status"::Printed,
                        CheckLedgerEntry."Entry Status"::"Test Print":
                            begin
                                GenJnlLine.SetCurrentKey(
                                  "Journal Template Name", "Journal Batch Name", "Posting Date", "Document No.");
                                GenJnlLine.SetRange("Posting Date", PostingDate);
                                GenJnlLine.SetRange("Document No.", DocumentNo);
                                if GenJnlLine.Find('-') then begin
                                    "Shortcut Dimension 1 Code" := GenJnlLine."Shortcut Dimension 1 Code";
                                    "Shortcut Dimension 2 Code" := GenJnlLine."Shortcut Dimension 2 Code";
                                    "Dimension Set ID" := GenJnlLine."Dimension Set ID";
                                end;
                            end else begin
                            BankLedgEntry.SetCurrentKey("Document No.", "Posting Date");
                            BankLedgEntry.SetRange("Document No.", DocumentNo);
                            BankLedgEntry.SetRange("Posting Date", PostingDate);
                            if BankLedgEntry.Find('-') then begin
                                "Shortcut Dimension 1 Code" := BankLedgEntry."Global Dimension 1 Code";
                                "Shortcut Dimension 2 Code" := BankLedgEntry."Global Dimension 2 Code";
                                "Dimension Set ID" := GenJnlLine."Dimension Set ID";
                            end;
                        end;
                    end;
                    Modify();
                end else
                    Error(Text001);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the number of the related document.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            if PAGE.RunModal(PAGE::"Check Ledger Entries", CheckLedgerEntry) = ACTION::LookupOK then begin
                                DocumentNo := CheckLedgerEntry."Document No.";
                                PostingDate := CheckLedgerEntry."Posting Date";
                            end;
                        end;
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the entries that you want to include in the report or batch job.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        GenJnlLine: Record "Gen. Journal Line";
        CheckLedgerEntry: Record "Check Ledger Entry";
        DocumentNo: Code[20];
        PostingDate: Date;
#pragma warning disable AA0074
        Text001: Label 'Document not found';
#pragma warning restore AA0074
        BankLedgEntry: Record "Bank Account Ledger Entry";
        BankAccount: Record "Bank Account";
        SourceAccType: Integer;
}

