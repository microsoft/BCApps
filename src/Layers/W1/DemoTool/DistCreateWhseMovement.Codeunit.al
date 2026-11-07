codeunit 118845 "Dist. Create Whse. Movement"
{

    trigger OnRun()
    var
        CreateMovFromWhseSource: Report "Whse.-Source - Create Document";
    begin
        InsertData(10000, 'LS-120', '', XPCS, XWHITE, XW020001, XW100001, 2);
        InsertData(20000, 'LS-Man-10', '', XPCS, XWHITE, XW050010, XW060001, 40);

        CreateMovFromWhseSource.SetHideValidationDialog(true);
        CreateMovFromWhseSource.UseRequestPage(false);
        CreateMovFromWhseSource.SetWhseWkshLine(WhseWkshLine);
        CreateMovFromWhseSource.RunModal();

        WhseWkshLine.DeleteAll();
    end;

    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        XPCS: Label 'PCS';
        XWHITE: Label 'WHITE';
        XW020001: Label 'W-02-0001';
        XW100001: Label 'W-10-0001';
        XW050010: Label 'W-05-0010';
        XW060001: Label 'W-06-0001';
        XMOVEMENT: Label 'MOVEMENT';

    procedure InsertData(LineNo: Integer; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; FromBinCode: Code[20]; ToBinCode: Code[20]; Quantity: Decimal)
    begin
        WhseWkshLine.Init();
        WhseWkshLine."Worksheet Template Name" := XMOVEMENT;
        WhseWkshLine.Validate("Line No.", LineNo);
        WhseWkshLine.Validate("Item No.", ItemNo);
        WhseWkshLine.Validate("Variant Code", VariantCode);
        WhseWkshLine.Validate("Unit of Measure Code", UOMCode);
        WhseWkshLine.Validate("Location Code", LocationCode);
        WhseWkshLine.Validate("From Bin Code", FromBinCode);
        WhseWkshLine.Validate("To Bin Code", ToBinCode);
        WhseWkshLine.Validate(Quantity, Quantity);
        WhseWkshLine.Validate("Qty. to Handle", Quantity);
        WhseWkshLine.Insert();
    end;
}

