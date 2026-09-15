#pragma warning disable AA0247
report 12457 "Posted Cash Outgoing Order"
{
    Caption = 'Posted Cash Outgoing Order';
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
                CreditGlNo := BankGLAccPostingGr."G/L Account No.";
                BAnkGLEntries.Get("Bank Account Ledger Entry No.");

                if BankAcc."Currency Code" <> '' then begin
                    Currency.Get(BankAcc."Currency Code");
                    CurrencyText := Currency.Description;
                end;

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

                DocAmount := "Credit Amount";
                WrittenAmount := LocMgt.Amount2Text(BankAcc."Currency Code", DocAmount);
                if DocAmount < 0 then
                    WrittenAmount := MinusTxt + WrittenAmount;

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
        CashOrderReportHelper.InitOutgoingReportTmpl();
    end;

    var
        CompanyInfo: Record "Company Information";
        CustomerPostingGr: Record "Customer Posting Group";
        BankAcc: Record "Bank Account";
        CustomerGeneralLedger: Record "Cust. Ledger Entry";
        PurchaserGLEntry: Record "Vendor Ledger Entry";
        BAnkGLEntries: Record "Bank Account Ledger Entry";
        VendorPostingGr: Record "Vendor Posting Group";
        BankGLAccPostingGr: Record "Bank Account Posting Group";
        Currency: Record Currency;
        LocMgt: Codeunit "Localisation Management";
        CashOrderReportHelper: Codeunit "Cash Order Report Helper";
        DocAmount: Decimal;
        WrittenAmount: Text[250];
        SettlAccNo: Code[20];
        CreditGlNo: Code[20];
        PaymentCheckNo: Code[20];
        CashierFullName: Text[100];
        MinusTxt: Label '(minus) ';
        CurrencyText: Text[30];
        CurrencyTxt: Label 'rub., kop.';
        FileName: Text;

    [Scope('OnPrem')]
    procedure TransferReportValues(var ReportValues: array[13] of Text; CheckLedgerEntry: Record "Check Ledger Entry")
    var
        LocRepMgt: Codeunit "Local Report Management";
    begin
        ReportValues[1] := LocRepMgt.GetCompanyName();
        ReportValues[2] := CompanyInfo."OKPO Code";
        ReportValues[3] := PaymentCheckNo;
        ReportValues[4] := LocMgt.Date2Text(CheckLedgerEntry."Posting Date");
        ReportValues[5] := CurrencyText;
        ReportValues[6] := SettlAccNo;
        ReportValues[7] := CreditGlNo;
        ReportValues[8] := LocRepMgt.FormatReportValue(CheckLedgerEntry."Credit Amount", 2);
        ReportValues[9] := BAnkGLEntries."Reason Code";
        ReportValues[10] := CheckLedgerEntry.Description;
        ReportValues[11] := CheckLedgerEntry."Payment Purpose";
        ReportValues[12] := WrittenAmount;
        ReportValues[13] := CheckLedgerEntry."Cash Order Supplement";
        ReportValues[14] := CompanyInfo."Director Name";
        ReportValues[15] := CompanyInfo."Accountant Name";
        ReportValues[16] := CheckLedgerEntry."Cash Order Including";
        ReportValues[17] := CashierFullName;
    end;

    [Scope('OnPrem')]
    procedure FillBody(CheckLedgerEntry: Record "Check Ledger Entry")
    var
        ReportValues: array[17] of Text;
    begin
        TransferReportValues(ReportValues, CheckLedgerEntry);
        CashOrderReportHelper.FillBodyOutgoing(ReportValues);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

