codeunit 117182 "Create Serv. Price Group Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XMONITOR, '', '', '', 0D, XMONITOR, false, ServPriceGroupSetup."Adjustment Type"::Maximum, 150, false);
        InsertData(XSERVER, '', '', '', 0D, XOSP, false, ServPriceGroupSetup."Adjustment Type"::Fixed, 200, false);
        InsertData(XSERVER, '', '', '', 19020101D, XOSP, false, ServPriceGroupSetup."Adjustment Type"::Fixed, 210, false);
    end;

    var
        ServPriceGroupSetup: Record "Serv. Price Group Setup";
        DemoDataSetup: Record "Demo Data Setup";
        XMONITOR: Label 'MONITOR';
        XSERVER: Label 'SERVER';
        XOSP: Label 'OSP';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("Service Price Group Code": Text[250]; "Fault Area Code": Text[250]; "Cust. Price Group Code": Text[250]; "Currency Code": Text[250]; "Starting Date": Date; "Serv. Price Adjmt. Gr. Code": Text[250]; "Include Discounts": Boolean; "Adjustment Type": Option; Amount: Decimal; "Include VAT": Boolean)
    var
        ServPriceGroupSetup: Record "Serv. Price Group Setup";
    begin
        ServPriceGroupSetup.Init();
        ServPriceGroupSetup.Validate("Service Price Group Code", "Service Price Group Code");
        ServPriceGroupSetup.Validate("Fault Area Code", "Fault Area Code");
        ServPriceGroupSetup.Validate("Cust. Price Group Code", "Cust. Price Group Code");
        ServPriceGroupSetup.Validate("Currency Code", "Currency Code");
        ServPriceGroupSetup.Validate("Starting Date", MakeAdjustments.AdjustDate("Starting Date"));
        ServPriceGroupSetup.Validate("Serv. Price Adjmt. Gr. Code", "Serv. Price Adjmt. Gr. Code");
        ServPriceGroupSetup.Validate("Include Discounts", "Include Discounts");
        ServPriceGroupSetup.Validate("Adjustment Type", "Adjustment Type");

        ServPriceGroupSetup.Amount :=
          Round(
            Amount * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor");
        ServPriceGroupSetup.Validate(Amount);

        ServPriceGroupSetup.Validate("Include VAT", "Include VAT");
        ServPriceGroupSetup.Insert(true);
    end;
}

