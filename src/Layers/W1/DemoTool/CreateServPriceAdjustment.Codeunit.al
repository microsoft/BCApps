codeunit 117184 "Create Serv. Price Adjustment"
{

    trigger OnRun()
    begin
        InsertData(XOSP, ServPriceAdjustmentDetail.Type::Item, '80205', '', '', X10MBitEthernet);
        InsertData(XOSP, ServPriceAdjustmentDetail.Type::Item, '80209', '', '', X2048xIDECDROM);
        InsertData(XOSP, ServPriceAdjustmentDetail.Type::Item, '80216', '', '', XEthernetCable);
        InsertData(XOSP, ServPriceAdjustmentDetail.Type::Item, '80218', '', '', XHardDiskDrive);
    end;

    var
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
        XOSP: Label 'OSP';
        X10MBitEthernet: Label '10MBit Ethernet';
        X2048xIDECDROM: Label '20/48x IDE CD ROM';
        XEthernetCable: Label 'Ethernet Cable';
        XHardDiskDrive: Label 'Hard Disk Drive';

    procedure InsertData("Serv. Price Adjmt. Gr. Code": Text[250]; Type: Option; "No.": Text[250]; "Work Type": Text[250]; "Gen. Prod. Posting Group": Text[250]; Description: Text[250])
    var
        ServPriceAdjustmentDetail: Record "Serv. Price Adjustment Detail";
    begin
        ServPriceAdjustmentDetail.Init();
        ServPriceAdjustmentDetail.Validate("Serv. Price Adjmt. Gr. Code", "Serv. Price Adjmt. Gr. Code");
        ServPriceAdjustmentDetail.Validate(Type, Type);
        ServPriceAdjustmentDetail.Validate("No.", "No.");
        if "Work Type" <> '' then
            ServPriceAdjustmentDetail.Validate("Work Type", "Work Type");
        ServPriceAdjustmentDetail.Validate("Gen. Prod. Posting Group", "Gen. Prod. Posting Group");
        ServPriceAdjustmentDetail.Validate(Description, Description);
        ServPriceAdjustmentDetail.Insert(true);
    end;
}

