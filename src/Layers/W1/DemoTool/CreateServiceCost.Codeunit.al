codeunit 117006 "Create Service Cost"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XSTART, XStartspaceFee, '6810', 20, 1, XPCS, ServiceCost."Cost Type"::Other, '', 2);
        InsertData(XTR_EAST, XTravelspaceFee, '6810', 2, 1, XPCS, ServiceCost."Cost Type"::Travel, XE, 0.2);
        InsertData(XTR_MID, XTravelspaceFee, '6810', 1, 1, XPCS, ServiceCost."Cost Type"::Travel, XM, 0.1);
        InsertData(XTR_NORTH, XTravelspaceFee, '6810', 3, 1, XPCS, ServiceCost."Cost Type"::Travel, XN, 0.3);
        InsertData(XTR_SE, XTravelspaceFee, '6810', 4, 1, XPCS, ServiceCost."Cost Type"::Travel, XSE, 0.4);
        InsertData(XTR_SOUTH, XTravelspaceFee, '6810', 5, 1, XPCS, ServiceCost."Cost Type"::Travel, XS, 0.5);
        InsertData(XTR_WEST, XTravelspaceFee, '6810', 6, 1, XPCS, ServiceCost."Cost Type"::Travel, XW, 0.6);
    end;

    var
        ServiceCost: Record "Service Cost";
        DemoDataSetup: Record "Demo Data Setup";
        XSTART: Label 'START';
        XTR_EAST: Label 'TR_EAST';
        XTR_MID: Label 'TR_MID';
        XTR_NORTH: Label 'TR_NORTH';
        XTR_SE: Label 'TR_SE';
        XTR_SOUTH: Label 'TR_SOUTH';
        XTR_WEST: Label 'TR_WEST';
        XStartspaceFee: Label 'Start Fee';
        XTravelspaceFee: Label 'Travel Fee';
        XPCS: Label 'PCS';
        XE: Label 'E';
        XM: Label 'M';
        XN: Label 'N';
        XSE: Label 'SE';
        XS: Label 'S';
        XW: Label 'W';

    procedure InsertData("Code": Text[250]; Description: Text[250]; "Account No.": Text[250]; "Default Unit Price": Decimal; "Default Quantity": Decimal; "Unit of Measure Code": Text[250]; "Cost Type": Option; "Service Zone Code": Text[250]; "Default Unit Cost": Decimal)
    var
        ServiceCost: Record "Service Cost";
    begin
        ServiceCost.Init();
        ServiceCost.Validate(Code, Code);
        ServiceCost.Validate(Description, Description);
        ServiceCost.Validate("Account No.", "Account No.");

        ServiceCost."Default Unit Price" :=
          Round(
            "Default Unit Price" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor");
        ServiceCost.Validate("Default Unit Price");

        ServiceCost.Validate("Default Quantity", "Default Quantity");
        ServiceCost.Validate("Unit of Measure Code", "Unit of Measure Code");
        ServiceCost.Validate("Cost Type", "Cost Type");
        ServiceCost.Validate("Service Zone Code", "Service Zone Code");

        ServiceCost."Default Unit Cost" :=
          Round(
            "Default Unit Cost" * DemoDataSetup."Local Currency Factor",
            1 * DemoDataSetup."Local Precision Factor");
        ServiceCost.Validate("Default Unit Cost");

        ServiceCost.Insert(true);
    end;
}

