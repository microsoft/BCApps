#pragma warning disable AA0247
report 14902 "Cash Report CO-4"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Report CO-4';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Bank Account"; "Bank Account")
        {
            DataItemTableView = sorting("No.");
            dataitem("Bank Account Ledger Entry"; "Bank Account Ledger Entry")
            {
                DataItemLink = "Bank Account No." = field("No.");
                DataItemTableView = sorting("Bank Account No.", "Posting Date");

                trigger OnAfterGetRecord()
                begin
                    if IsVoided() then
                        CurrReport.Skip();

                    if "Debit Amount" <> 0 then
                        IngoingOrder := IngoingOrder + 1
                    else
                        OutgoingOrder := OutgoingOrder + 1;
                    DebitTotal := DebitTotal + "Debit Amount (LCY)";
                    CreditTotal := CreditTotal + "Credit Amount (LCY)";

                    if "Bal. Account No." = '' then
                        CheckMgt.GetVoidedCheckParameters("Bank Account Ledger Entry")
                    else
                        case "Bal. Account Type" of
                            "Bal. Account Type"::Customer:
                                GetSalesBalAccNo("Bal. Account No.", "Agreement No.");
                            "Bal. Account Type"::Vendor:
                                GetPurchBalAccNo("Bal. Account No.", "Agreement No.");
                            "Bal. Account Type"::"Bank Account":
                                begin
                                    BankAccount.Get("Bal. Account No.");
                                    BankPostGroup.Get(BankAccount."Bank Acc. Posting Group");
                                    CorrAccountNo := BankPostGroup."G/L Account No.";
                                end;
                            "Bal. Account Type"::"G/L Account":
                                CorrAccountNo := "Bal. Account No.";
                        end;

                    DocumentNo := "Document No.";

                    DebitCurrencyCode := '';
                    CreditCurrencyCode := '';

                    if "Currency Code" = '' then begin
                        // for printing form only
                        "Debit Amount" := 0;
                        "Credit Amount" := 0;
                    end else begin
                        if "Debit Amount" <> 0 then begin
                            DebitCurrencyCode := "Currency Code";
                            TotalDebitCurr2 += "Debit Amount";
                        end;

                        if "Credit Amount" <> 0 then begin
                            CreditCurrencyCode := "Currency Code";
                            TotalCreditCurr2 += "Credit Amount";
                        end;
                    end;

                    if not PreviewReport then begin
                        CheckLedgEntry.SetRange("Bank Account Ledger Entry No.", "Entry No.");
                        if CheckLedgEntry.FindFirst() then begin
                            CheckLedgEntry."Cashier Report No." := PageNo;
                            CheckLedgEntry."Cashier Report Printed" := CheckLedgEntry."Cashier Report Printed" + 1;
                            CheckMgt.ModifyCheckLedgEntry(CheckLedgEntry);
                        end;
                    end;

                    FillBody();
                end;

                trigger OnPostDataItem()
                begin
                    if IsEmpty() then
                        CurrReport.Break();

                    if ExcelReportBuilderManager.IsPageBreakRequired('CASHDAYTOTAL', 'RESTINCASHEND,FOOTER') then
                        AddPageBreak();

                    FillDayTotal();
                    FillRestTotal();
                    FillFooter();

                    if not PreviewReport then
                        if ReportType = ReportType::"Cash Report CO-4" then begin
                            "Bank Account"."Last Cash Report Page No." := PageNo;
                            "Bank Account".Modify();
                        end;

                    if PrintLastSheet then
                        FillLastPage();
                end;

                trigger OnPreDataItem()
                begin
                    SetRange("Posting Date", CreateDate);
                    SetRange(Reversed, false);

                    if IsEmpty() then
                        CurrReport.Break();

                    if PrintTitleSheet and (ReportType = ReportType::"Cash Report CO-4") then
                        FillReportTitle();

                    FillHeader();
                end;
            }

            trigger OnAfterGetRecord()
            begin
                OutgoingOrder := 0;
                IngoingOrder := 0;
                if Employee.Get(CashierCode) then
                    Cashier := Employee."Last Name" + ' ' + Employee.Initials
                else
                    Cashier := '';

                SetFilter("Date Filter", '..%1', CalcDate('<-1D>', CreateDate));
                CalcFields("Balance at Date (LCY)", "Balance at Date");
                StartingBalance := "Balance at Date (LCY)";
                if "Currency Code" <> '' then
                    StartingBalanceCurr2 := "Balance at Date";

                PageNo := IncStr("Last Cash Report Page No.");

                CheckLedgEntry.SetCurrentKey("Document No.", "Posting Date");
                CheckLedgEntry.SetRange("Posting Date", CreateDate);
                CheckLedgEntry.SetRange("Bank Account No.", "No.");

                if CheckLedgEntry.FindSet() then
                    repeat
                        if CheckLedgEntry."Cashier Report No." <> '' then
                            PageNo := CheckLedgEntry."Cashier Report No."
                    until (CheckLedgEntry."Cashier Report No." <> '') or (CheckLedgEntry.Next() = 0)
                else
                    if PreviewReport then
                        PageNo := 'XXXXX';

                CashBookYear := Format(Date2DMY(CreateDate, 3));
            end;

            trigger OnPreDataItem()
            begin
                SetRange("No.", BankAccountFilter);
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
                    field(BankAccountFilter; BankAccountFilter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cash Account No.';
                        LookupPageID = "Bank Account List";
                        TableRelation = "Bank Account" where("Account Type" = const("Cash Account"));
                    }
                    field(ReportType; ReportType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Report Type';
                        OptionCaption = 'Cash Report CO-4,Cash Additional Sheet';

                        trigger OnValidate()
                        begin
                            ReportTypeOnAfterValidate();
                        end;
                    }
                    field(CreateDate; CreateDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Date';
                    }
                    field(Cashier; CashierCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Cashier';
                        Enabled = CashierEnable;
                        TableRelation = Employee;
                    }
                    field(PrintTitleSheet; PrintTitleSheet)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Title Sheet';
                        Enabled = PrintTitleSheetEnable;
                        ToolTip = 'Specifies that the first page will be printed, for validation.';
                    }
                    field(PrintLastSheet; PrintLastSheet)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print Last Sheet';
                        Enabled = PrintLastSheetEnable;
                        ToolTip = 'Specifies that the last page will be printed, for validation.';
                    }
                    field(PreviewMode; PreviewReport)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Preview Without Page Numbering';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            PrintLastSheetEnable := true;
            PrintTitleSheetEnable := true;
            CashierEnable := true;
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        PreviewReport := false;
    end;

    trigger OnPostReport()
    begin
        if FileName <> '' then
            ExcelReportBuilderManager.ExportDataToClientFile(FileName)
        else
            ExcelReportBuilderManager.ExportData();
    end;

    trigger OnPreReport()
    begin
        if CreateDate = 0D then
            Error(ReportDateErr);
        CompanyInfo.Get();

        InitReportTemplate();
    end;

    var
        BankAccount: Record "Bank Account";
        BankPostGroup: Record "Bank Account Posting Group";
        Customer: Record Customer;
        CustPostGroup: Record "Customer Posting Group";
        Vendor: Record Vendor;
        VendPostGroup: Record "Vendor Posting Group";
        CompanyInfo: Record "Company Information";
        Employee: Record Employee;
        CheckLedgEntry: Record "Check Ledger Entry";
        CheckMgt: Codeunit CheckManagement;
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        LocRepMgt: Codeunit "Local Report Management";
        CreateDate: Date;
        FileName: Text;
        Cashier: Text[30];
        CashierCode: Code[20];
        CorrAccountNo: Code[20];
        PageNo: Code[20];
        StartingBalance: Decimal;
        DebitTotal: Decimal;
        CreditTotal: Decimal;
        OutgoingOrder: Integer;
        IngoingOrder: Integer;
        DocumentNo: Code[20];
        ReportDateErr: Label 'Report Date must be defined.';
        DebitCurrencyCode: Code[10];
        CreditCurrencyCode: Code[10];
        CashBookYear: Text[10];
        PrintTitleSheet: Boolean;
        PrintLastSheet: Boolean;
        TotalDebitCurr2: Decimal;
        TotalCreditCurr2: Decimal;
        ReportType: Option "Cash Report CO-4","Cash Additional Sheet";
        StartingBalanceCurr2: Decimal;
        BankAccountFilter: Code[20];
        CashierEnable: Boolean;
        PrintTitleSheetEnable: Boolean;
        PrintLastSheetEnable: Boolean;
