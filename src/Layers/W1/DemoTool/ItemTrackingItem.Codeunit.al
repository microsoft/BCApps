codeunit 118652 "Item Tracking - Item"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(X80102T, 96, 54, '10000', '80102', 20, 19, 15.7, 0.1, '9403 90 90', XSNALL, XSN1, '', "Costing Method"::FIFO);
        InsertData(X80103T, 196, 103, '10000', '80103', 10, 27, 22.3, 0.2, '9403 90 90', XSNALL, '', '', "Costing Method"::Specific);
        InsertData(X80208T, 25, 17, '10000', '80208', 160, 0.2, 0.015, 0.001, '9403 90 90', XSNSALES, XSN2, '', "Costing Method"::FIFO);
        InsertData(X80216T, 7, 4, '10000', '80216', 200, 0.1, 0.007, 0.0002, '9403 90 90', XLOTALL, '', XLOT, "Costing Method"::FIFO);
        InsertData(X80218T, 196, 160, '10000', '80218', 50, 1.2, 0.87, 0.0017, '9403 90 90', XLOTSNSALES, '', XLOT, "Costing Method"::FIFO);
    end;

    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        DemoDataSetup: Record "Demo Data Setup";
        Counter1: Integer;
        X80102T: Label '80102-T';
        XSNALL: Label 'SNALL';
        XSN1: Label 'SN1';
        X80103T: Label '80103-T';
        X80208T: Label '80208-T';
        XSNSALES: Label 'SNSALES';
        XSN2: Label 'SN2';
        X80216T: Label '80216-T';
        XLOTALL: Label 'LOTALL';
        X80218T: Label '80218-T';
        XLOTSNSALES: Label 'LOTSNSALES';
        XLOT: Label 'LOT';
        XPCS: Label 'PCS';
        XFURNITURE: Label 'FURNITURE';

    procedure InsertData("No.": Code[20]; "Unit Price": Decimal; "Last Direct Cost": Decimal; "Vendor No.": Code[20]; "Vendor Item No.": Text[20]; "Reorder Point": Decimal; "Gross Weight": Decimal; "Net Weight": Decimal; "Unit Volume": Decimal; "Tariff No.": Code[10]; "Item Tracking Code": Code[10]; "Serial Nos.": Code[10]; "Lot Nos.": Code[10]; "Costing Method": Enum "Costing Method")
    begin
        Item.Init();
        Item.Validate("No.", "No.");
        Item.Validate("Vendor No.", "Vendor No.");
        Item.Validate("Vendor Item No.", "Vendor Item No.");
        Item.Validate("Reorder Point", "Reorder Point");
        Item.Validate("Gross Weight", "Gross Weight");
        Item.Validate("Net Weight", "Net Weight");
        Item.Validate("Unit Volume", "Unit Volume");
        Item.Validate("Tariff No.", "Tariff No.");

        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure."Item No." := Item."No.";
        ItemUnitOfMeasure.Code := XPCS;
        if ItemUnitOfMeasure.Insert() then;

        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item."Inventory Posting Group" := DemoDataSetup.ResaleCode();
        Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RetailCode());
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            Item.Validate("Tax Group Code", XFURNITURE);
        Item.Validate("Item Tracking Code", "Item Tracking Code");
        Item.Validate("Serial Nos.", "Serial Nos.");
        Item.Validate("Lot Nos.", "Lot Nos.");
        Item."Costing Method" := "Costing Method";

        Counter1 := Counter1 + 1;
        Item.Validate("Shelf No.", StrSubstNo('B%1-T', Counter1));
        Item."Item Disc. Group" := DemoDataSetup.ResaleCode();
        Item."Last Direct Cost" :=
          Round("Last Direct Cost" * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor");
        if Item."Costing Method" = "Costing Method"::Standard then
            Item."Standard Cost" := Item."Last Direct Cost";
        Item."Unit Cost" := Item."Last Direct Cost";
        Item.Validate(
          "Unit Price",
          Round("Unit Price" * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"));
        if Item.Insert() then;
    end;
}

