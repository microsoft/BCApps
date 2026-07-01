codeunit 118817 "Dist. Create/Register Pick"
{

    trigger OnRun()
    begin
        if WhseShptHeader2.Get(XSH000003) then begin
            CreatePick(WhseShptHeader2);
            PostWhseActivity(WhseShptHeader2);
        end;
        if WhseShptHeader2.Get(XSH000004) then begin
            CreatePick(WhseShptHeader2);
            PostWhseActivity(WhseShptHeader2);
        end;
    end;

    var
        WhseShptHeader2: Record "Warehouse Shipment Header";
        WhseShptLine2: Record "Warehouse Shipment Line";
        XSH000003: Label 'SH000003';
        XSH000004: Label 'SH000004';

    procedure CreatePick(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseShptRelease: Codeunit "Whse.-Shipment Release";
    begin
        WhseShptRelease.Release(WhseShptHeader);
        WhseShptLine2.SetRange("No.", WhseShptHeader."No.");
        if WhseShptLine2.FindFirst() then begin
            WhseShptLine2.SetHideValidationDialog(true);
            WhseShptLine2.CreatePickDoc(WhseShptLine2, WhseShptHeader);
        end;
    end;

    procedure PostWhseActivity(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseActivLine2: Record "Warehouse Activity Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivityPost: Codeunit "Whse.-Activity-Register";
    begin
        Clear(WhseShptLine2);
        Clear(WhseActivityPost);
        WhseShptLine2.SetRange("No.", WhseShptHeader."No.");
        if WhseShptLine2.FindFirst() then begin
            WhseActivLine2.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
            WhseActivLine2.SetRange("Whse. Document No.", WhseShptLine2."No.");
            WhseActivLine2.SetRange("Whse. Document Type", WhseActivLine2."Whse. Document Type"::Shipment);
            WhseActivLine2.SetRange("Activity Type", WhseActivLine2."Activity Type"::Pick);
            WhseActivLine2.FindFirst();
            WhseActivLine.Copy(WhseActivLine2);
            if WhseActivLine.Find() then
                WhseActivityPost.Run(WhseActivLine);
        end;
    end;
}

