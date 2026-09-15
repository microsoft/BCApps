#pragma warning disable AA0247
codeunit 14938 "Purchase Receipt M-4 Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";

    [Scope('OnPrem')]
    procedure InitM4Report()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.TestField("M-4 Template Code");
        InitReportTemplate(PurchSetup."M-4 Template Code");
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
    procedure FillM4ReportTitle(ReportHeaderArr: array[10] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTHEADER');

        ExcelReportBuilderMgr.AddDataToSection('CompanyName', ReportHeaderArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('DepartmentName', ReportHeaderArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('OKPO', ReportHeaderArr[3]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNumber', ReportHeaderArr[4]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', ReportHeaderArr[5]);
        ExcelReportBuilderMgr.AddDataToSection('InventLocation', ReportHeaderArr[6]);
        ExcelReportBuilderMgr.AddDataToSection('VendAccountName', ReportHeaderArr[7]);
        ExcelReportBuilderMgr.AddDataToSection('InvoiceAccount', ReportHeaderArr[8]);
        ExcelReportBuilderMgr.AddDataToSection('LedgerAccount', ReportHeaderArr[9]);
        ExcelReportBuilderMgr.AddDataToSection('VendorDocumentNo', ReportHeaderArr[10]);
    end;

    [Scope('OnPrem')]
    procedure FillM4PageHeader()
    begin
        ExcelReportBuilderMgr.AddSection('PAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillM4BodyInv(LedgerAccNo: Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODYINV', 'PAGEHEADER') then
            ExcelReportBuilderMgr.AddPagebreak();

        ExcelReportBuilderMgr.AddDataToSection('LedgerAccount', LedgerAccNo);
    end;

    [Scope('OnPrem')]
    procedure FillM4Body(PageHeaderArr: array[10] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODY', 'REPORTFOOTER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('PAGEHEADER');
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        ExcelReportBuilderMgr.AddDataToSection('ItemName', PageHeaderArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', PageHeaderArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('Unit', PageHeaderArr[3]);
        ExcelReportBuilderMgr.AddDataToSection('UnitName', PageHeaderArr[4]);
        ExcelReportBuilderMgr.AddDataToSection('Qty', PageHeaderArr[5]);
        ExcelReportBuilderMgr.AddDataToSection('QtyAccepted', PageHeaderArr[6]);
        ExcelReportBuilderMgr.AddDataToSection('Price', PageHeaderArr[7]);
        ExcelReportBuilderMgr.AddDataToSection('LineAmount', PageHeaderArr[8]);
        ExcelReportBuilderMgr.AddDataToSection('VATAmount', PageHeaderArr[9]);
        ExcelReportBuilderMgr.AddDataToSection('LineAmountWithTax', PageHeaderArr[10]);
        ExcelReportBuilderMgr.AddDataToSection('ItemNo', PageHeaderArr[2]);
    end;

    [Scope('OnPrem')]
    procedure FillM4ReportFooter(ReportFooterArr: array[8] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTFOOTER');

        ExcelReportBuilderMgr.AddDataToSection('TotalQty', ReportFooterArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('TotalBaseAmount', ReportFooterArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('TotalTaxAmount', ReportFooterArr[3]);
        ExcelReportBuilderMgr.AddDataToSection('TotalAmount', ReportFooterArr[4]);
        ExcelReportBuilderMgr.AddDataToSection('AcceptorPosition', ReportFooterArr[5]);
        ExcelReportBuilderMgr.AddDataToSection('AcceptorName', ReportFooterArr[6]);
        ExcelReportBuilderMgr.AddDataToSection('SenderPosition', ReportFooterArr[7]);
        ExcelReportBuilderMgr.AddDataToSection('SenderName', ReportFooterArr[8]);

        ExcelReportBuilderMgr.AddPagebreak();
    end;

    procedure InsertGLAccount(var GLAccountNetChange: Record "G/L Account Net Change"; AccountNo: Code[20]; var AccountNoToUpdate: Code[20])
    begin
        GLAccountNetChange.Reset();
        GLAccountNetChange.SetRange("No.", AccountNo);
        if not GLAccountNetChange.FindFirst() then begin
            GLAccountNetChange."No." := AccountNo;
            GLAccountNetChange.Insert();
            if AccountNoToUpdate = '' then
                AccountNoToUpdate := AccountNo;
        end;
    end;
}

