#pragma warning disable AA0247
report 12403 "Cash Ingoing Order"
{
    Caption = 'Cash Ingoing Order';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Gen. Journal Line"; "Gen. Journal Line")
        {
            DataItemTableView = sorting("Journal Template Name", "Journal Batch Name", "Line No.");

            trigger OnAfterGetRecord()
            var
                NoSeries: Codeunit "No. Series";
            begin
                CurrencyText := EmptyCurrencyTxt;

                CompanyInfo.Get();

                TestField("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                TestField("Bal. Account No.");
                TestField("Bank Payment Type");

                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                GenJnlBatch.TestField("No. Series", '');
                GenJnlBatch.TestField("Posting No. Series", '');

                BankAcc.Get("Bal. Account No.");
                BankAcc.TestField("Account Type", BankAcc."Account Type"::"Cash Account");
                if BankAcc."Currency Code" <> '' then
                    TestField("Currency Code", BankAcc."Currency Code");

                CashierFullName := BankAcc.Contact;

                WrittenAmount := LocMgt.Amount2Text("Currency Code", "Credit Amount");

                if "Gen. Journal Line"."Currency Code" <> '' then begin
                    Currency.Get("Gen. Journal Line"."Currency Code");
                    CurrencyText := Currency.Description;
                    WrittenAmountNumber := Format("Credit Amount" div 1) + ' ' + CopyStr(Currency."Unit Name 1", 1, 4) + '. ' +
                      FormatAmount("Credit Amount" mod 1 * 100) + ' ' + CopyStr(Currency."Hundred Name 1", 1, 4) + '.';
                end else
                    WrittenAmountNumber :=
                      StrSubstNo(CurrencyTxt, Format("Credit Amount" div 1), FormatAmount("Credit Amount" mod 1 * 100));

                if "Credit Amount" < 0 then
                    WrittenAmount := MinusTxt + WrittenAmount;

                if not "Check Printed" then
                    if not PrintTest then begin
                        if (("Account Type" = "Account Type"::"Bank Account") or
                            ("Bal. Account Type" = "Bal. Account Type"::"Bank Account")) and
                           ((Amount < 0) or (BankAcc."Account Type" = BankAcc."Account Type"::"Cash Account"))
                        then
                            TestField("Bank Payment Type");
                        if "Bank Payment Type" = "Bank Payment Type"::"Manual Check" then begin
                            TestField("Document No.");
                            if "Posting No. Series" <> '' then
                                if not Confirm(PrintQst,
                                     false, FieldCaption("Posting No. Series"), FieldCaption("Document No."))
                                then
                                    CurrReport.Quit();
                            "External Document No." := "Document No.";
                            Modify();
                        end else begin
                            if "Posting No. Series" <> '' then
                                FieldError("Posting No. Series",
                                  StrSubstNo(CannotBeUsedErr,
                                    FieldCaption("Bank Payment Type"), "Bank Payment Type"));

                            BankAcc.TestField("Debit Cash Order No. Series");
                            if "Document No." = '' then
                                "Document No." := NoSeries.GetNextNo(BankAcc."Debit Cash Order No. Series")
                            else begin
                                LastNo := NoSeries.PeekNextNo(BankAcc."Debit Cash Order No. Series");
                                if (DelChr("Document No.", '<>', '0123456789') <> DelChr(LastNo, '<>', '0123456789')) or
                                   ("Document No." > LastNo)
                                then
                                    Error(WrongDocumentNoErr, "Document No.", LastNo);
                                if "Document No." = LastNo then
                                    NoSeries.GetNextNo(BankAcc."Debit Cash Order No. Series");
                            end;
                            TestField("Document No.");

                            "Check Printed" := true;
                            if "External Document No." = '' then
                                "External Document No." := "Document No.";

                            CheckLedgEntry.Init();
                            CheckLedgEntry."Bank Account No." := "Bal. Account No.";
                            CheckLedgEntry."Posting Date" := "Posting Date";
                            CheckLedgEntry."Check Date" := "Posting Date";
                            CheckLedgEntry."Document Type" := "Document Type";
                            CheckLedgEntry."Document No." := "Document No.";
                            CheckLedgEntry.Description := Description;
                            CheckLedgEntry."Check No." := "Document No.";
                            CheckLedgEntry."Payment Purpose" := "Payment Purpose";
                            CheckLedgEntry."Cash Order Including" := "Cash Order Including";
                            CheckLedgEntry."Cash Order Supplement" := "Cash Order Supplement";
                            CheckLedgEntry.Amount := "Credit Amount";
                            CheckLedgEntry."Debit Amount" := "Credit Amount";
                            CheckLedgEntry.Positive := true;
                            CheckLedgEntry."Bal. Account Type" := "Account Type";
                            CheckLedgEntry."Bal. Account No." := "Account No.";
                            CheckLedgEntry."External Document No." := "External Document No.";
                            CheckLedgEntry."Entry Status" := CheckLedgEntry."Entry Status"::Printed;
                            CheckLedgEntry."Bank Payment Type" := "Bank Payment Type";
                            CheckManagement.InsertCheck(CheckLedgEntry, RecordId);
                            Modify();
                        end;
                    end;

                BankAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                DebitAccNo := BankAccPostingGr."G/L Account No.";

                case "Account Type" of
                    "Account Type"::Customer:
                        begin
                            CustPostingGr.Get("Posting Group");
                            BalAccNo := CustPostingGr."Receivables Account";
                            if Prepayment then
                                BalAccNo := CustPostingGr."Prepayment Account";
                        end;
                    "Account Type"::Vendor:
                        begin
                            VendPostingGr.Get("Posting Group");
                            BalAccNo := VendPostingGr."Payables Account";
                            if Prepayment then
                                BalAccNo := VendPostingGr."Prepayment Account";
                        end;
                    "Account Type"::"Bank Account":
                        begin
                            BankAcc2.Get("Account No.");
                            BankAccPostingGr.Get(BankAcc2."Bank Acc. Posting Group");
                            BalAccNo := BankAccPostingGr."G/L Account No.";
                        end;
                    "Account Type"::"G/L Account":
                        BalAccNo := "Account No.";
                end;

                PaymentCheckNo :=
                  LocMgt.DigitalPartCode("Document No.");

                if PaymentCheckNo = '' then
                    PaymentCheckNo := PadStr('', MaxStrLen(PaymentCheckNo), ' ');

                FillBody("Gen. Journal Line");
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
                    field(PrintTest; PrintTest)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Test Print';
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

    trigger OnPostReport()
    begin
        if FileName <> '' then
            CashOrderReportHelper.ExportDataFile(FileName)
        else
            CashOrderReportHelper.ExportData();
    end;

    trigger OnPreReport()
    begin
        CashOrderReportHelper.InitIngoingReportTmpl();
    end;

    var
#pragma warning disable AA0470
        PrintQst: Label 'If %1 is not empty then it will be changed during posting\\Do you want to continue printing?';
#pragma warning restore AA0470
#pragma warning disable AA0470
        CannotBeUsedErr: Label 'Cannot be used if %1 %2.', Comment = 'Parameter 1 - field caption, parameter 2 - bank payment type';
#pragma warning restore AA0470
        CompanyInfo: Record "Company Information";
        BankAcc: Record "Bank Account";
        CheckLedgEntry: Record "Check Ledger Entry";
        CustPostingGr: Record "Customer Posting Group";
        VendPostingGr: Record "Vendor Posting Group";
        BankAccPostingGr: Record "Bank Account Posting Group";
        GenJnlBatch: Record "Gen. Journal Batch";
        BankAcc2: Record "Bank Account";
        Currency: Record Currency;
        CheckManagement: Codeunit CheckManagement;
        LocMgt: Codeunit "Localisation Management";
        LocRepMgt: Codeunit "Local Report Management";
        CashOrderReportHelper: Codeunit "Cash Order Report Helper";
        FileName: Text;
        WrittenAmount: Text[250];
        BalAccNo: Code[20];
        DebitAccNo: Code[20];
        LastNo: Code[20];
        PrintTest: Boolean;
        PaymentCheckNo: Text[20];
        CashierFullName: Text[100];
#pragma warning disable AA0470
        WrongDocumentNoErr: Label 'The number of the document %1 does not match the input mask %2 or greater than the last number.';
#pragma warning restore AA0470
#pragma warning disable AA0470
        CurrencyTxt: Label '%1 Rub., %2 kop.';
#pragma warning restore AA0470
        WrittenAmountNumber: Text[250];
        CurrencyText: Text[30];
        EmptyCurrencyTxt: Label 'Rub., kop.';
        MinusTxt: Label '(minus) ';

    [Scope('OnPrem')]
    procedure FormatAmount(Amount: Decimal): Text[30]
    begin
        if Amount = 0 then
            exit('00');
        if Amount < 10 then
            exit('0' + Format(Format(Amount)));
        exit(Format(Amount));
    end;

    [Scope('OnPrem')]
    procedure TransferReportValues(var ReportValues: array[13] of Text; GenGnlLine: Record "Gen. Journal Line")
    begin
        ReportValues[1] := LocRepMgt.GetCompanyName();
        ReportValues[2] := CompanyInfo."OKPO Code";
        ReportValues[3] := PaymentCheckNo;
        ReportValues[4] := LocMgt.FormatDate(GenGnlLine."Posting Date");
        ReportValues[5] := CurrencyText;
        ReportValues[6] := DebitAccNo;
        ReportValues[7] := '-';
        ReportValues[8] := BalAccNo;
        ReportValues[9] := LocRepMgt.FormatReportValue(GenGnlLine."Credit Amount", 2);
        ReportValues[10] := GenGnlLine."Reason Code";
        ReportValues[11] := GenGnlLine.Description;
        ReportValues[12] := GenGnlLine."Payment Purpose";
        ReportValues[13] := WrittenAmount;
        ReportValues[14] := GenGnlLine."Cash Order Including";
        ReportValues[15] := GenGnlLine."Cash Order Supplement";
        ReportValues[16] := CompanyInfo."Accountant Name";
        ReportValues[17] := CashierFullName;
    end;

    [Scope('OnPrem')]
    procedure TransferReceiptValues(var ReceiptValues: array[14] of Text; GenGnlLine: Record "Gen. Journal Line")
    begin
        ReceiptValues[1] := LocRepMgt.GetCompanyName();
        ReceiptValues[2] := PaymentCheckNo;
        ReceiptValues[3] := LocMgt.Date2Text(GenGnlLine."Posting Date");
        ReceiptValues[4] := GenGnlLine.Description;
        ReceiptValues[5] := CopyStr(GenGnlLine."Payment Purpose", 1, 40);
        ReceiptValues[6] := CopyStr(GenGnlLine."Payment Purpose", 41, 50);
        ReceiptValues[7] := CopyStr(GenGnlLine."Payment Purpose", 91);
        ReceiptValues[8] := WrittenAmountNumber;
        ReceiptValues[9] := CopyStr(WrittenAmount, 1, 50);
        ReceiptValues[10] := CopyStr(WrittenAmount, 51, 50);
        ReceiptValues[11] := CopyStr(WrittenAmount, 101);
        ReceiptValues[12] := GenGnlLine."Cash Order Including";
        ReceiptValues[13] := CompanyInfo."Accountant Name";
        ReceiptValues[14] := CashierFullName;
    end;

    local procedure FillBody(GenGnlLine: Record "Gen. Journal Line")
    var
        ReportValues: array[17] of Text;
        ReceiptValues: array[14] of Text;
    begin
        TransferReportValues(ReportValues, GenGnlLine);
        TransferReceiptValues(ReceiptValues, GenGnlLine);
        CashOrderReportHelper.FillBodyIngoing(ReportValues, ReceiptValues);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

