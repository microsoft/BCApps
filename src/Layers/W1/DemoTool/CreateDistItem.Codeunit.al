codeunit 118838 "Create Dist. Item"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            TaxCode := DemoDataSetup.GoodsVATCode();

        InsertData('LS-75', XLoudspeakerCherry75W, 79.0, 36.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
        InsertData('LS-120', XLoudspeakerBlack120W, 88.0, 45.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
        InsertData('LS-150', XLoudspeakerCherry150W, 129.0, 72.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
        InsertData('LS-10PC', XLoudspeakersWhiteforPC, 59.0, 25.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
        InsertData('LS-Man-10', XManualforLoudspeakers, 0.0, 12.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
        InsertData('LS-2', XCablesforLoudspeakers, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
        InsertData('LS-S15', XStandforLoudspeakersLS150, 79.0, 45.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
        InsertData('LS-100', XLoudspeaker100WOakwoodDeluxe, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 1, 1, true, 0);
        InsertData('LSU-15', XBasespeakerunit15100W, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 1, true, 0);
        InsertData('LSU-8', XMiddletonespeakerunit8100W, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 1, true, 0);
        InsertData('LSU-4', XTweeterspeakerunit4100W, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 1, true, 0);
        InsertData('FF-100', XFrequencyfilterforLS100, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 1, true, 0);
        InsertData('C-100', XCablingforLS100, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 1, true, 0);
        InsertData('HS-100', XHousingLS100Oakwood120lts, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 1, true, 0);
        InsertData('SPK-100', XSpikeforLS100, 21.0, 15.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 1, true, 0);
        InsertData('LS-81', XLoudspeakerWalnut80W, 79.0, 36.0, 0, DemoDataSetup.RetailCode(), TaxCode, DemoDataSetup.ResaleCode(), 0, 0, false, 0);
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XLoudspeakerCherry75W: Label 'Loudspeaker, Cherry, 75W';
        XLoudspeakerBlack120W: Label 'Loudspeaker, Black, 120W';
        XLoudspeakerCherry150W: Label 'Loudspeaker, Cherry, 150W';
        XLoudspeakersWhiteforPC: Label 'Loudspeakers, White for PC';
        XManualforLoudspeakers: Label 'Manual for Loudspeakers';
        XCablesforLoudspeakers: Label 'Cables for Loudspeakers';
        XStandforLoudspeakersLS150: Label 'Stand for Loudspeakers LS-150';
        XLoudspeaker100WOakwoodDeluxe: Label 'Loudspeaker 100W OakwoodDeluxe';
        XBasespeakerunit15100W: Label 'Base speaker unit 15" 100W';
        XMiddletonespeakerunit8100W: Label 'Middletone speaker unit 8"100W';
        XTweeterspeakerunit4100W: Label 'Tweeter speaker unit 4" 100W';
        XFrequencyfilterforLS100: Label 'Frequency filter for LS-100';
        XCablingforLS100: Label 'Cabling for LS-100';
        XHousingLS100Oakwood120lts: Label 'Housing LS-100,Oakwood 120 lts';
        XSpikeforLS100: Label 'Spike for LS-100';
        XLoudspeakerWalnut80W: Label 'Loudspeaker, Walnut, 80W';
        TaxCode: Code[10];

    procedure InsertData(ItemNo: Code[20]; Desc: Text[30]; UnitPrice: Decimal; UnitCost: Decimal; CostingMethod: Integer; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; InventoryPostingGroup: Code[20]; ReplenishmentSystem: Option; ReorderingPolicy: Option " ","Fixed Reorder Qty","Maximum Qty.","Order","Lot-for-Lot"; IncludeInventory: Boolean; ManufacturingPolicy: Option "Make-to-Stock","Make-to-Order")
    var
        Item: Record Item;
    begin
        Item.Validate("No.", ItemNo);
        Item.Validate(Description, Desc);
        Item.Validate("Unit Price", UnitPrice);
        Item.Validate("Unit Cost", UnitCost);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Include Inventory", IncludeInventory);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Insert();
    end;

    procedure ModifyData(ItemNo: Code[20]; BaseUOM: Code[10]; PurchUOM: Code[10]; SalesUOM: Code[10]; PutawayUOM: Code[10])
    var
        Item: Record Item;
    begin
        if Item.Get(ItemNo) then begin
            Item.Validate("Base Unit of Measure", BaseUOM);
            Item.Validate("Purch. Unit of Measure", PurchUOM);
            Item.Validate("Sales Unit of Measure", SalesUOM);
            Item.Validate("Put-away Unit of Measure Code", PutawayUOM);
            Item.Modify();
        end;
    end;
}

