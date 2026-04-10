#pragma warning disable AA0247
codeunit 14955 "Recon. Act Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        FileName: Text;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    begin
        GLSetup.Get();
        GLSetup.TestField("C/V Recon. Act Template Code");
        ExcelReportBuilderManager.InitTemplate(GLSetup."C/V Recon. Act Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure FillPrevHeader()
    begin
        ExcelReportBuilderManager.AddSection('PREVIOUSHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(StartingDate: Date; EndingDate: Date)
    begin
        ExcelReportBuilderManager.AddSection('HEADER');

        ExcelReportBuilderManager.AddDataToSection('PeriodText', Format(StartingDate) + ' - ' + Format(EndingDate));
    end;

    [Scope('OnPrem')]
    procedure FillBody(LineNo: Text; DocDate: Text; DocDescription: Text; DocAmount: Text; DebitAmount: Text; CreditAmount: Text; OppDocAmount: Text; OppDebitAmount: Text; OppCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('BODY');

        ExcelReportBuilderManager.AddDataToSection('LineNo', LineNo);
        ExcelReportBuilderManager.AddDataToSection('DocDate', DocDate);
        ExcelReportBuilderManager.AddDataToSection('EntryDescription', DocDescription);
        ExcelReportBuilderManager.AddDataToSection('DocAmount', DocAmount);
        ExcelReportBuilderManager.AddDataToSection('DebitAmount', DebitAmount);
        ExcelReportBuilderManager.AddDataToSection('CreditAmount', CreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppDocAmount', OppDocAmount);
        ExcelReportBuilderManager.AddDataToSection('OppDebitAmount', OppDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppCreditAmount', OppCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillFooter(DocDescription: Text; DebitAmount: Text; CreditAmount: Text; OppDebitAmount: Text; OppCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');

        ExcelReportBuilderManager.AddDataToSection('BalanceEntryDescription', DocDescription);
        ExcelReportBuilderManager.AddDataToSection('BalanceDebitAmount', DebitAmount);
        ExcelReportBuilderManager.AddDataToSection('BalanceCreditAmount', CreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppBalanceDebitAmount', OppDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppBalanceCreditAmount', OppCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillCustFooter(StartingDate: Date; EndingDate: Date; TurnoverDebitAmount: Text; TurnoverCreditAmount: Text; OppTurnoverDebitAmount: Text; OppTurnoverCreditAmount: Text; CustBalanceDebitAmount: Text; CustBalanceCreditAmount: Text; CustOppBalanceDebitAmount: Text; CustOppBalanceCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('CUSTFOOTER');

        ExcelReportBuilderManager.AddDataToSection('CustTurnoverPeriodText', Format(StartingDate) + ' - ' + Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('CustTurnoverBalancePeriodText', Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('CustTurnoverDebitAmount', TurnoverDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('CustTurnoverCreditAmount', TurnoverCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('CustOppTurnoverDebitAmount', OppTurnoverDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('CustOppTurnoverCreditAmount', OppTurnoverCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('CustBalanceDebitAmount', CustBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('CustBalanceCreditAmount', CustBalanceCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('CustOppBalanceDebitAmount', CustOppBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('CustOppBalanceCreditAmount', CustOppBalanceCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillVendFooter(StartingDate: Date; EndingDate: Date; TurnoverDebitAmount: Text; TurnoverCreditAmount: Text; OppTurnoverDebitAmount: Text; OppTurnoverCreditAmount: Text; VendBalanceDebitAmount: Text; VendBalanceCreditAmount: Text; VendOppBalanceDebitAmount: Text; VendOppBalanceCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('VENDFOOTER');

        ExcelReportBuilderManager.AddDataToSection('VendTurnoverPeriodText', Format(StartingDate) + ' - ' + Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('VendTurnoverBalancePeriodText', Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('VendTurnoverDebitAmount', TurnoverDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('VendTurnoverCreditAmount', TurnoverCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('VendOppTurnoverDebitAmount', OppTurnoverDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('VendOppTurnoverCreditAmount', OppTurnoverCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('VendBalanceDebitAmount', VendBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('VendBalanceCreditAmount', VendBalanceCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('VendOppBalanceDebitAmount', VendOppBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('VendOppBalanceCreditAmount', VendOppBalanceCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillReportHeader(StartingDate: Date; EndingDate: Date; CompanyName: Text; VATRegNo: Text; CustVendName: Text; CustVendVATRegNo: Text)
    begin
        ExcelReportBuilderManager.AddSection('REPORTHEADER');

        ExcelReportBuilderManager.AddDataToSection('StartingDate', Format(StartingDate));
        ExcelReportBuilderManager.AddDataToSection('EndingDate', Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('CompanyNameReportHeader', CompanyName);
        ExcelReportBuilderManager.AddDataToSection('VATRegNoReportHeader', VATRegNo);
        ExcelReportBuilderManager.AddDataToSection('CustVendNameReportHeader', CustVendName);
        ExcelReportBuilderManager.AddDataToSection('CustVendVATRegNoReportHeader', CustVendVATRegNo);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader(CurrencyClaim: Text; CompanyName: Text; CustVendName: Text)
    begin
        ExcelReportBuilderManager.AddSection('PAGEHEADER');

        ExcelReportBuilderManager.AddDataToSection('CurrencyClaim', CurrencyClaim);
        ExcelReportBuilderManager.AddDataToSection('CompanyNamePageHeader', CompanyName);
        ExcelReportBuilderManager.AddDataToSection('CustVendNamePageHeader', CustVendName);
    end;

    [Scope('OnPrem')]
    procedure FillCustHeader(InitialBalanceDate: Text; InitialDebitAmount: Text; InitialCreditAmount: Text; OppInitialDebitAmount: Text; OppInitialCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('CUSTHEADER');

        ExcelReportBuilderManager.AddDataToSection('CustInitialBalanceDate', InitialBalanceDate);
        ExcelReportBuilderManager.AddDataToSection('CustInitialDebitAmount', InitialDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('CustInitialCreditAmount', InitialCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('CustOppInitialDebitAmount', OppInitialDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('CustOppInitialCreditAmount', OppInitialCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillVendHeader(InitialBalanceDate: Text; InitialDebitAmount: Text; InitialCreditAmount: Text; OppInitialDebitAmount: Text; OppInitialCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('VENDHEADER');

        ExcelReportBuilderManager.AddDataToSection('VendInitialBalanceDate', InitialBalanceDate);
        ExcelReportBuilderManager.AddDataToSection('VendInitialDebitAmount', InitialDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('VendInitialCreditAmount', InitialCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('VendOppInitialDebitAmount', OppInitialDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('VendOppInitialCreditAmount', OppInitialCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillAdvHeader(StartingDate: Date; EndingDate: Date)
    begin
        ExcelReportBuilderManager.AddSection('ADVANCEHEADER');

        ExcelReportBuilderManager.AddDataToSection('AdvancePeriodText', Format(StartingDate) + ' - ' + Format(EndingDate));
    end;

    [Scope('OnPrem')]
    procedure FillAdvOtherCurrBody(LineNo: Text; DocDescription: Text; AdvOtherCurrDebitAmount: Text; AdvOtherCurrCreditAmount: Text; OppAdvOtherCurrDebitAmount: Text; OppAdvOtherCurrCreditAmount: Text; AdvOtherCurrBalanceDebitAmount: Text; AdvOtherCurrBalanceCreditAmount: Text; OppAdvOtherCurrBalanceDebitAmount: Text; OppAdvOtherCurrBalanceCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('ADVANCEOTHERCURRBODY');

        ExcelReportBuilderManager.AddDataToSection('AdvOtherCurrLineNo', LineNo);
        ExcelReportBuilderManager.AddDataToSection('AdvOtherCurrDebitAmount', AdvOtherCurrDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('AdvOtherCurrCreditAmount', AdvOtherCurrCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppAdvOtherCurrDebitAmount', OppAdvOtherCurrDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppAdvOtherCurrCreditAmount', OppAdvOtherCurrCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('AdvOtherCurrBalanceEntryDescription', DocDescription);
        ExcelReportBuilderManager.AddDataToSection('AdvOtherCurrBalanceDebitAmount', AdvOtherCurrBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('AdvOtherCurrBalanceCreditAmount', AdvOtherCurrBalanceCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppAdvOtherCurrBalanceDebitAmount', OppAdvOtherCurrBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppAdvOtherCurrBalanceCreditAmount', OppAdvOtherCurrBalanceCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillAdvFooter(EndingDate: Date; AdvBalanceDebitAmount: Text; AdvBalanceCreditAmount: Text; OppAdvBalanceDebitAmount: Text; OppAdvBalanceCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('ADVANCEFOOTER');

        ExcelReportBuilderManager.AddDataToSection('AdvanceBalancePeriodText', Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('AdvanceBalanceDebitAmount', AdvBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('AdvanceBalanceCreditAmount', AdvBalanceCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppAdvanceBalanceDebitAmount', OppAdvBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppAdvanceBalanceCreditAmount', OppAdvBalanceCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillPrevAdvHeader(StartingDate: Date)
    begin
        ExcelReportBuilderManager.AddSection('PREVIOUSADVANCEHEADER');

        ExcelReportBuilderManager.AddDataToSection('PrevAdvPeriodText', Format(StartingDate));
    end;

    [Scope('OnPrem')]
    procedure FillPrevAdvFooter(EndingDate: Date; PrevAdvBalanceDebitAmount: Text; PrevAdvBalanceCreditAmount: Text; OppPrevAdvBalanceDebitAmount: Text; OppPrevAdvBalanceCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('PREVIOUSADVANCEFOOTER');

        ExcelReportBuilderManager.AddDataToSection('PrevAdvanceBalancePeriodText', Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('PrevAdvanceBalanceDebitAmount', PrevAdvBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('PrevAdvanceBalanceCreditAmount', PrevAdvBalanceCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppPrevAdvanceBalanceDebitAmount', OppPrevAdvBalanceDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppPrevAdvanceBalanceCreditAmount', OppPrevAdvBalanceCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillPageFooter(StartingDate: Date; EndingDate: Date; InitialDebitAmount: Text; InitialCreditAmount: Text; OppInitialDebitAmount: Text; OppInitialCreditAmount: Text; TurnoverDebitAmount: Text; TurnoverCreditAmount: Text; OppTurnoverDebitAmount: Text; OppTurnoverCreditAmount: Text; TotalDebitAmount: Text; TotalCreditAmount: Text; OppTotalDebitAmount: Text; OppTotalCreditAmount: Text)
    begin
        ExcelReportBuilderManager.AddSection('PAGEFOOTER');

        ExcelReportBuilderManager.AddDataToSection('TotalBalanceStartingDatePeriodText', Format(StartingDate));
        ExcelReportBuilderManager.AddDataToSection('TotalTurnoverPeriodText', Format(StartingDate) + ' - ' + Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('TotalBalanceEndingDatePeriodText', Format(EndingDate));
        ExcelReportBuilderManager.AddDataToSection('InitialDebitAmount', InitialDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('InitialCreditAmount', InitialCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppInitialDebitAmount', OppInitialDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppInitialCreditAmount', OppInitialCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('TurnoverDebitAmount', TurnoverDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('TurnoverCreditAmount', TurnoverCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppTurnoverDebitAmount', OppTurnoverDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppTurnoverCreditAmount', OppTurnoverCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('TotalDebitAmount', TotalDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('TotalCreditAmount', TotalCreditAmount);
        ExcelReportBuilderManager.AddDataToSection('OppTotalDebitAmount', OppTotalDebitAmount);
        ExcelReportBuilderManager.AddDataToSection('OppTotalCreditAmount', OppTotalCreditAmount);
    end;

    [Scope('OnPrem')]
    procedure FillReportFooter(ResultText: Text; CompanyName: Text; CustVendName: Text; DirectorName: Text; AccountantName: Text)
    begin
        ExcelReportBuilderManager.AddSection('REPORTFOOTER');

        ExcelReportBuilderManager.AddDataToSection('ResultText', ResultText);
        ExcelReportBuilderManager.AddDataToSection('CompanyName', CompanyName);
        ExcelReportBuilderManager.AddDataToSection('CustVendName', CustVendName);
        ExcelReportBuilderManager.AddDataToSection('DirectorName', DirectorName);
        ExcelReportBuilderManager.AddDataToSection('AccountantName', AccountantName);
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderManager.ExportData();
    end;

    [Scope('OnPrem')]
    procedure ExportDataFile(FileName: Text)
    begin
        ExcelReportBuilderManager.ExportDataToClientFile(FileName);
    end;

    [Scope('OnPrem')]
    procedure AddPageBreak()
    begin
        ExcelReportBuilderManager.AddPagebreak();
    end;
}

