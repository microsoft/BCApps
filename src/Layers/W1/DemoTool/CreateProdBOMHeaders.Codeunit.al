codeunit 119023 "Create Prod. BOM Headers"
{

    trigger OnRun()
    begin
        InsertData('1100', '', XFrontWheel, XPCS, 19020101D);
        InsertData('1150', '', XHub, XPCS, 19020101D);
        InsertData('1200', '', XBackWheel, XPCS, 19020101D);
        InsertData('1250', '', XHub, XPCS, 19020101D);
        InsertData('1300', '', XChainassy, XPCS, 19020101D);
        InsertData('1000', '', XBicycle, XPCS, 19020101D);
        InsertData('1700', '', XBrake, XPCS, 19020101D);
    end;

    var
        CA: Codeunit "Make Adjustments";
        XFrontWheel: Label 'Front Wheel';
        XPCS: Label 'PCS';
        XHub: Label 'Hub';
        XBackWheel: Label 'Back Wheel';
        XChainassy: Label 'Chain assy';
        XBicycle: Label 'Bicycle';
        XBrake: Label 'Brake';

    procedure InsertData(ProdBOMNo: Code[20]; ProdVersion: Code[10]; Description: Text[30]; UnitOfMeasureCode: Text[10]; StartingDate: Date)
    var
        ProdBOM: Record "Production BOM Header";
        ProdBOMVersion: Record "Production BOM Version";
    begin
        if not ProdBOM.Get(ProdBOMNo) then begin
            ProdBOM.Validate("No.", ProdBOMNo);
            ProdBOM.Validate(Description, Description);
            ProdBOM."Unit of Measure Code" := UnitOfMeasureCode;
            ProdBOM.Insert();
        end;
        if ProdVersion <> '' then begin
            ProdBOMVersion.Validate("Production BOM No.", ProdBOMNo);
            ProdBOMVersion.Validate("Version Code", ProdVersion);
            ProdBOMVersion.Insert();
            ProdBOMVersion.Validate("Unit of Measure Code", UnitOfMeasureCode);
            ProdBOMVersion.Validate(Description, Description);
            ProdBOMVersion.Validate("Starting Date", CA.AdjustDate(StartingDate));
            ProdBOMVersion.Modify();
        end;
    end;
}

