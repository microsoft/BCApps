#pragma warning disable AA0247
codeunit 14942 "Shipment Request M-11 Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";

    [Scope('OnPrem')]
    procedure InitM11Report()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Shpt.Request M-11 Templ. Code");
        InitReportTemplate(InventorySetup."Shpt.Request M-11 Templ. Code");
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
    procedure FillM11ReportHeader1(ReportHeaderArr: array[3] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTHEADER1');

        ExcelReportBuilderMgr.AddDataToSection('DocumentNum', ReportHeaderArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('CompanyName', ReportHeaderArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('OKPO', ReportHeaderArr[3]);
    end;

    [Scope('OnPrem')]
    procedure FillM11Body1(Body1Arr: array[9] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODY1', 'PAGEHEADER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('BODY1');
        end;
        ExcelReportBuilderMgr.AddDataToSection('CreationDate', Body1Arr[1]);
        ExcelReportBuilderMgr.AddDataToSection('OperationCode', Body1Arr[2]);
        ExcelReportBuilderMgr.AddDataToSection('FromInventLocation', Body1Arr[3]);
        ExcelReportBuilderMgr.AddDataToSection('FromActivityType', Body1Arr[4]);
        ExcelReportBuilderMgr.AddDataToSection('ToInventLocation', Body1Arr[5]);
        ExcelReportBuilderMgr.AddDataToSection('ToActivityType', Body1Arr[6]);
        ExcelReportBuilderMgr.AddDataToSection('ToLedgerAccount', Body1Arr[7]);
        ExcelReportBuilderMgr.AddDataToSection('ToAnalysisCode', Body1Arr[8]);
        ExcelReportBuilderMgr.AddDataToSection('UnitId', Body1Arr[9]);
    end;

    [Scope('OnPrem')]
    procedure FillM11ReportHeader2(ReportHeaderArr: array[3] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTHEADER2');

        ExcelReportBuilderMgr.AddDataToSection('InChargeName', ReportHeaderArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('RequesterName', ReportHeaderArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('ManagerName', ReportHeaderArr[3]);
    end;

    [Scope('OnPrem')]
    procedure FillM11PageHeader()
    begin
        if not ExcelReportBuilderMgr.TryAddSection('PAGEHEADER') then
            ExcelReportBuilderMgr.AddPagebreak();
    end;

    [Scope('OnPrem')]
    procedure FillM11Body(BodyArr: array[11] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSectionWithPlaceForFooter('BODY', 'REPORTFOOTER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('PAGEHEADER');
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        ExcelReportBuilderMgr.AddDataToSection('FromLedgerAccount', BodyArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('FromAnalysisCode', BodyArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('ItemName', BodyArr[3]);
        ExcelReportBuilderMgr.AddDataToSection('ItemId', BodyArr[4]);
        ExcelReportBuilderMgr.AddDataToSection('CodeOkei', BodyArr[5]);
        ExcelReportBuilderMgr.AddDataToSection('BOMUnitId', BodyArr[6]);
        ExcelReportBuilderMgr.AddDataToSection('QtyNeed', BodyArr[7]);
        ExcelReportBuilderMgr.AddDataToSection('Qty', BodyArr[8]);
        ExcelReportBuilderMgr.AddDataToSection('Price', BodyArr[9]);
        ExcelReportBuilderMgr.AddDataToSection('LineAmount', BodyArr[10]);
        ExcelReportBuilderMgr.AddDataToSection('InventoryNum', BodyArr[11]);
    end;

    [Scope('OnPrem')]
    procedure FillM11ReportFooter(ReportFooterArr: array[4] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('REPORTFOOTER');

        ExcelReportBuilderMgr.AddDataToSection('SupplierTitle', ReportFooterArr[1]);
        ExcelReportBuilderMgr.AddDataToSection('SupplierName', ReportFooterArr[2]);
        ExcelReportBuilderMgr.AddDataToSection('TakerTitle', ReportFooterArr[3]);
        ExcelReportBuilderMgr.AddDataToSection('TakerName', ReportFooterArr[4]);

        ExcelReportBuilderMgr.AddPagebreak();
    end;
}

