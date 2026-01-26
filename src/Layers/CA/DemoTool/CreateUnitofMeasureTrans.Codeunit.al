codeunit 101700 "Create Unit of Measure Trans."
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        UnitOfMeasureTranslation.DeleteAll();
        InsertData('DEU', XPCS, 'stück');
        InsertData('DAN', XPCS, 'stk');
        InsertData('NLD', XPCS, 'stuk');
        InsertData('DAN', XCAN, 'ds');

        InsertData('ENU', XHOUR, 'HOUR');
        InsertData('ENU', XDAY, 'DAY');
        InsertData('ENU', XPCS, 'Piece');
        InsertData('ENU', XCAN, 'CAN');
        InsertData('ENU', XBOX, 'BOX');
        InsertData('ENU', XPALLET, 'PALLET');
        InsertData('ENU', XPACK, 'PACK');
        InsertData('ENU', XMILES, 'MILES');
        InsertData('ENU', KMTok, 'Kilometer');
        InsertData('ENU', KGTok, 'Kilo');
	    InsertData('ENU', XSET, 'Set');
        InsertData('FRC', XHOUR, 'Heure');
        InsertData('FRC', XDAY, 'Jour');
        InsertData('FRC', XPCS, 'Piáce');
        InsertData('FRC', XCAN, 'Bidon');
        InsertData('FRC', XBOX, 'BoÆte');
        InsertData('FRC', XPACK, 'Paquet');
        InsertData('FRC', XPALLET, 'Palette');
        InsertData('FRC', XMILES, 'Miles');
        InsertData('FRC', KMTok, 'Kilomátre');
    end;

    var
        UnitOfMeasureTranslation: Record "Unit of Measure Translation";
        XPCS: Label 'PCS';
        XCAN: Label 'CAN';
        DemoDataSetup: Record "Demo Data Setup";
        XHOUR: Label 'HOUR';
        XDAY: Label 'DAY';
        XBOX: Label 'BOX';
        XPALLET: Label 'PALLET';
        XPACK: Label 'PACK';
        XMILES: Label 'MILES';
        KMTok: Label 'KM';
        KGTok: Label 'KG';
        XSET: Label 'SET';

    procedure InsertData("Language Code": Code[10]; "Code": Code[10]; Description: Text[10])
    begin
        if "Language Code" <> DemoDataSetup."Language Code" then begin
            UnitOfMeasureTranslation.Code := Code;
            UnitOfMeasureTranslation."Language Code" := "Language Code";
            UnitOfMeasureTranslation.Description := Description;
            UnitOfMeasureTranslation.Insert();
        end;
    end;
}

