#pragma warning disable AA0247
codeunit 14937 "Bank Payment Order Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        LocMgt: Codeunit "Localisation Management";

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("Bank Payment Order Tmpl. Code");
        ExcelReportBuilderManager.InitTemplate(GeneralLedgerSetup."Bank Payment Order Tmpl. Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
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
    procedure FillHeader(OKUD: Code[10])
    begin
        ExcelReportBuilderManager.AddSection('REPORT_HEADER');
        ExcelReportBuilderManager.AddDataToSection('OKUD', OKUD);
    end;

    [Scope('OnPrem')]
    procedure FillTitle(OKUD: Text; TitleFirstLine: Text; TitleSecondLine: Text; DocumentDate: Date; PaymentMethod: Text; CompStat: Text)
    begin
        ExcelReportBuilderManager.AddSection('TITLE');
        ExcelReportBuilderManager.AddDataToSection('OKUD', OKUD);
        ExcelReportBuilderManager.AddDataToSection('Title1', TitleFirstLine);
        ExcelReportBuilderManager.AddDataToSection('Title2', TitleSecondLine);
        ExcelReportBuilderManager.AddDataToSection('DocDate', LocMgt.Date2Text(DocumentDate));
        ExcelReportBuilderManager.AddDataToSection('PaymentMethod', PaymentMethod);
        ExcelReportBuilderManager.AddDataToSection('Status', CompStat);
    end;

    [Scope('OnPrem')]
    procedure FillRequestTitle(OKUD: Text; TitleFirstLine: Text; TitleSecondLine: Text; DocumentDate: Date; PaymentMethod: Text; CompStat: Text)
    begin
        ExcelReportBuilderManager.AddSection('REQ_TITLE');
        ExcelReportBuilderManager.AddDataToSection('REQ_OKUD', OKUD);
        ExcelReportBuilderManager.AddDataToSection('REQ_Title1', TitleFirstLine);
        ExcelReportBuilderManager.AddDataToSection('REQ_Title2', TitleSecondLine);
        ExcelReportBuilderManager.AddDataToSection('REQ_DocDate', LocMgt.Date2Text(DocumentDate));
        ExcelReportBuilderManager.AddDataToSection('REQ_PaymentMethod', PaymentMethod);
        ExcelReportBuilderManager.AddDataToSection('REQ_Status', CompStat);
    end;

    [Scope('OnPrem')]
    procedure FillBody(LineValue: array[28] of Text)
    begin
        ExcelReportBuilderManager.AddSection('BODY');

        ExcelReportBuilderManager.AddDataToSection('AmountInWords', LineValue[1]);
        ExcelReportBuilderManager.AddDataToSection('INN', LineValue[2]);
        ExcelReportBuilderManager.AddDataToSection('KPP', LineValue[3]);
        ExcelReportBuilderManager.AddDataToSection('PayerInfo', LineValue[4]);
        ExcelReportBuilderManager.AddDataToSection('PayerBankInfo', LineValue[5]);
        ExcelReportBuilderManager.AddDataToSection('BenefBankInfo', LineValue[6]);
        ExcelReportBuilderManager.AddDataToSection('BenefINN', LineValue[7]);
        ExcelReportBuilderManager.AddDataToSection('BenefKPP', LineValue[8]);
        ExcelReportBuilderManager.AddDataToSection('BenefInfo', LineValue[9]);
        ExcelReportBuilderManager.AddDataToSection('Amount', LineValue[11]);
        ExcelReportBuilderManager.AddDataToSection('PayerAccNo', LineValue[12]);
        ExcelReportBuilderManager.AddDataToSection('PayerBankBIC', LineValue[13]);
        ExcelReportBuilderManager.AddDataToSection('PayerBankAccNo', LineValue[14]);
        ExcelReportBuilderManager.AddDataToSection('BenefBankBIC', LineValue[15]);
        ExcelReportBuilderManager.AddDataToSection('BenefBankAccNo', LineValue[16]);
        ExcelReportBuilderManager.AddDataToSection('BenefAccNo', LineValue[17]);
        ExcelReportBuilderManager.AddDataToSection('PaymentType', LineValue[18]);
        ExcelReportBuilderManager.AddDataToSection('PaymentAssignment', LineValue[19]);
        ExcelReportBuilderManager.AddDataToSection('PaymentCode', LineValue[20]);
        ExcelReportBuilderManager.AddDataToSection('PaymentDate', LineValue[21]);
        ExcelReportBuilderManager.AddDataToSection('PaymentSubsequence', LineValue[22]);
        ExcelReportBuilderManager.AddDataToSection('KBK', LineValue[23]);
        ExcelReportBuilderManager.AddDataToSection('OKATO', LineValue[24]);
        ExcelReportBuilderManager.AddDataToSection('TaxPeriod', LineValue[25]);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocumentNo', LineValue[26]);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocumentDate', LineValue[27]);
        ExcelReportBuilderManager.AddDataToSection('TaxPaymentType', LineValue[28]);
    end;

    [Scope('OnPrem')]
    procedure FillFooter(Marks: Text; PaymentPurpose: Text)
    begin
        ExcelReportBuilderManager.AddSection('FOOTER');
        ExcelReportBuilderManager.AddDataToSection('BankMarks', Marks);
        ExcelReportBuilderManager.AddDataToSection('PaymentPurpose', PaymentPurpose);
    end;

    [Scope('OnPrem')]
    procedure FillReqFooter()
    begin
        ExcelReportBuilderManager.AddSection('REQ_FOOTER');
    end;

    [Scope('OnPrem')]
    procedure FillMarks()
    begin
        ExcelReportBuilderManager.AddSection('MARKS');
    end;
}

