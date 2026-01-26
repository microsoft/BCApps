codeunit 166501 "Create WHT Setup"
{

    trigger OnRun()
    begin
        WHTRevType.DeleteAll();
        InsertWHTRevType(XWHT, XWithholdingTax, 1);

        WHTBusPostGrp.DeleteAll();
        WHTProdPostGrp.DeleteAll();
        WHTPostingSetup.DeleteAll();

        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then
            InsertSetup('', '', 46.5, '5493', '5492', XWHT, '', WHTPostingSetup."WHT Report"::" ", 75)
        else
            InsertSetup('', '', 46.5, GetGLAccNo.WHTTaxPayable(), GetGLAccNo.WHTPrepaid(), XWHT, '', WHTPostingSetup."WHT Report"::" ", 75);

        if not SourceCode.Get(XWHTSTMT) then begin
            SourceCode.Init();
            SourceCode.Code := XWHTSTMT;
            SourceCode.Description := XWithholdingTaxStatement;
            SourceCode.Insert();
        end;

        if not SourceCode.Get('COMPRWHT') then begin
            SourceCode.Init();
            SourceCode.Code := XCOMPRWHT;
            SourceCode.Description := XDateCompressWHTEntries;
            SourceCode.Insert();
        end;

        SourceCodeSetup.Get();
        SourceCodeSetup."WHT Settlement" := XWHTSTMT;
        SourceCodeSetup.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        WHTRevType: Record "WHT Revenue Types";
        WHTBusPostGrp: Record "WHT Business Posting Group";
        WHTProdPostGrp: Record "WHT Product Posting Group";
        WHTPostingSetup: Record "WHT Posting Setup";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        GetGLAccNo: Codeunit "Create G/L Account";
        XWithholdingTax: Label 'Withholding Tax';
        XWHT: Label 'WHT';
        XWHTSTMT: Label 'WHTSTMT';
        XWithholdingTaxStatement: Label 'Withholding Tax Statement';
        XCOMPRWHT: Label 'COMPRWHT';
        XDateCompressWHTEntries: Label 'Date Compress WHT Entries';
        XWWBOPERATING: Label 'WWB-OPERATING';

    procedure InsertWHTRevType("Code": Code[10]; Description: Text[30]; Sequence: Integer)
    begin
        WHTRevType.Init();
        WHTRevType.Code := Code;
        WHTRevType.Description := Description;
        WHTRevType.Sequence := Sequence;
        WHTRevType.Insert();
    end;

    procedure InsertWHTBPG("Code": Code[10]; Description: Text[30])
    begin
        WHTBusPostGrp.Init();
        WHTBusPostGrp.Code := Code;
        WHTBusPostGrp.Description := Description;
        WHTBusPostGrp.Insert();
    end;

    procedure InsertWHTPPG("Code": Code[10]; Description: Text[30])
    begin
        WHTProdPostGrp.Init();
        WHTProdPostGrp.Code := Code;
        WHTProdPostGrp.Description := Description;
        WHTProdPostGrp.Insert();
    end;

    procedure InsertSetup(BPG: Code[10]; PPG: Code[10]; Percent: Decimal; Payable: Code[10]; Prepaid: Code[10]; RevType: Code[10]; WHTRepNoSerial: Code[10]; WHTReport: Option; MinWHTAmt: Decimal)
    begin
        DemoDataSetup.Get();
        WHTPostingSetup.Init();
        WHTPostingSetup."WHT Business Posting Group" := BPG;
        WHTPostingSetup."WHT Product Posting Group" := PPG;
        WHTPostingSetup."WHT %" := Percent;
        WHTPostingSetup."Prepaid WHT Account Code" := Prepaid;
        WHTPostingSetup."Payable WHT Account Code" := Payable;
        WHTPostingSetup."Revenue Type" := RevType;
        if Percent <> 0 then begin
            WHTPostingSetup."Bal. Prepaid Account No." := XWWBOPERATING;
            WHTPostingSetup."Bal. Payable Account No." := XWWBOPERATING;
            if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
                WHTPostingSetup."Sales WHT Adj. Account No." := '8930';
                WHTPostingSetup."Purch. WHT Adj. Account No." := '8920';
            end
            else begin
                WHTPostingSetup."Sales WHT Adj. Account No." := GetGLAccNo.SalesWHTAdjustments();
                WHTPostingSetup."Purch. WHT Adj. Account No." := GetGLAccNo.PurchaseWHTAdjustments();
            end;
        end;
        WHTPostingSetup."WHT Report" := WHTReport;
        WHTPostingSetup."WHT Report Line No. Series" := WHTRepNoSerial;
        WHTPostingSetup."Realized WHT Type" := WHTPostingSetup."Realized WHT Type"::Payment;
        WHTPostingSetup."WHT Minimum Invoice Amount" := MinWHTAmt;
        WHTPostingSetup."WHT Calculation Rule" := WHTPostingSetup."WHT Calculation Rule"::"Less than";
        WHTPostingSetup.Insert();
    end;

    procedure InsertWHTReportNoSeries("Code": Text[250]; Description: Text[250])
    var
        StartDate: Date;
        LineNo: Integer;
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LineNo := 0;
        StartDate := 20060101D;
        NoSeries.Init();
        NoSeries.Code := Code;
        NoSeries.Description := Description;
        NoSeries."Default Nos." := true;
        NoSeries."Manual Nos." := false;
        NoSeries.Insert();

        repeat
            LineNo := LineNo + 10000;
            NoSeriesLine.Init();
            NoSeriesLine."Series Code" := NoSeries.Code;
            NoSeriesLine."Line No." := LineNo;
            NoSeriesLine.Validate("Starting No.", '1');
            NoSeriesLine."Starting Date" := StartDate;
            NoSeriesLine.Insert(true);
            StartDate := CalcDate('1M', StartDate);
        until LineNo >= 120000;
    end;
}

