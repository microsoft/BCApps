#pragma warning disable AA0247
report 12402 "Cash Outgoing Order"
{
    Caption = 'Cash Outgoing Order';
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
                CurrencyText := CurrencyTxt;

                TestField("Bal. Account Type", "Bal. Account Type"::"Bank Account");
                TestField("Bal. Account No.");
                TestField("Bank Payment Type");

                GenJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                GenJnlBatch.TestField("No. Series", '');
                GenJnlBatch.TestField("Posting No. Series", '');

                BankAcc.Get("Bal. Account No.");
                BankAcc.TestField("Account Type", BankAcc."Account Type"::"Cash Account");

                if BankAcc."Currency Code" <> '' then begin
                    TestField("Currency Code", BankAcc."Currency Code");
                    Currency.Get("Gen. Journal Line"."Currency Code");
                    CurrencyText := Currency.Description;
                end;

                CashierFullName := BankAcc.Contact;

                WrittenAmount := LocMgt.Amount2Text("Currency Code", "Debit Amount");
                if "Debit Amount" < 0 then
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

                            BankAcc.TestField("Credit Cash Order No. Series");

                            if "Document No." = '' then
                                "Document No." := NoSeries.GetNextNo(BankAcc."Credit Cash Order No. Series")
                            else begin
                                LastNo := NoSeries.PeekNextNo(BankAcc."Credit Cash Order No. Series");
                                if (DelChr("Document No.", '<>', '0123456789') <> DelChr(LastNo, '<>', '0123456789')) or
                                   ("Document No." > LastNo)
                                then
                                    Error(WrongDocumentNoErr, "Document No.", LastNo);
                                if "Document No." = LastNo then
                                    NoSeries.GetNextNo(BankAcc."Credit Cash Order No. Series");
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
                            CheckLedgEntry.Amount := -"Debit Amount";
                            CheckLedgEntry."Credit Amount" := "Debit Amount";
                            CheckLedgEntry.Positive := false;
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
                CreditAccNo := BankAccPostingGr."G/L Account No.";

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
                        begin
                            BalAccNo := "Account No.";
                            "Account No." := '';
                        end;
                end;

                PaymentCheckNo :=
                  LocMgt.DigitalPartCode("Document No.");

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
        CompanyInfo.Get();
        EmployeeDirector.Get(CompanyInfo."Director No.");

        CashOrderReportHelper.InitOutgoingReportTmpl();
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
        EmployeeDirector: Record Employee;
        CheckManagement: Codeunit CheckManagement;
        LocMgt: Codeunit "Localisation Management";
        LocRepMgt: Codeunit "Local Report Management";
        CashOrderReportHelper: Codeunit "Cash Order Report Helper";
        FileName: Text;
        WrittenAmount: Text[250];
        BalAccNo: Code[20];
        PrintTest: Boolean;
        CreditAccNo: Code[20];
        PaymentCheckNo: Code[20];
        CashierFullName: Text[100];
        LastNo: Code[20];
#pragma warning disable AA0470
        WrongDocumentNoErr: Label 'The number of the document %1 does not match the input mask %2 or greater than the last number.';
#pragma warning restore AA0470
        CurrencyTxt: Label 'Rub., kop.';
        CurrencyText: Text[30];
        MinusTxt: Label '(minus)';

    [Scope('OnPrem')]
    procedure TransferReportValues(var ReportValues: array[18] of Text; GenGnlLine: Record "Gen. Journal Line")
    begin
        ReportValues[1] := LocRepMgt.GetCompanyName();
        ReportValues[2] := CompanyInfo."OKPO Code";
        ReportValues[3] := PaymentCheckNo;
        ReportValues[4] := LocMgt.FormatDate(GenGnlLine."Posting Date");
        ReportValues[5] := CurrencyText;
        ReportValues[6] := BalAccNo;
        ReportValues[7] := CreditAccNo;
        ReportValues[8] := LocRepMgt.FormatReportValue(GenGnlLine."Debit Amount", 2);
        ReportValues[9] := GenGnlLine."Reason Code";
        ReportValues[10] := GenGnlLine.Description;
        ReportValues[11] := GenGnlLine."Payment Purpose";
        ReportValues[12] := WrittenAmount;
        ReportValues[13] := GenGnlLine."Cash Order Supplement";
        ReportValues[14] := CompanyInfo."Director Name";
        ReportValues[15] := CompanyInfo."Accountant Name";
        ReportValues[16] := GenGnlLine."Cash Order Including";
        ReportValues[17] := CashierFullName;
        ReportValues[18] := EmployeeDirector."Job Title";
    end;

    local procedure FillBody(GenGnlLine: Record "Gen. Journal Line")
    var
        ReportValues: array[18] of Text;
    begin
        TransferReportValues(ReportValues, GenGnlLine);
        CashOrderReportHelper.FillBodyOutgoing(ReportValues);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

