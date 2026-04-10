#pragma warning disable AA0247
codeunit 14943 "INV-17 Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        StdRepMgt: Codeunit "Local Report Management";
        LocMgt: Codeunit "Localisation Management";

    [Scope('OnPrem')]
    procedure InitReportTemplate(ReportID: Integer)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        case ReportID of
            REPORT::"Invent. Act INV-17":
                begin
                    InventorySetup.TestField("INV-17 Template Code");
                    ExcelReportBuilderManager.InitTemplate(InventorySetup."INV-17 Template Code");
                end;
            REPORT::"Supplement to INV-17":
                begin
                    InventorySetup.TestField("INV-17 Appendix Template Code");
                    ExcelReportBuilderManager.InitTemplate(InventorySetup."INV-17 Appendix Template Code");
                end;
        end;
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(DocumentNo: Text; DocumentDate: Text; ReasonDocNo: Text; ReasonDocDate: Text; InvDate: Date)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyName', StdRepMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection(
          'CodeOKPO', CompanyInfo."OKPO Code");

        ExcelReportBuilderManager.AddDataToSection('DocumentNum', DocumentNo);
        ExcelReportBuilderManager.AddDataToSection('Documentdate', DocumentDate);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocumentNum', ReasonDocNo);
        ExcelReportBuilderManager.AddDataToSection('ReasonDocumentdate', ReasonDocDate);
        ExcelReportBuilderManager.AddDataToSection('Date', Format(Date2DMY(InvDate, 1)));
        ExcelReportBuilderManager.AddDataToSection('MthName', LocMgt.Month2Text(InvDate));
        ExcelReportBuilderManager.AddDataToSection('Year', Format(Date2DMY(InvDate, 1)));
    end;

    [Scope('OnPrem')]
    procedure FillAppndxHeader(DocumentNo: Text; DocumentDate: Date; InvDate: Date)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();
        ExcelReportBuilderManager.AddSection('REPORTHEADER');
        ExcelReportBuilderManager.AddDataToSection(
          'CompanyName', StdRepMgt.GetCompanyName());

        ExcelReportBuilderManager.AddDataToSection('DocumentNum', DocumentNo);
        ExcelReportBuilderManager.AddDataToSection('Date', Format(Date2DMY(DocumentDate, 1)));
        ExcelReportBuilderManager.AddDataToSection('MthName', LocMgt.Month2Text(DocumentDate));
        ExcelReportBuilderManager.AddDataToSection('Year', Format(Date2DMY(DocumentDate, 1)));
        ExcelReportBuilderManager.AddDataToSection('RptDate', Format(Date2DMY(InvDate, 1)));
        ExcelReportBuilderManager.AddDataToSection('RptMthName', LocMgt.Month2Text(InvDate));
        ExcelReportBuilderManager.AddDataToSection('RptYear', Format(Date2DMY(InvDate, 1)));
    end;

    [Scope('OnPrem')]
    procedure FillPartHeader(CategoryType: Option)
    var
        InvActLine: Record "Invent. Act Line";
    begin
        case CategoryType of
            InvActLine.Category::Debts:
                ExcelReportBuilderManager.AddSection('PART1HEADER');
            InvActLine.Category::Liabilities:
                begin
                    ExcelReportBuilderManager.AddPagebreak();
                    ExcelReportBuilderManager.AddSection('PART2HEADER');
                end;
        end;
        FillPageHeader(CategoryType);
    end;

    [Scope('OnPrem')]
    procedure FillPageHeader(CategoryType: Option)
    var
        InvActLine: Record "Invent. Act Line";
    begin
        case CategoryType of
            InvActLine.Category::Debts:
                ExcelReportBuilderManager.AddSection('PART1PAGEHEADER');
            InvActLine.Category::Liabilities:
                ExcelReportBuilderManager.AddSection('PART2PAGEHEADER');
        end;
    end;

    [Scope('OnPrem')]
    procedure FillAppndxPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('PAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillLine(ContractorName: Text; AccCode: Text; BodyDetails: array[4] of Decimal; FooterDetails: array[4] of Decimal; CategoryType: Option)
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', 'PARTFOOTER') then begin
            FillPageFooter(FooterDetails);
            ExcelReportBuilderManager.AddPagebreak();
            FillPageHeader(CategoryType);
            ExcelReportBuilderManager.AddSection('BODY');
        end;

        ExcelReportBuilderManager.AddDataToSection('Name', ContractorName);
        ExcelReportBuilderManager.AddDataToSection('AccCode', AccCode);
        ExcelReportBuilderManager.AddDataToSection('Amount', Format(BodyDetails[1]));
        ExcelReportBuilderManager.AddDataToSection('DebtAmount', Format(BodyDetails[2]));
        ExcelReportBuilderManager.AddDataToSection('NonapprovedAmount', Format(BodyDetails[3]));
        ExcelReportBuilderManager.AddDataToSection('HopelessAmount', Format(BodyDetails[4]));
    end;

    [Scope('OnPrem')]
    procedure FillAppndxLine(LineNo: Text; Name: Text; Agreement: Text; DebtDate: Text; DebtAmount: Text; CreditAmount: Text; DocType: Text; DocNo: Text; DocDate: Text)
    begin
        ExcelReportBuilderManager.AddSection('BODY');

        ExcelReportBuilderManager.AddDataToSection('LineNo', LineNo);
        ExcelReportBuilderManager.AddDataToSection('Name', Name);
        ExcelReportBuilderManager.AddDataToSection('Agreement', Agreement);
        ExcelReportBuilderManager.AddDataToSection('DebtDate', DebtDate);
        ExcelReportBuilderManager.AddDataToSection('DebtAmountDe', DebtAmount);
        ExcelReportBuilderManager.AddDataToSection('DebtAmountCr', CreditAmount);
        ExcelReportBuilderManager.AddDataToSection('LineDocName', DocType);
        ExcelReportBuilderManager.AddDataToSection('LineDocNum', DocNo);
        ExcelReportBuilderManager.AddDataToSection('LineDocDate', DocDate);
    end;

    [Scope('OnPrem')]
    procedure FillPageFooter(FooterDetails: array[6] of Decimal)
    begin
        ExcelReportBuilderManager.AddSection('PARTFOOTER');

        ExcelReportBuilderManager.AddDataToSection('TotalAmount', Format(FooterDetails[1]));
        ExcelReportBuilderManager.AddDataToSection('TotalDebtAmount', Format(FooterDetails[2]));
        ExcelReportBuilderManager.AddDataToSection('TotalNonapprovedAmount', Format(FooterDetails[3]));
        ExcelReportBuilderManager.AddDataToSection('TotalHopelessAmount', Format(FooterDetails[4]));
    end;

    [Scope('OnPrem')]
    procedure FillFooter(Chairman: Text; ChairmanName: Text; Member: Text; MemberName: Text; AdditionalMember: Text; AdditionalMemberName: Text)
    begin
        ExcelReportBuilderManager.AddSection('REPORTFOOTER');

        ExcelReportBuilderManager.AddDataToSection('Chairman', Chairman);
        ExcelReportBuilderManager.AddDataToSection('ChairmanName', ChairmanName);
        ExcelReportBuilderManager.AddDataToSection('Member', Member);
        ExcelReportBuilderManager.AddDataToSection('MemberName', MemberName);

        ExcelReportBuilderManager.AddSection('ADDITIONALMEMBERSECTION');
        ExcelReportBuilderManager.AddDataToSection('AdditionalMember', AdditionalMember);
        ExcelReportBuilderManager.AddDataToSection('AdditionalMemberName', AdditionalMemberName);
        ExcelReportBuilderManager.AddPagebreak();
    end;

    [Scope('OnPrem')]
    procedure FillAppndxFooter(AccountantName: Text)
    begin
        ExcelReportBuilderManager.AddSection('REPORTFOOTER');
        ExcelReportBuilderManager.AddDataToSection('AccountantName', AccountantName);
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
    procedure CheckSignature(var DocSign: Record "Document Signature"; ActNo: Code[20]; EmpType: Integer)
    var
        DocSignMgt: Codeunit "Doc. Signature Management";
    begin
        DocSignMgt.GetDocSign(
          DocSign, DATABASE::"Invent. Act Header",
          0, ActNo, EmpType, true);
    end;
}

