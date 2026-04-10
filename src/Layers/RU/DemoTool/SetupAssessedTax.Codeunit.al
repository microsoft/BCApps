codeunit 163418 "Setup Assessed Tax"
{

    trigger OnRun()
    begin
        ModifyFALocation(XADM, '45263000000');
        ModifyFALocation(XSALES, '45263000000');
        ModifyFALocation(XPROD, '45263000000');
        ModifyFALocation(XRECEPTION, '45263000000');
        ModifyFALocation(XBUILD2, '45263000000');

        DemoSetup.Get();
        if not DemoSetup."Skip creation of master data" then
            ModifyOKATOCode('45263000000', '00010', '77');
    end;

    var
        FALocation: Record "FA Location";
        XRECEPTION: Label 'RECEPTION';
        XADM: Label 'ADM';
        XSALES: Label 'SALES';
        XPROD: Label 'PROD';
        FixedAsset: Record "Fixed Asset";
        OKATO: Record OKATO;
        DemoSetup: Record "Demo Data Setup";
        XBUILD2: Label 'BUILD_2';

    procedure ModifyFALocation(FALocationCode: Code[10]; OKATOCode: Code[11])
    begin
        FALocation.Get(FALocationCode);
        FALocation."OKATO Code" := OKATOCode;
        FALocation.Modify();
    end;

    procedure ModifyOKATOCode(OKATOCode: Code[11]; "Tax Authority No.": Code[20]; "Region Code": Code[2])
    begin
        OKATO.Get(OKATOCode);
        OKATO."Tax Authority No." := "Tax Authority No.";
        OKATO."Region Code" := "Region Code";
        OKATO.Modify();
    end;

    procedure ModifyFixedAsset(FANo: Code[20]; "Assessed Tax Code": Code[20]; "FA Type for Taxation": Option " ",Movable,Immovable,Untaxable; "Distributed Asset": Boolean; "UGSS Asset": Boolean; "Book Value per Share": Decimal)
    begin
        FixedAsset.Get(FANo);
        FixedAsset.Validate("FA Location Code");
        FixedAsset.Validate("Assessed Tax Code", "Assessed Tax Code");
        FixedAsset."FA Type for Taxation" := "FA Type for Taxation";
        FixedAsset."Distributed Asset" := "Distributed Asset";
        FixedAsset."UGSS Asset" := "UGSS Asset";
        FixedAsset."Book Value per Share" := "Book Value per Share";
        FixedAsset.Modify();
    end;
}