#pragma warning disable AA0470
        CashAccountForDateTxt: Label '%1 at %2';
#pragma warning restore AA0470
#pragma warning disable AA0470
        PageTxt: Label 'Page %1';
#pragma warning restore AA0470
        PreviewReport: Boolean;
        CashReportCO4Txt: Label 'Loose-leaf cashbook';
        CashAdditionalSheetTxt: Label 'Cashier report';

    local procedure AddPageBreak()
    begin
        ExcelReportBuilderManager.AddPagebreak();
        if not PreviewReport then
            PageNo := IncStr(PageNo);
        FillTop();
    end;

    local procedure GetPageNumber(): Integer
    var
        Result: Integer;
        NumberText: Text;
    begin
        Result := 0;
        NumberText := DelChr(PageNo, '=', DelChr(PageNo, '<>', '0123456789'));
        if NumberText <> '' then
            Evaluate(Result, NumberText);

        exit(Result);
    end;

    local procedure GetSalesBalAccNo(CustNo: Code[20]; AgreementCode: Code[20])
    begin
        if AgreementCode = '' then
            CorrAccountNo := GetAccNoFromCust(CustNo)
        else
            CorrAccountNo := GetAccNoFromCustAgreement(CustNo, AgreementCode);
    end;

    local procedure GetAccNoFromCust(CustNo: Code[20]): Code[20]
    begin
        Customer.Get(CustNo);
        Customer.TestField("Customer Posting Group");
        exit(GetAccNoFromCustPostGroup(Customer."Customer Posting Group"));
    end;

    local procedure GetAccNoFromCustAgreement(CustNo: Code[20]; AgreementCode: Code[20]): Code[20]
    var
        CustAgreement: Record "Customer Agreement";
    begin
        CustAgreement.Get(CustNo, AgreementCode);
        CustAgreement.TestField("Customer Posting Group");
        exit(GetAccNoFromCustPostGroup(CustAgreement."Customer Posting Group"));
    end;

    local procedure GetAccNoFromCustPostGroup(CustPostGroupCode: Code[20]): Code[20]
    begin
        CustPostGroup.Get(CustPostGroupCode);
        exit(CustPostGroup."Receivables Account");
    end;

    local procedure GetPurchBalAccNo(VendNo: Code[20]; AgreementCode: Code[20])
    begin
        if AgreementCode = '' then
            CorrAccountNo := GetAccNoFromVend(VendNo)
        else
            CorrAccountNo := GetAccNoFromVendAgreement(VendNo, AgreementCode);
    end;

    local procedure GetAccNoFromVend(VendNo: Code[20]): Code[20]
    begin
        Vendor.Get(VendNo);
        Vendor.TestField("Vendor Posting Group");
        exit(GetAccNoFromVendPostGroup(Vendor."Vendor Posting Group"));
    end;

    local procedure GetAccNoFromVendAgreement(VendNo: Code[20]; AgreementCode: Code[20]): Code[20]
    var
        VendAgreement: Record "Vendor Agreement";
    begin
        VendAgreement.Get(VendNo, AgreementCode);
        VendAgreement.TestField("Vendor Posting Group");
        exit(GetAccNoFromVendPostGroup(VendAgreement."Vendor Posting Group"));
    end;

    local procedure GetAccNoFromVendPostGroup(VendPostGroupCode: Code[20]): Code[20]
    begin
        VendPostGroup.Get(VendPostGroupCode);
        exit(VendPostGroup."Payables Account");
    end;

    local procedure ReportTypeOnAfterValidate()
    begin
        if ReportType = ReportType::"Cash Report CO-4" then begin
            CashierEnable := true;
            PrintTitleSheetEnable := true;
            PrintLastSheetEnable := true;
        end else begin
            CashierEnable := false;
            PrintTitleSheetEnable := false;
            PrintLastSheetEnable := false;
        end
    end;

    local procedure InitReportTemplate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Cash Order KO4 Template Code");
        ExcelReportBuilderManager.InitTemplate(GeneralLedgerSetup."Cash Order KO4 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    local procedure FillReportTitle()
    begin
        ExcelReportBuilderManager.AddSection('PROLOG');

        ExcelReportBuilderManager.AddDataToSection('CompanyName', CompanyInfo.Name);
        ExcelReportBuilderManager.AddDataToSection('CodeOKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderManager.AddDataToSection('Year', CashBookYear);

        ExcelReportBuilderManager.AddPagebreak();
    end;

    local procedure FillTop()
    begin
        ExcelReportBuilderManager.AddSection('TOP');
        ExcelReportBuilderManager.AddDataToSection('CashAccountName', GetPageTitle());
        ExcelReportBuilderManager.AddDataToSection(
          'CashDate', StrSubstNo(CashAccountForDateTxt, "Bank Account".Name,
            Format(CreateDate, 0, '<Day,2>.<Month,2>.<Year4>')));

        ExcelReportBuilderManager.AddDataToSection('CashBookPage', StrSubstNo(PageTxt, GetPageNumber()))
    end;

    local procedure FillHeader()
    begin
        FillTop();
        ExcelReportBuilderManager.AddSection('HEADER');
        ExcelReportBuilderManager.AddSection('RESTINCASH');
        ExcelReportBuilderManager.AddDataToSection(
          'RestInCashCashAmountDebet', FormatAmount(StartingBalance, false));
    end;

    local procedure FillBody()
    var
        LocalisationManagement: Codeunit "Localisation Management";
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', 'BODY') then begin
            AddPageBreak();

            ExcelReportBuilderManager.AddSection('HEADER');
            ExcelReportBuilderManager.AddSection('BODY');
        end;

        ExcelReportBuilderManager.AddDataToSection(
          'BodyCashVoucher', LocalisationManagement.DigitalPartCode(DocumentNo));
        ExcelReportBuilderManager.AddDataToSection(
          'BodyCashNotes', "Bank Account Ledger Entry".Description);
        ExcelReportBuilderManager.AddDataToSection('BodyCashAccountNum', CorrAccountNo);
        ExcelReportBuilderManager.AddDataToSection(
          'BodyCashAmountDebet', FormatAmount("Bank Account Ledger Entry"."Debit Amount (LCY)", true));
        ExcelReportBuilderManager.AddDataToSection(
          'BodyCashAmountCredit', FormatAmount("Bank Account Ledger Entry"."Credit Amount (LCY)", true));

        if ("Bank Account Ledger Entry"."Debit Amount" <> 0) or ("Bank Account Ledger Entry"."Credit Amount" <> 0) then begin
            ExcelReportBuilderManager.AddSection('BODY');
            ExcelReportBuilderManager.AddDataToSection(
              'BodyCashAmountDebet', FormatAmount("Bank Account Ledger Entry"."Debit Amount", true) +
              ' ' + DebitCurrencyCode);
            ExcelReportBuilderManager.AddDataToSection(
              'BodyCashAmountCredit', FormatAmount("Bank Account Ledger Entry"."Credit Amount", true) +
              ' ' + CreditCurrencyCode);
        end;
    end;

    local procedure FillDayTotal()
    begin
        if DebitCurrencyCode <> '' then
            CreditCurrencyCode := DebitCurrencyCode
        else
            DebitCurrencyCode := CreditCurrencyCode;

        if TotalDebitCurr2 = 0 then
            DebitCurrencyCode := '';

        if TotalCreditCurr2 = 0 then
            CreditCurrencyCode := '';

        ExcelReportBuilderManager.AddSection('CASHDAYTOTAL');
        ExcelReportBuilderManager.AddDataToSection(
          'CashDayTotalCashAmountDebet', FormatAmount(DebitTotal, false));
        ExcelReportBuilderManager.AddDataToSection(
          'CashDayTotalCashAmountCredit', FormatAmount(CreditTotal, false));

        if "Bank Account"."Currency Code" <> '' then begin
            ExcelReportBuilderManager.AddSection('CASHDAYTOTALCUR');
            if TotalDebitCurr2 <> 0 then
                ExcelReportBuilderManager.AddDataToSection(
                  'CashDayTotalCurDebet', FormatAmount(TotalDebitCurr2, false) + ' ' + DebitCurrencyCode);
            if TotalCreditCurr2 <> 0 then
                ExcelReportBuilderManager.AddDataToSection(
                  'CashDayTotalCurCredit', FormatAmount(TotalCreditCurr2, false) + ' ' + CreditCurrencyCode);
        end;
    end;

    local procedure FillRestTotal()
    begin
        ExcelReportBuilderManager.AddSection('RESTINCASHEND');
        ExcelReportBuilderManager.AddDataToSection(
          'RestInCashEndBodyCashAmountDebet',
          FormatAmount(StartingBalance + DebitTotal - CreditTotal, false));

        if "Bank Account"."Currency Code" <> '' then begin
            ExcelReportBuilderManager.AddSection('RESTINCASHENDCUR');
            if StartingBalanceCurr2 + TotalDebitCurr2 - TotalCreditCurr2 <> 0 then
                ExcelReportBuilderManager.AddDataToSection(
                  'RestInCashEndCurAmount',
                  Format(StartingBalanceCurr2 + TotalDebitCurr2 - TotalCreditCurr2, 0,
                    '<Sign><Integer Thousand><Decimals,3>') +
                  ' ' + "Bank Account"."Currency Code");
        end;
    end;

    local procedure FillFooter()
    var
        LocalisationManagement: Codeunit "Localisation Management";
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');
        ExcelReportBuilderManager.AddDataToSection('CashierName', Cashier);
        ExcelReportBuilderManager.AddDataToSection('IncomeOrder', LocalisationManagement.Integer2Text(IngoingOrder, 1, '', '', ''));
        ExcelReportBuilderManager.AddDataToSection('OutgoingOrder', LocalisationManagement.Integer2Text(OutgoingOrder, 1, '', '', ''));
        ExcelReportBuilderManager.AddDataToSection('AccountantNameFooter', CompanyInfo."Accountant Name");
    end;

    local procedure FillLastPage()
    var
        LastPageNo: Integer;
    begin
        ExcelReportBuilderManager.AddPagebreak();
        ExcelReportBuilderManager.AddSection('EPILOG');
        LastPageNo := GetPageNumber();
        if LastPageNo <> 0 then
            ExcelReportBuilderManager.AddDataToSection('NumberOfList', Format(LastPageNo));
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(CashAccountNo: Code[20]; NewCreateDate: Date; NewPrintTitleSheet: Boolean; NewPrintLastSheet: Boolean; NewReportType: Option)
    begin
        BankAccountFilter := CashAccountNo;
        CreateDate := NewCreateDate;
        PrintTitleSheet := NewPrintTitleSheet;
        PrintLastSheet := NewPrintLastSheet;
        ReportType := NewReportType;
    end;

    local procedure IsVoided(): Boolean
    var
        CheckLedgerEntry: Record "Check Ledger Entry";
    begin
        CheckLedgerEntry.SetRange("Bank Account No.", "Bank Account Ledger Entry"."Bank Account No.");
        CheckLedgerEntry.SetRange("Posting Date", "Bank Account Ledger Entry"."Posting Date");
        CheckLedgerEntry.SetRange("Document No.", "Bank Account Ledger Entry"."Document No.");
        CheckLedgerEntry.SetRange("Entry Status", CheckLedgerEntry."Entry Status"::"Financially Voided");
        exit(not CheckLedgerEntry.IsEmpty);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FormatAmount(Amount: Decimal; BlankZero: Boolean): Text
    begin
        if BlankZero and (Amount = 0) then
            exit('');

        exit(LocRepMgt.FormatReportValue(Amount, 2));
    end;

    local procedure GetPageTitle(): Text
    begin
        case ReportType of
            ReportType::"Cash Report CO-4":
                exit(CashReportCO4Txt);
            ReportType::"Cash Additional Sheet":
                exit(CashAdditionalSheetTxt);
        end;
    end;
}

