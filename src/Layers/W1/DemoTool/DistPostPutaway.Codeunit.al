codeunit 118828 "Dist. Post Put-away"
{

    trigger OnRun()
    begin
        ModifyData(1, XPU000001, 10000, 5, false);
        ModifyData(1, XPU000001, 20000, 0, true);
        ModifyData(1, XPU000001, 30000, 100, false);
        PostData(1, XPU000001);
    end;

    var
        WhseActLine: Record "Warehouse Activity Line";
        XPU000001: Label 'PU000001';

    procedure ModifyData(WhseActType: Option; WhseActNo: Code[20]; WhseActLineNo: Integer; QtyToHandle: Decimal; Autofill: Boolean)
    begin
        WhseActLine.Reset();
        WhseActLine.Get(WhseActType, WhseActNo, WhseActLineNo);
        if Autofill then begin
            WhseActLine.SetRecFilter();
            WhseActLine.AutofillQtyToHandle(WhseActLine)
        end else
            WhseActLine.Validate("Qty. to Handle", QtyToHandle);
        WhseActLine.Modify();
    end;

    procedure PostData(WhseActType: Option; WhseActNo: Code[20])
    var
        WhsePutawayPost: Codeunit "Whse.-Activity-Register";
    begin
        WhseActLine.Reset();
        WhseActLine.SetRange("Activity Type", WhseActType);
        WhseActLine.SetRange("No.", WhseActNo);
        WhsePutawayPost.Run(WhseActLine);
    end;
}

