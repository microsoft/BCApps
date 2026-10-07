#pragma warning disable AA0247
report 12458 "Posted Cash Ingoing Order"
{
    Caption = 'Posted Cash Ingoing Order';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Check Ledger Entry"; "Check Ledger Entry")
        {
            DataItemTableView = sorting("Entry No.");
            RequestFilterFields = "Entry No.";

            trigger OnAfterGetRecord()
            begin
                CurrencyText := CurrencyTxt;
                TestField("Entry Status", "Entry Status"::Posted);
                BankAcc.Get("Bank Account No.");
                BankAcc.TestField("Account Type", BankAcc."Account Type"::"Cash Account");
                BankGLAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                DebitGLNo := BankGLAccPostingGr."G/L Account No.";
                BAnkGLEntries.Get("Bank Account Ledger Entry No.");

                case "Bal. Account Type" of
                    "Bal. Account Type"::Customer:
                        begin
                            CustomerGeneralLedger.SetCurrentKey("Transaction No.");
                            CustomerGeneralLedger.SetRange("Transaction No.", BAnkGLEntries."Transaction No.");
                            CustomerGeneralLedger.FindFirst();
                            CustomerPostingGr.Get(CustomerGeneralLedger."Customer Posting Group");
                            SettlAccNo := CustomerPostingGr."Receivables Account";
                        end;
                    "Bal. Account Type"::Vendor:
                        begin
                            PurchaserGLEntry.SetCurrentKey("Transaction No.");
                            PurchaserGLEntry.SetRange("Transaction No.", BAnkGLEntries."Transaction No.");
                            PurchaserGLEntry.FindFirst();
                            VendorPostingGr.Get(PurchaserGLEntry."Vendor Posting Group");
                            SettlAccNo := VendorPostingGr."Payables Account";
                        end;
                    "Bal. Account Type"::"Bank Account":
                        begin
                            BankAcc.Get("Bal. Account No.");
                            BankGLAccPostingGr.Get(BankAcc."Bank Acc. Posting Group");
                            SettlAccNo := BankGLAccPostingGr."G/L Account No.";
                        end;
                    "Bal. Account Type"::"G/L Account":
                        SettlAccNo := "Bal. Account No."
                end;

                DocAmount := "Debit Amount";
                WrittenAmount := LocMgt.Amount2Text(BankAcc."Currency Code", DocAmount);

                if BankAcc."Currency Code" <> '' then begin
                    Currency.Get(BankAcc."Currency Code");
                    CurrencyText := Currency.Description;
                    WrittenAmountNumber := Format(DocAmount div 1) + ' ' + CopyStr(Currency."Unit Name 1", 1) + '. ' +
                    FormatAmount(DocAmount mod 1 * 100) + ' ' + CopyStr(Currency."Hundred Name 1", 1) + '.';
                end else
                    WrittenAmountNumber :=
                      StrSubstNo(AmountCurrencyTxt, Format(Abs(Amount) div 1), FormatAmount(Abs(Amount) mod 1 * 100));

                if DocAmount < 0 then begin
                    WrittenAmount := MinusTxt + WrittenAmount;
                    WrittenAmountNumber := MinusTxt + WrittenAmountNumber;
                end;
                CashierFullName := BankAcc.Contact;
                PaymentCheckNo :=
                  LocMgt.DigitalPartCode("Document No.");

                FillBody("Check Ledger Entry");
            end;
        }
    }

    requestpage
    {

        layout
        {
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
        CompanyInfo.Get();
        CashOrderReportHelper.InitIngoingReportTmpl();
    end;

    var
        CompanyInfo: Record "Company Information";
        CustomerGeneralLedger: Record "Cust. Ledger Entry";
        PurchaserGLEntry: Record "Vendor Ledger Entry";
        BAnkGLEntries: Record "Bank Account Ledger Entry";
        CustomerPostingGr: Record "Customer Posting Group";
        VendorPostingGr: Record "Vendor Posting Group";
        BankAcc: Record "Bank Account";
        BankGLAccPostingGr: Record "Bank Account Posting Group";
        Currency: Record Currency;
        LocMgt: Codeunit "Localisation Management";
        LocRepMgt: Codeunit "Local Report Management";
        CashOrderReportHelper: Codeunit "Cash Order Report Helper";
        DocAmount: Decimal;
        WrittenAmount: Text[250];
        SettlAccNo: Code[20];
        DebitGLNo: Code[20];
        PaymentCheckNo: Text[20];
        CashierFullName: Text[100];
        WrittenAmountNumber: Text[250];
#pragma warning disable AA0470
        AmountCurrencyTxt: Label '%1 rub. %2 kop.';
#pragma warning restore AA0470
        CurrencyText: Text[30];
        MinusTxt: Label '(minus) ';
        FileName: Text;
        CurrencyTxt: Label 'rub., kop.';

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
    procedure TransferReportValues(var ReportValues: array[13] of Text; CheckLedgerEntry: Record "Check Ledger Entry")
    begin
        ReportValues[1] := LocRepMgt.GetCompanyName();
        ReportValues[2] := CompanyInfo."OKPO Code";
        ReportValues[3] := PaymentCheckNo;
        ReportValues[4] := LocMgt.Date2Text(CheckLedgerEntry."Posting Date");
        ReportValues[5] := CurrencyText;
        ReportValues[6] := DebitGLNo;
        ReportValues[7] := '-';
        ReportValues[8] := SettlAccNo;
        ReportValues[9] := LocRepMgt.FormatReportValue(CheckLedgerEntry."Debit Amount", 2);
        ReportValues[10] := BAnkGLEntries."Reason Code";
        ReportValues[11] := CheckLedgerEntry.Description;
        ReportValues[12] := CheckLedgerEntry."Payment Purpose";
        ReportValues[13] := WrittenAmount;
        ReportValues[14] := CheckLedgerEntry."Cash Order Including";
        ReportValues[15] := CheckLedgerEntry."Cash Order Supplement";
        ReportValues[16] := CompanyInfo."Accountant Name";
        ReportValues[17] := CashierFullName;
    end;

    [Scope('OnPrem')]
    procedure TransferReceiptValues(var ReceiptValues: array[14] of Text; CheckLedgerEntry: Record "Check Ledger Entry")
    begin
        ReceiptValues[1] := LocRepMgt.GetCompanyName();
        ReceiptValues[2] := PaymentCheckNo;
        ReceiptValues[3] := LocMgt.Date2Text(CheckLedgerEntry."Posting Date");
        ReceiptValues[4] := CheckLedgerEntry.Description;
        ReceiptValues[5] := CopyStr(CheckLedgerEntry."Payment Purpose", 1, 40);
        ReceiptValues[6] := CopyStr(CheckLedgerEntry."Payment Purpose", 41, 50);
        ReceiptValues[7] := CopyStr(CheckLedgerEntry."Payment Purpose", 91);
        ReceiptValues[8] := WrittenAmountNumber;
        ReceiptValues[9] := CopyStr(WrittenAmount, 1, 50);
        ReceiptValues[10] := CopyStr(WrittenAmount, 51, 50);
        ReceiptValues[11] := CopyStr(WrittenAmount, 101);
        ReceiptValues[12] := CheckLedgerEntry."Cash Order Including";
        ReceiptValues[13] := CompanyInfo."Accountant Name";
        ReceiptValues[14] := CashierFullName;
    end;

    local procedure FillBody(CheckLedgerEntry: Record "Check Ledger Entry")
    var
        ReportValues: array[17] of Text;
        ReceiptValues: array[14] of Text;
    begin
        TransferReportValues(ReportValues, CheckLedgerEntry);
        TransferReceiptValues(ReceiptValues, CheckLedgerEntry);
        CashOrderReportHelper.FillBodyIngoing(ReportValues, ReceiptValues);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

