#pragma warning disable AA0247
codeunit 14946 "FA-1 Report Helper"
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
        FASetup.TestField("FA-1 Template Code");
        ExcelReportBuilderManager.InitTemplate(FASetup."FA-1 Template Code");
    end;

    [Scope('OnPrem')]
    procedure SetReportHeaderSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure SetBodySectionSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet2');
    end;

    [Scope('OnPrem')]
    procedure SetFooterSectionSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet3');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(OrgInfoArray: array[9] of Text; ReasonDocNo: Text; ReasonDocDate: Text; DocNo: Text; DocDate: Text; DepreciationStartingDate: Text; DisposalDate: Text; AcqCostAccount: Text; DepreciationCode: Text; DepreciationGroup: Text; InventoryNumber: Text; FactoryNo: Text; FADescription: Text; FALocationName: Text; FAManufacturer: Text; SuppInfo1: Text; SuppInfo2: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'acquireCompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'acquireCompanyAddress', StdRepMgt.GetCompanyAddress());
        ExcelReportBuilderManager.AddDataToSection(
          'acquireBank', StdRepMgt.GetCompanyBank());
        ExcelReportBuilderManager.AddDataToSection(
          'acquireChiefName', CompanyInfo."Director Name");
        ExcelReportBuilderManager.AddDataToSection(
          'acquirecodeOKPO', CompanyInfo."OKPO Code");

        ExcelReportBuilderManager.AddDataToSection('deliverChiefPost', OrgInfoArray[1]);
        ExcelReportBuilderManager.AddDataToSection('deliverChiefName', OrgInfoArray[2]);
        ExcelReportBuilderManager.AddDataToSection('acquireChiefPost', OrgInfoArray[3]);
        ExcelReportBuilderManager.AddDataToSection('acquireDepartamentName', OrgInfoArray[4]);
        ExcelReportBuilderManager.AddDataToSection('deliverCompanyName', OrgInfoArray[5]);
        ExcelReportBuilderManager.AddDataToSection('deliverCompanyAddress', OrgInfoArray[6]);
        ExcelReportBuilderManager.AddDataToSection('deliverBank', CopyStr(OrgInfoArray[7], 1, 75));
        ExcelReportBuilderManager.AddDataToSection('deliverDepartamentName', OrgInfoArray[8]);
        ExcelReportBuilderManager.AddDataToSection('Reason', OrgInfoArray[9]);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocNo', ReasonDocNo);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocDate', ReasonDocDate);
        ExcelReportBuilderManager.AddDataToSection('ActNumber', DocNo);
        ExcelReportBuilderManager.AddDataToSection('ActDate', DocDate);
        ExcelReportBuilderManager.AddDataToSection('DateToBusinessAccounting', DepreciationStartingDate);
        ExcelReportBuilderManager.AddDataToSection('DateFromBusinessAccounting', DisposalDate);
        ExcelReportBuilderManager.AddDataToSection('ControlAccount', AcqCostAccount);
        ExcelReportBuilderManager.AddDataToSection('DepreciationCode', DepreciationCode);
        ExcelReportBuilderManager.AddDataToSection('AssetGroup', DepreciationGroup);
        ExcelReportBuilderManager.AddDataToSection('AccountNum', InventoryNumber);
        ExcelReportBuilderManager.AddDataToSection('SerialNum', FactoryNo);
        ExcelReportBuilderManager.AddDataToSection('AssetName', FADescription);
        ExcelReportBuilderManager.AddDataToSection('AssetLocation', FALocationName);
        ExcelReportBuilderManager.AddDataToSection('Make', FAManufacturer);
        ExcelReportBuilderManager.AddDataToSection('SupplementalInfo1', SuppInfo1);
        ExcelReportBuilderManager.AddDataToSection('SupplementalInfo2', SuppInfo2);
    end;

    [Scope('OnPrem')]
    procedure FillDataPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('DATAPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillCharPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('CHARPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillDataLine(ManufacturingYear: Text; InitialReleaseDate: Text; LastMaintenanceDate: Text; ActualUse: Text; NoOfDeprMonths: Text; Depreciation: Decimal; BookValue: Decimal; AcqCost: Decimal; InitAcqCost: Text; NewNoOfDeprMonths: Text; DeprMethod: Text; DepreciationRate: Text; PrintFADeprBookLine: Boolean)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('DATABODY', 'OTHERCHARFOOTER') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillDataPageHeader();
            ExcelReportBuilderManager.AddSection('DATABODY');
        end;

        if PrintFADeprBookLine then begin
            ExcelReportBuilderManager.AddDataToSection('OldGuaranteeDate', ManufacturingYear);
            ExcelReportBuilderManager.AddDataToSection('OldTransDate', InitialReleaseDate);
            ExcelReportBuilderManager.AddDataToSection('OldDateRevaluationLast', LastMaintenanceDate);
            ExcelReportBuilderManager.AddDataToSection('OldObservedLife', ActualUse);
            ExcelReportBuilderManager.AddDataToSection('OldUsefulLife', NoOfDeprMonths);
            ExcelReportBuilderManager.AddDataToSection('OldDepreciation', Format(Depreciation));
            ExcelReportBuilderManager.AddDataToSection('OldDeprCost', Format(BookValue));
            ExcelReportBuilderManager.AddDataToSection('OldAcquisitPrice', Format(AcqCost));
        end;
        ExcelReportBuilderManager.AddDataToSection('NewAcquisitionPrice', InitAcqCost);
        ExcelReportBuilderManager.AddDataToSection('NewUsefulLife', NewNoOfDeprMonths);
        ExcelReportBuilderManager.AddDataToSection('NewDeprProfileName', DeprMethod);
        ExcelReportBuilderManager.AddDataToSection('NewDepreciationRate', DepreciationRate);
    end;

    [Scope('OnPrem')]
    procedure FillCharLine(Name: Text; NomenclatureNo: Text; UOMCode: Code[10]; Quantity: Text; Mass: Text)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('CHARBODY', 'OTHERCHARFOOTER') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillCharPageHeader();
            ExcelReportBuilderManager.AddSection('CHARBODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('MetalName', Name);
        ExcelReportBuilderManager.AddDataToSection('MetalNo', NomenclatureNo);
        ExcelReportBuilderManager.AddDataToSection('MetalUOM', StdRepMgt.GetUoMDesc(UOMCode));
        ExcelReportBuilderManager.AddDataToSection('MetalQty', Quantity);
        ExcelReportBuilderManager.AddDataToSection('MetalMass', Mass);
    end;

    [Scope('OnPrem')]
    procedure FillCharPageFooter(Characteristics: array[5] of Text)
    var
        i: Integer;
    begin
        ExcelReportBuilderManager.AddSection('OTHERCHARFOOTER');

        for i := 1 to ArrayLen(Characteristics) do
            ExcelReportBuilderManager.AddDataToSection('Char' + Format(i), Characteristics[i]);
    end;

    [Scope('OnPrem')]
    procedure FillReportFooter(Result1: Text; Result2: Text; ExtraWork1: Text; ExtraWork2: Text; Conclusion1: Text; Conclusion2: Text; Appendix1: Text; Appendix2: Text; Chairman: Text; ChairmanName: Text; Member1: Text; Member1Name: Text; Member2: Text; Member2Name: Text; Receiver: Text; ReceiverName: Text; StoredBy: Text; StoredByName: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTFOOTER');
        ExcelReportBuilderManager.AddDataToSection('Result1', Result1);
        ExcelReportBuilderManager.AddDataToSection('Result2', Result2);
        ExcelReportBuilderManager.AddDataToSection('ExtraWork1', ExtraWork1);
        ExcelReportBuilderManager.AddDataToSection('ExtraWork2', ExtraWork2);
        ExcelReportBuilderManager.AddDataToSection('Conclusion1', Conclusion1);
        ExcelReportBuilderManager.AddDataToSection('Conclusion2', Conclusion2);
        ExcelReportBuilderManager.AddDataToSection('Appendix1', Appendix1);
        ExcelReportBuilderManager.AddDataToSection('Appendix2', Appendix2);
        ExcelReportBuilderManager.AddDataToSection('Chairman', Chairman);
        ExcelReportBuilderManager.AddDataToSection('ChairmanName', ChairmanName);
        ExcelReportBuilderManager.AddDataToSection('Member1', Member1);
        ExcelReportBuilderManager.AddDataToSection('Member1Name', Member1Name);
        ExcelReportBuilderManager.AddDataToSection('Member2', Member2);
        ExcelReportBuilderManager.AddDataToSection('Member2Name', Member2Name);
        ExcelReportBuilderManager.AddDataToSection('Receiver', Receiver);
        ExcelReportBuilderManager.AddDataToSection('ReceiverName', ReceiverName);
        ExcelReportBuilderManager.AddDataToSection('NewEmplTitle', StoredBy);
        ExcelReportBuilderManager.AddDataToSection('NewEmplName', StoredByName);
        ExcelReportBuilderManager.AddDataToSection('NewChiefAccountantName', CompanyInfo."Accountant Name");
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

    [Scope('OnPrem')]
    procedure CheckSignature(var DocSign: Record "Document Signature"; TableID: Integer; DocType: Option; DocNo: Code[20]; EmpType: Integer)
    var
        DocSignMgt: Codeunit "Doc. Signature Management";
    begin
        DocSignMgt.GetDocSign(
          DocSign, TableID,
          DocType, DocNo, EmpType, true);
    end;

    [Scope('OnPrem')]
    procedure CheckPostedSignature(var DocSign: Record "Posted Document Signature"; TableID: Integer; DocType: Option; DocNo: Code[20]; EmpType: Integer)
    var
        DocSignMgt: Codeunit "Doc. Signature Management";
    begin
        DocSignMgt.GetPostedDocSign(
          DocSign, TableID,
          DocType, DocNo, EmpType, true);
    end;

    [Scope('OnPrem')]
    procedure CalcActualUse(PostingDate: Date; InitialReleaseDate: Date): Text[30]
    var
        LocalisationManagement: Codeunit "Localisation Management";
        CalculateFrom: Date;
    begin
        if InitialReleaseDate = 0D then
            CalculateFrom := PostingDate
        else
            CalculateFrom := InitialReleaseDate;
        exit(CopyStr(LocalisationManagement.GetPeriodDate(CalculateFrom, PostingDate, 2), 1, 30));
    end;

    [Scope('OnPrem')]
    procedure CalcDepreciationRate(FADepreciationBook: Record "FA Depreciation Book"): Decimal
    begin
        if FADepreciationBook."No. of Depreciation Years" <> 0 then
            exit(Round(100 / (12 * FADepreciationBook."No. of Depreciation Years"), 0.01));
        exit(FADepreciationBook."Straight-Line %");
    end;

    [Scope('OnPrem')]
    procedure IsPrintFADeprBookLine(FADepreciationBook: Record "FA Depreciation Book"): Boolean
    begin
        exit(FADepreciationBook.Depreciation <> 0);
    end;
}

