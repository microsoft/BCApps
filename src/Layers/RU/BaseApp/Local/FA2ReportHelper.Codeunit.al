#pragma warning disable AA0247
codeunit 14948 "FA-2 Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderManager: Codeunit "Excel Report Builder Manager";
        TotalAmount: Decimal;
        UndersideTxt: Label 'FA-2 Underside';

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    var
        FASetup: Record "FA Setup";
    begin
        FASetup.Get();
        FASetup.TestField("FA-2 Template Code");
        ExcelReportBuilderManager.InitTemplate(FASetup."FA-2 Template Code");
        ExcelReportBuilderManager.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure FillHeader(FADocHeader: Record "FA Document Header")
    var
        CompanyInfo: Record "Company Information";
        FALocation: Record "FA Location";
        LocalReportMgt: Codeunit "Local Report Management";
    begin
        ExcelReportBuilderManager.AddSection('REPORTHEADER');

        ExcelReportBuilderManager.AddDataToSection('CompanyName', LocalReportMgt.GetCompanyName());
        ExcelReportBuilderManager.AddDataToSection('OldLocation', FALocation.GetName(FADocHeader."FA Location Code"));
        ExcelReportBuilderManager.AddDataToSection('NewLocation', FALocation.GetName(FADocHeader."New FA Location Code"));
        ExcelReportBuilderManager.AddDataToSection('DocumentNo', FADocHeader."No.");
        ExcelReportBuilderManager.AddDataToSection('DocumentDate', Format(FADocHeader."Posting Date"));
        ExcelReportBuilderManager.AddDataToSection('OKUD', '0306001');
        ExcelReportBuilderManager.AddDataToSection('OKPO', CompanyInfo."OKPO Code");
    end;

    [Scope('OnPrem')]
    procedure FillBody(FADocLine: Record "FA Document Line"; LineNo: Integer)
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if not ExcelReportBuilderManager.TryAddSectionWithPlaceForFooter('BODY', 'PAGEFOOTER') then begin
            ExcelReportBuilderManager.AddPagebreak();
            ExcelReportBuilderManager.AddSection('PAGEHEADER');
            ExcelReportBuilderManager.AddDataToSection('Underside', UndersideTxt);
            ExcelReportBuilderManager.AddSection('BODY');
        end;

        FixedAsset.Get(FADocLine."FA No.");
        ExcelReportBuilderManager.AddDataToSection('Number', Format(LineNo));
        ExcelReportBuilderManager.AddDataToSection('FADescription', FADocLine.Description);
        ExcelReportBuilderManager.AddDataToSection('FAYear', Format(FixedAsset."Manufacturing Year"));
        ExcelReportBuilderManager.AddDataToSection('FAInventoryNo', Format(FixedAsset."Inventory Number"));
        ExcelReportBuilderManager.AddDataToSection('FAQty', Format(FADocLine.Quantity, 0, 1));
        ExcelReportBuilderManager.AddDataToSection('FAAmount', Format(FADocLine.Amount, 0, 1));
        ExcelReportBuilderManager.AddDataToSection('FATotalAmount', Format(FADocLine."Book Value", 0, 1));

        TotalAmount += FADocLine."Book Value";
    end;

    [Scope('OnPrem')]
    procedure FillFooter(ReleasedBy: Record "Document Signature"; ReceivedBy: Record "Document Signature"; Appendix: array[5] of Text)
    var
        CompanyInfo: Record "Company Information";
    begin
        CompanyInfo.Get();

        ExcelReportBuilderManager.AddSection('REPORTFOOTER');

        ExcelReportBuilderManager.AddDataToSection('Appendix1', Appendix[1]);
        ExcelReportBuilderManager.AddDataToSection('Appendix2', Appendix[2]);
        ExcelReportBuilderManager.AddDataToSection('Appendix3', Appendix[3]);
        ExcelReportBuilderManager.AddDataToSection('Appendix4', Appendix[4]);
        ExcelReportBuilderManager.AddDataToSection('Appendix5', Appendix[5]);
        ExcelReportBuilderManager.AddDataToSection('OldTitle', ReleasedBy."Employee Job Title");
        ExcelReportBuilderManager.AddDataToSection('OldName', ReleasedBy."Employee Name");
        ExcelReportBuilderManager.AddDataToSection('NewTitle', ReceivedBy."Employee Job Title");
        ExcelReportBuilderManager.AddDataToSection('NewName', ReceivedBy."Employee Name");
        ExcelReportBuilderManager.AddDataToSection('OldId', ReleasedBy."Employee No.");
        ExcelReportBuilderManager.AddDataToSection('NewId', ReceivedBy."Employee No.");
        ExcelReportBuilderManager.AddDataToSection('ChiefAccountantName', CompanyInfo."Accountant Name");
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
    procedure FillPageHeader()
    begin
        ExcelReportBuilderManager.AddSection('PAGEHEADER');
    end;

    [Scope('OnPrem')]
    procedure FillPageFooter()
    begin
        ExcelReportBuilderManager.AddSection('PAGEFOOTER');
        ExcelReportBuilderManager.AddDataToSection('Sum', Format(TotalAmount, 0, 1));
    end;

    [Scope('OnPrem')]
    procedure FillHeaderFromPostedDoc(PostedFADocHeader: Record "Posted FA Doc. Header")
    var
        FADocHeader: Record "FA Document Header";
    begin
        FADocHeader.TransferFields(PostedFADocHeader);
        FillHeader(FADocHeader);
    end;

    [Scope('OnPrem')]
    procedure FillBodyFromPostedDoc(PostedFADocLine: Record "Posted FA Doc. Line"; LineNo: Integer)
    var
        FADocLine: Record "FA Document Line";
    begin
        FADocLine.TransferFields(PostedFADocLine);
        FillBody(FADocLine, LineNo);
    end;

    [Scope('OnPrem')]
    procedure FillFooterFromPostedDoc(PostedReleasedBy: Record "Posted Document Signature"; PostedReceivedBy: Record "Posted Document Signature"; Appendix: array[5] of Text)
    var
        ReleasedBy: Record "Document Signature";
        ReceivedBy: Record "Document Signature";
    begin
        ReleasedBy.TransferFields(PostedReleasedBy);
        ReceivedBy.TransferFields(PostedReceivedBy);
        FillFooter(ReleasedBy, ReceivedBy, Appendix);
    end;
}

