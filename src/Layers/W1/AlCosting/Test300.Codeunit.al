codeunit 103514 "Test 300"
{
    // Unsupported version tags:
    // NA: Skipped for Execution
    // ES: Skipped for Execution
    // DE: Skipped for Execution


    trigger OnRun()
    var
        WMSTestscriptManagement: Codeunit "WMS TestscriptManagement";
    begin
        TestscriptMgt.InitializeOutput(CODEUNIT::"Test 300");
        WMSTestscriptManagement.SetGlobalPreconditions();
        SetPreconditions();
        "Test 300.1.1"();
        "Test 300.1.2"();
        "Test 300.1.3"();
        "Test 300.1.4"();
        "Test 300.1.5"();
        "Test 300.2.1"();
        "Test 300.2.2"();
        "Test 300.2.3"();
        "Test 300.2.4"();
        "Test 300.2.5"();
        "Test 300.3.1"();
        "Test 300.3.2"();
        "Test 300.3.3"();
        "Test 300.3.4"();
        "Test 300.3.5"();
        "Test 300.3.6"();

        if ShowTestResuts then
            TestscriptMgt.ShowTestscriptResult();
    end;

    var
        TestscriptMgt: Codeunit TestscriptManagement;
        GLUtil: Codeunit GLUtil;
        INVTUtil: Codeunit INVTUtil;
        MFGUtil: Codeunit MFGUtil;
        CRPUtil: Codeunit CRPUtil;
        CurrTest: Text[30];
        ShowTestResuts: Boolean;

    [Scope('OnPrem')]
    procedure SetPreconditions()
    begin
        CODEUNIT.Run(CODEUNIT::"Set Global Preconditions");

        GLUtil.SetRndgPrec(0.01, 0.00001);
        CreateWorkCenters();
        CreateMachCenters();
        CreateRoutings();
        CreateItems();
        CreatePBOMs();
        ConnectPBOMAndRoutings();
    end;

    [Scope('OnPrem')]
    procedure "Test 300.1.1"()
    begin
        CurrTest := '300.1.1';

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 5.0, 0.0, 0, 0, 0, 5, 0, 0, 0, 0, 5);
        ValidateCostShare('2', 2.0, 0.0, 0, 0, 0, 2, 0, 0, 0, 0, 2);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.34, 0.0, 0, 0, 0, 4.34, 0, 0, 0, 0, 4.34);
        ValidateCostShare('5', 18.9, 0.0, 0, 0, 0, 18.9, 0, 0, 0, 0, 18.9);
        ValidateCostShare('6', 0.02, 0.0, 0, 0, 0, 0.02, 0, 0, 0, 0, 0.02);
        ValidateCostShare('7', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('8', 0.04, 0.0, 0, 0, 0, 0.04, 0, 0, 0, 0, 0.04);
        ValidateCostShare(
          '9', 9.8, 141.93, 0, 17.9594, 26.864, 9.8, 141.93, 0, 17.9594, 26.864, 196.5534);
        ValidateCostShare(
          '10', 27.48, 36.9, 31.5, 5.41985, 10.517, 27.48, 36.9, 31.5, 5.41985, 10.517, 111.81685);
        ValidateCostShare(
          '11', 37.3, 253.53, 31.5, 47.18661, 51.08, 308.39025, 74.7, 0, 23.80736, 13.699, 420.59661);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.1.2"()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        CurrTest := '300.1.2';

        Item.Get('8');
        Item.Validate("Base Unit of Measure", 'M');
        Item.Validate("Standard Cost", 4);
        Item.Validate("Lot Size", 10);
        Item.Validate("Rounding Precision", 0.01);
        Item.Modify(true);

        if ItemUnitOfMeasure.Get(Item."No.", 'CM') then
            ItemUnitOfMeasure.Delete(true);
        UpdatePBOMQtyAndUOM('3', 50000, 0.88, 'M');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 5.0, 0.0, 0, 0, 0, 5, 0, 0, 0, 0, 5);
        ValidateCostShare('2', 2.0, 0.0, 0, 0, 0, 2, 0, 0, 0, 0, 2);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.34, 0.0, 0, 0, 0, 4.34, 0, 0, 0, 0, 4.34);
        ValidateCostShare('5', 18.9, 0.0, 0, 0, 0, 18.9, 0, 0, 0, 0, 18.9);
        ValidateCostShare('6', 0.02, 0.0, 0, 0, 0, 0.02, 0, 0, 0, 0, 0.02);
        ValidateCostShare('7', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('8', 4, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare(
          '9', 9.8, 141.93, 0, 17.9594, 26.864, 9.8, 141.93, 0, 17.9594, 26.864, 196.5534);
        ValidateCostShare(
          '10', 27.48, 36.9, 31.5, 5.41985, 10.517, 27.48, 36.9, 31.5, 5.41985, 10.517, 111.81685);
        ValidateCostShare(
          '11', 37.3, 253.53, 31.5, 47.18661, 51.08, 308.39025, 74.7, 0, 23.80736, 13.699, 420.59661);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.1.3"()
    begin
        CurrTest := '300.1.3';

        UpdateRtngSetupAndRunTime('1', '', '11', 4, 'MINUTES', 25, 'MINUTES');
        UpdateRtngSetupAndRunTime('1', '', '12', 1, 'MINUTES', 62, 'MINUTES');
        UpdateRtngSetupAndRunTime('1', '', '13', 1, 'MINUTES', 0, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '21', 12, 'MINUTES', 111, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '22', 6.6, 'MINUTES', 2, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '23', 0, 'MINUTES', 0, 'MINUTES');
        UpdateRtngSetupAndRunTime('3', '', '32', 4, 'MINUTES', 6656, 'MINUTES');
        UpdateItemLotSize('1', 645);
        UpdateItemLotSize('2', 1);
        UpdateItemLotSize('11', 100000);

        UpdatePBOMQtyAndUOM('1', 10000, 0.9, 'PCS');
        UpdatePBOMQtyAndUOM('1', 30000, 3.14159, 'PCS');
        UpdatePBOMQtyAndUOM('2', 10000, 1000, 'PCS');
        UpdatePBOMQtyAndUOM('3', 10000, 600, 'PCS');
        UpdatePBOMQtyAndUOM('3', 20000, 343, 'PCS');
        UpdatePBOMQtyAndUOM('3', 50000, 0.001, 'M');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 5.0, 0.0, 0, 0, 0, 5, 0, 0, 0, 0, 5);
        ValidateCostShare('2', 2.0, 0.0, 0, 0, 0, 2, 0, 0, 0, 0, 2);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.34, 0.0, 0, 0, 0, 4.34, 0, 0, 0, 0, 4.34);
        ValidateCostShare('5', 18.9, 0.0, 0, 0, 0, 18.9, 0, 0, 0, 0, 18.9);
        ValidateCostShare('6', 0.02, 0.0, 0, 0, 0, 0.02, 0, 0, 0, 0, 0.02);
        ValidateCostShare('7', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('8', 4, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare(
          '9', 5004.8, 1014.588, 0, 621.40636, 193.6756, 5004.8, 1014.588, 0, 621.40636, 193.6756, 6834.46996);
        ValidateCostShare(
          '10', 9087.424, 59907.6, 31.5, 4024.04985, 11452.473, 9087.424, 59907.6, 31.5, 4024.04985, 11452.473, 84503.04685);
        ValidateCostShare(
          '11', 13591.80683, 61138.72959, 31.5, 10045.15356, 11685.28111, 90654.13265, 318.00039, 0, 5461.83799, 58.50007, 96492.4711);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.1.4"()
    begin
        CurrTest := '300.1.4';

        UpdateRtngSetupAndRunTime('1', '', '11', 1, 'MINUTES', 6, 'MINUTES');
        UpdateRtngSetupAndRunTime('1', '', '12', 1, 'MINUTES', 10, 'MINUTES');
        UpdateRtngSetupAndRunTime('1', '', '13', 1, 'MINUTES', 3, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '21', 1, 'MINUTES', 11, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '22', 1, 'MINUTES', 3, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '23', 0.5, 'MINUTES', 4, 'MINUTES');
        UpdateRtngSetupAndRunTime('3', '', '32', 1, 'MINUTES', 4, 'MINUTES');

        UpdateItemLotSize('1', 25);
        UpdateItemLotSize('2', 100);
        UpdateItemLotSize('11', 10);

        UpdatePBOMQtyAndUOM('1', 10000, 1, 'PCS');
        UpdatePBOMQtyAndUOM('1', 30000, 1, 'PCS');
        UpdatePBOMQtyAndUOM('2', 10000, 1, 'PCS');
        UpdatePBOMQtyAndUOM('3', 10000, 1, 'PCS');
        UpdatePBOMQtyAndUOM('3', 20000, 1, 'PCS');
        UpdatePBOMQtyAndUOM('3', 50000, 0.88, 'M');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 5.0, 0.0, 0, 0, 0, 5, 0, 0, 0, 0, 5);
        ValidateCostShare('2', 2.0, 0.0, 0, 0, 0, 2, 0, 0, 0, 0, 2);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.34, 0.0, 0, 0, 0, 4.34, 0, 0, 0, 0, 4.34);
        ValidateCostShare('5', 18.9, 0.0, 0, 0, 0, 18.9, 0, 0, 0, 0, 18.9);
        ValidateCostShare('6', 0.02, 0.0, 0, 0, 0, 0.02, 0, 0, 0, 0, 0.02);
        ValidateCostShare('7', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('8', 4, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare(
          '9', 9.8, 141.93, 0, 17.9594, 26.864, 9.8, 141.93, 0, 17.9594, 26.864, 196.5534);
        ValidateCostShare(
          '10', 27.48, 36.9, 31.5, 5.41985, 10.517, 27.48, 36.9, 31.5, 5.41985, 10.517, 111.81685);
        ValidateCostShare(
          '11', 37.3, 253.53, 31.5, 47.18661, 51.08, 308.39025, 74.7, 0, 23.80736, 13.699, 420.59661);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.1.5"()
    begin
        CurrTest := '300.1.5';

        UpdateItemLotSize('1', 10);
        UpdateItemLotSize('2', 50);
        UpdateItemLotSize('3', 24);
        UpdateItemLotSize('4', 2);
        UpdateItemLotSize('5', 100);
        UpdateItemLotSize('8', 25);
        UpdateItemLotSize('9', 5);
        UpdateItemLotSize('10', 5);
        UpdateItemLotSize('11', 5);

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 5.0, 0.0, 0, 0, 0, 5, 0, 0, 0, 0, 5);
        ValidateCostShare('2', 2.0, 0.0, 0, 0, 0, 2, 0, 0, 0, 0, 2);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.34, 0.0, 0, 0, 0, 4.34, 0, 0, 0, 0, 4.34);
        ValidateCostShare('5', 18.9, 0.0, 0, 0, 0, 18.9, 0, 0, 0, 0, 18.9);
        ValidateCostShare('6', 0.02, 0.0, 0, 0, 0, 0.02, 0, 0, 0, 0, 0.02);
        ValidateCostShare('7', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('8', 4, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare(
          '9', 9.8, 143.46, 0, 18.1408, 27.148, 9.8, 143.46, 0, 18.1408, 27.148, 198.5488);
        ValidateCostShare(
          '10', 27.48, 37.8, 33, 5.5567, 10.854, 27.48, 37.8, 33, 5.5567, 10.854, 114.6907);
        ValidateCostShare(
          '11', 37.3, 257.16, 33, 47.88215, 51.92, 313.2595, 75.9, 0, 24.18465, 13.918, 427.26215);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.2.1"()
    begin
        CurrTest := '300.2.1';

        UpdateRtngSetupAndRunTime('1', '', '11', 0.5, 'MINUTES', 3, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '21', 0.5, 'MINUTES', 6, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '23', 0.5, 'MINUTES', 3, 'MINUTES');
        UpdateRtngSetupAndRunTime('3', '', '32', 0.5, 'MINUTES', 3, 'MINUTES');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 5.0, 0.0, 0, 0, 0, 5, 0, 0, 0, 0, 5);
        ValidateCostShare('2', 2.0, 0.0, 0, 0, 0, 2, 0, 0, 0, 0, 2);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.34, 0.0, 0, 0, 0, 4.34, 0, 0, 0, 0, 4.34);
        ValidateCostShare('5', 18.9, 0.0, 0, 0, 0, 18.9, 0, 0, 0, 0, 18.9);
        ValidateCostShare('6', 0.02, 0.0, 0, 0, 0, 0.02, 0, 0, 0, 0, 0.02);
        ValidateCostShare('7', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('8', 4, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare(
          '9', 9.8, 88.56, 0, 11.6016, 16.656, 9.8, 88.56, 0, 11.6016, 16.656, 126.6176);
        ValidateCostShare(
          '10', 27.48, 27.9, 33, 4.9671, 8.962, 27.48, 27.9, 33, 4.9671, 8.962, 102.3091);
        ValidateCostShare(
          '11', 37.3, 164.46, 33, 33.70066, 34.204, 228.9467, 48, 0, 17.13196, 8.586, 302.66466);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.2.2"()
    begin
        CurrTest := '300.2.2';

        UpdateItemStdCost('1', 4);
        UpdateItemStdCost('2', 1.8);
        UpdateItemStdCost('4', 4.12);
        UpdateItemStdCost('5', 18.1);
        UpdateItemStdCost('6', 0.018);
        UpdateItemStdCost('7', 0.66);
        UpdateItemStdCost('8', 3.98);

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 88.56, 0, 11.4816, 16.656, 8.6, 88.56, 0, 11.4816, 16.656, 125.2976);
        ValidateCostShare(
          '10', 26.4004, 27.9, 33, 4.91312, 8.962, 26.4004, 27.9, 33, 4.91312, 8.962, 101.17552);
        ValidateCostShare(
          '11', 35.0184, 164.46, 33, 33.37935, 34.204, 226.49112, 48, 0, 16.98463, 8.586, 300.06175);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.2.3"()
    begin
        CurrTest := '300.2.3';

        UpdateMachCenter('1', 1.4);
        UpdateMachCenter('2', 1.4);
        UpdateMachCenter('3', 1.7);

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 88.24, 0, 11.4464, 16.624, 8.6, 88.24, 0, 11.4464, 16.624, 124.9104);
        ValidateCostShare(
          '10', 26.4004, 27.9, 33, 4.91312, 8.962, 26.4004, 27.9, 33, 4.91312, 8.962, 101.17552);
        ValidateCostShare(
          '11', 35.0184, 162.8, 33, 33.23248, 34.038, 226.10392, 46.66, 0, 16.87296, 8.452, 298.08888);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.2.4"()
    begin
        CurrTest := '300.2.4';

        UpdateRtngSetupAndRunTime('1', '', '11', 0.4, 'MINUTES', 3, 'MINUTES');
        UpdateRtngSetupAndRunTime('1', '', '13', 1, 'MINUTES', 2.9, 'MINUTES');
        UpdateRtngSetupAndRunTime('3', '', '32', 0.4, 'MINUTES', 2.9, 'MINUTES');

        UpdatePBOMQtyAndUOM('1', 30000, 0, 'PCS');
        UpdatePBOMQtyAndUOM('3', 30000, 0, 'PCS');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 88.24, 0, 11.4464, 16.624, 8.6, 88.24, 0, 11.4464, 16.624, 124.9104);
        ValidateCostShare(
          '10', 26.3824, 26.82, 33, 4.8479, 8.7556, 26.3824, 26.82, 33, 4.8479, 8.7556, 99.8059);
        ValidateCostShare(
          '11', 34.9824, 161.4, 33, 33.06147, 33.7762, 224.7163, 46.34, 0, 16.76717, 8.3966, 296.22007);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.2.5"()
    begin
        CurrTest := '300.2.5';

        UpdateRtngSetupAndRunTime('2', '', '22', 0, 'MINUTES', 0, 'MINUTES');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 82.8, 0, 10.8224, 15.824, 8.6, 82.8, 0, 10.8224, 15.824, 118.0464);
        ValidateCostShare(
          '10', 26.3824, 26.82, 33, 4.8479, 8.7556, 26.3824, 26.82, 33, 4.8479, 8.7556, 99.8059);
        ValidateCostShare(
          '11', 34.9824, 155.96, 33, 32.02563, 32.9762, 217.8523, 46.34, 0, 16.35533, 8.3966, 288.94423);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.3.1"()
    begin
        CurrTest := '300.3.1';

        INVTUtil.InsertItemUOM('10', 'PACK', 17);
        UpdatePBOMQtyAndUOM('1', 20000, 1, 'PACK');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 82.8, 0, 10.8224, 15.824, 8.6, 82.8, 0, 10.8224, 15.824, 118.0464);
        ValidateCostShare(
          '10', 26.3824, 26.82, 33, 4.8479, 8.7556, 26.3824, 26.82, 33, 4.8479, 8.7556, 99.8059);
        ValidateCostShare(
          '11', 457.1008, 585.08, 561, 205.4057, 173.0658, 1814.7467, 46.34, 0, 112.169, 8.3966, 1981.6523);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.3.2"()
    var
        WorkCenter: Record "Work Center";
        RtngLine: Record "Routing Line";
    begin
        CurrTest := '300.3.2';

        WorkCenter.Get('2');
        WorkCenter.Validate("Specific Unit Cost", true);
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Modify(true);

        CRPUtil.UncertifyRouting('3', '');
        RtngLine.Get('3', '', '31');
        RtngLine.Validate("Unit Cost per", 2.30258);
        RtngLine.Modify(true);
        CRPUtil.CertifyRouting('3', '');

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 82.8, 0, 10.8224, 15.824, 8.6, 82.8, 0, 10.8224, 15.824, 118.0464);
        ValidateCostShare(
          '10', 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 63.76211);
        ValidateCostShare(
          '11', 457.1008, 585.08, 32.42274, 139.46274, 118.07692, 1202.00227, 46.34, 0, 75.40433, 8.3966, 1332.1432);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.3.3"()
    var
        ProdBOMVersion: Record "Production BOM Version";
        ProdBOMComponent: Record "Production BOM Line";
        RtngVersion: Record "Routing Version";
    begin
        CurrTest := '300.3.3';

        INVTUtil.InsertItemUOM('11', 'BOX', 3);
        MFGUtil.InsertPBOMVersion('1', '1', 20020101D, 'BOX', ProdBOMVersion);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMVersion."Production BOM No.", ProdBOMVersion."Version Code", ProdBOMVersion."Starting Date", '', '2', 3.14159, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMVersion."Production BOM No.", ProdBOMVersion."Version Code", ProdBOMVersion."Starting Date", '10', '', 1, false);
        MFGUtil.CertifyPBOM(ProdBOMVersion."Production BOM No.", ProdBOMVersion."Version Code");

        CRPUtil.InsertRtngVersion('1', '1', 20020101D, RtngVersion);
        InsertRntgLine(RtngVersion."Routing No.", RtngVersion."Version Code", '11', '1', '');
        UpdateRtngSetupAndRunTime(RtngVersion."Routing No.", RtngVersion."Version Code", '11', 3.14159, 'MINUTES', 3.33333, 'MINUTES');
        InsertRntgLine(RtngVersion."Routing No.", RtngVersion."Version Code", '12', '', '1');
        UpdateRtngSetupAndRunTime(RtngVersion."Routing No.", RtngVersion."Version Code", '12', 1.94591, 'MINUTES', 3.66667, 'MINUTES');
        CRPUtil.CertifyRouting(RtngVersion."Routing No.", RtngVersion."Version Code");

        CalcStdCost('11', 20020101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 82.8, 0, 10.8224, 15.824, 8.6, 82.8, 0, 10.8224, 15.824, 118.0464);
        ValidateCostShare(
          '10', 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 63.76211);
        ValidateCostShare(
          '11', 17.80003, 50.27304, 0.63574, 5.80667, 9.62776, 30.25996, 41.33302, 0, 4.76283, 7.78744, 84.14325);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.3.4"()
    begin
        CurrTest := '300.3.4';

        UpdateItemScrapPct('11', 5);
        UpdatePBOMLinkCodeScrap('2', 10000, '', '', 9);
        UpdateRtngLinkCodeAndScrap('1', '1', '11', '', 7, 3);
        UpdateRtngLinkCodeAndScrap('1', '1', '12', '100', 11, 5);
        UpdatePBOMLinkCodeScrap('1', 20000, '1', '100', 0);

        CalcStdCost('11', 20020101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 8.6, 82.8, 0, 10.8224, 15.824, 8.6, 82.8, 0, 10.8224, 15.824, 118.0464);
        ValidateCostShare(
          '10', 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 63.76211);
        ValidateCostShare(
          '11', 74.09526, 196.72404, 2.09953, 22.29048, 37.68697, 115.24412, 167.19967, 0, 18.84319, 31.60931, 332.89629);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.3.5"()
    begin
        CurrTest := '300.3.5';

        UpdateItemScrapPct('11', 0);
        UpdateItemLotSize('11', 0);
        UpdateRtngLinkCodeAndScrap('2', '', '23', '', 7, 3);
        UpdateRtngSetupAndRunTime('2', '', '23', 0.5, 'HOURS', 3, 'MINUTES');
        UpdatePBOMQtyAndUOM('2', 10000, -1, 'PCS');
        UpdatePBOMLinkCodeScrap('2', 10000, '', '', -9);

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 1.8288, 251.73, 0, 30.26672, 48.1084, 1.8288, 251.73, 0, 30.26672, 48.1084, 331.93392);
        ValidateCostShare(
          '10', 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 63.76211);
        ValidateCostShare(
          '11', 450.3296, 759.13, 32.42274, 172.10214, 151.27172, 1415.88979, 51.46, 0, 88.59941, 9.307, 1565.2562);
    end;

    [Scope('OnPrem')]
    procedure "Test 300.3.6"()
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
        Item: Record Item;
    begin
        CurrTest := '300.3.6';

        MFGUtil.InsertPBOMHeader('0', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '', '1', 1, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '9', '', 1, false);
        Item.Get('11');
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);

        CalcStdCost('11', 20010101D);

        ValidateCostShare('1', 4.0, 0.0, 0, 0, 0, 4, 0, 0, 0, 0, 4);
        ValidateCostShare('2', 1.8, 0.0, 0, 0, 0, 1.8, 0, 0, 0, 0, 1.8);
        ValidateCostShare('3', 0.7, 0.0, 0, 0, 0, 0.7, 0, 0, 0, 0, 0.7);
        ValidateCostShare('4', 4.12, 0.0, 0, 0, 0, 4.12, 0, 0, 0, 0, 4.12);
        ValidateCostShare('5', 18.1, 0.0, 0, 0, 0, 18.1, 0, 0, 0, 0, 18.1);
        ValidateCostShare('6', 0.018, 0.0, 0, 0, 0, 0.018, 0, 0, 0, 0, 0.018);
        ValidateCostShare('7', 0.66, 0.0, 0, 0, 0, 0.66, 0, 0, 0, 0, 0.66);
        ValidateCostShare('8', 3.98, 0.0, 0, 0, 0, 3.98, 0, 0, 0, 0, 3.98);
        ValidateCostShare(
          '9', 1.8288, 251.73, 0, 30.26672, 48.1084, 1.8288, 251.73, 0, 30.26672, 48.1084, 331.93392);
        ValidateCostShare(
          '10', 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 26.3824, 26.82, 1.90722, 3.13153, 5.52096, 63.76211);
        ValidateCostShare(
          '11', 452.1584, 1010.86, 32.42274, 222.28489, 199.38012, 1747.82371, 51.46, 0, 108.51544, 9.307, 1917.10615);
    end;

    local procedure CreateWorkCenters()
    var
        WorkCenter: Record "Work Center";
    begin
        InsertWorkCenter(
          '1', 'Floor', '1', 9, 8, 1,
          WorkCenter."Unit Cost Calculation"::Time, false, '', WorkCenter."Flushing Method"::Manual, 'MINUTES');
        InsertWorkCenter(
          '2', 'Service Electronics', '1', 5, 5, 0.3,
          WorkCenter."Unit Cost Calculation"::Time, false, '50000', WorkCenter."Flushing Method"::Manual, 'MINUTES');
    end;

    local procedure InsertWorkCenter(No: Code[20]; WorkCenterName: Text[30]; GroupCode: Code[10]; DirectUnitCost: Decimal; IndirectCost: Decimal; OverheadRate: Decimal; UnitCostCalculation: Enum "Unit Cost Calculation Type"; SpecificUnitCost: Boolean; SubcontractorNo: Code[20]; FlushingMethod: Enum "Flushing Method Routing"; UnitofMeasureCode: Code[10])
    var
        WorkCenter: Record "Work Center";
    begin
        Clear(WorkCenter);
        WorkCenter.Init();
        WorkCenter.Validate("No.", No);
        WorkCenter.Validate(Name, WorkCenterName);
        WorkCenter.Insert(true);
        WorkCenter.Validate("Work Center Group Code", GroupCode);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate("Indirect Cost %", IndirectCost);
        WorkCenter.Validate("Overhead Rate", OverheadRate);
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalculation);
        WorkCenter.Validate("Specific Unit Cost", SpecificUnitCost);
        WorkCenter.Validate("Subcontractor No.", SubcontractorNo);
        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Unit of Measure Code", UnitofMeasureCode);
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachCenters()
    var
        MachineCenter: Record "Machine Center";
    begin
        InsertMachCenter('1', 'Mr. Goodman', '1', false, 1.5, 10, 0.1, MachineCenter."Flushing Method"::Manual);
        InsertMachCenter('2', 'Mrs. Puyt', '1', false, 1.5, 10, 0.07, MachineCenter."Flushing Method"::Manual);
        InsertMachCenter('3', 'Mr. Howles', '1', false, 1.8, 10, 0.08, MachineCenter."Flushing Method"::Manual);
    end;

    local procedure InsertMachCenter(No: Code[20]; MachineCenterName: Text[30]; WorkCenterNo: Code[10]; WorkCenterBlocked: Boolean; DirectUnitCost: Decimal; IndirectCost: Decimal; OverheadRate: Decimal; FlushingMethod: Enum "Flushing Method Routing")
    var
        MachineCenter: Record "Machine Center";
    begin
        Clear(MachineCenter);
        MachineCenter.Init();
        MachineCenter.Validate("No.", No);
        MachineCenter.Insert(true);
        MachineCenter.Validate(Name, MachineCenterName);
        MachineCenter.Validate("Work Center No.", WorkCenterNo);
        MachineCenter.Validate(Blocked, WorkCenterBlocked);
        MachineCenter.Validate("Direct Unit Cost", DirectUnitCost);
        MachineCenter.Validate("Indirect Cost %", IndirectCost);
        MachineCenter.Validate("Overhead Rate", OverheadRate);
        MachineCenter.Validate("Flushing Method", FlushingMethod);
        MachineCenter.Modify(true);
    end;

    local procedure UpdateMachCenter(No: Code[10]; DirectUnitCost: Decimal)
    var
        MachineCenter: Record "Machine Center";
    begin
        MachineCenter.Get(No);
        MachineCenter.Validate("Direct Unit Cost", DirectUnitCost);
        MachineCenter.Modify(true);
    end;

    local procedure CreateRoutings()
    var
        RtngHeader: Record "Routing Header";
    begin
        CRPUtil.InsertRtngHeader('1', RtngHeader);
        InsertRntgLine('1', '', '11', '1', '');
        InsertRntgLine('1', '', '12', '', '1');
        InsertRntgLine('1', '', '13', '', '2');

        CRPUtil.InsertRtngHeader('2', RtngHeader);
        InsertRntgLine('2', '', '21', '1', '');
        InsertRntgLine('2', '', '22', '', '3');
        InsertRntgLine('2', '', '23', '1', '');

        CRPUtil.InsertRtngHeader('3', RtngHeader);
        InsertRntgLine('3', '', '31', '2', '');
        InsertRntgLine('3', '', '32', '1', '');

        UpdateRtngSetupAndRunTime('1', '', '11', 1, 'MINUTES', 6, 'MINUTES');
        UpdateRtngSetupAndRunTime('1', '', '12', 1, 'MINUTES', 10, 'MINUTES');
        UpdateRtngSetupAndRunTime('1', '', '13', 1, 'MINUTES', 3, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '21', 1, 'MINUTES', 11, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '22', 1, 'MINUTES', 3, 'MINUTES');
        UpdateRtngSetupAndRunTime('2', '', '23', 0.5, 'MINUTES', 4, 'MINUTES');
        UpdateRtngSetupAndRunTime('3', '', '31', 3, 'MINUTES', 6, 'MINUTES');
        UpdateRtngSetupAndRunTime('3', '', '32', 1, 'MINUTES', 4, 'MINUTES');
    end;

    local procedure InsertRntgLine(RtngNo: Code[20]; VersionCode: Code[10]; OperationNo: Code[10]; WorkCenterNo: Code[20]; MachineCenterNo: Code[20])
    var
        RtngLine: Record "Routing Line";
    begin
        CRPUtil.InsertRntgLine(RtngNo, VersionCode, OperationNo, RtngLine);
        if WorkCenterNo <> '' then begin
            RtngLine.Validate(Type, RtngLine.Type::"Work Center");
            RtngLine.Validate("No.", WorkCenterNo);
        end else begin
            RtngLine.Validate(Type, RtngLine.Type::"Machine Center");
            RtngLine.Validate("No.", MachineCenterNo);
        end;
        RtngLine.Modify(true);
    end;

    local procedure UpdateRtngSetupAndRunTime(RoutingNo: Code[20]; VersionCode: Code[20]; OperationNo: Code[20]; SetupTime: Decimal; SetupTimeUOM: Code[20]; RunTime: Decimal; RunTimeUOM: Code[20])
    var
        RtngLine: Record "Routing Line";
    begin
        CRPUtil.UncertifyRouting(RoutingNo, '');
        RtngLine.Get(RoutingNo, VersionCode, OperationNo);
        RtngLine.Validate("Setup Time", SetupTime);
        RtngLine.Validate("Setup Time Unit of Meas. Code", SetupTimeUOM);
        RtngLine.Validate("Run Time", RunTime);
        RtngLine.Validate("Run Time Unit of Meas. Code", RunTimeUOM);
        RtngLine.Modify(true);
        CRPUtil.CertifyRouting(RoutingNo, '');
    end;

    local procedure UpdateRtngLinkCodeAndScrap(RoutingNo: Code[20]; VersionCode: Code[20]; OperationNo: Code[20]; RoutingLinkCode: Code[20]; FixedScrapQty: Decimal; ScrapFactorPct: Decimal)
    var
        RtngLine: Record "Routing Line";
    begin
        CRPUtil.UncertifyRouting(RoutingNo, VersionCode);
        RtngLine.Get(RoutingNo, VersionCode, OperationNo);
        RtngLine.Validate("Routing Link Code", RoutingLinkCode);
        RtngLine.Validate("Fixed Scrap Quantity", FixedScrapQty);
        RtngLine.Validate("Scrap Factor %", ScrapFactorPct);
        RtngLine.Modify(true);
        CRPUtil.CertifyRouting(RoutingNo, VersionCode);
    end;

    local procedure CreateItems()
    var
        Item: Record Item;
        UnitOfMeasure: Record "Unit of Measure";
    begin
        InsertItem('1', Item, 'PCS');
        Item.Validate(Description, 'Glass Container');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 5);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 25);
        Item.Validate("Rounding Precision", 0.01);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Indirect Cost %", 2);
        Item.Modify(true);

        InsertItem('2', Item, 'PCS');
        Item.Validate(Description, 'Plastic Lid');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 2);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 100);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Overhead Rate", 0.01);
        Item.Validate("Indirect Cost %", 3);
        Item.Modify(true);

        InsertItem('3', Item, 'PCS');
        Item.Validate(Description, 'Steel Blade Part');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 0.7);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 200);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Indirect Cost %", 2);
        Item.Modify(true);

        InsertItem('4', Item, 'PCS');
        Item.Validate(Description, 'Casting');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 4.34);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 10);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Overhead Rate", 0.02);
        Item.Validate("Indirect Cost %", 2);
        Item.Modify(true);

        InsertItem('5', Item, 'PCS');
        Item.Validate(Description, 'Motor');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 18.9);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 5);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Overhead Rate", 0.11);
        Item.Modify(true);

        InsertItem('6', Item, 'PCS');
        Item.Validate(Description, 'Fuse');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 0.02);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 1000);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Indirect Cost %", 1);
        Item.Modify(true);

        InsertItem('7', Item, 'PCS');
        Item.Validate(Description, 'Switch');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 0.7);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 25);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Modify(true);

        InsertItem('8', Item, 'CM');
        Item.Validate(Description, 'El. Cord');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", 0.04);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Validate("Lot Size", 1000);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Indirect Cost %", 2);
        Item.Modify(true);

        InsertItem('9', Item, 'PCS');
        Item.Validate(Description, 'Pitcher');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Lot Size", 10);
        Item.Validate("Routing No.", '2');
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Overhead Rate", 0.1);
        Item.Validate("Indirect Cost %", 10);
        Item.Modify(true);

        InsertItem('10', Item, 'PCS');
        Item.Validate(Description, 'Blender Base');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Lot Size", 10);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Overhead Rate", 0.1);
        Item.Validate("Indirect Cost %", 5);
        Item.Modify(true);

        InsertItem('11', Item, 'PCS');
        Item.Validate(Description, 'Blender');
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Lot Size", 10);
        Item.Validate("Rounding Precision", 1);
        Item.Validate("Flushing Method", Item."Flushing Method"::Manual);
        Item.Validate("Indirect Cost %", 6);
        Item.Modify(true);

        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, 'M');
        if UnitOfMeasure.Insert(true) then;
    end;

    local procedure InsertItem(ItemNo: Code[20]; var Item: Record Item; BaseUOM: Code[20])
    begin
        Clear(Item);
        Item.Init();
        Item.Validate("No.", ItemNo);
        Item.Insert(true);

        INVTUtil.InsertItemUOM(ItemNo, BaseUOM, 1);
        Item.Validate("Base Unit of Measure", BaseUOM);
        Item.Modify(true);
    end;

    local procedure UpdateItemLotSize(ItemNo: Code[20]; LotSize: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
    end;

    local procedure UpdateItemStdCost(ItemNo: Code[20]; StdCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Standard Cost", StdCost);
        Item.Modify(true);
    end;

    local procedure UpdateItemScrapPct(ItemNo: Code[20]; ScrapPct: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Scrap %", ScrapPct);
        Item.Modify(true);
    end;

    local procedure CreatePBOMs()
    var
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMComponent: Record "Production BOM Line";
    begin
        MFGUtil.InsertPBOMHeader('1', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '9', '', 1, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '10', '', 1, false);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '6', '', 1, false);

        MFGUtil.InsertPBOMHeader('2', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '1', '', 1, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '2', '', 1, false);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '3', '', 4, false);

        MFGUtil.InsertPBOMHeader('3', ProdBOMHeader);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '4', '', 1, true);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '5', '', 1, false);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '6', '', 1, false);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '7', '', 1, false);
        MFGUtil.InsertPBOMComponent(ProdBOMComponent, ProdBOMHeader."No.", '', 0D, '8', '', 88, false);
    end;

    local procedure UpdatePBOMQtyAndUOM(PBOMNo: Code[20]; PBOMLineNo: Integer; QtyPer: Decimal; UOMCode: Code[20])
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        MFGUtil.UncertifyPBOM(PBOMNo, '');
        ProdBOMLine.Get(PBOMNo, '', PBOMLineNo);
        ProdBOMLine.Validate(ProdBOMLine."Quantity per", QtyPer);
        ProdBOMLine.Validate(ProdBOMLine."Unit of Measure Code", UOMCode);
        ProdBOMLine.Modify(true);
        MFGUtil.CertifyPBOM(PBOMNo, '');
    end;

    local procedure UpdatePBOMLinkCodeScrap(PBOMNo: Code[20]; PBOMLineNo: Integer; PBOMVersionCode: Code[20]; RoutingLinkCode: Code[20]; ScrapPct: Decimal)
    var
        ProdBOMLine: Record "Production BOM Line";
    begin
        MFGUtil.UncertifyPBOM(PBOMNo, PBOMVersionCode);
        ProdBOMLine.Get(PBOMNo, PBOMVersionCode, PBOMLineNo);
        ProdBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProdBOMLine.Validate("Scrap %", ScrapPct);
        ProdBOMLine.Modify(true);
        MFGUtil.CertifyPBOM(PBOMNo, PBOMVersionCode);
    end;

    local procedure ConnectPBOMAndRoutings()
    var
        Item: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        RtngHeader: Record "Routing Header";
    begin
        Item.Get('11');
        ProdBOMHeader.Get('1');
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);
        RtngHeader.Get('1');
        CRPUtil.CertifyRtngAndConnectToItem(RtngHeader, Item);

        Item.Get('9');
        ProdBOMHeader.Get('2');
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);
        RtngHeader.Get('2');
        CRPUtil.CertifyRtngAndConnectToItem(RtngHeader, Item);

        Item.Get('10');
        ProdBOMHeader.Get('3');
        MFGUtil.CertifyPBOMAndConnectToItem(ProdBOMHeader, Item);
        RtngHeader.Get('3');
        CRPUtil.CertifyRtngAndConnectToItem(RtngHeader, Item);
    end;

    local procedure ValidateCostShare(ItemNo: Code[20]; RUMat: Decimal; RUCap: Decimal; RUSub: Decimal; RUMfgOvhd: Decimal; RUCapOvhd: Decimal; SLMat: Decimal; SLCap: Decimal; SLSub: Decimal; SLMfgOvhd: Decimal; SLCapOvhd: Decimal; StdCost: Decimal)
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Rolled-up Material Cost")),
          Item."Rolled-up Material Cost", RUMat);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Rolled-up Capacity Cost")),
          Item."Rolled-up Capacity Cost", RUCap);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Rolled-up Subcontracted Cost")),
          Item."Rolled-up Subcontracted Cost", RUSub);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Rolled-up Cap. Overhead Cost")),
          Item."Rolled-up Cap. Overhead Cost", RUCapOvhd);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Rolled-up Mfg. Ovhd Cost")),
          Item."Rolled-up Mfg. Ovhd Cost", RUMfgOvhd);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Single-Level Material Cost")),
          Item."Single-Level Material Cost", SLMat);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Single-Level Capacity Cost")),
          Item."Single-Level Capacity Cost", SLCap);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Single-Level Subcontrd. Cost")),
          Item."Single-Level Subcontrd. Cost", SLSub);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Single-Level Cap. Ovhd Cost")),
          Item."Single-Level Cap. Ovhd Cost", SLCapOvhd);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Single-Level Mfg. Ovhd Cost")),
          Item."Single-Level Mfg. Ovhd Cost", SLMfgOvhd);

        TestscriptMgt.TestNumberValue(
          StrSubstNo('%1 - %2 %3', CurrTest, Item."No.", Item.FieldName("Standard Cost")),
          Item."Standard Cost", StdCost);
    end;

    [Scope('OnPrem')]
    procedure CalcStdCost(ItemNo: Code[20]; CalcDate: Date)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        CalcStdCost: Codeunit "Calculate Standard Cost";
        ItemCostMgt: Codeunit ItemCostManagement;
    begin
        Item.SetRange("No.", ItemNo);
        CalcStdCost.SetProperties(CalcDate, true, false, false, '', true);
        CalcStdCost.CalcItems(Item, TempItem);

        if TempItem.Find('-') then
            repeat
                ItemCostMgt.UpdateStdCostShares(TempItem);
            until TempItem.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure SetShowTestResuts(NewShowTestResuts: Boolean)
    begin
        ShowTestResuts := NewShowTestResuts;
    end;
}

