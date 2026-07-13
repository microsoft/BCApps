codeunit 118011 "Create Transfer Route"
{

    trigger OnRun()
    begin
        TransferRoute.DeleteAll();
        InsertData(XBLUE, XYELLOW, XOUTLOG, XDHL, XSTANDARD);
        InsertData(XBLUE, XRED, XOUTLOG, XFEDEX, XNEXTDAY);
        InsertData(XGREEN, XYELLOW, XOWNLOG, XOWNLOG, XNEXTDAY);
        InsertData(XGREEN, XRED, XOWNLOG, XOWNLOG, XNEXTDAY);
        InsertData(XRED, XBLUE, XOUTLOG, XFEDEX, XNEXTDAY);
        InsertData(XBLUE, XWHITE, XOWNLOG, XDHL, XSTANDARD);
        InsertData(XGREEN, XWHITE, XOWNLOG, XOWNLOG, XNEXTDAY);
        InsertData(XWHITE, XRED, XOWNLOG, XDHL, XSTANDARD);
    end;

    var
        TransferRoute: Record "Transfer Route";
        XBLUE: Label 'BLUE';
        XYELLOW: Label 'YELLOW';
        XOUTLOG: Label 'OUT. LOG.';
        XDHL: Label 'DHL';
        XSTANDARD: Label 'STANDARD';
        XRED: Label 'RED';
        XFEDEX: Label 'FEDEX';
        XNEXTDAY: Label 'NEXT DAY';
        XOWNLOG: Label 'OWN LOG.';
        XGREEN: Label 'GREEN';
        XWHITE: Label 'WHITE';
        XMAIN: Label 'MAIN';
        XEAST: Label 'EAST';
        XWEST: Label 'WEST';

    local procedure InsertData(TransferFromCode: Code[20]; TransferToCode: Code[20]; InTransitCode: Code[20]; ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10])
    begin
        TransferRoute.Init();
        TransferRoute."Transfer-from Code" := TransferFromCode;
        TransferRoute."Transfer-to Code" := TransferToCode;
        TransferRoute."Shipping Agent Code" := ShippingAgentCode;
        TransferRoute."Shipping Agent Service Code" := ShippingAgentServiceCode;
        TransferRoute."In-Transit Code" := InTransitCode;
        TransferRoute.Insert();
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(XWEST, XMAIN, XOWNLOG, '', '');
        InsertData(XMAIN, XEAST, XOWNLOG, '', '');
    end;
}

