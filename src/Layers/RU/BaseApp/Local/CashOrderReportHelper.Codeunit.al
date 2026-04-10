#pragma warning disable AA0247
codeunit 14936 "Cash Order Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";

    [Scope('OnPrem')]
    procedure InitOutgoingReportTmpl()
    var
        GeneralLedgSetup: Record "General Ledger Setup";
    begin
        GeneralLedgSetup.Get();
        GeneralLedgSetup.TestField("Cash Outgoin Order Tmpl. Code");
        InitReportTemplate(GeneralLedgSetup."Cash Outgoin Order Tmpl. Code");
    end;

    [Scope('OnPrem')]
    procedure InitIngoingReportTmpl()
    var
        GeneralLedgSetup: Record "General Ledger Setup";
    begin
        GeneralLedgSetup.Get();
        GeneralLedgSetup.TestField("Cash Ingoing Order Tmpl. Code");
        InitReportTemplate(GeneralLedgSetup."Cash Ingoing Order Tmpl. Code");
    end;

    local procedure InitReportTemplate(TemplateName: Code[10])
    var
        SheetName: Text;
    begin
        SheetName := 'Sheet1';
        ExcelReportBuilderMgr.InitTemplate(TemplateName);
        ExcelReportBuilderMgr.SetSheet(SheetName);
    end;

    [Scope('OnPrem')]
    procedure ExportData()
    begin
        ExcelReportBuilderMgr.ExportData();
    end;

    [Scope('OnPrem')]
    procedure ExportDataFile(FileName: Text)
    begin
        ExcelReportBuilderMgr.ExportDataToClientFile(FileName);
    end;

    [Scope('OnPrem')]
    procedure FillBodyOutgoing(ReportValue: array[18] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('DISBURSEMENT');

        ExcelReportBuilderMgr.AddDataToSection('CompanyNameDisb', ReportValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('OKPODisb', ReportValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNumDisb', ReportValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('TransDateDisb', ReportValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('CurrencyTableDisb', ReportValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('OffsetAccountDisb', ReportValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('LedgerAccountDisb', ReportValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('AmountCurDisb', ReportValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('PurposeNumDisb', ReportValue[9]);
        ExcelReportBuilderMgr.AddDataToSection('RepresPersonNameDisb', ReportValue[10]);
        ExcelReportBuilderMgr.AddDataToSection('PaymentNotesDisb', ReportValue[11]);
        ExcelReportBuilderMgr.AddDataToSection('TxtAmount1Disb', ReportValue[12]);
        ExcelReportBuilderMgr.AddDataToSection('Attachment1Disb', ReportValue[13]);
        ExcelReportBuilderMgr.AddDataToSection('DirectorNameDisb', ReportValue[14]);
        ExcelReportBuilderMgr.AddDataToSection('AccountantNameDisb', ReportValue[15]);
        ExcelReportBuilderMgr.AddDataToSection('RepresPersonCard1Disb', ReportValue[16]);
        ExcelReportBuilderMgr.AddDataToSection('CashierNameDisb', ReportValue[17]);
        ExcelReportBuilderMgr.AddDataToSection('DirectorTitleDisb', ReportValue[18]);
    end;

    [Scope('OnPrem')]
    procedure FillBodyIngoing(ReportValue: array[17] of Text; ReceiptValue: array[14] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REIMBURSEMENT');

        ExcelReportBuilderMgr.AddDataToSection('CompanyName', ReportValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('OKPO', ReportValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNum', ReportValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('TransDate', ReportValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('CurrencyTableReimb', ReportValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('AccountDebit', ReportValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('DepartmentNum', ReportValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('OffsetAccount', ReportValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('Amount', ReportValue[9]);
        ExcelReportBuilderMgr.AddDataToSection('PurposeNum', ReportValue[10]);
        ExcelReportBuilderMgr.AddDataToSection('RepresPersonName', ReportValue[11]);
        ExcelReportBuilderMgr.AddDataToSection('Notes1', ReportValue[12]);
        ExcelReportBuilderMgr.AddDataToSection('TxtAmount1', ReportValue[13]);
        ExcelReportBuilderMgr.AddDataToSection('TxtVATAmount', ReportValue[14]);
        ExcelReportBuilderMgr.AddDataToSection('Attachment', ReportValue[15]);
        ExcelReportBuilderMgr.AddDataToSection('AccountantName', ReportValue[16]);
        ExcelReportBuilderMgr.AddDataToSection('CashierName', ReportValue[17]);

        ExcelReportBuilderMgr.AddDataToSection('CompanyNameQ', ReceiptValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNumQ', ReceiptValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('TxtTransDateQ', ReceiptValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('RepresPersonNameQ1', ReceiptValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('NotesQ1', ReceiptValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('NotesQ2', ReceiptValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('NotesQ3', ReceiptValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('TxtShortAmountQ', ReceiptValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('TxtAmountQ1', ReceiptValue[9]);
        ExcelReportBuilderMgr.AddDataToSection('TxtAmountQ2', ReceiptValue[10]);
        ExcelReportBuilderMgr.AddDataToSection('TxtAmountQ3', ReceiptValue[11]);
        ExcelReportBuilderMgr.AddDataToSection('VatAmountQ1', ReceiptValue[12]);
        ExcelReportBuilderMgr.AddDataToSection('AccountantNameQ', ReceiptValue[13]);
        ExcelReportBuilderMgr.AddDataToSection('CashierNameQ', ReceiptValue[14]);
    end;
}

