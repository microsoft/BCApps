codeunit 101027 "Create Item"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('70000', 263, 134, '10000', '10-102', 250, 2.65, 2.3, 0.04, '9403 90 30', '', '', '');
        InsertData('70001', 345, 176, '10000', '10-103', 250, 3.22, 2.8, 0.06, '9403 90 30', '', '', '');
        InsertData('70002', 246, 125, '10000', '10-104', 250, 2.88, 2.5, 0.04, '9403 90 30', '', '', '');
        InsertData('70003', 253, 129, '10000', '10-105', 250, 7.02, 6.1, 0.7, '9403 90 30', '', '', '');
        InsertData('70010', 446, 227, '10000', '10-106', 250, 3.11, 2.7, 0.04, '9403 90 30', '', '', '');
        InsertData('70011', 619, 316, '10000', '10-107', 250, 7.25, 6.3, 0.04, '9403 90 90', '', '', '');
        InsertData('70040', 926, 472, '10000', '10-108', 250, 10.81, 9.4, 0.45, '9403 90 30', '', '', '');
        InsertData('70041', 200, 102, '10000', '10-109', 250, 2.42, 2.1, 0.4, '9403 90 30', '', '', '');
        InsertData('70060', 112, 57, '32456123', '10-110', 1000, 1.73, 1.5, 0.05, '9403 90 10', '', '', '');
        InsertData('70100', 23, 12, '20000', '20-127', 150, 1.84, 1.6, 0.01, '9999 99 99', XCAN, '', '');
        InsertData('70101', 23, 12, '20000', '20-128', 150, 1.84, 1.6, 0.01, '9999 99 99', XCAN, '', '');
        InsertData('70102', 23, 12, '20000', '20-129', 150, 1.84, 1.6, 0.01, '9999 99 99', XCAN, '', '');
        InsertData('70103', 23, 12, '20000', '20-130', 150, 1.84, 1.6, 0.01, '9999 99 99', XCAN, '', '');
        InsertData('70104', 23, 12, '20000', '20-131', 150, 1.84, 1.6, 0.01, '9999 99 99', XCAN, '', '');
        InsertData('70200', 11, 6, '10000', '10-111', 1200, 0.35, 0.3, 0.01, '9403 90 10', '', '', '');
        InsertData('70201', 10, 5, '10000', '10-112', 1200, 0.23, 0.2, 0.01, '9403 90 30', '', '', '');
        InsertData('80100', 49, 26, '46558855', '', 0, 0, 0, 0, '9999 99 99', XBOX, XPACK, XPALLET);
        InsertData('1896-S', 5560, 4337, '30000', '30-111', 25, 39.79, 34.6, 1.2, '9403 30 11', '', '', '');
        InsertData('1900-S', 1071, 835, '20000', '20-121', 50, 9.55, 8.3, 0.25, '9401 71 00', '', '', '');
        InsertData('1906-S', 2409, 1879, '30000', '30-112', 25, 19.67, 17.1, 0.26, '9403 30 91', '', '', '');
        InsertData('1908-S', 1056, 823, '30000', '30-113', 50, 15.99, 13.9, 0.25, '9401 30 10', '', '', '');
        InsertData('1920-S', 3599, 2808, '20000', '20-122', 15, 28.06, 24.4, 0.9, '9403 30 19', '', '', '');
        InsertData('1924-W', 1168, 699, '', '', 150, 15.77, 13.7, 0.84, '9403 30 19', '', '', '');
        InsertData('1928-S', 305, 238, '10000', '10-101', 45, 4.03, 3.5, 0.03, '9405 20 99', '', '', '');
        InsertData('1928-W', 2929, 1644, '', '', 50, 26.58, 23.1, 1.29, '9403 30 19', '', '', '');
        InsertData('1936-S', 1071, 835, '20000', '20-123', 50, 9.55, 8.3, 0.25, '9401 71 00', '', '', '');
        InsertData('1952-W', 1357, 801, '', '', 50, 18.19, 15.8, 1.24, '9403 30 19', '', '', '');
        InsertData('1960-S', 1071, 835, '20000', '20-124', 50, 9.55, 8.3, 0.25, '9401 71 00', '', '', '');
        InsertData('1964-S', 1071, 835, '20000', '20-125', 50, 9.55, 8.3, 0.25, '9401 71 00', '', '', '');
        InsertData('1964-W', 2500, 1466, '', '', 50, 26.02, 22.6, 1.3, '9403 30 91', '', '', '');
        InsertData('1968-S', 1056, 823, '30000', '30-114', 50, 15.99, 13.9, 0.25, '9401 30 10', '', '', '');
        InsertData('1968-W', 8346, 6067, '', '', 50, 82.11, 0, 0, '9403 30 19', '', '', '');
        InsertData('1972-S', 1056, 823, '30000', '30-115', 50, 15.99, 13.9, 0.25, '9401 30 10', '', '', '');
        InsertData('1972-W', 8346, 6067, '', '', 50, 82.11, 71.4, 0.32, '9403 30 19', '', '', '');
        InsertData('1976-W', 2193, 1289, '', '', 50, 21.88, 19, 1.3, '9403 30 91', '', '', '');
        InsertData('1980-S', 1056, 823, '30000', '30-116', 50, 15.99, 13.9, 0.25, '9401 30 10', '', '', '');
        InsertData('1984-W', 8346, 6067, '', '', 50, 82.11, 71.4, 0.32, '9403 30 19', '', '', '');
        InsertData('1988-S', 1071, 835, '20000', '20-126', 50, 9.55, 8.3, 0.25, '9401 71 00', '', '', '');
        InsertData('1988-W', 8346, 6067, '', '', 50, 82.11, 71.4, 0.32, '9403 30 19', '', '', '');
        InsertData('1992-W', 8346, 6067, '', '', 50, 82.11, 71.4, 0.32, '9403 30 19', '', '', '');
        InsertData('1996-S', 7763, 6055, '30000', '30-117', 100, 80.27, 69.8, 0.31, '9403 30 19', '', '', '');
        InsertData('2000-S', 1056, 823, '30000', '30-118', 50, 15.99, 13.9, 0.25, '9401 30 10', '', '', '');
        InsertData('1925-W', 1049, 0, '', '', 50, 0.0, 0.0, 0.0, '', '', '', '');
        InsertData('1929-W', 1299, 0, '', '', 50, 0.0, 0.0, 0.0, '', '', '', '');
        InsertData('1953-W', 699, 0, '', '', 50, 0.0, 0.0, 0.0, '', '', '', '');
        InsertData('1965-W', 1299, 0, '', '', 50, 0.0, 0.0, 0.0, '', '', '', '');
        InsertData('1969-W', 1899, 0, '', '', 50, 0.0, 0.0, 0.0, '', '', '', '');
        InsertData('766BC-A', 46350.76923, 30128, '', '', 10, 119.72, 104.1, 1.47, '9403 30 19', '', '', '');
        InsertData('766BC-B', 15305.00086, 10666, '', '', 10, 155.96, 135.6, 6.67, '9403 30 19', '', '', '');
        InsertData('766BC-C', 8087.69231, 5257, '', '', 10, 94.31, 82, 5.18, '9403 30 19', '', '', '');
        InsertItemAttributesAndValues();
        InsertLocalData();
        InsertItemCategoriesWithAttributes();
        AssignCategoriesToItems();
        // Remember to add Item Description in codeunit 101030 Create Item Translation.
    end;

    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        DemoDataSetup: Record "Demo Data Setup";
        ItemCategory: Record "Item Category";
        Counter1: Integer;
        Counter2: Integer;
        Counter3: Integer;
        Counter4: Integer;
        XCAN: Label 'CAN';
        XBOX: Label 'BOX';
        XPACK: Label 'PACK';
        XPALLET: Label 'PALLET';
        XPCS: Label 'PCS';
        XSET: Label 'SET';
        XFURNITURE: Label 'FURNITURE';
        XMATERIALS: Label 'MATERIALS';
        XA: Label 'A';
        XB: Label 'B';
        XSUPPLIES: Label 'SUPPLIES';
        XCM: Label 'CM';
        XYes: Label 'Yes';
        XNo: Label 'No';
        xColor: Label 'Color';
        XDepth: Label 'Depth';
        XWidth: Label 'Width';
        XHeight: Label 'Height';
        XMaterialDescription: Label 'Material Description';
        XMaterialSurface: Label 'Material (Surface)';
        XMaterialLegs: Label 'Material (Legs)';
        XAdjustableHeight: Label 'Adjustable height';
        XAssemblyRequired: Label 'Assembly required';
        XCableManagement: Label 'Cable management';
        XCertifications: Label 'Certifications';
        XModelYear: Label 'Model Year';
        XRed: Label 'Red';
        XOrange: Label 'Orange';
        XYellow: Label 'Yellow';
        XGreen: Label 'Green';
        XBlue: Label 'Blue';
        XViolet: Label 'Violet';
        XPurple: Label 'Purple';
        XBlack: Label 'Black';
        XWhite: Label 'White';
        XDescription1: Label 'Wood';
        XDescription2: Label 'Leather, Satin Polished Aluminum base';
        XDescription3: Label 'Plastic, Cotton';
        XDescription4: Label 'Cotton, Wood Legs';
        XDescription5: Label 'Steel';
        XDescription6: Label 'Cotton, Aluminium';
        XDescription7: Label 'Plastic, Steel';
        XDescription8: Label 'Cotton, Plastic, Steel';
        XDescription9: Label 'Cotton, Steel legs';
        XDescription10: Label 'Mountable cable trunk included';
        XDescription11: Label 'FSC';
        XMaterial1: Label 'Solid oak';
        XMaterial2: Label 'Polished stainless steel';
        IncorrectInsertNonOptionUsageErr: Label 'Error inserting an option attribute value, correct sequence is creation then mapping.';
        XOfficefurniture: Label 'Office Furniture';
        XMiscellaneous: Label 'Miscellaneous';
        XCHAIR: Label 'CHAIR';
        XOfficeChair: Label 'Office Chair';
        XDesklc: Label 'Desk';
        XOfficeDesk: Label 'Office Desk';
        XTablelc: Label 'Table';
        XAssortedTables: Label 'Assorted Tables';
        XSuppliers: Label 'Suppliers';
        XOfficeSupplies: Label 'Office Supplies';

    procedure InsertData("No.": Code[20]; "Unit Price": Decimal; "Last Direct Cost": Decimal; "Vendor No.": Code[20]; "Vendor Item No.": Text[20]; "Reorder Point": Decimal; "Gross Weight": Decimal; "Net Weight": Decimal; "Unit Volume": Decimal; "Tariff No.": Code[10]; "Base Unit of Measure": Code[10]; "Sales Unit of Measure": Code[10]; "Purch. Unit of Measure": Code[10])
    var
        ItemImagePath: Text;
    begin
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Evaluation then begin
            if (StrPos("No.", 'S') = 0) and not ("No." in ['1925-W', '1929-W', '1953-W', '1965-W', '1969-W']) then
                exit;
            "Tariff No." := '';
        end;

        Item.Init();
        Item.Validate("No.", "No.");
        Item.Validate("Vendor No.", "Vendor No.");
        Item.Validate("Vendor Item No.", "Vendor Item No.");
        Item.Validate("Reorder Point", "Reorder Point");
        Item.Validate("Gross Weight", "Gross Weight");
        Item.Validate("Net Weight", "Net Weight");
        Item.Validate("Unit Volume", "Unit Volume");
        Item.Validate("Tariff No.", "Tariff No.");
        if "Base Unit of Measure" = '' then
            "Base Unit of Measure" := XPCS;

        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure."Item No." := Item."No.";
        ItemUnitOfMeasure.Code := "Base Unit of Measure";
        if ItemUnitOfMeasure.Code = XPCS then
            ItemUnitOfMeasure."Qty. Rounding Precision" := 1;
        ItemUnitOfMeasure.Insert();

        Item.Validate("Base Unit of Measure", "Base Unit of Measure");

        if "Sales Unit of Measure" <> '' then
            Item."Sales Unit of Measure" := "Sales Unit of Measure";
        if "Purch. Unit of Measure" <> '' then
            Item."Purch. Unit of Measure" := "Purch. Unit of Measure";

        case true of
            Item."No." in ['1900-S', '1968-S', '1972-S', '1960-S', '1988-S']:
                begin
                    ItemUnitOfMeasure.Init();
                    ItemUnitOfMeasure."Item No." := Item."No.";
                    ItemUnitOfMeasure.Code := XSET;
                    ItemUnitOfMeasure."Qty. per Unit of Measure" := 4;
                    ItemUnitOfMeasure.Insert();
                end;
            Item."No." in ['1908-S', '1936-S', '1980-S', '1964-S', '2000-S']:
                begin
                    ItemUnitOfMeasure.Init();
                    ItemUnitOfMeasure."Item No." := Item."No.";
                    ItemUnitOfMeasure.Code := XSET;
                    ItemUnitOfMeasure."Qty. per Unit of Measure" := 6;
                    ItemUnitOfMeasure.Insert();
                end;
        end;

        case true of
            Item."No." in ['1925-W', '1929-W', '1953-W', '1965-W', '1969-W']:
                begin
                    Item."Inventory Posting Group" := DemoDataSetup.ResaleCode();
                    Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RetailCode());
                    Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
                end;
            StrPos(Item."No.", 'W') > 0:
                begin
                    Item."Inventory Posting Group" := DemoDataSetup.FinishedCode();
                    Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RetailCode());
                    Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
                end;
            (StrPos(Item."No.", 'S') > 0) or (Item."No." = '80100'):
                begin
                    Item."Inventory Posting Group" := DemoDataSetup.ResaleCode();
                    Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RetailCode());
                end;
            Item."No." in ['766BC-A', '766BC-B', '766BC-C']:
                begin
                    Item."Inventory Posting Group" := DemoDataSetup.FinishedCode();
                    Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RetailCode());
                    Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
                end;
            else begin
                Item."Inventory Posting Group" := DemoDataSetup.RawMatCode();
                Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RawMatCode());
            end;
        end;

        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::"Sales Tax" then
            Item.Validate("Tax Group Code", GetTaxGroupCode());

        case Item."Inventory Posting Group" of
            DemoDataSetup.RawMatCode():
                if Item."Base Unit of Measure" = XCAN then begin
                    Counter1 := Counter1 + 1;
                    Item.Validate("Shelf No.", StrSubstNo('B%1', Counter1));
                end else begin
                    Counter4 := Counter4 + 1;
                    Item.Validate("Shelf No.", StrSubstNo('A%1', Counter4));
                end;
            DemoDataSetup.ResaleCode():
                begin
                    Counter2 := Counter2 + 1;
                    Item.Validate("Shelf No.", StrSubstNo('D%1', Counter2));
                end;
            DemoDataSetup.FinishedCode():
                begin
                    Counter3 := Counter3 + 1;
                    Item.Validate("Shelf No.", StrSubstNo('F%1', Counter3));
                end;
        end;

        case Item."Inventory Posting Group" of
            DemoDataSetup.RawMatCode():
                Item."Item Disc. Group" := DemoDataSetup.RawMatCode();
            DemoDataSetup.ResaleCode():
                Item."Item Disc. Group" := DemoDataSetup.ResaleCode();
            DemoDataSetup.FinishedCode():
                Item."Item Disc. Group" := DemoDataSetup.FinishedCode();
            else
                Item."Item Disc. Group" := '';
        end;

        if Item."No." in ['766BC-A', '766BC-B', '766BC-C'] then
            Item."Item Disc. Group" := XA;

        if Item."No." in ['70100', '70101', '70102', '70103', '70104'] then
            Item."Item Disc. Group" := XB;

        if Item."No." in
           ['1924-W', '1928-W', '1952-W', '1964-W',
            '1968-W', '1972-W', '1976-W', '1984-W',
            '1988-W', '1992-W', '766BC-A', '766BC-B', '766BC-C']
        then
            Item."Costing Method" := "Costing Method"::Standard;

        if Item."No." in ['80100'] then
            Item."Costing Method" := "Costing Method"::Average;

        if Item."No." = '1924-W' then begin
            Item.Validate("Vendor No.", '20000');
            Evaluate(Item."Lead Time Calculation", '<2W>');
            Item.Validate("Lead Time Calculation");
        end;

        if Item."No." = '80100' then
            Item."Net Weight" := 12180;

        Item."Last Direct Cost" :=
          Round(
            "Last Direct Cost" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor");
        if Item."Costing Method" = "Costing Method"::Standard then
            Item."Standard Cost" := Item."Last Direct Cost";
        Item."Unit Cost" := Item."Last Direct Cost";

        Item.Validate(
          "Unit Price",
          Round(
            "Unit Price" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor"));

        case Item."No." of // After price calculation since the profit is not know at this time.
            '766BC-A', '766BC-B', '766BC-C':
                Item."Price/Profit Calculation" := Item."Price/Profit Calculation"::"Price=Cost+Profit";
        end;

        ItemImagePath := DemoDataSetup."Path to Picture Folder" + StrSubstNo('Images\Item\%1.jpg', Item."No.");
        if Exists(ItemImagePath) then
            Item.Picture.ImportFile(ItemImagePath, Item."No.");
        Item.Insert();
    end;

    local procedure InsertItemAttributesAndValues()
    var
        DummyItemAttribute: Record "Item Attribute";
        ColorAttributeID: Integer;
        AssemblyRequiredAttributeID: Integer;
        NoAssemblyRequiredID: Integer;
        BlackColorID: Integer;
        WhiteColorID: Integer;
        RedColorID: Integer;
        BlueColorID: Integer;
        YellowColorID: Integer;
        GreenColorID: Integer;
    begin
        ColorAttributeID := CreateItemAttribute(xColor, DummyItemAttribute.Type::Option, '');
        RedColorID := CreateOptionItemAttributeValue(ColorAttributeID, XRed);
        CreateOptionItemAttributeValue(ColorAttributeID, XOrange);
        YellowColorID := CreateOptionItemAttributeValue(ColorAttributeID, XYellow);
        GreenColorID := CreateOptionItemAttributeValue(ColorAttributeID, XGreen);
        BlueColorID := CreateOptionItemAttributeValue(ColorAttributeID, XBlue);
        CreateOptionItemAttributeValue(ColorAttributeID, XViolet);
        CreateOptionItemAttributeValue(ColorAttributeID, XPurple);
        BlackColorID := CreateOptionItemAttributeValue(ColorAttributeID, XBlack);
        WhiteColorID := CreateOptionItemAttributeValue(ColorAttributeID, XWhite);

        CreateItemAttribute(XDepth, DummyItemAttribute.Type::Decimal, XCM);
        CreateItemAttribute(XWidth, DummyItemAttribute.Type::Decimal, XCM);
        CreateItemAttribute(XHeight, DummyItemAttribute.Type::Decimal, XCM);
        CreateItemAttribute(XMaterialDescription, DummyItemAttribute.Type::Text, '');
        CreateItemAttribute(XModelYear, DummyItemAttribute.Type::Integer, '');

        // Additional item attributes
        CreateItemAttribute(XMaterialSurface, DummyItemAttribute.Type::Text, '');
        CreateItemAttribute(XMaterialLegs, DummyItemAttribute.Type::Text, '');
        CreateItemAttribute(XAdjustableHeight, DummyItemAttribute.Type::Text, '');
        AssemblyRequiredAttributeID := CreateItemAttribute(XAssemblyRequired, DummyItemAttribute.Type::Option, '');
        CreateOptionItemAttributeValue(AssemblyRequiredAttributeID, XYes);
        NoAssemblyRequiredID := CreateOptionItemAttributeValue(AssemblyRequiredAttributeID, XNo);
        CreateItemAttribute(XCableManagement, DummyItemAttribute.Type::Text, '');
        CreateItemAttribute(XCertifications, DummyItemAttribute.Type::Text, '');

        InsertItemAttributeValues('1896-S', BlackColorID, '100', '200', '95', XDescription1, '');
        InsertItemAttributeValues('1900-S', BlackColorID, '70', '75', '100', XDescription2, '1952');
        InsertItemAttributeValues('1906-S', BlackColorID, '75', '', '90', XDescription1, '1942');
        InsertItemAttributeValues('1908-S', BlueColorID, '80', '80', '140', XDescription3, '');
        InsertItemAttributeValues('1920-S', WhiteColorID, '300', '150', '130', XDescription4, '');
        InsertItemAttributeValues('1928-S', RedColorID, '30', '', '60', XDescription5, '');
        InsertItemAttributeValues('1936-S', YellowColorID, '100', '120', '115', XDescription4, '1940');
        InsertItemAttributeValues('1960-S', GreenColorID, '40', '120', '110', XDescription6, '1980');
        InsertItemAttributeValues('1964-S', BlueColorID, '80', '90', '125', XDescription4, '');
        InsertItemAttributeValues('1968-S', BlackColorID, '75', '95', '135', XDescription5, '');
        InsertItemAttributeValues('1972-S', YellowColorID, '70', '90', '110', XDescription7, '');
        InsertItemAttributeValues('1980-S', RedColorID, '85', '90', '140', XDescription8, '');
        InsertItemAttributeValues('1988-S', RedColorID, '70', '90', '120', XDescription9, '');
        InsertItemAttributeValues('1996-S', WhiteColorID, '', '200', '250', XDescription7, '');
        InsertItemAttributeValues('2000-S', GreenColorID, '80', '90', '110', XDescription9, '');

        // Insert additional item attributes for '1896-S'
        InsertItemAttributeValueMapping(DATABASE::Item, '1896-S', AssemblyRequiredAttributeID, NoAssemblyRequiredID);
        InsertNonOptionItemAttributeValue(DATABASE::Item, '1896-S', GetItemAttributeIDByName(XMaterialSurface), DummyItemAttribute.Type::Text, XMaterial1);
        InsertNonOptionItemAttributeValue(DATABASE::Item, '1896-S', GetItemAttributeIDByName(XMaterialLegs), DummyItemAttribute.Type::Text, XMaterial2);
        InsertNonOptionItemAttributeValue(DATABASE::Item, '1896-S', GetItemAttributeIDByName(XAdjustableHeight), DummyItemAttribute.Type::Text, XNo);
        InsertNonOptionItemAttributeValue(DATABASE::Item, '1896-S', GetItemAttributeIDByName(XCableManagement), DummyItemAttribute.Type::Text, XDescription10);
        InsertNonOptionItemAttributeValue(DATABASE::Item, '1896-S', GetItemAttributeIDByName(XCertifications), DummyItemAttribute.Type::Text, XDescription11);
    end;

    local procedure CreateItemAttribute(Name: Text[250]; Type: Option; UoM: Text[30]): Integer
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.Init();
        ItemAttribute.Name := Name;
        ItemAttribute.Type := Type;
        ItemAttribute."Unit of Measure" := UoM;
        ItemAttribute.Insert();
        exit(ItemAttribute.ID);
    end;

    local procedure InsertItemAttributeValues(ItemNo: Code[20]; ColorAttributeValueID: Integer; DepthAttributeValue: Text[250]; WidthAttributeValue: Text[250]; HeightAttributeValue: Text[250]; MaterialDescriptionAttributeValue: Text[250]; ModelYearAttributeValue: Text[250])
    var
        DummyItemAttribute: Record "Item Attribute";
    begin
        if ColorAttributeValueID > 0 then
            InsertItemAttributeValueMapping(DATABASE::Item, ItemNo, GetItemAttributeIDByName(xColor), ColorAttributeValueID);
        if StrLen(DepthAttributeValue) > 0 then
            InsertNonOptionItemAttributeValue(
              DATABASE::Item, ItemNo, GetItemAttributeIDByName(XDepth), DummyItemAttribute.Type::Decimal, DepthAttributeValue);
        if StrLen(WidthAttributeValue) > 0 then
            InsertNonOptionItemAttributeValue(
              DATABASE::Item, ItemNo, GetItemAttributeIDByName(XWidth), DummyItemAttribute.Type::Decimal, WidthAttributeValue);
        if StrLen(HeightAttributeValue) > 0 then
            InsertNonOptionItemAttributeValue(
              DATABASE::Item, ItemNo, GetItemAttributeIDByName(XHeight), DummyItemAttribute.Type::Decimal, HeightAttributeValue);
        if StrLen(MaterialDescriptionAttributeValue) > 0 then
            InsertNonOptionItemAttributeValue(
              DATABASE::Item, ItemNo, GetItemAttributeIDByName(XMaterialDescription), DummyItemAttribute.Type::Text,
              MaterialDescriptionAttributeValue);
        if StrLen(ModelYearAttributeValue) > 0 then
            InsertNonOptionItemAttributeValue(
              DATABASE::Item, ItemNo, GetItemAttributeIDByName(XModelYear), DummyItemAttribute.Type::Integer, ModelYearAttributeValue);
    end;

    local procedure CreateOptionItemAttributeValue("Attribute ID": Integer; Value: Text[250]): Integer
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.Init();
        ItemAttributeValue."Attribute ID" := "Attribute ID";
        ItemAttributeValue.Validate(Value, Value);
        ItemAttributeValue.Insert();
        exit(ItemAttributeValue.ID);
    end;

    local procedure InsertNonOptionItemAttributeValue(TableID: Integer; KeyCode: Code[20]; AttributeID: Integer; AttributeType: Option; TextValue: Text[250])
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ExistingItemAttributeValue: Record "Item Attribute Value";
        DummyItemAttribute: Record "Item Attribute";
        DecimalVal: Decimal;
    begin
        case AttributeType of
            DummyItemAttribute.Type::Option:
                Error(IncorrectInsertNonOptionUsageErr);
            DummyItemAttribute.Type::Decimal:
                if TextValue <> '' then begin
                    Evaluate(DecimalVal, TextValue);
                    TextValue := Format(DecimalVal, 0, 9);
                end;
        end;

        ExistingItemAttributeValue.SetRange("Attribute ID", AttributeID);
        ExistingItemAttributeValue.SetRange(Value, TextValue);
        if not ExistingItemAttributeValue.FindFirst() then begin
            ItemAttributeValue.Init();
            ItemAttributeValue.Validate("Attribute ID", AttributeID);
            ItemAttributeValue.Validate(Value, TextValue);
            ItemAttributeValue.Insert();
            ExistingItemAttributeValue.ID := ItemAttributeValue.ID;
        end;

        InsertItemAttributeValueMapping(TableID, KeyCode, AttributeID, ExistingItemAttributeValue.ID);
    end;

    local procedure InsertItemAttributeValueMapping(TableID: Integer; KeyCode: Code[20]; AttributeID: Integer; AttributeValueID: Integer)
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.Init();
        ItemAttributeValueMapping."Table ID" := TableID;
        ItemAttributeValueMapping."No." := KeyCode;
        ItemAttributeValueMapping."Item Attribute ID" := AttributeID;
        ItemAttributeValueMapping."Item Attribute Value ID" := AttributeValueID;
        ItemAttributeValueMapping.Insert();
    end;

    local procedure InsertItemCategoriesWithAttributes()
    var
        DummyItemAttribute: Record "Item Attribute";
        EmptyColorAttributeValueID: Integer;
    begin
        ItemCategory.DeleteAll();
        InsertItemCategoryData(
          XFURNITURE, XOfficefurniture, '');
        InsertItemCategoryData(
          DemoDataSetup.MiscCode(), XMiscellaneous, '');

        InsertItemCategoryData(XCHAIR, XOfficeChair, XFURNITURE);
        InsertItemCategoryData(XDesklc, XOfficeDesk, XFURNITURE);
        InsertItemCategoryData(XTablelc, XAssortedTables, XFURNITURE);
        InsertItemCategoryData(XSuppliers, XOfficeSupplies, DemoDataSetup.MiscCode());

        EmptyColorAttributeValueID := CreateOptionItemAttributeValue(GetItemAttributeIDByName(xColor), '');
        InsertItemAttributeValueMapping(
          DATABASE::"Item Category", XFURNITURE, GetItemAttributeIDByName(xColor), EmptyColorAttributeValueID);
        InsertNonOptionItemAttributeValue(
          DATABASE::"Item Category", XFURNITURE, GetItemAttributeIDByName(XDepth), DummyItemAttribute.Type::Decimal, '');
        InsertNonOptionItemAttributeValue(
          DATABASE::"Item Category", XFURNITURE, GetItemAttributeIDByName(XHeight), DummyItemAttribute.Type::Decimal, '');

        InsertNonOptionItemAttributeValue(
          DATABASE::"Item Category", XCHAIR, GetItemAttributeIDByName(XWidth), DummyItemAttribute.Type::Decimal, '');

        InsertNonOptionItemAttributeValue(
          DATABASE::"Item Category", XTablelc, GetItemAttributeIDByName(XMaterialDescription), DummyItemAttribute.Type::Text, '');
    end;

    procedure InsertItemCategoryData(ChildCategoryCode: Code[20]; ChildCategoryDescription: Text[30]; ParentCategoryCode: Code[20])
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.Init();
        ItemCategory.Validate(Code, ChildCategoryCode);
        ItemCategory.Validate("Parent Category", ParentCategoryCode);
        ItemCategory.Validate(Description, ChildCategoryDescription);
        ItemCategory.Insert(true);
    end;

    local procedure AssignCategoriesToItems()
    begin
        AddCategoryToItem('1896-S', XDesklc);
        AddCategoryToItem('1900-S', XCHAIR);
        AddCategoryToItem('1906-S', XTablelc);
        AddCategoryToItem('1908-S', XCHAIR);
        AddCategoryToItem('1920-S', XTablelc);
        AddCategoryToItem('1928-S', DemoDataSetup.MiscCode());
        AddCategoryToItem('1936-S', XCHAIR);
        AddCategoryToItem('1960-S', XCHAIR);
        AddCategoryToItem('1964-S', XCHAIR);
        AddCategoryToItem('1968-S', XCHAIR);
        AddCategoryToItem('1972-S', XCHAIR);
        AddCategoryToItem('1980-S', XCHAIR);
        AddCategoryToItem('1988-S', XCHAIR);
        AddCategoryToItem('1996-S', DemoDataSetup.MiscCode());
        AddCategoryToItem('2000-S', XCHAIR);
    end;

    local procedure AddCategoryToItem(ItemNo: Code[20]; CategoryCode: Code[20])
    begin
        Item.Get(ItemNo);
        Item.Validate("Item Category Code", CategoryCode);
        Item.Modify(true);
    end;

    local procedure InsertLocalData()
    begin
    end;

    local procedure GetTaxGroupCode(): Code[10]
    begin
        case true of
            StrPos(Item."No.", 'W') > 0,
          StrPos(Item."No.", 'S') > 0,
          StrPos(Item."No.", 'A') > 0,
          StrPos(Item."No.", 'B') > 0,
          StrPos(Item."No.", 'C') > 0:
                exit(XFURNITURE);
            Item."No." in ['70100' .. '70104', '80100']:
                exit(XSUPPLIES);
            Item."No." in ['70000' .. '70060', '70200', '70201']:
                exit(XMATERIALS);
        end;
    end;

    local procedure GetItemAttributeIDByName(AttributeName: Text): Integer
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ItemAttribute.SetRange(Name, AttributeName);
        ItemAttribute.FindFirst();
        exit(ItemAttribute.ID);
    end;

    procedure GetItemCategoryCode(ItemCategoryCode: Text): Code[20]
    begin
        case UpperCase(ItemCategoryCode) of
            'XCHAIR':
                exit(XCHAIR);
            'XDESKLC':
                exit(XDesklc);
            'XTTABLEC':
                exit(XTablelc);
            'XSUPPLIERS':
                exit(XSuppliers);
            'XFURNITURE':
                exit(XFURNITURE);
            else
                Error('Unknown Item Category Code %1.', ItemCategoryCode);
        end;
    end;
}
