codeunit 101094 "Create Item Posting Group"
{

    trigger OnRun()
    begin
        InsertData('07-1000', XEquipForInstallation);
        InsertData('10-0100', XRawMaterials);
        InsertData('10-0200', XHalfFinishedProducts);
        InsertData('10-0300', XFuel);
        InsertData('10-0400', XPackagingMaterials);
        InsertData('10-0500', XSpareParts);
        InsertData('10-0600', XOtherMaterials);
        InsertData('10-0800', XBuildingMaterials);
        InsertData('10-0900', XInventoryAndAccessories);
        InsertData('10-1000', XWorkingClothers);
        InsertData('10-3000', XAssetsLessThen20000);
        InsertData('41-1000', XGoodsOnStock);
        InsertData('41-2000', XGoodsInRetail);
        InsertData('41-3000', XTareAndEmptyTare);
        InsertData('41-4000', XPurchasedGoods);
        InsertData('43-1000', XFinishedProduct);
        InsertData('99-0020', XInventUnderSafekeeping);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        InventoryPostingGroup: Record "Inventory Posting Group";
        XResaleItemsTxt: Label 'Resale items';
        XRawMaterials: Label 'Raw materials';
        XSpareParts: Label 'Spare parts';
        XFuel: Label 'Fuel';
        XOtherMaterials: Label 'Other Materials';
        XBuildingMaterials: Label 'Building Materials';
        XPackagingMaterials: Label 'Package and Packaging Materials';
        XEXCLTACOST: Label 'EXCLTACOST';
        XINCLTACOST: Label 'INCLTACOST';
        XEquipForInstallation: Label 'Equipment for installation';
        XHalfFinishedProducts: Label 'Half-finished products, BOMs';
        XInventoryAndAccessories: Label 'Inventory and household accessories';
        XWorkingClothers: Label 'Working clothes';
        XAssetsLessThen20000: Label 'Assets <2000 rub';
        XGoodsOnStock: Label 'Goods on stock';
        XGoodsInRetail: Label 'Goods in retail sale';
        XTareAndEmptyTare: Label 'Tare and empty tare';
        XPurchasedGoods: Label 'Purchased Goods';
        XFinishedProduct: Label 'Finished product';
        XInventUnderSafekeeping: Label 'Inventories under safekeeping';

    procedure InsertData("Code": Code[20]; PostingGroupDescription: Text[50])
    begin
        InventoryPostingGroup.Init();
        InventoryPostingGroup.Validate(Code, Code);
        InventoryPostingGroup.Validate(Description, PostingGroupDescription);
        InventoryPostingGroup.Validate("Purch. PD Charge FCY (Item)", XEXCLTACOST);
        InventoryPostingGroup.Validate("Purch. PD Charge Conv. (Item)", XINCLTACOST);
        InventoryPostingGroup.Validate("Sales PD Charge FCY (Item)", XEXCLTACOST);
        InventoryPostingGroup.Validate("Sales PD Charge Conv. (Item)", XINCLTACOST);
        InventoryPostingGroup.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData(DemoDataSetup.ResaleCode(), XResaleItemsTxt);
    end;
}

