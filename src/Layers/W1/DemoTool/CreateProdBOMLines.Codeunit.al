codeunit 119024 "Create Prod. BOM Lines"
{

    trigger OnRun()
    begin
        InsertData('1000', '', 1, '1100', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1200', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1300', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1400', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1450', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1500', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1600', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1700', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1800', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1850', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1000', '', 1, '1900', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1100', '', 1, '1110', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1100', '', 1, '1120', 0, 0, 0, 0, 0, 50, '', '', '', 0, 0D, 0D);
        InsertData('1100', '', 1, '1150', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1100', '', 1, '1160', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1100', '', 1, '1170', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1150', '', 1, '1151', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1150', '', 1, '1155', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1200', '', 1, '1110', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1200', '', 1, '1120', 0, 0, 0, 0, 0, 50, '', '', '', 0, 0D, 0D);
        InsertData('1200', '', 1, '1250', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1200', '', 1, '1160', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1200', '', 1, '1170', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1250', '', 1, '1251', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1250', '', 1, '1255', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1300', '', 1, '1310', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1300', '', 1, '1320', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1300', '', 1, '1330', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1700', '', 1, '1710', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
        InsertData('1700', '', 1, '1720', 0, 0, 0, 0, 0, 1, '', '', '', 0, 0D, 0D);
    end;

    var
        ProdBOMComponent: Record "Production BOM Line";
        PreviousBOMNo: Code[20];

    procedure InsertData(ProdBOMNo: Code[20]; VersionCode: Code[10]; Type: Option " ",Item,"Production BOM"; No: Code[20]; Length: Decimal; Width: Decimal; Weight: Decimal; Depth: Decimal; CalcFormula: Option; QuantityPer: Decimal; Position: Code[10]; LeadTimeOffset: Code[20]; RoutingLinkCode: Code[10]; ScrapPct: Decimal; StartingDate: Date; EndingDate: Date)
    begin
        ProdBOMComponent.Validate("Production BOM No.", ProdBOMNo);
        ProdBOMComponent.Validate("Version Code", VersionCode);

        case PreviousBOMNo of
            ProdBOMNo:
                begin
                    ProdBOMComponent."Line No." := ProdBOMComponent."Line No." + 10000;
                    ProdBOMComponent.Validate("Line No.", ProdBOMComponent."Line No.");
                end;
            else begin
                    ProdBOMComponent."Line No." := 10000;
                    PreviousBOMNo := ProdBOMNo;
                    ProdBOMComponent.Validate("Line No.", ProdBOMComponent."Line No.");
                end;
        end;

        ProdBOMComponent.Validate(Type, Type);
        ProdBOMComponent.Validate("No.", No);
        ProdBOMComponent.Validate(Length, Length);
        ProdBOMComponent.Validate(Width, Width);
        ProdBOMComponent.Validate(Weight, Weight);
        ProdBOMComponent.Validate(Depth, Depth);
        ProdBOMComponent.Validate("Quantity per", QuantityPer);
        ProdBOMComponent.Validate("Calculation Formula", CalcFormula);
        ProdBOMComponent.Validate(Position, Position);
        Evaluate(ProdBOMComponent."Lead-Time Offset", LeadTimeOffset);
        ProdBOMComponent.Validate("Lead-Time Offset");
        ProdBOMComponent.Validate("Routing Link Code", RoutingLinkCode);
        ProdBOMComponent.Validate("Scrap %", ScrapPct);
        ProdBOMComponent.Validate("Starting Date", StartingDate);
        ProdBOMComponent.Validate("Ending Date", EndingDate);
        ProdBOMComponent.Insert();
    end;
}

