codeunit 118840 "Create Put-away Templates"
{

    trigger OnRun()
    begin
        InsertPutAwayHeader(XSTD, XStandardTemplate);
        InsertPutAwayHeader(XVAR, XVariableTemplate);

        InsertPutAwayLine(XSTD, 10000, true, false, true, true, true, false);
        InsertPutAwayLine(XSTD, 20000, true, false, true, true, false, false);
        InsertPutAwayLine(XSTD, 30000, false, true, true, true, false, false);
        InsertPutAwayLine(XSTD, 40000, false, true, true, false, false, false);
        InsertPutAwayLine(XSTD, 50000, false, true, false, false, false, true);
        InsertPutAwayLine(XSTD, 60000, false, true, false, false, false, false);

        InsertPutAwayLine(XVAR, 10000, false, true, true, true, false, false);
        InsertPutAwayLine(XVAR, 20000, false, true, false, false, false, true);
        InsertPutAwayLine(XVAR, 30000, false, true, false, false, false, false);
    end;

    var
        XSTD: Label 'STD';
        XVAR: Label 'VAR';
        XStandardTemplate: Label 'Standard Template';
        XVariableTemplate: Label 'Variable Template';

    local procedure InsertPutAwayHeader("Code": Code[10]; Description: Text[30])
    var
        PutAwayTemplHeader: Record "Put-away Template Header";
    begin
        PutAwayTemplHeader.Code := Code;
        PutAwayTemplHeader.Description := Description;
        PutAwayTemplHeader.Insert();
    end;

    local procedure InsertPutAwayLine("Code": Code[10]; LineNo: Integer; FindDedicatedBin: Boolean; FindFloatingBin: Boolean; FindSameBin: Boolean; FindUOMMatch: Boolean; FindBinLessThanMinQty: Boolean; FindEmptyBin: Boolean)
    var
        PutAwayTemplLine: Record "Put-away Template Line";
    begin
        PutAwayTemplLine."Put-away Template Code" := Code;
        PutAwayTemplLine."Line No." := LineNo;
        PutAwayTemplLine."Find Fixed Bin" := FindDedicatedBin;
        PutAwayTemplLine."Find Floating Bin" := FindFloatingBin;
        PutAwayTemplLine."Find Same Item" := FindSameBin;
        PutAwayTemplLine."Find Unit of Measure Match" := FindUOMMatch;
        PutAwayTemplLine."Find Bin w. Less than Min. Qty" := FindBinLessThanMinQty;
        PutAwayTemplLine."Find Empty Bin" := FindEmptyBin;
        PutAwayTemplLine.Insert();
    end;
}

