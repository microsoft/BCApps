#pragma warning disable AA0247
codeunit 14951 "FA-14 Helper"
{

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        Director: Record Employee;
        Vendor: Record Vendor;
        FAPostingGroup: Record "FA Posting Group";
        FALocation: Record "FA Location";
        FirstFA: Record "Fixed Asset";
        PurchLineWithLCYAmt: Record "Purchase Line" temporary;
        FASetup: Record "FA Setup";
        FAComment: Record "FA Comment";
        PostedFAComment: Record "Posted FA Comment";
        DocSignature: Record "Document Signature";
        PostedDocSignature: Record "Posted Document Signature";
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";
        LocalReportManagement: Codeunit "Local Report Management";
        DocSignMgt: Codeunit "Doc. Signature Management";
        Reason: array[5] of Text;
        Conclusion: array[5] of Text;
        Appendix: array[5] of Text;
        Complect: array[5] of Text;
        Package: array[5] of Text;
        DirectorPos: Text[50];
        AppendixLine: array[5] of Text[80];
        DefectLine: array[5] of Text[80];
        Price: Decimal;
        Amount: Decimal;
        Members: array[5, 2] of Text;

    [Scope('OnPrem')]
    procedure FillReportUnpostedHeader(PurchaseHeader: Record "Purchase Header"; FirstPurchLine: Record "Purchase Line")
    var
        FAComment: Record "FA Comment";
        FASetup: Record "FA Setup";
    begin
        CompanyInfo.Get();
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        FASetup.Get();

        FAPostingGroup.Get(FirstPurchLine."Posting Group");
        FirstFA.Get(FirstPurchLine."No.");

        if FASetup."FA Location Mandatory" then
            FALocation.Get(FirstPurchLine."FA Location Code");
        GetDirectorPos();
        GetFAComments(FAComment."Document Type"::"Purchase Invoice", PurchaseHeader."No.");

        CheckSignature(
          1, DocSignature."Employee Type"::Chairman, PurchaseHeader);
        CheckSignature(2, DocSignature."Employee Type"::Member1, PurchaseHeader);
        CheckSignature(3, DocSignature."Employee Type"::Member2, PurchaseHeader);
        CheckSignature(4, DocSignature."Employee Type"::ReceivedBy, PurchaseHeader);
        CheckSignature(5, DocSignature."Employee Type"::StoredBy, PurchaseHeader);
        CalcAmounts(PurchaseHeader);

        FillReportHeaderSection(
          PurchaseHeader."No.", PurchaseHeader."Document Date", PurchaseHeader."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure FillReportPostedHeader(PurchaseInvHeader: Record "Purch. Inv. Header"; FirstPurchInvLine: Record "Purch. Inv. Line")
    var
        FASetup: Record "FA Setup";
    begin
        CompanyInfo.Get();
        Vendor.Get(PurchaseInvHeader."Buy-from Vendor No.");
        FASetup.Get();

        FAPostingGroup.Get(FirstPurchInvLine."Posting Group");
        FirstFA.Get(FirstPurchInvLine."No.");

        if FASetup."FA Location Mandatory" then
            FALocation.Get(FirstPurchInvLine."FA Location Code");
        GetDirectorPos();
        GetPostedFAComments(PostedFAComment."Document Type"::"Purchase Invoice", PurchaseInvHeader."No.");

        CheckPostedDocSignature(
          1, PostedDocSignature."Employee Type"::Chairman, PurchaseInvHeader);
        CheckPostedDocSignature(2, PostedDocSignature."Employee Type"::Member1, PurchaseInvHeader);
        CheckPostedDocSignature(3, PostedDocSignature."Employee Type"::Member2, PurchaseInvHeader);
        CheckPostedDocSignature(4, PostedDocSignature."Employee Type"::ReceivedBy, PurchaseInvHeader);
        CheckPostedDocSignature(5, PostedDocSignature."Employee Type"::StoredBy, PurchaseInvHeader);

        FillReportHeaderSection(
          PurchaseInvHeader."No.", PurchaseInvHeader."Document Date", PurchaseInvHeader."Posting Date");
    end;

    [Scope('OnPrem')]
    procedure GetFAComments(DocumentType: Option; DocumentNo: Code[20])
    var
        TempFADocHeader: Record "FA Document Header";
        FAComment: Record "FA Comment";
    begin
        TempFADocHeader."No." := DocumentNo;
        TempFADocHeader."Document Type" := DocumentType;
        TempFADocHeader.GetFAComments(Reason, FAComment.Type::Reason);
        TempFADocHeader.GetFAComments(Package, FAComment.Type::Package);
        TempFADocHeader.GetFAComments(Complect, FAComment.Type::Complect);
        TempFADocHeader.GetFAComments(Conclusion, FAComment.Type::Conclusion);
        TempFADocHeader.GetFAComments(Appendix, FAComment.Type::Appendix);
    end;

    [Scope('OnPrem')]
    procedure GetPostedFAComments(DocumentType: Option; DocumentNo: Code[20])
    var
        TempPostFADocHeader: Record "Posted FA Doc. Header";
    begin
        TempPostFADocHeader."No." := DocumentNo;
        TempPostFADocHeader."Document Type" := DocumentType;
        TempPostFADocHeader.GetFAComments(Reason, PostedFAComment.Type::Reason);
        TempPostFADocHeader.GetFAComments(Package, PostedFAComment.Type::Package);
        TempPostFADocHeader.GetFAComments(Complect, PostedFAComment.Type::Complect);
        TempPostFADocHeader.GetFAComments(Conclusion, PostedFAComment.Type::Conclusion);
        TempPostFADocHeader.GetFAComments(Appendix, PostedFAComment.Type::Appendix);
    end;

    [Scope('OnPrem')]
    procedure FillReportHeaderSection(DocumentNo: Code[20]; DocumentDate: Date; PostingDate: Date)
    begin
        ExcelReportBuilderMgr.AddSection('ReportHeader');
        ExcelReportBuilderMgr.AddDataToSection('acquireCompanyName', LocalReportManagement.GetCompanyName());
        ExcelReportBuilderMgr.AddDataToSection('acquireCompanyAddress', CompanyInfo."Phone No." + ' ' + CompanyInfo."Fax No.");
        ExcelReportBuilderMgr.AddDataToSection('acquireBank', LocalReportManagement.GetCompanyBank());
        ExcelReportBuilderMgr.AddDataToSection('acquirecodeOKPO', CompanyInfo."OKPO Code");
        ExcelReportBuilderMgr.AddDataToSection('Reason', Reason[1]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentNo', DocumentNo);
        ExcelReportBuilderMgr.AddDataToSection('DocumentDate', Format(DocumentDate, 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('ChiefPost', DirectorPos);
        ExcelReportBuilderMgr.AddDataToSection('ChiefName', CompanyInfo."Director Name");
        ExcelReportBuilderMgr.AddDataToSection('ActNumber', DocumentNo);
        ExcelReportBuilderMgr.AddDataToSection('ActDate', Format(DocumentDate, 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('DateToBusinessAccounting', Format(PostingDate, 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('ControlAccount', FAPostingGroup."Acquisition Cost Account");
        ExcelReportBuilderMgr.AddDataToSection('DeprCode', FirstFA."Depreciation Code");
        ExcelReportBuilderMgr.AddDataToSection('AssetGroup', FirstFA."Depreciation Group");
        ExcelReportBuilderMgr.AddDataToSection('deliverCompanyName', Vendor.Name + ' ' + Vendor."Name 2");
        ExcelReportBuilderMgr.AddDataToSection('deliverCompanyAddress', Vendor."Phone No." + ' ' + Vendor."Fax No.");
        ExcelReportBuilderMgr.AddDataToSection('Make', FirstFA.Manufacturer);
        ExcelReportBuilderMgr.AddDataToSection('ReceivingEnd', FALocation.Name);
        ExcelReportBuilderMgr.AddDataToSection('deliverCodeOKPO', Vendor."OKPO Code");
    end;

    [Scope('OnPrem')]
    procedure GetDirectorPos()
    begin
        if Director.Get(CompanyInfo."Director No.") then
            DirectorPos := Director.GetJobTitleName()
        else
            DirectorPos := '';
    end;

    [Scope('OnPrem')]
    procedure CheckSignature(MemberNo: Integer; EmpType: Integer; PurchaseHeader: Record "Purchase Header")
    var
        DocSign: Record "Document Signature";
    begin
        DocSignMgt.GetDocSign(
          DocSign, DATABASE::"Purchase Header",
          PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.", EmpType, true);
        Members[MemberNo, 1] := DocSign."Employee Job Title";
        Members[MemberNo, 2] := DocSign."Employee Name";
    end;

    [Scope('OnPrem')]
    procedure CheckPostedDocSignature(MemberNo: Integer; EmpType: Integer; PurchaseInvHeader: Record "Purch. Inv. Header")
    var
        PostedDocSign: Record "Posted Document Signature";
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Purch. Inv. Header",
          0, PurchaseInvHeader."No.", EmpType, false);
        Members[MemberNo, 1] := PostedDocSign."Employee Job Title";
        Members[MemberNo, 2] := PostedDocSign."Employee Name";
    end;

    [Scope('OnPrem')]
    procedure CalcAmounts(PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
        PurchasePosting: Codeunit "Purch.-Post";
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        TotalAmountLCY: Decimal;
        TotalAmountInclVATLCY: Decimal;
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '>0');
        PurchLine.SetFilter(Quantity, '<>0');

        PurchasePosting.SumPurchLines2Ex(PurchHeader, PurchLineWithLCYAmt, PurchLine, 0,
          TotalAmount, TotalAmountInclVAT, TotalAmountLCY, TotalAmountInclVATLCY);
    end;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    begin
        FASetup.Get();
        FASetup.TestField("FA-14 Template Code");
        ExcelReportBuilderMgr.InitTemplate(FASetup."FA-14 Template Code");
        ExcelReportBuilderMgr.SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure ExportData(FileName: Text)
    begin
        if FileName <> '' then
            ExcelReportBuilderMgr.ExportDataToClientFile(FileName)
        else
            ExcelReportBuilderMgr.ExportData();
    end;

    [Scope('OnPrem')]
    procedure AddPageHeader()
    begin
        ExcelReportBuilderMgr.SetSheet('Sheet2');
        ExcelReportBuilderMgr.AddSection('PageHeader');
    end;

    [Scope('OnPrem')]
    procedure FillReportBody(PurchaseLine: Record "Purchase Line")
    var
        TempFADocLine: Record "FA Document Line";
        FixedAsset: Record "Fixed Asset";
    begin
        AddBodySection();

        if FASetup."FA Location Mandatory" then
            PurchaseLine.TestField("FA Location Code");
        if FASetup."Employee No. Mandatory" then
            PurchaseLine.TestField("Employee No.");

        FixedAsset.Get(PurchaseLine."No.");
        PurchaseLine.TestField("Depreciation Book Code");
        PurchaseLine.TestField("Posting Group");
        if FixedAsset."Factory No." = '' then
            FixedAsset."Factory No." := PurchaseLine."No.";

        Clear(DefectLine);
        Clear(AppendixLine);
        TempFADocLine."Document No." := PurchaseLine."Document No.";
        TempFADocLine."Document Type" := FAComment."Document Type"::"Purchase Invoice";
        TempFADocLine.GetFAComments(DefectLine, FAComment.Type::Defect);
        TempFADocLine.GetFAComments(AppendixLine, FAComment.Type::Appendix);
        if PurchLineWithLCYAmt.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.") then begin
            if PurchLineWithLCYAmt.Quantity <> 0 then
                Price := Round(PurchLineWithLCYAmt.Amount / PurchLineWithLCYAmt.Quantity, 0.01);
            Amount := PurchLineWithLCYAmt.Amount;
        end;

        ExcelReportBuilderMgr.AddDataToSection('AssetName', PurchaseLine.Description);
        ExcelReportBuilderMgr.AddDataToSection('AssetWorksNumber', FixedAsset."Factory No.");
        ExcelReportBuilderMgr.AddDataToSection('AssetModel', FixedAsset.Manufacturer);
        ExcelReportBuilderMgr.AddDataToSection('UnitOfMeasure', PurchaseLine."Unit of Measure");
        ExcelReportBuilderMgr.AddDataToSection('Quantity', Format(PurchaseLine.Quantity, 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('AmountPrice', Format(Price, 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('AmountCost', Format(Amount, 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('QtyToReceive', Format(PurchaseLine."Qty. to Receive", 0, 3));

        ExcelReportBuilderMgr.AddDataToSection('DefectFound', DefectLine[1]);
        ExcelReportBuilderMgr.AddDataToSection('Comment', AppendixLine[1]);
    end;

    [Scope('OnPrem')]
    procedure FillPostedReportBody(PurchaseInvLine: Record "Purch. Inv. Line")
    var
        TempPostFADocLine: Record "Posted FA Doc. Line";
        FixedAsset: Record "Fixed Asset";
    begin
        AddBodySection();

        if FASetup."FA Location Mandatory" then
            PurchaseInvLine.TestField("FA Location Code");
        if FASetup."Employee No. Mandatory" then
            PurchaseInvLine.TestField("Employee No.");

        FixedAsset.Get(PurchaseInvLine."No.");
        PurchaseInvLine.TestField("Depreciation Book Code");
        PurchaseInvLine.TestField("Posting Group");

        if FixedAsset."Factory No." = '' then
            FixedAsset."Factory No." := PurchaseInvLine."No.";

        Clear(DefectLine);
        Clear(AppendixLine);
        TempPostFADocLine."Document No." := PurchaseInvLine."Document No.";
        TempPostFADocLine."Document Type" := PostedFAComment."Document Type"::"Purchase Invoice";
        TempPostFADocLine.GetFAComments(DefectLine, PostedFAComment.Type::Defect);
        TempPostFADocLine.GetFAComments(AppendixLine, PostedFAComment.Type::Appendix);

        ExcelReportBuilderMgr.AddDataToSection('AssetName', PurchaseInvLine.Description);
        ExcelReportBuilderMgr.AddDataToSection('AssetWorksNumber', FixedAsset."Factory No.");
        ExcelReportBuilderMgr.AddDataToSection('AssetModel', FixedAsset.Manufacturer);
        ExcelReportBuilderMgr.AddDataToSection('UnitOfMeasure', PurchaseInvLine."Unit of Measure");
        ExcelReportBuilderMgr.AddDataToSection('Quantity', Format(PurchaseInvLine.Quantity, 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('AmountPrice',
          Format(Round(PurchaseInvLine."Amount (LCY)" / PurchaseInvLine.Quantity), 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('AmountCost', Format(PurchaseInvLine."Amount (LCY)", 0, 3));
        ExcelReportBuilderMgr.AddDataToSection('QtyToReceive', Format(PurchaseInvLine.Quantity, 0, 3));

        ExcelReportBuilderMgr.AddDataToSection('DefectFound', DefectLine[1]);
        ExcelReportBuilderMgr.AddDataToSection('Comment', AppendixLine[1]);
    end;

    [Scope('OnPrem')]
    procedure FillReportFooter()
    begin
        if not ExcelReportBuilderMgr.TryAddSection('ReportFooter') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('ReportFooter');
        end;

        ExcelReportBuilderMgr.AddDataToSection('PackageDefect', Package[1]);
        ExcelReportBuilderMgr.AddDataToSection('Complect', Complect[1]);
        ExcelReportBuilderMgr.AddDataToSection('Consclusion', Conclusion[1] + ' ' + Conclusion[2]);
        ExcelReportBuilderMgr.AddDataToSection('DocumentsAttached', Appendix[1] + Appendix[2]);

        ExcelReportBuilderMgr.AddDataToSection('ChairManJobTitle', Members[1, 1]);
        ExcelReportBuilderMgr.AddDataToSection('ChairManName', Members[1, 2]);
        ExcelReportBuilderMgr.AddDataToSection('Member1JobTitle', Members[2, 1]);
        ExcelReportBuilderMgr.AddDataToSection('Member1Name', Members[2, 2]);
        ExcelReportBuilderMgr.AddDataToSection('Member2JobTitle', Members[3, 1]);
        ExcelReportBuilderMgr.AddDataToSection('Member2Name', Members[3, 2]);
        ExcelReportBuilderMgr.AddDataToSection('ReceivedByJobTitle', Members[4, 1]);
        ExcelReportBuilderMgr.AddDataToSection('ReceivedByName', Members[4, 2]);
        ExcelReportBuilderMgr.AddDataToSection('StoredByJobTitle', Members[5, 1]);
        ExcelReportBuilderMgr.AddDataToSection('StoredByName', Members[5, 2]);
        ExcelReportBuilderMgr.AddDataToSection('ChiefAccountantName', CompanyInfo."Accountant Name");
    end;

    [Scope('OnPrem')]
    procedure AddBodySection()
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('PageHeader');
            ExcelReportBuilderMgr.AddSection('BODY');
        end;
    end;
}

