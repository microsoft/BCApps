#pragma warning disable AA0247
codeunit 14947 "INV-18 Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";
        TotalAmount: array[4] of Decimal;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.TestField("INV-18 Template Code");
        ExcelReportBuilderManager.InitTemplate(FASetup."INV-18 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(EmployeeNo: Code[20]; Reason: Text; DocumentNo: Text; DocumentDate: Text; LineDocNo: Text; StartingDate: Text; EndingDate: Text; CreationDate: Text; UntilDate: Date; Member1: Code[20]; Member2: Code[20])
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'Department', StdRepMgt.GetEmpDepartment(EmployeeNo));
        ExcelReportBuilderManager.AddDataToSection(
          'OKPO', CompanyInfo."OKPO Code");

        ExcelReportBuilderManager.AddDataToSection('Reason', Reason);
        ExcelReportBuilderManager.AddDataToSection('InventoryOrder', DocumentNo);
        ExcelReportBuilderManager.AddDataToSection('InventoryDate', DocumentDate);
        ExcelReportBuilderManager.AddDataToSection('StartDate', StartingDate);
        ExcelReportBuilderManager.AddDataToSection('EndDate', EndingDate);
        ExcelReportBuilderManager.AddDataToSection('OrderNum', LineDocNo);
        ExcelReportBuilderManager.AddDataToSection('OrderDate', CreationDate);
        if UntilDate <> 0D then begin
            ExcelReportBuilderManager.AddDataToSection('DayDateEnd', Format(Date2DMY(UntilDate, 1)));
            ExcelReportBuilderManager.AddDataToSection('MonthDateEnd', LocMgt.Month2Text(UntilDate));
            ExcelReportBuilderManager.AddDataToSection('YearDateEnd', Format(Date2DMY(UntilDate, 1)));
        end;
        ExcelReportBuilderManager.AddDataToSection('ResponsibleTitle1', StdRepMgt.GetEmpPosition(Member1));
        ExcelReportBuilderManager.AddDataToSection('ResponsibleName1', StdRepMgt.GetEmpName(Member1));
        ExcelReportBuilderManager.AddDataToSection('ResponsibleTitle2', StdRepMgt.GetEmpPosition(Member2));
        ExcelReportBuilderManager.AddDataToSection('ResponsibleName2', StdRepMgt.GetEmpName(Member2));

        Clear(TotalAmount);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('PAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillLine(LineNo: Text; Description: Text; ManufacturingYear: Text; InventoryNumber: Text; FactoryNo: Text; PassportNo: Text; QtyPlus: Decimal; AmountPlus: Decimal; QtyMinus: Decimal; AmountMinus: Decimal)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', 'PAGEFOOTER') then begin
            FillPageFooter();
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderManager.AddSection('BODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('LineNo', LineNo);
        ExcelReportBuilderManager.AddDataToSection('Name', Description);
        ExcelReportBuilderManager.AddDataToSection('YearOfRelease', ManufacturingYear);
        ExcelReportBuilderManager.AddDataToSection('InventoryNum', InventoryNumber);
        ExcelReportBuilderManager.AddDataToSection('SerialNum', FactoryNo);
        ExcelReportBuilderManager.AddDataToSection('PassportNum', PassportNo);
        ExcelReportBuilderManager.AddDataToSection('SurplusQty', Format(QtyPlus));
        ExcelReportBuilderManager.AddDataToSection('SurplusAmount', Format(AmountPlus));
        ExcelReportBuilderManager.AddDataToSection('DeficitQty', Format(QtyMinus));
        ExcelReportBuilderManager.AddDataToSection('DeficitAmount', Format(AmountMinus));

        TotalAmount[1] += QtyPlus;
        TotalAmount[2] += AmountPlus;
        TotalAmount[3] += QtyMinus;
        TotalAmount[4] += AmountMinus;
    end;

    [Scope('OnPrem')]
    procedure FillPageFooter()
    begin
        ExcelReportBuilderManager.AddSection('PAGEFOOTER');

        ExcelReportBuilderManager.AddDataToSection('surplusQtyTotal', Format(TotalAmount[1]));
        ExcelReportBuilderManager.AddDataToSection('surplusAmountTotal', Format(TotalAmount[2]));
        ExcelReportBuilderManager.AddDataToSection('deficitQtyTotal', Format(TotalAmount[3]));
        ExcelReportBuilderManager.AddDataToSection('deficitAmountTotal', Format(TotalAmount[4]));
    end;

    [Scope('OnPrem')]
    procedure FillFooter(RespTitle: Text; RespName: Text)
    begin
        ExcelReportBuilderManager.AddSection('REPORTFOOTER');

        ExcelReportBuilderManager.AddDataToSection('RespTitle1', RespTitle);
        ExcelReportBuilderManager.AddDataToSection('RespName1', RespName);
        ExcelReportBuilderManager.AddPagebreak();
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
}

