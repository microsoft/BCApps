codeunit 101800 "Create Fixed Asset"
{

    trigger OnRun()
    begin
        "Vendor No." := '44127914';
        InsertData(
          XFA000010, XMercedes300, XTANGIBLE, XCAR, XADM, '', XADM, 0, '', XOF,
            XEA12394Q, 19030412D, "Vendor No.", "Vendor No.", '001', '15 3410010', 0, '3', 1);
        SetupAT.ModifyFixedAsset(XFA000010, '0001', 1, false, false, 1);
        InsertData(
          XFA000020, XToyotaSupra30, XTANGIBLE, XCAR, XSALES, '', XSALES, 0, '', XJO,
          XEA12395Q, 19030718D, "Vendor No.", "Vendor No.", '002', '15 3410010', 0, '3', 1);
        SetupAT.ModifyFixedAsset(XFA000020, '0001', 1, false, false, 1);
        InsertData(
          XFA000030, XVWTransporter, XTANGIBLE, XCAR, XPROD, '', XPROD, 0, '', XRB,
          XEA15397Q, 19030821D, "Vendor No.", "Vendor No.", '003', '14 2915257', 0, '3', 1);
        SetupAT.ModifyFixedAsset(XFA000030, '0001', 1, false, false, 1);
        "Vendor No." := '44127904';
        InsertData(
          XFA000040, XConveyorMainAsset, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 1, XFA000040, XMH,
          X23111SW0, 19030815D, "Vendor No.", "Vendor No.", '004', '14 2915257', 0, '5', 1);
        SetupAT.ModifyFixedAsset(XFA000040, '0001', 2, false, false, 1);
        InsertData(
          XFA000050, XConveyorBelt, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 2, XFA000040, XMH,
          X23111SW1, 19030815D, "Vendor No.", "Vendor No.", '005', '14 2915257', 0, '5', 1);
        SetupAT.ModifyFixedAsset(XFA000050, '0001', 2, false, false, 1);
        InsertData(
          XFA000060, XConveyorLift, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 2, XFA000040, XMH,
          X23111SW2, 19030815D, "Vendor No.", "Vendor No.", '006', '14 2915257', 0, '5', 1);
        SetupAT.ModifyFixedAsset(XFA000060, '0001', 2, false, false, 1);
        InsertData(
          XFA000070, XConveyorComputer, XTANGIBLE, XMACHINERY, XPROD, '', XBUILD2, 2, XFA000040, XMH,
          X23111SW3, 19030815D, "Vendor No.", "Vendor No.", '007', '14 3020201', 0, '3', 1);
        SetupAT.ModifyFixedAsset(XFA000070, '0001', 2, false, false, 1);
        InsertData(
          XFA000080, XLiftforFurniture, XTANGIBLE, XMACHINERY, XPROD, '', XPROD, 0, '', XMH,
          XAKW2476111, 19030421D, "Vendor No.", "Vendor No.", '008', '14 2923581', 0, '5', 1);
        SetupAT.ModifyFixedAsset(XFA000080, '0001', 2, false, false, 1);
        InsertData(
          XFA000090, XSwitchboard, XTANGIBLE, XTELEPHONE, XADM, '', XRECEPTION, 0, '', XEH,
          XTELE4476Z, 19031212D, "Vendor No.", "Vendor No.", '009', '14 3020201', 0, '4', 1);
        SetupAT.ModifyFixedAsset(XFA000090, '0001', 2, false, false, 1);

        InsertData(
          XIA + '001',           // No.
          XBillingSoftware,   // Description
          XINTANGIBLE,        // FA Class Code
          XSOFTWARE,          // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          XVSH + '004',         // Vendor No.
          '',                 // Maintenance Vendor No.
          '',                 // Inventory Number
          '22 7260012',       // Depreciation Code
          1,                  // FA Type
          '3',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XIA + '001', '0001', 1, false, false, 1);
        InsertData(
          XIA + '002', XFilmAuthorRight, XINTANGIBLE, XSOFTWARE, XADM, '', XADM, 0, '', XMH,
          '', 0D, XVLE + '017', XVLE + '017', '', '23 0001020', 1, '3', 2);
        SetupAT.ModifyFixedAsset(XIA + '002', '0001', 1, false, false, 1);
        InsertData(
          XIA + '003',           // No.
          XInternetPortal,    // Description
          XINTANGIBLE,        // FA Class Code
          XSOFTWARE,          // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          XVLE + '009',         // Vendor No.
          '',                 // Maintenance Vendor No.
          '',                 // Inventory Number
          '22 7260012',       // Depreciation Code
          1,                  // FA Type
          '3',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XIA + '003', '0001', 1, false, false, 1);
        InsertData(
          XFAOB + '001',           // No.
          XBuilding2,         // Description
          '',        // FA Class Code
          XBUILDING,          // FA Subclass Code
          '',                 // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          '',                 // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          '',                 // Inventory Number
          '11 0001190',       // Depreciation Code
          0,                  // FA Type
          '',                 // Depreciation Group
          0);                 // Belonging to Manufacturing

        InsertData(
          XFA + '001',           // No.
          XBuilding3,         // Description
          XINTANGIBLE,        // FA Class Code
          XBUILDING,          // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          XVSH + '003',         // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '001',          // Inventory Number
          '11 0001120',       // Depreciation Code
          0,                  // FA Type
          '10',               // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '001', '0001', 2, false, false, 1);
        InsertData(
          XFA + '002',           // No.
          XAVAIADefinity,     // Description
          XINTANGIBLE,        // FA Class Code
          XTELEPHONE,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          'AnyData 5346',     // Serial No.
          0D,                 // Next Service Date
          XVLE + '008',         // Vendor No.
          XVLE + '008',           // Maintenance Vendor No.
          XFA + '002',          // Inventory Number
          '14 3222101',       // Depreciation Code
          0,                  // FA Type
          '6',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '001', '0001', 1, false, false, 1);
        InsertData(
          XFA + '003',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034562',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '003',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '003', '0001', 1, false, false, 1);
        InsertData(
          XFA + '004',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034563',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '004',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '004', '0001', 1, false, false, 1);
        InsertData(
          XFA + '005',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034564',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '005',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '005', '0001', 1, false, false, 1);
        InsertData(
          XFA + '006',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034565',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '006',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '006', '0001', 1, false, false, 1);
        InsertData(
          XFA + '007',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034566',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '007',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '007', '0001', 1, false, false, 1);
        InsertData(
          XFA + '008',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034567',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '008',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '008', '0001', 1, false, false, 1);
        InsertData(
          XFA + '009',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034568',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '009',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '009', '0001', 1, false, false, 1);
        InsertData(
          XFA + '010',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034569',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '010',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing

        InsertData(
          XFA + '011',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034582',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '011',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '011', '0001', 1, false, false, 1);
        InsertData(
          XFA + '012',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034585',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '012',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '012', '0001', 1, false, false, 1);
        InsertData(
          XFA + '013',           // No.
          XWorkingTable,      // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '013',          // Inventory Number
          '16 3612421',       // Depreciation Code
          0,                  // FA Type
          '3',                // Depreciation Group
          1);                 // Belonging to Manufacturing

        InsertData(
          XFA + '014',           // No.
          XMovingPedestalCherry, // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '014',          // Inventory Number
          '16 3612461',       // Depreciation Code
          0,                  // FA Type
          '3',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '014', '0001', 1, false, false, 1);
        InsertData(
          XFA + '015',           // No.
          X4DoorsPedestalCherry, // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '015',          // Inventory Number
          '16 3612461',       // Depreciation Code
          0,                  // FA Type
          '3',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '015', '0001', 1, false, false, 1);
        InsertData(
          XFA + '016',           // No.
          XProductionBuilding,// Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XPROD,              // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XSALES,             // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '016',          // Inventory Number
          '11 0001190',       // Depreciation Code
          0,                  // FA Type
          '10',               // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '016', '0001', 1, false, false, 1);
        InsertData(
          XFA + '017',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034610',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '017',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '017', '0001', 1, false, false, 1);
        InsertData(
          XFA + '018',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034611',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '018',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '018', '0001', 1, false, false, 1);
        InsertData(
          XFA + '019',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034612',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '019',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '019', '0001', 1, false, false, 1);
        InsertData(
          XFA + '020',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034613',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '020',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '020', '0001', 1, false, false, 1);
        InsertData(
          XFA + '021',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034614',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '021',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '021', '0001', 1, false, false, 1);
        InsertData(
          XFA + '022',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034615',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '022',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '022', '0001', 1, false, false, 1);
        InsertData(
          XFA + '023',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034616',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '023',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '023', '0001', 1, false, false, 1);
        InsertData(
          XFA + '024',           // No.
          XComputer,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034617',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '024',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing

        InsertData(
          XFA + '025',           // No.
          XComputer,        // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,          // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034618',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '025',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '025', '0001', 1, false, false, 1);
        InsertData(
          XFA + '026',           // No.
          XComputer,        // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,          // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '0034619',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '026',          // Inventory Number
          '14 3020201',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing

        InsertData(
          XFA + '027',           // No.
          XConveyor,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          'PRS 12 307',       // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '027',          // Inventory Number
          '14 2915257',       // Depreciation Code
          0,                  // FA Type
          '3',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '027', '0001', 1, false, false, 1);
        InsertData(
          XFA + '028',           // No.
          XCarGazel,          // Description
          XINTANGIBLE,        // FA Class Code
          XCAR,               // FA Subclass Code
          XSALES,             // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          'AG 12 394',        // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '028',          // Inventory Number
          '15 3410010',       // Depreciation Code
          0,                  // FA Type
          '3',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '028', '0001', 1, false, false, 1);
        InsertData(
          XFA + '029',           // No.
          XAirconditioner,    // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          'WD 12 3076',       // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '029',          // Inventory Number
          '16 2930274',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '029', '0001', 1, false, false, 1);
        InsertData(
          XFA + '030',           // No.
          XAirconditioner,    // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          'WD 12 3052',       // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '030',          // Inventory Number
          '16 2930274',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '030', '0001', 1, false, false, 1);
        InsertData(
          XFA + '031',           // No.
          XCurtains,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '031',          // Inventory Number
          '16 1721000',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '031', '0001', 1, false, false, 1);
        InsertData(
          XFA + '032',           // No.
          XCurtains,          // Description
          XINTANGIBLE,        // FA Class Code
          XMACHINERY,         // FA Subclass Code
          XADM,               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          XADM,               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          XMH,                // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          XFA + '032',          // Inventory Number
          '16 1721000',       // Depreciation Code
          0,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
        SetupAT.ModifyFixedAsset(XFA + '032', '0001', 1, false, false, 1);

        InsertData(
          XFE + '001',           // No.
          XDominoSoftware,    // Description
          XINTANGIBLE,        // FA Class Code
          '',                 // FA Subclass Code
          '',                 // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          '',                 // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          '',                 // Responsible Employee
          '',                 // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          '',                 // Inventory Number
          '22 7260012',       // Depreciation Code
          2,                  // FA Type
          '1',                // Depreciation Group
          1);                 // Belonging to Manufacturing

        InsertData(
          XFE + '002',           // No.
          XSalesFAWithLoss,   // Description
          XINTANGIBLE,        // FA Class Code
          '',          // FA Subclass Code
          '',               // Global Dimension 1 Code
          '',                 // Global Dimension 2 Code
          '',               // FA Location Code
          0,                  // Main Asset/Component
          '',                 // Component of Main Asset
          '',                // Responsible Employee
          '',          // Serial No.
          0D,                 // Next Service Date
          '',                 // Vendor No.
          '',                 // Maintenance Vendor No.
          '',          // Inventory Number
          '14 3020201',       // Depreciation Code
          2,                  // FA Type
          '2',                // Depreciation Group
          1);                 // Belonging to Manufacturing
    end;

    var
        "Fixed Asset": Record "Fixed Asset";
        CA: Codeunit "Make Adjustments";
        SetupAT: Codeunit "Setup Assessed Tax";
        "Vendor No.": Code[20];
        XFA000010: Label 'FA000010';
        XMercedes300: Label 'Mercedes 300';
        XTANGIBLE: Label 'TANGIBLE';
        XCAR: Label 'CAR';
        XADM: Label 'ADM';
        XOF: Label 'OF';
        XEA12394Q: Label 'EA 12 394 Q';
        XFA000020: Label 'FA000020';
        XToyotaSupra30: Label 'Toyota Supra 3.0';
        XSALES: Label 'SALES';
        XJO: Label 'JO';
        XEA12395Q: Label 'EA 12 395 Q';
        XFA000030: Label 'FA000030';
        XVWTransporter: Label 'VW Transporter';
        XPROD: Label 'PROD';
        XRB: Label 'RB';
        XEA15397Q: Label 'EA 15 397 Q';
        XFA000040: Label 'FA000040';
        XConveyorMainAsset: Label 'Conveyor, Main Asset';
        XMACHINERY: Label 'MACHINERY';
        XBUILD2: Label 'BUILD_2';
        XMH: Label 'MH';
        X23111SW0: Label '23 111 SW0';
        XFA000050: Label 'FA000050';
        XConveyorBelt: Label 'Conveyor Belt';
        X23111SW1: Label '23 111 SW1';
        XFA000070: Label 'FA000070';
        X23111SW2: Label '23 111 SW2';
        XConveyorComputer: Label 'Conveyor Computer';
        X23111SW3: Label '23 111 SW3';
        XFA000080: Label 'FA000080';
        XLiftforFurniture: Label 'Lift for Furniture';
        XFA000060: Label 'FA000060';
        XConveyorLift: Label 'Conveyor Lift';
        XAKW2476111: Label 'AKW2476111';
        XFA000090: Label 'FA000090';
        XSwitchboard: Label 'Switchboard';
        XTELEPHONE: Label 'TELEPHONE';
        XRECEPTION: Label 'RECEPTION';
        XEH: Label 'EH';
        XTELE4476Z: Label 'TELE 4476 Z', Comment = 'Name';
        XVSH: Label 'VSH';
        XIA: Label 'IA';
        XFA: Label 'FA';
        XINTANGIBLE: Label 'INTANGIBLE';
        XSOFTWARE: Label 'SOFTWARE';
        XBUILDING: Label 'BUILDING';
        XFE: Label 'FE';
        XFAOB: Label 'FAOB';
        XVLE: Label 'VLE';
        XBillingSoftware: Label 'Billing Software';
        XInternetPortal: Label 'Internet Portal CRONUS';
        XBuilding2: Label 'Building';
        XBuilding3: Label 'Building (Koroleva str.14)';
        XAVAIADefinity: Label 'ATS AVAIA Definity';
        XWorkingTable: Label 'Working Table';
        XMovingPedestalCherry: Label 'Moving Pedestal, Cherry';
        X4DoorsPedestalCherry: Label '4 Doors Pedestal, Cherry';
        XProductionBuilding: Label 'Production Building';
        XConveyor: Label 'Conveyor';
        XCarGazel: Label 'Car Gazel';
        XAirconditioner: Label 'Airconditioner';
        XCurtains: Label 'Curtains';
        XDominoSoftware: Label 'Domino Software';
        XSalesFAWithLoss: Label 'Sales FA-012 with loss';
        XComputer: Label 'Computer';
        XFilmAuthorRight: Label 'Film author right';

    procedure InsertData("No.": Code[20]; Description: Text[30]; "FA Class Code": Code[10]; "FA Subclass Code": Code[10]; "Global Dimension 1 Code": Code[20]; "Global Dimension 2 Code": Code[20]; "FA Location Code": Code[10]; "Main Asset/Component": Integer; "Component of Main Asset": Code[20]; "Responsible Employee": Code[20]; "Serial No.": Text[30]; "Next Service Date": Date; "Vendor No.": Code[20]; "Maintenance Vendor No.": Code[20]; "Inventory Number": Text[30]; "Depreciation Code": Code[10]; "FA Type": Integer; "Depreciation Group": Code[10]; "Belonging to Manufacturing": Integer)
    begin
        "Fixed Asset".Init();
        "Fixed Asset"."No." := "No.";
        "Fixed Asset".Description := Description;
        "Fixed Asset"."Search Description" := Description;
        "Fixed Asset".Validate("FA Class Code", "FA Class Code");
        if "FA Subclass Code" <> '' then
            "Fixed Asset".Validate("FA Subclass Code", "FA Subclass Code");
        "Fixed Asset".Validate("FA Location Code", "FA Location Code");
        "Fixed Asset"."Main Asset/Component" := "FA Component Type".FromInteger("Main Asset/Component");
        "Fixed Asset"."Component of Main Asset" := "Component of Main Asset";
        "Fixed Asset".Validate("Responsible Employee", "Responsible Employee");
        "Fixed Asset".Validate("Serial No.", "Serial No.");
        if "Next Service Date" <> 0D then
            "Fixed Asset".Validate("Next Service Date", CA.AdjustDate("Next Service Date"));
        "Fixed Asset".Validate("Vendor No.", "Vendor No.");
        "Fixed Asset".Validate("Maintenance Vendor No.", "Maintenance Vendor No.");
        "Fixed Asset"."Inventory Number" := "Inventory Number";
        "Fixed Asset"."Depreciation Code" := "Depreciation Code";
        "Fixed Asset"."Depreciation Group" := "Depreciation Group";
        "Fixed Asset"."FA Type" := "FA Type";
        "Fixed Asset"."Belonging to Manufacturing" := "Belonging to Manufacturing";

        "Fixed Asset".Insert();
        "Fixed Asset".Validate("Global Dimension 1 Code", "Global Dimension 1 Code");
        "Fixed Asset".Validate("Global Dimension 2 Code", "Global Dimension 2 Code");
        "Fixed Asset".InitFADeprBooks("Fixed Asset"."No.");
        "Fixed Asset".Modify();
    end;

    procedure InsertDeprCode("Code": Code[10]; GroupCode: Code[10])
    var
        DepreciationCode: Record "Depreciation Code";
    begin
        DepreciationCode.Init();
        DepreciationCode.Code := Code;
        DepreciationCode."Depreciation Group" := GroupCode;
        if DepreciationCode.Insert() then;
    end;
}

