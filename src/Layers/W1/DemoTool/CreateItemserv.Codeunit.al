codeunit 117528 "Create Item (serv)"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            TaxCode := DemoDataSetup.GoodsVATCode()
        else
            TaxCode := '';

        InsertData('80001', XComputerIII533MHzlc, XCOMPUTERIII533MHZ, DemoDataSetup.ResaleCode(), 108, 53.7037, 50, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80002', XComputerIII600MHzlc, XCOMPUTERIII600MHZ, DemoDataSetup.ResaleCode(), 128, 53.125, 60, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80003', XComputerIII733MHzlc, XCOMPUTERIII733MHZ, DemoDataSetup.ResaleCode(), 138, 49.27536, 70, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80004', XComputerIII800MHzlc, XCOMPUTERIII800MHZ, DemoDataSetup.ResaleCode(), 148, 45.94595, 80, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80005', XComputerIII866MHzlc, XCOMPUTERIII866MHZ, DemoDataSetup.ResaleCode(), 178, 49.4382, 90, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80006', XTeamWorkComputer533MHzlc, XTEAMWORKCOMPUTER533MHZ, DemoDataSetup.ResaleCode(), 1499, 46.63109, 800, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XSERVER, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80007', XEnterpriseComputer667MHzlc, XENTERPRISECOMPUTER667MHZ, DemoDataSetup.ResaleCode(), 2119, 48.08872, 1100, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XSERVER, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80010', X64MBPC800ECC, X64MBPC800ECC, DemoDataSetup.ResaleCode(), 85, 41.17647, 50, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMEMORY, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80011', X128MBPC800ECC, X128MBPC800ECC, DemoDataSetup.ResaleCode(), 185, 51.35135, 90, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMEMORY, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80012', X256MBPC800ECC, X256MBPC800ECC, DemoDataSetup.ResaleCode(), 245, 51.02041, 120, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMEMORY, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80013', X384MBPC800ECC, X384MBPC800ECC, DemoDataSetup.ResaleCode(), 195, 23.07692, 150, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMEMORY, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80014', X512MBPC800ECC, X512MBPC800ECC, DemoDataSetup.ResaleCode(), 315, 49.20635, 160, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMEMORY, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80021', X102GBATA66IDE, X102GBATA66IDE, DemoDataSetup.ResaleCode(), 115, 47.82609, 60, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80022', X204GBATA66IDE, X204GBATA66IDE, DemoDataSetup.ResaleCode(), 180, 50, 90, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80023', X27GBATA66IDE, X27GBATA66IDE, DemoDataSetup.ResaleCode(), 215, 48.83721, 110, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80024', X40GBATA66IDE, X40GBATA66IDE, DemoDataSetup.ResaleCode(), 305, 49.18033, 155, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80025', X9GBUltra160MSCSI, X9GBUltra160MSCSI, DemoDataSetup.ResaleCode(), 155, 48.3871, 80, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80026', X18GBUltra160MSCSI, X18GBUltra160MSCSI, DemoDataSetup.ResaleCode(), 175, 48.57143, 90, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80027', X36GBUltra160MSCSI, X36GBUltra160MSCSI, DemoDataSetup.ResaleCode(), 299, 49.83278, 150, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80101', X151501FPFlatPanellc, X151501FPFLATPANEL, DemoDataSetup.ResaleCode(), 215, 53.48837, 100, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMONITOR, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80102', X17M780Monitorlc, X17M780MONITOR, DemoDataSetup.ResaleCode(), 295, 49.15254, 150, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMONITOR, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80103', X19M009Monitorlc, X19M009MONITOR, DemoDataSetup.ResaleCode(), 356, 49.4382, 180, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMONITOR, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80104', X21UltraScanP1110lc, X21ULTRASCANP1110, DemoDataSetup.ResaleCode(), 412, 51.45631, 200, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMONITOR, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80105', X24Ultrascanlc, X24ULTRASCAN, DemoDataSetup.ResaleCode(), 469, 50.95949, 230, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMONITOR, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80201', XGRAPHICPROGRAM, XGraphicProgramlc, DemoDataSetup.ResaleCode(), 36, 44.44444, 20, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XGRAPHICS, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80202', XChip32MBlc, XCHIP32MB, DemoDataSetup.ResaleCode(), 45, 46.66667, 24, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XGRAPHICS, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80203', XGraphicCard9400lc, XGRAPHICCARD9400, DemoDataSetup.ResaleCode(), 58, 48.27586, 30, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XGRAPHICS, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80204', XUltra160MSCSIControllerlc, XULTRA160MSCSICONTROLLER, DemoDataSetup.ResaleCode(), 58, 48.27586, 30, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XCONTROLLER, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80205', X10MBitEthernetlc, X10MBITETHERNET, DemoDataSetup.ResaleCode(), 34, 41.17647, 20, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XNETWCARD, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80206', XWebcamlc, XWEBCAM, DemoDataSetup.ResaleCode(), 12, 50, 6, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XMOUSE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80207', XBasicMouselc, XBASICMOUSE, DemoDataSetup.ResaleCode(), 25, 60, 10, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XMOUSE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80208', XAdvamcedMouselc, XADVAMCEDMOUSE, DemoDataSetup.ResaleCode(), 18, 50, 9, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XMOUSE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80209', X2048xIDECDROM, X2048xIDECDROM, DemoDataSetup.ResaleCode(), 150, 33.33333, 100, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XCDROM, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80210', X8x4x32xIDECDReadWritelc, X8X4X32XIDECDREADWRITE, DemoDataSetup.ResaleCode(), 280, 28.57143, 200, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XCDROM, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80211', XQuietkeyKeyboardlc, XQUIETKEYKEYBOARD, DemoDataSetup.ResaleCode(), 50, 50, 25, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XKEYBOARD, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80212', XPerformanceKeyboardlc, XPERFORMANCEKEYBOARD, DemoDataSetup.ResaleCode(), 85, 52.94118, 40, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XKEYBOARD, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80213', XDrive250lc, XDRIVE250, DemoDataSetup.ResaleCode(), 115, 65.21739, 40, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, XZIPDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80214', X250MBDisks2packlc, X250MBDISKS2PACK, DemoDataSetup.ResaleCode(), 22, 54.54545, 10, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, '', '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80215', X250MBDisks4packlc, X250MBDISKS4PACK, DemoDataSetup.ResaleCode(), 39, 48.71795, 20, 19040517D,
          DemoDataSetup.RetailCode(), TaxCode, '', '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80216', XEthernetCablelc, XETHERNETCABLE, DemoDataSetup.ResaleCode(), 3.5, 64.28571, 1.25, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMISCACCESS, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80217', XPowerSupplyCablelc, XPOWERSUPPLYCABLE, DemoDataSetup.ResaleCode(), 4.2, 51.19048, 2.05, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMISCACCESS, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80218', XHardDiskDrivelc, XHARDDISKDRIVE, DemoDataSetup.ResaleCode(), 39, 48.71795, 20, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XHARDDRIVE, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80219', XScrewonHardDriveMountinglc, XSCREWONHARDDRIVEMOUNTING, DemoDataSetup.ResaleCode(), 0.05, 80, 0.01, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMISCACCESS, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData('80220', XScrewonMountCDTapeDrivelc, XSCREWONMOUNTCDTAPEDRIVE, DemoDataSetup.ResaleCode(), 0.05, 80, 0.01, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XMISCACCESS, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Purchase);
        InsertData(X8904W, XComputerBasicPackagelc, XCOMPUTERBASICPACKAGE, DemoDataSetup.ResaleCode(), 558.9, 100, 0, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Assembly);
        InsertData(X8908W, XComputerHighlinePackagelc, XCOMPUTERHIGHLINEPACKAGE, DemoDataSetup.ResaleCode(), 977.4, 100, 0, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Assembly);
        InsertData(X8912W, XComputerTrendyPackagelc, XCOMPUTERTRENDYPACKAGE, DemoDataSetup.ResaleCode(), 1270.2, 100, 0, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Assembly);
        InsertData(X8916W, XComputerTURBOPackagelc, XCOMPUTERTURBOPACKAGE, DemoDataSetup.ResaleCode(), 1602, 100, 0, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XDESKTOP, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Assembly);
        InsertData(X8920W, XServerTeamwearPackagelc, XSERVERTEAMWEARPACKAGE, DemoDataSetup.ResaleCode(), 2203.2, 100, 0, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XSERVER, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Assembly);
        InsertData(X8924W, XServerEnterprisePackagelc, XSERVERENTERPRISEPACKAGE, DemoDataSetup.ResaleCode(), 2964.6, 100, 0, 19020816D,
          DemoDataSetup.RetailCode(), TaxCode, XSERVER, '50000', XPCS, XFREEENTRY, Item."Replenishment System"::Assembly);
    end;

    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        DemoDataSetup: Record "Demo Data Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
        TaxCode: Code[10];
        XComputerIII533MHzlc: Label 'Computer III 533 MHz';
        XDESKTOP: Label 'DESKTOP';
        XFREEENTRY: Label 'FREEENTRY';
        XPCS: Label 'PCS';
        XSERVER: Label 'SERVER';
        XComputerIII600MHzlc: Label 'Computer III 600 MHz';
        XComputerIII733MHzlc: Label 'Computer III 733 MHz';
        XComputerIII800MHzlc: Label 'Computer III 800 MHz';
        XComputerIII866MHzlc: Label 'Computer III 866 MHz';
        XCOMPUTERIII533MHZ: Label 'COMPUTER III 533 MHZ';
        XCOMPUTERIII600MHZ: Label 'COMPUTER III 600 MHZ';
        XCOMPUTERIII733MHZ: Label 'COMPUTER III 733 MHZ';
        XCOMPUTERIII800MHZ: Label 'COMPUTER III 800 MHZ';
        XCOMPUTERIII866MHZ: Label 'COMPUTER III 866 MHZ';
        XTeamWorkComputer533MHzlc: Label 'Team Work Computer 533 MHz';
        XTEAMWORKCOMPUTER533MHZ: Label 'TEAM WORK COMPUTER 533 MHZ';
        XEnterpriseComputer667MHzlc: Label 'Enterprise Computer 667 MHz';
        XENTERPRISECOMPUTER667MHZ: Label 'ENTERPRISE COMPUTER 667 MHZ';
        X64MBPC800ECC: Label '64 MB PC800 ECC';
        XMEMORY: Label 'MEMORY';
        X128MBPC800ECC: Label '128 MB PC800 ECC';
        X256MBPC800ECC: Label '256 MB PC800 ECC';
        X384MBPC800ECC: Label '384 MB PC800 ECC';
        X512MBPC800ECC: Label '512 MB PC800 ECC';
        X102GBATA66IDE: Label '10.2 GB ATA-66 IDE';
        X204GBATA66IDE: Label '20.4 GB ATA-66 IDE';
        X27GBATA66IDE: Label '27GB ATA-66 IDE';
        X40GBATA66IDE: Label '40GB ATA-66 IDE';
        XHARDDRIVE: Label 'HARDDRIVE';
        X9GBUltra160MSCSI: Label '9GB Ultra 160/M SCSI';
        X18GBUltra160MSCSI: Label '18GB Ultra 160/M SCSI';
        X36GBUltra160MSCSI: Label '36GB Ultra 160/M SCSI';
        XMONITOR: Label 'MONITOR';
        X17M780Monitorlc: Label '17" M780 Monitor';
        X17M780MONITOR: Label '17" M780 MONITOR';
        X151501FPFlatPanellc: Label '15" 1501 FP Flat Panel';
        X151501FPFLATPANEL: Label '15" 1501 FP FLAT PANEL';
        X19M009Monitorlc: Label '19" M009 Monitor';
        X19M009MONITOR: Label '19" M009 MONITOR';
        X21UltraScanP1110lc: Label '21" UltraScan P1110';
        X21ULTRASCANP1110: Label '21" ULTRASCAN P1110';
        X24Ultrascanlc: Label '24" Ultrascan';
        X24ULTRASCAN: Label '24" ULTRASCAN';
        XGraphicProgramlc: Label 'Graphic Program';
        XGRAPHICPROGRAM: Label 'GRAPHIC PROGRAM';
        XChip32MBlc: Label 'Chip 32 MB';
        XCHIP32MB: Label 'CHIP 32 MB';
        XGraphicCard9400lc: Label 'Graphic Card 9400';
        XGRAPHICCARD9400: Label 'GRAPHIC CARD 9400';
        XUltra160MSCSIControllerlc: Label 'Ultra 160/M SCSI Controller';
        XULTRA160MSCSICONTROLLER: Label 'ULTRA 160/M SCSI CONTROLLER';
        XCONTROLLER: Label 'CONTROLLER';
        X10MBitEthernetlc: Label '10MBit Ethernet';
        X10MBITETHERNET: Label '10MBIT ETHERNET';
        XGRAPHICS: Label 'GRAPHICS';
        XWebcamlc: Label 'Webcam';
        XWEBCAM: Label 'WEBCAM';
        XMOUSE: Label 'MOUSE';
        XBasicMouselc: Label 'Basic Mouse';
        XBASICMOUSE: Label 'BASIC MOUSE';
        XAdvamcedMouselc: Label 'Advanced Mouse';
        XADVAMCEDMOUSE: Label 'ADVANCED MOUSE';
        X2048xIDECDROM: Label '20/48x IDE CD ROM';
        XCDROM: Label 'CD ROM';
        X8x4x32xIDECDReadWritelc: Label '8x/4x/32x IDE CD Read-Write';
        X8X4X32XIDECDREADWRITE: Label '8X/4X/32X IDE CD READ-WRITE';
        XQuietkeyKeyboardlc: Label 'Quietkey Keyboard';
        XQUIETKEYKEYBOARD: Label 'QUIETKEY KEYBOARD';
        XKEYBOARD: Label 'KEYBOARD';
        XPerformanceKeyboardlc: Label 'Performance Keyboard';
        XPERFORMANCEKEYBOARD: Label 'PERFORMANCE KEYBOARD';
        XZIPDRIVE: Label 'ZIPDRIVE';
        XDrive250lc: Label 'Drive250';
        XDRIVE250: Label 'DRIVE 250';
        X250MBDisks2packlc: Label '250MB Disks/2pack';
        X250MBDISKS2PACK: Label '250MB DISKS/2PACK';
        X250MBDisks4packlc: Label '250MB Disks/4pack';
        X250MBDISKS4PACK: Label '250MB DISKS/4PACK';
        XEthernetCablelc: Label 'Ethernet Cable';
        XETHERNETCABLE: Label 'ETHERNET CABLE';
        XMISCACCESS: Label 'MISCACCESS';
        XPowerSupplyCablelc: Label 'Power Supply Cable';
        XPOWERSUPPLYCABLE: Label 'POWER SUPPLY CABLE';
        XHardDiskDrivelc: Label 'Hard Disk Drive';
        XHARDDISKDRIVE: Label 'HARD DISK DRIVE';
        XScrewonHardDriveMountinglc: Label 'Screw on Hard Drive Mounting';
        XSCREWONHARDDRIVEMOUNTING: Label 'SCREW ON HARD DRIVE MOUNTING';
        XScrewonMountCDTapeDrivelc: Label 'Screw on Mount CD/Tape Drive';
        XSCREWONMOUNTCDTAPEDRIVE: Label 'SCREW ON MOUNT CD/TAPE DRIVE';
        X8904W: Label '8904-W';
        X8908W: Label '8908-W';
        X8912W: Label '8912-W';
        X8916W: Label '8916-W';
        X8920W: Label '8920-W';
        X8924W: Label '8924-W';
        XComputerBasicPackagelc: Label 'Computer - Basic Package';
        XCOMPUTERBASICPACKAGE: Label 'COMPUTER - BASIC PACKAGE';
        XComputerHighlinePackagelc: Label 'Computer - Highline Package';
        XCOMPUTERHIGHLINEPACKAGE: Label 'COMPUTER - HIGHLINE PACKAGE';
        XComputerTrendyPackagelc: Label 'Computer - Trendy Package';
        XCOMPUTERTRENDYPACKAGE: Label 'COMPUTER - TRENDY PACKAGE';
        XComputerTURBOPackagelc: Label 'Computer - TURBO Package';
        XCOMPUTERTURBOPACKAGE: Label 'COMPUTER - TURBO PACKAGE';
        XServerTeamwearPackagelc: Label 'Server - Teamwear Package';
        XSERVERTEAMWEARPACKAGE: Label 'SERVER - TEAMWEAR PACKAGE';
        XServerEnterprisePackagelc: Label 'Server - Enterprise Package';
        XSERVERENTERPRISEPACKAGE: Label 'SERVER - ENTERPRISE PACKAGE';
        XNETWCARD: Label 'NETWCARD';

    procedure InsertData(ItemNo: Code[20]; Description: Text[100]; SearchDescription: Text[100]; InventoryPostingGroup: Code[20]; UnitPrice: Decimal; ProfitPercent: Decimal; UnitCost: Decimal; LastDateModified: Date; GenProdPostingGroup: Code[20]; TaxProdPostingGroup: Code[20]; ServiceItemGroup: Code[10]; VendorNo: Code[20]; BaseUnitOfMeasure: Code[10]; ItemTrackingCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
    begin
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Validate(Description, Description);
        Item.Validate("Search Description", SearchDescription);
        Item.Validate("Inventory Posting Group", InventoryPostingGroup);
        Item.Validate("Replenishment System", ReplenishmentSystem);

        Item."Last Direct Cost" :=
          Round(
            UnitCost * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor");
        if Item."Costing Method" = "Costing Method"::Standard then
            Item."Standard Cost" := Item."Last Direct Cost";
        Item."Unit Cost" := Item."Last Direct Cost";

        Item.Validate(
          "Unit Price",
          Round(
            UnitPrice * DemoDataSetup."Local Currency Factor", DemoDataSetup."Local Precision Factor"));

        Item.Validate("Profit %", ProfitPercent);
        Item.Validate("Last Date Modified", MakeAdjustments.AdjustDate(LastDateModified));
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        if DemoDataSetup."Company Type" = DemoDataSetup."Company Type"::VAT then
            Item.Validate("VAT Prod. Posting Group", TaxProdPostingGroup)
        else
            Item.Validate("Tax Group Code", TaxProdPostingGroup);
        Item.Validate("Service Item Group", ServiceItemGroup);
        Item.Validate("Vendor No.", VendorNo);

        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure."Item No." := ItemNo;
        ItemUnitOfMeasure.Code := BaseUnitOfMeasure;
        if not ItemUnitOfMeasure.Insert() then;

        Item.Validate("Base Unit of Measure", BaseUnitOfMeasure);
        Item.Validate("Item Tracking Code", ItemTrackingCode);
        Item.Insert(true);
    end;
}

