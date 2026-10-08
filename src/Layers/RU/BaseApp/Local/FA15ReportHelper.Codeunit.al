#pragma warning disable AA0247
codeunit 14954 "FA-15 Report Helper"
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
        FASetup.TestField("FA-15 Template Code");
        ExcelReportBuilderManager.InitTemplate(FASetup."FA-15 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(FALocationName: Text; Reason: Text; ReasonDocNo: Text; ReasonDocDate: Text; DocNo: Text; DocDate: Text; NewFALocationName: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('FIRSTPAGETITLE');

        ExcelReportBuilderManager.AddDataToSection('CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection('DepartmentName', FALocationName);
        ExcelReportBuilderManager.AddDataToSection('Reason', Reason);
        ExcelReportBuilderManager.AddDataToSection('OKPO', CompanyInfo."OKPO Code");

        ExcelReportBuilderManager.AddDataToSection('ReasonDocNo', ReasonDocNo);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocDate', ReasonDocDate);
        ExcelReportBuilderManager.AddDataToSection('Field1', ReasonDocNo);
        ExcelReportBuilderManager.AddDataToSection('Field2', ReasonDocDate);
        ExcelReportBuilderManager.AddDataToSection('Field3', ReasonDocDate);

        ExcelReportBuilderManager.AddDataToSection('DocumentNo', DocNo);
        ExcelReportBuilderManager.AddDataToSection('DocumentDate', DocDate);
        ExcelReportBuilderManager.AddDataToSection('LocationName', NewFALocationName);

        ExcelReportBuilderManager.AddSection('FIRSTPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillBody(Description: Text; FactoryNo: Text; PassportNo: Text; PostingDate: Text; Quantity: Text; BookValue: Text; Amount: Text)
    begin
        if not ExcelReportBuilderManager.TryAddSection('FIRSTPAGEBODY') then begin
            ExcelReportBuilderManager.AddPagebreak();
            ExcelReportBuilderManager.AddSection('FIRSTPAGEBODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('AssetName', Description);
        ExcelReportBuilderManager.AddDataToSection('FactoryNo', FactoryNo);
        ExcelReportBuilderManager.AddDataToSection('PassportNo', PassportNo);
        ExcelReportBuilderManager.AddDataToSection('PostingDate', PostingDate);
        ExcelReportBuilderManager.AddDataToSection('Quantity', Quantity);
        ExcelReportBuilderManager.AddDataToSection('BookValue', BookValue);
        ExcelReportBuilderManager.AddDataToSection('Amount', Amount);
    end;

    [Scope('OnPrem')]
    procedure FillLastHeader(Result: array[5] of Text; Complect: array[5] of Text; Defect: array[5] of Text; Conclusion: array[5] of Text)
    begin
        ExcelReportBuilderManager.SetSheet('Sheet2');
        ExcelReportBuilderManager.AddSection('LASTPAGEHEADER');

        ExcelReportBuilderManager.AddDataToSection('Result1', Result[1]);
        ExcelReportBuilderManager.AddDataToSection('Result2', Result[2]);
        ExcelReportBuilderManager.AddDataToSection('Complect1', Complect[1]);
        ExcelReportBuilderManager.AddDataToSection('Complect2', Complect[2]);
        ExcelReportBuilderManager.AddDataToSection('Complect3', Complect[3]);
        ExcelReportBuilderManager.AddDataToSection('Complect4', Complect[4]);
        ExcelReportBuilderManager.AddDataToSection('Complect5', Complect[5]);
        ExcelReportBuilderManager.AddDataToSection('Defect1', Defect[1]);
        ExcelReportBuilderManager.AddDataToSection('Defect2', Defect[2]);
        ExcelReportBuilderManager.AddDataToSection('Defect3', Defect[3]);
        ExcelReportBuilderManager.AddDataToSection('Conclusion1', Conclusion[1]);
        ExcelReportBuilderManager.AddDataToSection('Conclusion2', Conclusion[2]);
        ExcelReportBuilderManager.AddDataToSection('Conclusion3', Conclusion[3]);
        ExcelReportBuilderManager.AddDataToSection('Conclusion4', Conclusion[4]);
        ExcelReportBuilderManager.AddDataToSection('Conclusion5', Conclusion[5]);
    end;

    [Scope('OnPrem')]
    procedure FillLastFooter(ReleasedBy: Text; ReleasedByName: Text; ReceivedBy: Text; ReceivedByName: Text; StoredBy: Text; StoredByName: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('LASTPAGEFOOTER');
        ExcelReportBuilderManager.AddDataToSection('ReleasedByTitle', ReleasedBy);
        ExcelReportBuilderManager.AddDataToSection('ReleasedByName', ReleasedByName);
        ExcelReportBuilderManager.AddDataToSection('ReceivedByTitle', ReceivedBy);
        ExcelReportBuilderManager.AddDataToSection('ReceivedByName', ReceivedByName);
        ExcelReportBuilderManager.AddDataToSection('StoredByTitle', StoredBy);
        ExcelReportBuilderManager.AddDataToSection('StoredByName', StoredByName);
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

