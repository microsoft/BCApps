#pragma warning disable AA0247
report 12425 "Copy Pay Document"
{
    Caption = 'Copy Pay Document';
    ProcessingOnly = true;

    dataset
    {
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
                    field(DocType; DocType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        OptionCaption = 'Payment order,Ingoing order,Outgoing order';
                        ToolTip = 'Specifies the type of the related document.';

                        trigger OnValidate()
                        begin
                            EntryNo := 0;
                            CheckEntryNo();
                        end;
                    }
                    field(EntryNo; EntryNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Entry No.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            SelectEntryNo();
                        end;

                        trigger OnValidate()
                        begin
                            CheckEntryNo();
                        end;
                    }
                    field("FromCheckLedgerEntry.""Document No."""; FromCheckLedgerEntry."Document No.")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        Editable = false;
                        ToolTip = 'Specifies the number of the related document.';
                    }
                    field("FromCheckLedgerEntry.Description"; FromCheckLedgerEntry.Description)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Description';
                        Editable = false;
                        ToolTip = 'Specifies a description of the record or entry.';
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

    trigger OnPreReport()
    begin
        if EntryNo = 0 then
            Error(Text000);

        FromCheckLedgerEntry.Get(EntryNo);

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := xGenJournalLine."Journal Template Name";
        GenJournalLine."Journal Batch Name" := xGenJournalLine."Journal Batch Name";
        xGenJournalLine.SetRange("Journal Template Name", xGenJournalLine."Journal Template Name");
        xGenJournalLine.SetRange("Journal Batch Name", xGenJournalLine."Journal Batch Name");

        if xGenJournalLine.Find('+') then
            GenJournalLine."Line No." := xGenJournalLine."Line No." + 10000
        else
            GenJournalLine."Line No." := 10000;

        GenJournalLine.SetUpNewLine(xGenJournalLine, 0, true);

        GenJournalLine.Validate("Account Type", FromCheckLedgerEntry."Bal. Account Type");
        GenJournalLine.Validate("Account No.", FromCheckLedgerEntry."Bal. Account No.");
        GenJournalLine.Validate("Document Type", FromCheckLedgerEntry."Document Type");
        GenJournalLine.Validate("Document No.", '');
        GenJournalLine.Validate(Description, FromCheckLedgerEntry.Description);

        if BankAccountLedgerEntry.Get(FromCheckLedgerEntry."Bank Account Ledger Entry No.") then
            if BankAccountLedgerEntry."Currency Code" <> GenJournalLine."Currency Code" then
                Error(Text001, GenJournalLine."Currency Code", BankAccountLedgerEntry."Currency Code");

        GenJournalLine.Validate(Amount, -FromCheckLedgerEntry.Amount);
        GenJournalLine.Validate("Bank Payment Type", 1);
        GenJournalLine.Validate("Beneficiary Bank Code", FromCheckLedgerEntry."Beneficiary Bank Code");
        GenJournalLine.Validate("Payment Purpose", FromCheckLedgerEntry."Payment Purpose");
        GenJournalLine.Validate("Cash Order Including", FromCheckLedgerEntry."Cash Order Including");
        GenJournalLine.Validate("Cash Order Supplement", FromCheckLedgerEntry."Cash Order Supplement");
        GenJournalLine.Validate("Payment Method", FromCheckLedgerEntry."Payment Method");
        GenJournalLine.Validate("Payment Date", FromCheckLedgerEntry."Payment Before Date");
        GenJournalLine.Validate("Payment Subsequence", FromCheckLedgerEntry."Payment Subsequence");
        GenJournalLine.Validate("Payment Code", FromCheckLedgerEntry."Payment Code");
        GenJournalLine.Validate("Payment Assignment", FromCheckLedgerEntry."Payment Assignment");
        GenJournalLine.Validate("Payment Type", FromCheckLedgerEntry."Payment Type");
        GenJournalLine.Insert();
    end;

    var
        FromCheckLedgerEntry: Record "Check Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        xGenJournalLine: Record "Gen. Journal Line";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        DocType: Option "Payment order","Ingoing order","Outgoing order";
        EntryNo: Integer;
#pragma warning disable AA0074
        Text000: Label 'Please enter Entry No.';
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Currency Code mismatch: Bank Acc %1 not equal to Check Ledger Entry %2';
#pragma warning restore AA0470
#pragma warning restore AA0074

    [Scope('OnPrem')]
    procedure CheckEntryNo()
    begin
        if EntryNo = 0 then
            FromCheckLedgerEntry.Init()
        else
            if EntryNo <> FromCheckLedgerEntry."Entry No." then
                FromCheckLedgerEntry.Get(EntryNo);
    end;

    [Scope('OnPrem')]
    procedure SelectEntryNo()
    begin
        FromCheckLedgerEntry.FilterGroup(2);
        FromCheckLedgerEntry.Reset();
        FromCheckLedgerEntry.CalcFields("Bank Account Type");
        case DocType of
            0:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 0);
                    FromCheckLedgerEntry.SetFilter(Amount, '<0');
                end;
            1:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 1);
                    FromCheckLedgerEntry.SetFilter(Amount, '>0');
                end;
            2:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 1);
                    FromCheckLedgerEntry.SetFilter(Amount, '<0');
                end;
            3:
                begin
                    FromCheckLedgerEntry.SetRange("Bank Account Type", 0);
                    FromCheckLedgerEntry.SetFilter(Amount, '>0');
                end;
        end;
        FromCheckLedgerEntry.SetRange("Entry Status", 3);
        FromCheckLedgerEntry.FilterGroup(0);

        if PAGE.RunModal(0, FromCheckLedgerEntry) = ACTION::LookupOK then
            EntryNo := FromCheckLedgerEntry."Entry No.";

        CheckEntryNo();
    end;

    [Scope('OnPrem')]
    procedure SetJournalLine(var NewGenJournalLine: Record "Gen. Journal Line")
    begin
        xGenJournalLine := NewGenJournalLine;
    end;
}

