codeunit 118802 "Create Item Cross Reference"
{

    trigger OnRun()
    begin
        ItemReference.DeleteAll();
        DemoDataSetup.Get();
        InsertData('1908-S', ItemReference."Reference Type"::Vendor, '30000',
          XBlueSwivel, XPCS, XBlueSwivelChair);
        InsertData('1908-S', ItemReference."Reference Type"::Vendor, '10000',
          '1908-S', XPCS, '');
        InsertData('1908-S', ItemReference."Reference Type"::Vendor, '20000',
          '1908-S', XPCS, '');
        InsertData('1908-S', ItemReference."Reference Type"::Customer, '50000',
          XC100425, XPCS, XSwivelChairBlue);
        InsertData('1928-S', ItemReference."Reference Type"::Customer, '30000',
          XSwivelLamp, XPCS, XRedSwivelLamp);
        InsertData('1928-S', ItemReference."Reference Type"::Vendor, '50000',
          XD200552, XPCS, XDeskSwivelLamp);
    end;

    var
        ItemReference: Record "Item Reference";
        XSwivelChairBlue: Label 'Armless swivel chair, blue';
        XBlueSwivelChair: Label 'Blue armless swivel chair';
        XRedSwivelLamp: Label 'Red Swivel Lamp';
        DemoDataSetup: Record "Demo Data Setup";
        XDeskSwivelLamp: Label 'Desk Swivel Lamp';
        XBlueSwivel: Label 'BLUESWIVEL', Locked = true;
        XC100425: Label 'C100425', Locked = true;
        XSwivelLamp: Label 'SWIVELLAMP', Locked = true;
        XD200552: Label 'D200552', Locked = true;
        XPCS: Label 'PCS';

    local procedure InsertData(ItemNo: Code[20]; RefType: Enum "Item Reference Type"; RefTypeNo: Code[20]; RefNo: Code[50]; UnitOfMeasure: Code[10]; Description: Text[50])
    begin
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then
            if StrPos(ItemNo, 'S') = 0 then
                exit;
        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemNo);
        ItemReference.Validate("Reference Type", RefType);
        ItemReference.Validate("Reference Type No.", RefTypeNo);
        ItemReference.Validate("Reference No.", RefNo);
        ItemReference.Validate("Unit of Measure", UnitOfMeasure);
        ItemReference.Validate(Description, Description);
        ItemReference.Insert(true);
    end;
}
