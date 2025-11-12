codeunit 118858 "Create Item Identifier"
{

    trigger OnRun()
    begin
        InsertData('0000152926732', 'FF-100', '', XPCS);
        InsertData('00007421570561', 'HS-100', '', XPCS);
        InsertData('00009357749333', 'LSU-15', '', XPCS);
        InsertData('00004569472006', 'LSU-4', '', XPCS);
        InsertData('00008897837787', 'LSU-8', '', XPCS);
        InsertData('00007778179835', 'LS-MAN-10', '', XPCS);
        InsertData('00001617431031', 'LS-S15', '', XPCS);
        InsertData('00006903425359', 'LS-10PC', '', XBOX);
        InsertData('0000653721406', 'LS-10PC', '', XPCS);
        InsertData('00002311193879', 'LS-100', '', XPCS);
        InsertData('0000348352589', 'LS-120', '', XPALLET);
        InsertData('00003284048305', 'LS-120', '', XPCS);
        InsertData('00004751676143', 'LS-150', '', XPALLET);
        InsertData('00008324666300', 'LS-150', '', XPCS);
        InsertData('00008660998235', 'LS-2', '', XBOX);
        InsertData('00001776940531', 'LS-2', '', XPCS);
        InsertData('00003446229157', 'LS-75', '', XPALLET);
        InsertData('00007529819404', 'LS-75', '', XPCS);
        InsertData('00006405461731', 'SPK-100', '', XPCS);
    end;

    var
        ItemIdentifier: Record "Item Identifier";
        XPCS: Label 'PCS';
        XBOX: Label 'BOX';
        XPALLET: Label 'PALLET';

    procedure InsertData("Code": Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOM: Code[10])
    begin
        ItemIdentifier.Init();
        ItemIdentifier.Validate(Code, Code);
        ItemIdentifier.Validate("Item No.", ItemNo);
        ItemIdentifier.Validate("Variant Code", VariantCode);
        ItemIdentifier.Validate("Unit of Measure Code", UOM);
        ItemIdentifier.Insert(true);
    end;
}

