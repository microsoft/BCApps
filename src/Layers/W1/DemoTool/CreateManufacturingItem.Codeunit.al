codeunit 119040 "Create Manufacturing Item"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('1110', XRim, 0, 0, '01587796', '266666', 200, 0, 0, 0, '');
        InsertData('1120', XSpokes, 0, 0, '01587796', '45455', 5000, 0, 0, 0, '');
        InsertData('1151', XAxleFrontWheel, 0, 0, '32456123', '11111', 100, 0, 0, 0, '');
        InsertData('1155', XSocketFront, 0, 0, '32456123', 'A-12122', 100, 0, 0, 0, '');
        InsertData('1160', XTire, 0, 0, '01587796', 'ADG-4577', 100, 0, 0, 0, '');
        InsertData('1170', XTube, 0, 0, '01587796', 'GG-78827', 100, 0, 0, 0, '');
        InsertData('1251', XAxleBackWheel, 0, 0, '01587796', '4577-4555', 100, 0, 0, 0, '');
        InsertData('1255', XSocketBack, 0, 0, '01587796', 'WW4577', 100, 0, 0, 0, '');
        InsertData('1310', XChain, 0, 0, '32456123', 'HH-45888', 100, 0, 0, 0, '');
        InsertData('1320', XChainWheelFront, 0, 0, '32456123', 'PP-45656', 100, 0, 0, 0, '');
        InsertData('1330', XChainWheelBack, 0, 0, '32456123', 'PP-7397', 100, 0, 0, 0, '');
        InsertData('1400', XMudguardfront, 0, 0, '32456123', '45888', 100, 0, 0, 0, '');
        InsertData('1450', XMudguardback, 0, 0, '32456123', '45889', 100, 0, 0, 0, '');
        InsertData('1500', XLamp, 0, 0, '45774477', 'A-4577', 100, 0, 0, 0, '');
        InsertData('1600', XBell, 0, 0, '32456123', '2777775', 100, 0, 0, 0, '');
        InsertData('1710', XHandrearwheelBrake, 0, 0, '32456123', '88-45888', 100, 0, 0, 0, '');
        InsertData('1720', XHandfrontwheelBrake, 0, 0, '01587796', '4577-AA', 100, 0, 0, 0, '');
        InsertData('1800', XHandlebars, 0, 0, '01587796', '4577-BB', 100, 0, 0, 0, '');
        InsertData('1850', XSaddle, 0, 0, '01587796', 'T5555-FF', 100, 0, 0, 0, '');
        InsertData('1900', XFrame, 0, 0, '01587796', 'FR 48888', 100, 0, 0, 0, '');

        InsertData('1000', XBicycle, 4000, 0, '', '', 0, 0, 0, 0, '');
        InsertData('1001', XTouringBicycle, 4000, 0, '', '', 0, 0, 0, 0, '');
        InsertData('1100', XFrontWheel, 1000, 0, '', '', 100, 0, 0, 0, '');
        InsertData('1150', XFrontHub, 500, 0, '', '', 100, 0, 0, 0, '');
        InsertData('1300', XChainAssy, 800, 0, '', '', 100, 0, 0, 0, '');
        InsertData('1200', XBackWheel, 1200, 0, '', '', 100, 0, 0, 0, '');
        InsertData('1250', XBackHub, 1100, 0, '', '', 100, 0, 0, 0, '');
        InsertData('1700', XBrake, 600, 0, '', '', 100, 0, 0, 0, '');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        Item: Record Item;
        Counter1: Integer;
        Counter2: Integer;
        Counter3: Integer;
        Counter4: Integer;
        XRim: Label 'Rim';
        XSpokes: Label 'Spokes';
        XAxleFrontWheel: Label 'Axle Front Wheel';
        XSocketFront: Label 'Socket Front';
        XTire: Label 'Tire';
        XTube: Label 'Tube';
        XAxleBackWheel: Label 'Axle Back Wheel';
        XSocketBack: Label 'Socket Back';
        XChain: Label 'Chain';
        XChainWheelFront: Label 'Chain Wheel Front';
        XChainWheelBack: Label 'Chain Wheel Back';
        XMudguardfront: Label 'Mudguard front';
        XMudguardback: Label 'Mudguard back';
        XLamp: Label 'Lamp';
        XBell: Label 'Bell';
        XHandrearwheelBrake: Label 'Hand rear wheel Brake';
        XHandfrontwheelBrake: Label 'Hand front wheel Brake';
        XHandlebars: Label 'Handlebars';
        XSaddle: Label 'Saddle';
        XFrame: Label 'Frame';
        XBicycle: Label 'Bicycle';
        XTouringBicycle: Label 'Touring Bicycle';
        XFrontWheel: Label 'Front Wheel';
        XFrontHub: Label 'Front Hub';
        XChainAssy: Label 'Chain Assy';
        XBackWheel: Label 'Back Wheel';
        XBackHub: Label 'Back Hub';
        XBrake: Label 'Brake';
        XPCS: Label 'PCS';
        XCAN: Label 'CAN';
        XA: Label 'A';

    local procedure InsertData("No.": Code[20]; Description: Text[30]; "Unit Price": Decimal; "Last Direct Cost": Decimal; "Vendor No.": Code[20]; "Vendor Item No.": Text[20]; "Minimum Qty. on Hand": Decimal; "Gross Weight": Decimal; "Net Weight": Decimal; "Unit Volume": Decimal; "Tariff No.": Code[10])
    begin
        Item.Init();
        Item.Validate("No.", "No.");
        Item.Validate(Description, Description);
        Item.Validate("Vendor No.", "Vendor No.");
        Item.Validate("Vendor Item No.", "Vendor Item No.");
        Item.Validate("Reorder Point", "Minimum Qty. on Hand");
        Item.Validate("Gross Weight", "Gross Weight");
        Item.Validate("Net Weight", "Net Weight");
        Item.Validate("Unit Volume", "Unit Volume");
        Item.Validate("Tariff No.", "Tariff No.");
        Item."Base Unit of Measure" := XPCS;
        Item."Sales Unit of Measure" := XPCS;
        Item."Purch. Unit of Measure" := XPCS;

        case true of
            StrPos(Item."No.", '10') > 0:
                begin
                    Item."Inventory Posting Group" := DemoDataSetup.FinishedCode();
                    Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RetailCode());
                end;
            Item."No." in ['1100', '1200', '1300', '1150', '1250', '1700']:
                begin
                    Item."Inventory Posting Group" := DemoDataSetup.FinishedCode();
                    Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RetailCode());
                end;
            else begin
                Item."Inventory Posting Group" := DemoDataSetup.RawMatCode();
                Item.Validate("Gen. Prod. Posting Group", DemoDataSetup.RawMatCode());
            end;
        end;

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

        Item."Item Disc. Group" := Item."Inventory Posting Group";
        if Item."No." = '1000' then
            Item."Item Disc. Group" := XA;

        Item."Costing Method" := "Costing Method"::Standard;

        case Item."No." of
            '1100':
                begin
                    Item.Validate("Vendor No.", '20000');
                    Evaluate(Item."Lead Time Calculation", '<2W>');
                    Item.Validate("Lead Time Calculation");
                end;
        end;

        Item."Last Direct Cost" := "Last Direct Cost";
        if Item."Costing Method" = "Costing Method"::Average then
            Item."Standard Cost" := Item."Last Direct Cost";
        Item."Unit Cost" := Item."Last Direct Cost";

        Item.Validate("Unit Price", "Unit Price");

        Item.Insert();
    end;
}

