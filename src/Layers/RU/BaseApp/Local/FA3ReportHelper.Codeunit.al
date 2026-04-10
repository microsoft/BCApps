#pragma warning disable AA0247
codeunit 14952 "FA-3 Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.TestField("FA-3 Template Code");
        ExcelReportBuilderManager.InitTemplate(FASetup."FA-3 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(NewFALocationName: Text; FALocationName: Text; DocNo: Text; DocDate: Text; DirectorPosition: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CustCompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'CustOKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderManager.AddDataToSection(
          'ChiefName', CompanyInfo."Director Name");

        ExcelReportBuilderManager.AddDataToSection('CustDepartment', NewFALocationName);
        ExcelReportBuilderManager.AddDataToSection('ExecDepartment', FALocationName);
        ExcelReportBuilderManager.AddDataToSection('DocumentNumber', DocNo);
        ExcelReportBuilderManager.AddDataToSection('DocumentDate', DocDate);
        ExcelReportBuilderManager.AddDataToSection('ChiefPost', DirectorPosition);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('STATEPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillLine(ConsNo: Text; Description: Text; InventoryNumber: Text; PassportNo: Text; FactoryNo: Text; Amount: Text; ActualUse: Text)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('STATEBODY', 'EXPFOOTER') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader();
            ExcelReportBuilderManager.AddSection('STATEBODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('ConsNo', ConsNo);
        ExcelReportBuilderManager.AddDataToSection('AssetNameBefore', Description);
        ExcelReportBuilderManager.AddDataToSection('AssetID', InventoryNumber);
        ExcelReportBuilderManager.AddDataToSection('PassportID', PassportNo);
        ExcelReportBuilderManager.AddDataToSection('AssetSerialNum', FactoryNo);
        ExcelReportBuilderManager.AddDataToSection('DeprCost', Amount);
        ExcelReportBuilderManager.AddDataToSection('ObservedLife', ActualUse);
    end;

    [Scope('OnPrem')]
    procedure FillExpFooter()
    begin
        ExcelReportBuilderManager.AddSection('EXPFOOTER');
    end;

    [Scope('OnPrem')]
    procedure FillReportFooter(Conclusion1: Text; Conclusion2: Text; Appendix: array[5] of Text; Chairman: Text; ChairmanName: Text; Member1: Text; Member1Name: Text; Member2: Text; Member2Name: Text; ReleasedBy: Text; ReleasedByName: Text; ReceivedBy: Text; ReceivedByName: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTFOOTER');
        ExcelReportBuilderManager.AddDataToSection('Conclusion1', Conclusion1);
        ExcelReportBuilderManager.AddDataToSection('Conclusion2', Conclusion2);
        ExcelReportBuilderManager.AddDataToSection('Appendix1', Appendix[1]);
        ExcelReportBuilderManager.AddDataToSection('Appendix2', Appendix[2]);
        ExcelReportBuilderManager.AddDataToSection('Appendix3', Appendix[3]);
        ExcelReportBuilderManager.AddDataToSection('Appendix4', Appendix[4]);
        ExcelReportBuilderManager.AddDataToSection('Appendix5', Appendix[5]);
        ExcelReportBuilderManager.AddDataToSection('Chairman', Chairman);
        ExcelReportBuilderManager.AddDataToSection('ChairmanName', ChairmanName);
        ExcelReportBuilderManager.AddDataToSection('Member1', Member1);
        ExcelReportBuilderManager.AddDataToSection('Member1Name', Member1Name);
        ExcelReportBuilderManager.AddDataToSection('Member2', Member2);
        ExcelReportBuilderManager.AddDataToSection('Member2Name', Member2Name);
        ExcelReportBuilderManager.AddDataToSection('ReleasedBy', ReleasedBy);
        ExcelReportBuilderManager.AddDataToSection('ReleasedByName', ReleasedByName);
        ExcelReportBuilderManager.AddDataToSection('NewEmplTitle', ReceivedBy);
        ExcelReportBuilderManager.AddDataToSection('NewEmplName', ReceivedByName);
        ExcelReportBuilderManager.AddDataToSection('ChiefAccountantName', CompanyInfo."Accountant Name");
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

