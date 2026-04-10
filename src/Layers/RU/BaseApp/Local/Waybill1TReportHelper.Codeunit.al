#pragma warning disable AA0247
codeunit 14933 "Waybill 1-T Report Helper"
{

    trigger OnRun()
    begin
    end;

    var
        ExcelReportBuilderMgr: Codeunit "Excel Report Builder Manager";

    [Scope('OnPrem')]
    procedure InitWaybillReportTmpl()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.TestField("Waybill 1-T Template Code");
        InitReportTemplate(InventorySetup."Waybill 1-T Template Code");
    end;

    [Scope('OnPrem')]
    procedure SetMainSheet()
    begin
        SetSheet('Sheet1');
    end;

    [Scope('OnPrem')]
    procedure SetSheet(SheetName: Text)
    begin
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

    local procedure InitReportTemplate(TemplateCode: Code[10])
    begin
        ExcelReportBuilderMgr.InitTemplate(TemplateCode);
    end;

    [Scope('OnPrem')]
    procedure FillProlog(HeaderValue: array[8] of Text)
    begin
        ExcelReportBuilderMgr.AddSection('PROLOG');

        ExcelReportBuilderMgr.AddDataToSection('DocNum', HeaderValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('DocDate', HeaderValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('ConsignorOKPO', HeaderValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('ConsigneeOKPO', HeaderValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('CustomerOKPO', HeaderValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('ConsignorAddress', HeaderValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('ConsigneeAddress', HeaderValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('CustomerBankAddress', HeaderValue[8]);

        ExcelReportBuilderMgr.AddSection('HEADER');
    end;

    [Scope('OnPrem')]
    procedure FillBody(LineValue: array[9] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSection('BODY') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('HEADER');
            ExcelReportBuilderMgr.AddSection('BODY');
        end;

        ExcelReportBuilderMgr.AddDataToSection('ItemId', LineValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('Qty', LineValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('Price', LineValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('ItemName', LineValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('Unit', LineValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('Packing', LineValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('Places', LineValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('Weight', LineValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('Amount', LineValue[9]);
    end;

    [Scope('OnPrem')]
    procedure FinalizeReport(FooterValue: array[12] of Text)
    begin
        FillReportFooter(FooterValue);
        ExcelReportBuilderMgr.AddPagebreak();
    end;

    local procedure FillReportFooter(FooterValue: array[12] of Text)
    begin
        if not ExcelReportBuilderMgr.TryAddSection('FOOTER') then begin
            ExcelReportBuilderMgr.AddPagebreak();
            ExcelReportBuilderMgr.AddSection('FOOTER');
        end;

        ExcelReportBuilderMgr.AddDataToSection('PageCount', GetProlongPageCount());
        ExcelReportBuilderMgr.AddDataToSection('RowCount', FooterValue[1]);
        ExcelReportBuilderMgr.AddDataToSection('RowCountEx', FooterValue[2]);
        ExcelReportBuilderMgr.AddDataToSection('TotalAmountVAT', FooterValue[3]);
        ExcelReportBuilderMgr.AddDataToSection('TotalGrossWeight', FooterValue[4]);
        ExcelReportBuilderMgr.AddDataToSection('ApplCount', FooterValue[5]);
        ExcelReportBuilderMgr.AddDataToSection('AttorneyId', FooterValue[6]);
        ExcelReportBuilderMgr.AddDataToSection('TotalAmountVATEx', FooterValue[7]);
        ExcelReportBuilderMgr.AddDataToSection('AcceptorName', FooterValue[8]);
        ExcelReportBuilderMgr.AddDataToSection('PostingDate', FooterValue[9]);
        ExcelReportBuilderMgr.AddDataToSection('ManagerName', FooterValue[10]);
        ExcelReportBuilderMgr.AddDataToSection('Accountant', FooterValue[11]);
        ExcelReportBuilderMgr.AddDataToSection('SupplierName', FooterValue[12]);
    end;

    [Scope('OnPrem')]
    procedure FillBackSide(BackSideVaue: Text)
    begin
        SetSheet('Sheet2');
        ExcelReportBuilderMgr.AddSection('PAGE2');
        ExcelReportBuilderMgr.AddDataToSection('DocNum_2', BackSideVaue);
    end;

    [Scope('OnPrem')]
    procedure TransferLineDescrValues(var LineValues: array[9] of Text; LineDescription: Text)
    var
        I: Integer;
    begin
        for I := 1 to 3 do
            LineValues[I] := '';

        LineValues[4] := LineDescription;

        for I := 5 to 9 do
            LineValues[I] := '';
    end;

    local procedure GetProlongPageCount(): Text
    var
        LocMgt: Codeunit "Localisation Management";
        PageCount: Integer;
    begin
        PageCount := ExcelReportBuilderMgr.GetLastPageNo();
        if PageCount = 1 then
            exit('');

        exit(LocMgt.Integer2Text(PageCount - 1, 1, '', '', ''));
    end;
}

