#pragma warning disable AA0247
codeunit 14953 "FA-4 Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        ConcTotalAmount: Decimal;

    [Scope('OnPrem')]
    procedure InitReportTemplate(ReportID: Integer)
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        case ReportID of
            REPORT::"FA Write-off Act FA-4", REPORT::"FA Posted Writeoff Act FA-4":
                begin
                    FASetup.TestField("FA-4 Template Code");
                    ExcelReportBuilderManager.InitTemplate(FASetup."FA-4 Template Code");
                end;
            REPORT::"FA Writeoff Act FA-4a", REPORT::"Posted FA Writeoff Act FA-4a":
                begin
                    FASetup.TestField("FA-4a Template Code");
                    ExcelReportBuilderManager.InitTemplate(FASetup."FA-4a Template Code");
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure SetDocSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure SetAssetSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet2');
    end;

    [Scope('OnPrem')]
    procedure SetExpSheet()
    begin
        ExcelReportBuilderManager.SetSheet('Sheet3');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(EmployeeDepartment: Text; EmployeeName: Text; Reason: Text; FAPostingDate: Text; ReasonDocNo: Text; ReasonDocDate: Text; FAEmployeeNo: Text; DirectorPosition: Text; DocNo: Text; DocDate: Text; PostingDescription: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'CodeOKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderManager.AddDataToSection(
          'ChiefName', CompanyInfo."Director Name");

        ExcelReportBuilderManager.AddDataToSection('DepartamentName', EmployeeDepartment);
        ExcelReportBuilderManager.AddDataToSection('EmplName', EmployeeName);
        ExcelReportBuilderManager.AddDataToSection('Reason', Reason);
        ExcelReportBuilderManager.AddDataToSection('FromBusinessAccount', FAPostingDate);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocNo', ReasonDocNo);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocDate', ReasonDocDate);
        ExcelReportBuilderManager.AddDataToSection('EmplID', FAEmployeeNo);
        ExcelReportBuilderManager.AddDataToSection('ChiefPost', DirectorPosition);
        ExcelReportBuilderManager.AddDataToSection('ActNumber', DocNo);
        ExcelReportBuilderManager.AddDataToSection('ActDate', DocDate);
        ExcelReportBuilderManager.AddDataToSection('PostingDescription', PostingDescription);
    end;

    [Scope('OnPrem')]
    procedure FillHeader2(EmployeeDepartment: Text; FAPostingDate: Text; AcqCostAccount: Text; DirectorPosition: Text; DocNo: Text; DocDate: Text; FactoryNo: Text; VehicleRegNo: Text; InventoryNumber: Text; VehicleDescription: Text; PostingDescription: Text; EmployeePosition: Text; EmployeeName: Text; FAEmployeeNo: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'CodeOKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderManager.AddDataToSection(
          'ChiefName', CompanyInfo."Director Name");

        ExcelReportBuilderManager.AddDataToSection('DepartamentName', EmployeeDepartment);
        ExcelReportBuilderManager.AddDataToSection('EmplName', EmployeeName);
        ExcelReportBuilderManager.AddDataToSection('FromBusinessAccount', FAPostingDate);
        ExcelReportBuilderManager.AddDataToSection('ControlAccount', AcqCostAccount);
        ExcelReportBuilderManager.AddDataToSection('ChiefPost', DirectorPosition);
        ExcelReportBuilderManager.AddDataToSection('ActNumber', DocNo);
        ExcelReportBuilderManager.AddDataToSection('ActDate', DocDate);
        ExcelReportBuilderManager.AddDataToSection('AssetSerialNum', FactoryNo);
        ExcelReportBuilderManager.AddDataToSection('AssetRegNum', VehicleRegNo);
        ExcelReportBuilderManager.AddDataToSection('AssetAccountNum', InventoryNumber);
        ExcelReportBuilderManager.AddDataToSection('AssetName', VehicleDescription);
        ExcelReportBuilderManager.AddDataToSection('PostingDescription', PostingDescription);
        ExcelReportBuilderManager.AddDataToSection('EmplTitle', EmployeePosition);
        ExcelReportBuilderManager.AddDataToSection('EmplName', EmployeeName);
        ExcelReportBuilderManager.AddDataToSection('EmplID', FAEmployeeNo);
    end;

    [Scope('OnPrem')]
    procedure FillConclusionHeader(Conclusion1: Text; Conclusion2: Text; Appendix1: Text; Appendix2: Text; Chairman: Text; ChairmanName: Text; Member1: Text; Member1Name: Text; Member2: Text; Member2Name: Text)
    begin
        ExcelReportBuilderManager.AddSection('CONCLUSIONHEADER');
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

        ConcTotalAmount := 0;
    end;

    [Scope('OnPrem')]
    procedure FillAssetHeader()
    begin
        ExcelReportBuilderManager.AddSection('ASSETHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillStatePageHeader()
    begin
        ExcelReportBuilderManager.AddSection('STATEPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillAssetPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('ASSETPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillConclusionPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('CONCLUSIONPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillStateLine(Description: Text; InventoryNumber: Text; FactoryNo: Text; ManufacturingYear: Text; InitialReleaseDate: Text; FactYears: Text; AcquisitionCost: Text; Depreciation: Text; BookValue: Text)
    begin
        TryAddBodySection();

        ExcelReportBuilderManager.AddDataToSection('AssetName', Description);
        ExcelReportBuilderManager.AddDataToSection('AssetAccountNum', InventoryNumber);
        ExcelReportBuilderManager.AddDataToSection('AssetSerialNum', FactoryNo);
        ExcelReportBuilderManager.AddDataToSection('AssetGuaranteeDate', ManufacturingYear);
        ExcelReportBuilderManager.AddDataToSection('ToBusinessAccount', InitialReleaseDate);
        ExcelReportBuilderManager.AddDataToSection('ObservedLife', FactYears);
        ExcelReportBuilderManager.AddDataToSection('AcquisitionPrice', AcquisitionCost);
        ExcelReportBuilderManager.AddDataToSection('AmountDepreciation', Depreciation);
        ExcelReportBuilderManager.AddDataToSection('DeprCost', BookValue);
    end;

    [Scope('OnPrem')]
    procedure FillStateLine2(ManufacturingYear: Text; AcqDate: Text; GLAcqDate: Text; IsVehicle: Text; VehicleWriteoffDate: Text; RunAfterReleaseDate: Text; RunAfterRenovationDate: Text; InitialAcqCost: Text; Depreciation: Text; BookValue: Text)
    begin
        TryAddBodySection();
        ExcelReportBuilderManager.AddDataToSection('AssetGuaranteeDate', ManufacturingYear);
        ExcelReportBuilderManager.AddDataToSection('AcquisitionDate', AcqDate);
        ExcelReportBuilderManager.AddDataToSection('ToBusinessAccount', GLAcqDate);
        ExcelReportBuilderManager.AddDataToSection('DateRevaluationLast', IsVehicle);
        ExcelReportBuilderManager.AddDataToSection('VehicleWriteoffDate', VehicleWriteoffDate);
        ExcelReportBuilderManager.AddDataToSection('UseValue', RunAfterReleaseDate);
        ExcelReportBuilderManager.AddDataToSection('UseValueFromLastRepairs', RunAfterRenovationDate);
        ExcelReportBuilderManager.AddDataToSection('AcquisitionPrice', InitialAcqCost);
        ExcelReportBuilderManager.AddDataToSection('AmountDepreciation', Depreciation);
        ExcelReportBuilderManager.AddDataToSection('DeprCost', BookValue);
    end;

    local procedure TryAddBodySection()
    begin
        if not ExcelReportBuilderManager.TryAddSection('STATEBODY') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillStatePageHeader();
            ExcelReportBuilderManager.AddSection('STATEBODY');
        end;
    end;

    [Scope('OnPrem')]
    procedure FillAssetLine(Description: Text; AssetQty: Text; Name: Text; PreciousMetalCode: Text; UnitOfMeasureCode: Text; MetalQty: Text; MetalMass: Text)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('ASSETBODY', 'ASSETPAGEFOOTER') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillAssetPageHeader();
            ExcelReportBuilderManager.AddSection('ASSETBODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('AssetDescription', Description);
        ExcelReportBuilderManager.AddDataToSection('AssetQuantity', AssetQty);
        ExcelReportBuilderManager.AddDataToSection('Name', Name);
        ExcelReportBuilderManager.AddDataToSection('MetalCode', PreciousMetalCode);
        ExcelReportBuilderManager.AddDataToSection('Name', Name);
        ExcelReportBuilderManager.AddDataToSection('MetalCode', PreciousMetalCode);
        ExcelReportBuilderManager.AddDataToSection('UnitOfMeasure', UnitOfMeasureCode);
        ExcelReportBuilderManager.AddDataToSection('MetalQty', MetalQty);
        ExcelReportBuilderManager.AddDataToSection('MetalMass', MetalMass);
    end;

    [Scope('OnPrem')]
    procedure FillAssetLine2(VehicleRegNo: Text; VehicleEngineNo: Text; VehicleChassisNo: Text; VehicleCapacity: Text; VehiclePassportWeight: Text; Name: Text; PreciousMetalCode: Text; UnitOfMeasureCode: Text; MetalQty: Text; MetalMass: Text)
    begin
        if not ExcelReportBuilderManager.TryAddSection('ASSETBODY') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillAssetPageHeader();
            ExcelReportBuilderManager.AddSection('ASSETBODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('ConsNo', '1');
        ExcelReportBuilderManager.AddDataToSection('VehicleRegNo', VehicleRegNo);
        ExcelReportBuilderManager.AddDataToSection('VehicleEngineNo', VehicleEngineNo);
        ExcelReportBuilderManager.AddDataToSection('VehicleChassisNo', VehicleChassisNo);
        ExcelReportBuilderManager.AddDataToSection('VehicleCapacity', VehicleCapacity);
        ExcelReportBuilderManager.AddDataToSection('VehiclePassportWeight', VehiclePassportWeight);
        ExcelReportBuilderManager.AddDataToSection('MetalName', Name);
        ExcelReportBuilderManager.AddDataToSection('MetalCode', PreciousMetalCode);
        ExcelReportBuilderManager.AddDataToSection('UnitOfMeasure', UnitOfMeasureCode);
        ExcelReportBuilderManager.AddDataToSection('MetalQty', MetalQty);
        ExcelReportBuilderManager.AddDataToSection('MetalMass', MetalMass);
    end;

    [Scope('OnPrem')]
    procedure FillConclusionLine(DocNo: Text; Description: Text; ItemNo: Text; UnitOfMeasure: Text; Qty: Text; UnitAmount: Text; Amount: Decimal)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('CONCLUSIONBODY', 'CONCLUSIONPAGEFOOTER') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillConclusionPageHeader();
            ExcelReportBuilderManager.AddSection('CONCLUSIONBODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('ConcDocNo', DocNo);
        ExcelReportBuilderManager.AddDataToSection('ConcDescription', Description);
        ExcelReportBuilderManager.AddDataToSection('ConcItemNo', ItemNo);
        ExcelReportBuilderManager.AddDataToSection('ConcUOM', UnitOfMeasure);
        ExcelReportBuilderManager.AddDataToSection('ConcQty', Qty);
        ExcelReportBuilderManager.AddDataToSection('ConcUnitAmount', UnitAmount);
        ExcelReportBuilderManager.AddDataToSection('ConcAmount', StdRepMgt.FormatReportValue(Amount, 2));

        ConcTotalAmount += Amount;
    end;

    [Scope('OnPrem')]
    procedure FillAssetPageFooter()
    begin
        ExcelReportBuilderManager.AddSection('ASSETPAGEFOOTER');
    end;

    [Scope('OnPrem')]
    procedure FillAssetFooter(Characteristics: array[5] of Text; Conclusion: array[5] of Text; Appendix1: Text; Appendix2: Text; Chairman: Text; ChairmanName: Text; Member1: Text; Member1Name: Text; Member2: Text; Member2Name: Text)
    var
        i: Integer;
    begin
        ExcelReportBuilderManager.AddSection('ASSETFOOTER');

        for i := 1 to ArrayLen(Conclusion) do begin
            ExcelReportBuilderManager.AddDataToSection(
              'Characteristics' + Format(i), Characteristics[i]);
            ExcelReportBuilderManager.AddDataToSection(
              'Conclusion' + Format(i), Conclusion[i]);
        end;

        ExcelReportBuilderManager.AddDataToSection('Appendix1', Appendix1);
        ExcelReportBuilderManager.AddDataToSection('Appendix2', Appendix2);
        ExcelReportBuilderManager.AddDataToSection('Chairman', Chairman);
        ExcelReportBuilderManager.AddDataToSection('ChairmanName', ChairmanName);
        ExcelReportBuilderManager.AddDataToSection('Member1', Member1);
        ExcelReportBuilderManager.AddDataToSection('Member1Name', Member1Name);
        ExcelReportBuilderManager.AddDataToSection('Member2', Member2);
        ExcelReportBuilderManager.AddDataToSection('Member2Name', Member2Name);
    end;

    [Scope('OnPrem')]
    procedure FillConclusionPageFooter()
    begin
        ExcelReportBuilderManager.AddSection('CONCLUSIONPAGEFOOTER');

        ExcelReportBuilderManager.AddDataToSection('ScrapTotal', StdRepMgt.FormatReportValue(ConcTotalAmount, 2));
    end;

    [Scope('OnPrem')]
    procedure FillExpHeader()
    begin
        ExcelReportBuilderManager.AddSection('EXPHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillExpPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('EXPPAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillExpLine(ConsNo: Text; ItemNo: Text; Description: Text; UnitOfMeasureCode: Text; Qty: Text; UnitAmount: Text; Amount: Text)
    begin
        if not ExcelReportBuilderManager.TryAddSection('EXPBODY') then begin
            ExcelReportBuilderManager.AddPagebreak();
            FillExpPageHeader();
            ExcelReportBuilderManager.AddSection('EXPBODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('ItemConsNo', ConsNo);
        ExcelReportBuilderManager.AddDataToSection('ItemNo', ItemNo);
        ExcelReportBuilderManager.AddDataToSection('ItemDescription', Description);
        ExcelReportBuilderManager.AddDataToSection('ItemUOM', UnitOfMeasureCode);
        ExcelReportBuilderManager.AddDataToSection('ItemQty', Qty);
        ExcelReportBuilderManager.AddDataToSection('ItemUnitAmount', UnitAmount);
        ExcelReportBuilderManager.AddDataToSection('ItemAmount', Amount);
    end;

    [Scope('OnPrem')]
    procedure FillExpFooter()
    begin
        ExcelReportBuilderManager.AddSection('EXPFOOTER');
    end;

    [Scope('OnPrem')]
    procedure FillReportFooter(Result1: Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTFOOTER');
        ExcelReportBuilderManager.AddDataToSection('Result', Result1);
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

