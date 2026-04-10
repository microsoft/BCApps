#pragma warning disable AA0247
codeunit 14944 "Sales Shipment M-15 Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";

    [Scope('OnPrem')]
    procedure InitM15Report()
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup.TestField("Sales Shipment M-15 Templ.Code");
        InitReportTemplate(SalesSetup."Sales Shipment M-15 Templ.Code");
    end;

    local procedure InitReportTemplate(TemplateName: Code[10])
    begin
        ExcelReportBuilderMgr.InitTemplate(TemplateName);
        ExcelReportBuilderMgr.SetSheet('Sheet1');
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
    procedure FillM15ReportHeader(ReportHeaderArr: array[15] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTHEADER');

        ExcelReportBuilderMgr.AddDataToSection('InvoiceID', ReportHeaderArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('Organisation', ReportHeaderArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('OKPO', ReportHeaderArr[3]);

        ExcelReportBuilderMgr.AddDataToSection('InvoiceDate', ReportHeaderArr[4]);
        ExcelReportBuilderMgr.AddDataToSection('OperationTypeCode', ReportHeaderArr[5]);
        ExcelReportBuilderMgr.AddDataToSection('Sender_StructDpt', ReportHeaderArr[6]);
        ExcelReportBuilderMgr.AddDataToSection('Sender_ActivityType', ReportHeaderArr[7]);
        ExcelReportBuilderMgr.AddDataToSection('Receiver_StructDpt', ReportHeaderArr[8]);
        ExcelReportBuilderMgr.AddDataToSection('Receiver_ActivityType', ReportHeaderArr[9]);
        ExcelReportBuilderMgr.AddDataToSection('Delivery_StructDpt', ReportHeaderArr[10]);
        ExcelReportBuilderMgr.AddDataToSection('Delivery_ActivityType', ReportHeaderArr[11]);
        ExcelReportBuilderMgr.AddDataToSection('Delivery_ExecutiveName', ReportHeaderArr[12]);

        ExcelReportBuilderMgr.AddDataToSection('InvoiceBasis', ReportHeaderArr[13]);
        ExcelReportBuilderMgr.AddDataToSection('Header_ToWhom', ReportHeaderArr[14]);
        ExcelReportBuilderMgr.AddDataToSection('Header_ByWhom', ReportHeaderArr[15]);
    end;

    [Scope('OnPrem')]
    procedure FillM15PageHeader()
    begin
        ExcelReportBuilderMgr.AddSection('PAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillM15Body(ReportBodyArr: array[15] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODY', 'REPORTFOOTER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            FillM15PageHeader();
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        ExcelReportBuilderMgr.AddDataToSection('AccountNum', ReportBodyArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('AnalyticAccount', ReportBodyArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('ItemName', ReportBodyArr[3]);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', ReportBodyArr[4]);
        ExcelReportBuilderMgr.AddDataToSection('CodeOKEI', ReportBodyArr[5]);
        ExcelReportBuilderMgr.AddDataToSection('UnitId', ReportBodyArr[6]);
        ExcelReportBuilderMgr.AddDataToSection('Qty', ReportBodyArr[7]);
        ExcelReportBuilderMgr.AddDataToSection('QtyIssue', ReportBodyArr[8]);
        ExcelReportBuilderMgr.AddDataToSection('Price', ReportBodyArr[9]);
        ExcelReportBuilderMgr.AddDataToSection('LineAmount', ReportBodyArr[10]);
        ExcelReportBuilderMgr.AddDataToSection('VATAmount', ReportBodyArr[11]);
        ExcelReportBuilderMgr.AddDataToSection('LineAmountWithVAT', ReportBodyArr[12]);
        ExcelReportBuilderMgr.AddDataToSection('AssetId', ReportBodyArr[13]);
        ExcelReportBuilderMgr.AddDataToSection('PassportNum', ReportBodyArr[14]);
        ExcelReportBuilderMgr.AddDataToSection('OrderNumber', ReportBodyArr[15]);
    end;

    [Scope('OnPrem')]
    procedure FillM15ReportFooter(ReportFooterArr: array[12] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTFOOTER');

        ExcelReportBuilderMgr.AddDataToSection('F_TotalItemsShipped', ReportFooterArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('F_TotalAmtWithVAT_Letters', ReportFooterArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('F_TotalAmtWithVAT_Penny', ReportFooterArr[3]);
        ExcelReportBuilderMgr.AddDataToSection('F_TotalVAT', ReportFooterArr[4]);
        ExcelReportBuilderMgr.AddDataToSection('F_TotalVAT_Penny', ReportFooterArr[5]);
        ExcelReportBuilderMgr.AddDataToSection('Director_Position', ReportFooterArr[6]);
        ExcelReportBuilderMgr.AddDataToSection('Director_Name', ReportFooterArr[7]);
        ExcelReportBuilderMgr.AddDataToSection('Accountant_Name', ReportFooterArr[8]);
        ExcelReportBuilderMgr.AddDataToSection('Supplier_Position', ReportFooterArr[9]);
        ExcelReportBuilderMgr.AddDataToSection('Supplier_Name', ReportFooterArr[10]);
        ExcelReportBuilderMgr.AddDataToSection('Taker_Position', ReportFooterArr[11]);
        ExcelReportBuilderMgr.AddDataToSection('Taker_Name', ReportFooterArr[12]);

        ExcelReportBuilderMgr.AddPagebreak();
    end;
}

