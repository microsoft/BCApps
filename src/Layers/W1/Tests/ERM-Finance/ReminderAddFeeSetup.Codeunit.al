codeunit 134998 "Reminder - Add. Fee Setup"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    Permissions = TableData "Feature Data Update Status" = rimd;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Additional Fee]
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;
        Commit();
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedAddFeeAmountErr: Label 'Unexpected Additional Fee Amount. Expected %1, Actual %2.';
        AddFeeCalculationType: Option "Fixed","Single Dynamic","Accumulated Dynamic";
        CaptionErr: Label 'Page Captions must match.';
        ReminderTermsTxt: Label 'Reminder Terms:';
        ReminderLevelTxt: Label 'Level:';
        AddFeePerLineTxt: Label 'Additional Fee Setup - Additional Fee per Line Setup -';

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicRemAmtLessThanThresholdRemAmt()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] Remaining amount is less than Threshold Remaining Amount defined in Additional Fee Setup
        // and Calculation Type is Accumulated Dynamic then Add. Fee Amount = 0
        Initialize();

        // [GIVEN] Remaining Amount less than Threshold Remaining Amount
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        RemainingAmount := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, RemainingAmount + 1, '', false, AddFeeCalculationType);

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);

        // [THEN] Add. Fee is 0
        Assert.AreEqual(0, AddFeeAmount, StrSubstNo(UnexpectedAddFeeAmountErr, 0, AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicAddFeeFixedFeeAmount()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains Additional Fee Amount >0 and Additional Fee % = 0
        // and Calculation Type is Accumulated Dynamic then calculated amount is Additional Fee Amount
        Initialize();

        // [GIVEN] Additional Fee Setup conatins Additional Fee Amount <>0 and Additional Fee % = 0
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup + 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] then calculated amount is Additional Fee Amount defined in Add. Fee Setup
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicAddFeePercentage()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeePerc: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains Additional Fee Amount  = 0 and Additional Fee % > 0
        // and Calculation Type is Accumulated Dynamic then Add. Fee calculation is based on Additional Fee %
        Initialize();

        // [GIVEN] Additional Fee Setup conatins Additional Fee Amount = 0 and Additional Fee % > 0
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        RemainingAmount := LibraryRandom.RandDec(99, 2);
        AddFeePerc := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeePerc * RemainingAmount,// Max. Add. Fee Amount
          0,// Add. Fee Amount
          AddFeePerc);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);

        // [THEN] then calculated amount is Remaining Amount multiplied by Additional Fee %
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee %" * RemainingAmount / 100, AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicAddFeeAmountLessThanMin()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is less than Min. Add. Fee Amount
        // and Calculation Type is Accumulated Dynamic then calculated amount is equal to Min. Add. Fee Amount
        Initialize();

        // [GIVEN] Additional Fee Amount defined by Additional Fee Setup is less than Min. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);

        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          AddFeeAmountSetup + 1,// Min. Add. Fee Amount
          0,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // then calculated amount is equal to Min. Add. Fee Amount
        Assert.AreEqual(AddFeeAmountSetup + 1, AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountSetup + 1, AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicAddFeeAmountEqualToMin()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is equal to Min. Add. Fee Amount
        // and Calculation Type is Accumulated Dynamic then calculated amount is 0
        Initialize();

        // [GIVEN] Additional Fee Amount defined by Additional Fee Setup is equal to Min. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);

        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          AddFeeAmountSetup,// Min. Add. Fee Amount
          AddFeeAmountSetup + 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] Add. Fee is Min. Add. Fee Amount
        Assert.AreEqual(AddFeeAmountSetup, AddFeeAmount, StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountSetup, AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicAddFeeAmountBiggerThanMax()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is bigger than Max. Add. Fee Amount
        // and Calculation Type is Accumulated Dynamic then calculated amount is equal to Max. Add. Fee Amount
        Initialize();

        // [GIVEN] When Additional Fee Amount calculated from Additional Fee Setup is bigger than Max. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup - 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] calculated Add. Fee Amount is equal to Max. Add. Fee Amount
        Assert.AreEqual(AdditionalFeeSetup."Max. Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicAddFeeAmountEqualToMax()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is equal to Max. Add. Fee Amount
        // and Calculation Type is Accumulated Dynamic then calculated amount is equal to Max. Add. Fee Amount
        Initialize();

        // [GIVEN] When Additional Fee Amount calculated from Additional Fee Setup is equal to Max. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] calculated Add. Fee Amount is equal to Max. Add. Fee Amount
        Assert.AreEqual(AdditionalFeeSetup."Max. Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicAddFixedFeeAmountFeePercentageSum()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmountActual: Decimal;
        AddFeeAmountExpected: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains Additional Fee Amount  > 0 and Additional Fee % > 0
        // and Calculation Type is Accumulated Dynamic then Add. Fee calculation is sum of Additional Fee Amount
        // and "Additional Fee %" * RemainingAmount / 100
        Initialize();

        // [GIVEN] Additional Fee Setup conatins Additional Fee Amount > 0 and Additional Fee % > 0
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        RemainingAmount := LibraryRandom.RandDec(99, 2);

        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          100 * RemainingAmount,// Max. Add. Fee Amount
          LibraryRandom.RandDec(100, 2),// Add. Fee Amount
          LibraryRandom.RandDec(99, 2));// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmountActual := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);
        AddFeeAmountExpected :=
          (AdditionalFeeSetup."Additional Fee %" * RemainingAmount / 100) + AdditionalFeeSetup."Additional Fee Amount";

        // [THEN] then calculated amount is Remaining Amount multiplied by Additional Fee %
        Assert.AreEqual(
          AddFeeAmountExpected, AddFeeAmountActual, StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountExpected, AddFeeAmountActual));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicMultipleAmountRanges()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AdditionalFeeSetup1: Record "Additional Fee Setup";
        AdditionalFeeSetup2: Record "Additional Fee Setup";
        AddFeeAmountActual: Decimal;
        AddFeeAmountExpected: Decimal;
        RangeAmount2: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains multiple amount ranges with Additional Fee Amount  > 0 and Additional Fee % > 0
        // and Calculation Type is Accumulated Dynamic then Add. Fee calculation is based on amount ranges
        Initialize();

        // [GIVEN] When Additional Fee Setup contains multiple amount ranges with Additional Fee Amount  > 0 and Additional Fee % > 0
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        RemainingAmount := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup1, 0, '', false, AddFeeCalculationType);

        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup1,
          0,// Min. Add. Fee Amount
          100 * RemainingAmount,// Max. Add. Fee Amount
          LibraryRandom.RandDec(100, 2),// Add. Fee Amount
          LibraryRandom.RandDec(99, 2));// Add. Fee Perc

        RangeAmount2 := LibraryRandom.RandDec(99, 2);

        AdditionalFeeSetup2.Init();
        AdditionalFeeSetup2."Charge Per Line" := AdditionalFeeSetup1."Charge Per Line";
        AdditionalFeeSetup2."Reminder Terms Code" := AdditionalFeeSetup1."Reminder Terms Code";
        AdditionalFeeSetup2."Reminder Level No." := AdditionalFeeSetup1."Reminder Level No.";
        AdditionalFeeSetup2."Currency Code" := AdditionalFeeSetup1."Currency Code";
        AdditionalFeeSetup2."Threshold Remaining Amount" := RangeAmount2;
        AdditionalFeeSetup2."Max. Additional Fee Amount" := 100 * RemainingAmount;
        AdditionalFeeSetup2."Additional Fee Amount" := LibraryRandom.RandDec(100, 2);
        AdditionalFeeSetup2."Additional Fee %" := LibraryRandom.RandDec(99, 2);
        AdditionalFeeSetup2.Insert(true);

        AdditionalFeeSetup.SetRange("Reminder Terms Code", AdditionalFeeSetup1."Reminder Terms Code");
        AdditionalFeeSetup.FindFirst();

        // [WHEN] Add. Fee is calculated
        AddFeeAmountActual := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);
        AddFeeAmountExpected :=
          (AdditionalFeeSetup1."Additional Fee %" * AdditionalFeeSetup2."Threshold Remaining Amount" / 100) +
          AdditionalFeeSetup1."Additional Fee Amount" +
          (AdditionalFeeSetup2."Additional Fee %" * (RemainingAmount - AdditionalFeeSetup2."Threshold Remaining Amount") / 100) +
          AdditionalFeeSetup2."Additional Fee Amount";

        // [THEN] then Add. Fee calculation is based on amount ranges
        Assert.AreEqual(
          AddFeeAmountExpected, AddFeeAmountActual, StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountExpected, AddFeeAmountActual));

        // Tear down
        AdditionalFeeSetup1.Delete(true);
        AdditionalFeeSetup2.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicCurrencyCodeNotEmpty()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeePerc: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains record with Currency Code <> ''
        // and Calculation Type is Accumulated Dynamic then Add. Fee calculation is based on that record
        Initialize();

        // [GIVEN] When Additional Fee Setup contains record with Currency Code <> ''
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        RemainingAmount := LibraryRandom.RandDec(99, 2);
        AddFeePerc := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, LibraryERM.CreateCurrencyWithRandomExchRates(), false, AddFeeCalculationType);

        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeePerc * RemainingAmount,// Max. Add. Fee Amount
          0,// Add. Fee Amount
          AddFeePerc);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);

        // [THEN] then calculated amount is based on Add. Fee Setup with defined Currency Code
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee %" * RemainingAmount / 100, AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AccumulatedDynamicChargePerLine()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When calculation requires Additional Fee per Line
        // and Calculation Type is Accumulated Dynamic then calculation will be based only on record with Charge per Line = TRUE
        Initialize();

        // [GIVEN] Additional Fee Setup conatins record with Charge per Line = TRUE
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', true, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup + 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] then calculation will be based only on record with Charge per Line = TRUE
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicRemAmtLessThanThresholdRemAmt()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] Remaining amount is less than Threshold Remaining Amount defined in Additional Fee Setup
        // and Calculation Type is Single Dynamic then Add. Fee Amount = 0
        Initialize();

        // [GIVEN] Remaining Amount less than Threshold Remaining Amount
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        RemainingAmount := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, RemainingAmount + 1, '', false, AddFeeCalculationType);

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);

        // [THEN] Add. Fee is 0
        Assert.AreEqual(0, AddFeeAmount, StrSubstNo(UnexpectedAddFeeAmountErr, 0, AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicAddFeeFixedFeeAmount()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains Additional Fee Amount > 0 and Additional Fee % = 0
        // and Calculation Type is Single Dynamic then calculated amount is Additional Fee Amount
        Initialize();

        // [GIVEN] Additional Fee Setup conatins Additional Fee Amount <>0 and Additional Fee % = 0
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup + 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] then calculated amount is Additional Fee Amount defined in Add. Fee Setup
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicAddFeePercentage()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeePerc: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains Additional Fee Amount  = 0 and Additional Fee % > 0
        // and Calculation Type is Single Dynamic then Add. Fee calculation is equal to Remaining Amount * Additional Fee %/100
        Initialize();

        // [GIVEN] Additional Fee Setup conatins Additional Fee Amount = 0 and Additional Fee % > 0
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        RemainingAmount := LibraryRandom.RandDec(99, 2);
        AddFeePerc := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeePerc * RemainingAmount,// Max. Add. Fee Amount
          0,// Add. Fee Amount
          AddFeePerc);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);

        // [THEN] then calculated amount is Remaining Amount multiplied by Additional Fee %
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee %" * RemainingAmount / 100, AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicAddFeeAmountLessThanMin()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is less than Min. Add. Fee Amount
        // and Calculation Type is Single Dynamic then calculated amount is equal to Min. Add. Fee Amount
        Initialize();

        // [GIVEN] Additional Fee Amount defined by Additional Fee Setup is less than Min. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);

        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          AddFeeAmountSetup + 1,// Min. Add. Fee Amount
          0,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // then calculated amount is equal to Min. Add. Fee Amount
        Assert.AreEqual(AddFeeAmountSetup + 1, AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountSetup + 1, AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicAddFeeAmountEqualToMin()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is equal to Min. Add. Fee Amount
        // and Calculation Type is Single Dynamic then calculated amount is Min. Add. Fee Amount
        Initialize();

        // [GIVEN] Additional Fee Amount defined by Additional Fee Setup is equal to Min. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);

        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          AddFeeAmountSetup,// Min. Add. Fee Amount
          AddFeeAmountSetup + 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] Add. Fee is Min. Add. Fee Amount
        Assert.AreEqual(AddFeeAmountSetup, AddFeeAmount, StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountSetup, AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicAddFeeAmountBiggerThanMax()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is bigger than Max. Add. Fee Amount
        // and Calculation Type is Single Dynamic then calculated amount is equal to Max. Add. Fee Amount
        Initialize();

        // [GIVEN] When Additional Fee Amount calculated from Additional Fee Setup is bigger than Max. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup - 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] calculated Add. Fee Amount is equal to Max. Add. Fee Amount
        Assert.AreEqual(AdditionalFeeSetup."Max. Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicAddFeeAmountEqualToMax()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Amount calculated from Additional Fee Setup is equal to Max. Add. Fee Amount
        // and Calculation Type is Single Dynamic then calculated amount is equal to Max. Add. Fee Amount
        Initialize();

        // [GIVEN] When Additional Fee Amount calculated from Additional Fee Setup is equal to Max. Add. Fee Amount
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] calculated Add. Fee Amount is equal to Max. Add. Fee Amount
        Assert.AreEqual(AdditionalFeeSetup."Max. Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicAddFixedFeeAmountFeePercentageSum()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmountActual: Decimal;
        AddFeeAmountExpected: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains Additional Fee Amount  > 0 and Additional Fee % > 0
        // and Calculation Type is Single Dynamic then Add. Fee calculation is sum of Add Fee Amount
        // and "Additional Fee %" * RemainingAmount / 100 from that Amount Range
        Initialize();

        // [GIVEN] Additional Fee Setup conatins Additional Fee Amount > 0 and Additional Fee % > 0
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        RemainingAmount := LibraryRandom.RandDec(99, 2);

        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          100 * RemainingAmount,// Max. Add. Fee Amount
          LibraryRandom.RandDec(100, 2),// Add. Fee Amount
          LibraryRandom.RandDec(99, 2));// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmountActual := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);
        AddFeeAmountExpected :=
          (AdditionalFeeSetup."Additional Fee %" * RemainingAmount / 100) + AdditionalFeeSetup."Additional Fee Amount";

        // [THEN] then calculated amount is sum of Add Fee Amount and "Additional Fee %" * RemainingAmount / 100 from that Amount Range
        Assert.AreEqual(
          AddFeeAmountExpected, AddFeeAmountActual, StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountExpected, AddFeeAmountActual));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicMultipleAmountRanges()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AdditionalFeeSetup1: Record "Additional Fee Setup";
        AdditionalFeeSetup2: Record "Additional Fee Setup";
        AddFeeAmountActual: Decimal;
        AddFeeAmountExpected: Decimal;
        RangeAmount2: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains multiple amount ranges with Additional Fee Amount  > 0 and Additional Fee % > 0
        // and Calculation Type is Single Dynamic then Add. Fee calculation is based on chosen amount range
        Initialize();

        // [GIVEN] When Additional Fee Setup contains multiple amount ranges with Additional Fee Amount  > 0 and Additional Fee % > 0
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        RemainingAmount := LibraryRandom.RandDecInDecimalRange(100, 200, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup1, 0, '', false, AddFeeCalculationType);

        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup1,
          0,// Min. Add. Fee Amount
          100 * RemainingAmount,// Max. Add. Fee Amount
          LibraryRandom.RandDec(100, 2),// Add. Fee Amount
          LibraryRandom.RandDec(99, 2));// Add. Fee Perc

        RangeAmount2 := LibraryRandom.RandDec(99, 2);

        AdditionalFeeSetup2.Init();
        AdditionalFeeSetup2."Charge Per Line" := AdditionalFeeSetup1."Charge Per Line";
        AdditionalFeeSetup2."Reminder Terms Code" := AdditionalFeeSetup1."Reminder Terms Code";
        AdditionalFeeSetup2."Reminder Level No." := AdditionalFeeSetup1."Reminder Level No.";
        AdditionalFeeSetup2."Currency Code" := AdditionalFeeSetup1."Currency Code";
        AdditionalFeeSetup2."Threshold Remaining Amount" := RangeAmount2;
        AdditionalFeeSetup2."Max. Additional Fee Amount" := 100 * RemainingAmount;
        AdditionalFeeSetup2."Additional Fee Amount" := LibraryRandom.RandDec(100, 2);
        AdditionalFeeSetup2."Additional Fee %" := LibraryRandom.RandDec(99, 2);
        AdditionalFeeSetup2.Insert(true);

        AdditionalFeeSetup.SetRange("Reminder Terms Code", AdditionalFeeSetup1."Reminder Terms Code");
        AdditionalFeeSetup.FindFirst();

        // [WHEN] Add. Fee is calculated
        AddFeeAmountActual := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);
        AddFeeAmountExpected :=
          (AdditionalFeeSetup2."Additional Fee %" * RemainingAmount / 100) +
          AdditionalFeeSetup2."Additional Fee Amount";

        // [THEN] then Add. Fee calculation is based on amount ranges
        Assert.AreEqual(
          AddFeeAmountExpected, AddFeeAmountActual, StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountExpected, AddFeeAmountActual));

        // Tear down
        AdditionalFeeSetup1.Delete(true);
        AdditionalFeeSetup2.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicCurrencyCodeNotEmpty()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeePerc: Decimal;
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] When Additional Fee Setup contains record with Currency Code <> ''
        // and Calculation Type is Single Dynamic then Add. Fee calculation is based on that record
        Initialize();

        // [GIVEN] When Additional Fee Setup contains record with Currency Code <> ''
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        RemainingAmount := LibraryRandom.RandDec(99, 2);
        AddFeePerc := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, LibraryERM.CreateCurrencyWithRandomExchRates(), false, AddFeeCalculationType);

        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeePerc * RemainingAmount,// Max. Add. Fee Amount
          0,// Add. Fee Amount
          AddFeePerc);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, RemainingAmount);

        // [THEN] then calculated amount is based on Add. Fee Setup with defined Currency Code
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee %" * RemainingAmount / 100, AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleDynamicChargePerLine()
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
        AddFeeAmount: Decimal;
        AddFeeAmountSetup: Decimal;
    begin
        // [SCENARIO 107048] When calculation requires Additional Fee per Line
        // and Calculation Type is Dynamic then calculation will be based only on record with Charge per Line = TRUE
        Initialize();

        // [GIVEN] Additional Fee Setup conatins record with Charge per Line = TRUE
        AddFeeCalculationType := AddFeeCalculationType::"Single Dynamic";
        AddFeeAmountSetup := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', true, AddFeeCalculationType);
        SetUpAdditionalFeePropertiesUT(AdditionalFeeSetup,
          0,// Min. Add. Fee Amount
          AddFeeAmountSetup + 1,// Max. Add. Fee Amount
          AddFeeAmountSetup,// Add. Fee Amount
          0);// Add. Fee Perc

        // [WHEN] Add. Fee is calculated
        AddFeeAmount := CalculateAddFeeFromSetupUT(AdditionalFeeSetup, LibraryRandom.RandDec(100, 2));

        // [THEN] then calculation will be based only on record with Charge per Line = TRUE
        Assert.AreEqual(AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AdditionalFeeSetup."Additional Fee Amount", AddFeeAmount));

        // Tear down
        AdditionalFeeSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedFeeChargePerLineFalse()
    var
        ReminderLevel: Record "Reminder Level";
        AddFeeAmountCalculated: Decimal;
    begin
        // [SCENARIO 107048] When Reminder Level contains Additional Fee Amount > 0
        // and Post Additional Fee = TRUE and Calculation Type is Fixed
        // then calculated amount is Additional Fee Amount
        Initialize();

        // [GIVEN] When Reminder Level contains Additional Fee (LCY) Amount > 0
        AddFeeCalculationType := AddFeeCalculationType::Fixed;
        CreateReminderTermsAndLevel(ReminderLevel, true, true, AddFeeCalculationType);
        ReminderLevel."Additional Fee (LCY)" := LibraryRandom.RandDec(100, 2);
        ReminderLevel.Modify(true);

        // [WHEN] Add. Fee is calculated
        AddFeeAmountCalculated := ReminderLevel.GetAdditionalFee(LibraryRandom.RandDec(100, 2),
            '', false, Today);

        // [THEN] then calculated amount is Additional Fee (LCY) Amount
        Assert.AreEqual(ReminderLevel."Additional Fee (LCY)", AddFeeAmountCalculated,
          StrSubstNo(UnexpectedAddFeeAmountErr, ReminderLevel."Additional Fee (LCY)", AddFeeAmountCalculated));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedFeeChargePerLineTrue()
    var
        ReminderLevel: Record "Reminder Level";
        AddFeeAmountCalculated: Decimal;
    begin
        // [SCENARIO 107048] When Reminder Level contains Additional Fee per Line Amount > 0
        // and Post Additional Fee per Line  = TRUE
        // and Calculation Type is Fixed then calculated amount is Additional Fee per Line Amount
        Initialize();

        // [GIVEN] When Reminder Level contains Additional Fee Amount > 0
        AddFeeCalculationType := AddFeeCalculationType::Fixed;
        CreateReminderTermsAndLevel(ReminderLevel, true, true, AddFeeCalculationType);
        ReminderLevel."Add. Fee per Line Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        ReminderLevel.Modify(true);

        // [WHEN] Add. Fee is calculated
        AddFeeAmountCalculated := ReminderLevel.GetAdditionalFee(LibraryRandom.RandDec(100, 2),
            '', true, Today);

        // [THEN] then calculated amount is Additional Fee Amount defined in Add. Fee Setup
        Assert.AreEqual(ReminderLevel."Add. Fee per Line Amount (LCY)", AddFeeAmountCalculated,
          StrSubstNo(UnexpectedAddFeeAmountErr, ReminderLevel."Add. Fee per Line Amount (LCY)", AddFeeAmountCalculated));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedFeeChargePerLineFalseFCY()
    var
        Currency: Record Currency;
        ReminderLevel: Record "Reminder Level";
        AddFeeAmount: Decimal;
        AddFeeAmountCalculated: Decimal;
    begin
        // [SCENARIO 107048] When Reminder Level contains Currency for Reminder Level record
        // and Post Additional Fee = TRUE and Calculation Type is Fixed
        // then calculated amount is Additional Fee Amount in FCY
        Initialize();

        // [GIVEN] When Reminder Level contains Additional Fee (LCY) Amount record
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        AddFeeCalculationType := AddFeeCalculationType::Fixed;
        AddFeeAmount := LibraryRandom.RandDec(100, 2);
        CreateReminderTermsAndLevel(ReminderLevel, true, true, AddFeeCalculationType);
        CreateCurrencyForReminderLevel(ReminderLevel, Currency.Code, AddFeeAmount, 0);

        // [WHEN] Add. Fee is calculated
        AddFeeAmountCalculated := ReminderLevel.GetAdditionalFee(LibraryRandom.RandDec(100, 2),
            Currency.Code, false, Today);

        // [THEN] then calculated amount is Additional Fee (FCY) Amount
        Assert.AreEqual(AddFeeAmountCalculated, AddFeeAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountCalculated, AddFeeAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixedFeeChargePerLineTrueFCY()
    var
        Currency: Record Currency;
        ReminderLevel: Record "Reminder Level";
        AddFeePerLineAmount: Decimal;
        AddFeeAmountCalculated: Decimal;
    begin
        // [SCENARIO 107048] When Reminder Level contains Currency for Reminder Level
        // and Post Additional Fee per Line = TRUE and Calculation Type is Fixed
        // then calculated amount is Additional Fee per Line Amount in FCY
        Initialize();

        // [GIVEN] When Reminder Level contains Currency for Reminder Level
        Currency.Get(LibraryERM.CreateCurrencyWithRandomExchRates());
        AddFeeCalculationType := AddFeeCalculationType::Fixed;
        AddFeePerLineAmount := LibraryRandom.RandDec(100, 2);
        CreateReminderTermsAndLevel(ReminderLevel, true, true, AddFeeCalculationType);
        CreateCurrencyForReminderLevel(ReminderLevel, Currency.Code, 0, AddFeePerLineAmount);

        // [WHEN] Add. Fee is calculated
        AddFeeAmountCalculated := ReminderLevel.GetAdditionalFee(LibraryRandom.RandDec(100, 2),
            Currency.Code, true, Today);

        // [THEN] then calculated amount is Additional Fee per Line Amount in FCY
        Assert.AreEqual(AddFeeAmountCalculated, AddFeePerLineAmount,
          StrSubstNo(UnexpectedAddFeeAmountErr, AddFeeAmountCalculated, AddFeePerLineAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostAdditionalFeePerLineFalse()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTermsCode: Code[10];
        AddFeeAmountCalculated: Decimal;
    begin
        // [SCENARIO 107048] When Reminder Terms has value Post Add. Fee Per Line = FALSE
        // then Add. Fee Amount =0
        Initialize();

        // [GIVEN] When Reminder Terms has value Post Add. Fee per Line = FALSE
        AddFeeCalculationType := AddFeeCalculationType::Fixed;
        ReminderTermsCode := CreateReminderTermsAndLevel(ReminderLevel, true, false, AddFeeCalculationType);

        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        ReminderLevel."Add. Fee per Line Amount (LCY)" := LibraryRandom.RandDec(100, 2);
        ReminderLevel.Modify(true);

        // [WHEN] Add. Fee is calculated
        AddFeeAmountCalculated := ReminderLevel.GetAdditionalFee(LibraryRandom.RandDec(100, 2),
            '', false, Today);

        // [THEN] then calculated amount is Additional Fee (LCY) Amount
        Assert.AreEqual(0, AddFeeAmountCalculated,
          StrSubstNo(UnexpectedAddFeeAmountErr, 0, AddFeeAmountCalculated));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddFeeSetupOnOpenPageUT()
    var
        ReminderLevel: Record "Reminder Level";
        AdditionalFeeSetupPage: TestPage "Additional Fee Setup";
        ReminderLevels: TestPage "Reminder Levels";
        PageCaption: Text;
    begin
        // [SCENARIO 107048] Verify Add. Fee Setup Caption
        Initialize();

        // [GIVEN] When Reminder Terms and Reminder Level exist
        CreateReminderTermsAndLevel(ReminderLevel, true, true, AddFeeCalculationType);

        // [WHEN] Add. Fee Setup Page is run from Reminder Levels Page.
        OpenReminderLevelsPage(ReminderLevels, ReminderLevel."Reminder Terms Code", ReminderLevel."No.");
        ReminderLevels."Add. Fee Calculation Type".SetValue(ReminderLevel."Add. Fee Calculation Type"::"Single Dynamic");

        AdditionalFeeSetupPage.Trap();
        ReminderLevels."Additional Fee per Line".Invoke();
        PageCaption := AddFeePerLineTxt + ' ' + ReminderTermsTxt + ' ' + ReminderLevel."Reminder Terms Code" + ' ' +
          ReminderLevelTxt + ' ' + Format(ReminderLevel."No.");

        // [THEN] then caption contains Reminder Terms and Reminder Level specified
        Assert.AreEqual(AdditionalFeeSetupPage.Caption, PageCaption, CaptionErr);
    end;

    [Test]
    [HandlerFunctions('AdditionalFeeChartPageHandler')]
    [Scope('OnPrem')]
    procedure AddFeeChartOnOpenPageUT()
    var
        ReminderLevel: Record "Reminder Level";
        AdditionalFeeChart: TestPage "Additional Fee Chart";
        ReminderLevels: TestPage "Reminder Levels";
    begin
        // [SCENARIO 107048] Verify Add. Fee Chart
        Initialize();

        // [GIVEN] When Reminder Terms and Reminder Level exist
        CreateReminderTermsAndLevel(ReminderLevel, true, true, AddFeeCalculationType);

        // [WHEN] Add. Fee Chart Page is run from Reminder Levels Page.
        OpenReminderLevelsPage(ReminderLevels, ReminderLevel."Reminder Terms Code", ReminderLevel."No.");
        ReminderLevels."Add. Fee Calculation Type".SetValue(ReminderLevel."Add. Fee Calculation Type"::"Single Dynamic");
        AdditionalFeeChart.Trap();
        ReminderLevels."View Additional Fee Chart".Invoke();

        // [THEN] then Additional Fee  per Line, M
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionalFeeChartUpdateDataUT()
    var
        SortingTable: Record "Sorting Table";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AdditionalFeeSetup: Record "Additional Fee Setup";
        ReminderLevel: Record "Reminder Level";
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] Verify Add. Fee Setup Caption
        Initialize();

        // [GIVEN] When Reminder Terms and Reminder Level exist
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        RemainingAmount := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, RemainingAmount + 1, '', true, AddFeeCalculationType);
        ReminderLevel.Get(AdditionalFeeSetup."Reminder Terms Code", AdditionalFeeSetup."Reminder Level No.");

        // [WHEN] Add. Fee Setup Page is run from Reminder Levels Page.
        SortingTable.UpdateData(BusinessChartBuffer, ReminderLevel, true, '', 'TEST', 100000);

        VerifyBufferData(BusinessChartBuffer, AdditionalFeeSetup, ReminderLevel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddFeeChartUpdateDataMinBiggerThanAmountUT()
    var
        SortingTable: Record "Sorting Table";
        BusinessChartBuffer: Record "Business Chart Buffer";
        AdditionalFeeSetup: Record "Additional Fee Setup";
        ReminderLevel: Record "Reminder Level";
        RemainingAmount: Decimal;
    begin
        // [SCENARIO 107048] Verify Add. Fee Setup Caption
        Initialize();

        // [GIVEN] When Reminder Terms and Reminder Level exist
        AddFeeCalculationType := AddFeeCalculationType::"Accumulated Dynamic";
        RemainingAmount := LibraryRandom.RandDec(100, 2);
        CreateAddFeeSetupUT(AdditionalFeeSetup, RemainingAmount + 1, '', true, AddFeeCalculationType);
        AdditionalFeeSetup."Min. Additional Fee Amount" := AdditionalFeeSetup."Additional Fee Amount" +
          AdditionalFeeSetup."Max. Additional Fee Amount" * (AdditionalFeeSetup."Additional Fee %" / 100);
        AdditionalFeeSetup.Modify();
        ReminderLevel.Get(AdditionalFeeSetup."Reminder Terms Code", AdditionalFeeSetup."Reminder Level No.");

        // [WHEN] Add. Fee Setup Page is run from Reminder Levels Page.
        SortingTable.UpdateData(BusinessChartBuffer, ReminderLevel, true, '', 'TEST', 100000);

        // [THEN] buffer table is updated
        VerifyBufferData(BusinessChartBuffer, AdditionalFeeSetup, ReminderLevel);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionalFeeAmountValidatesReminderLevel()
    var
        ReminderLevel: Record "Reminder Level";
        AdditionalFeeSetup: Record "Additional Fee Setup";
    begin
        // [SCENARIO 291536] Changing Additional Fee Amount in Additional Fee Setup validates the value to it's parent Reminder Level
        Initialize();

        // [GIVEN] Additional Fee Setup was created for a Reminder Level with Charge Per Line = FALSE
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', false, ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic");

        // [WHEN] Amount is validated for this additional fee setup
        AdditionalFeeSetup.Validate("Additional Fee Amount", LibraryRandom.RandDec(10, 2));

        // [THEN] Addition Fee Amount in the Reminder Level is equal to the value in Additional Fee Setup
        ReminderLevel.Get(AdditionalFeeSetup."Reminder Terms Code", AdditionalFeeSetup."Reminder Level No.");
        ReminderLevel.TestField("Additional Fee (LCY)", AdditionalFeeSetup."Additional Fee Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionalFeeAmountValidatesReminderLevelInPerLine()
    var
        ReminderLevel: Record "Reminder Level";
        AdditionalFeeSetup: Record "Additional Fee Setup";
    begin
        // [SCENARIO 291536] Changing Additional Fee Amount in Additional Fee Setup validates the Per Line value to it's parent Reminder Level
        Initialize();

        // [GIVEN] Additional Fee Setup was created for a Reminder Level with Charge Per Line = TRUE
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, '', true, ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic");

        // [WHEN] Amount is validated for this additional fee setup
        AdditionalFeeSetup.Validate("Additional Fee Amount", LibraryRandom.RandDec(10, 2));

        // [THEN] Add. Fee per Line Amount in the Reminder Level is equal to the value in Additional Fee Setup
        ReminderLevel.Get(AdditionalFeeSetup."Reminder Terms Code", AdditionalFeeSetup."Reminder Level No.");
        ReminderLevel.TestField("Add. Fee per Line Amount (LCY)", AdditionalFeeSetup."Additional Fee Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdditionalFeeAmountDoesntChangeAnythingWhenCurrencyCodeNotEmpty()
    var
        ReminderLevel: Record "Reminder Level";
        AdditionalFeeSetup: Record "Additional Fee Setup";
        Currency: Record Currency;
    begin
        // [SCENARIO 291536] Changing Additional Fee Amount in Additional Fee Setup validates the Per Line value to the Reminder Level
        Initialize();

        // [GIVEN] Currency
        LibraryERM.CreateCurrency(Currency);

        // [GIVEN] Additional Fee Setup was created for a Reminder Level with Currency Code not blank
        CreateAddFeeSetupUT(AdditionalFeeSetup, 0, Currency.Code, false, ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic");

        // [WHEN] Amount is validated for this additional fee setup
        AdditionalFeeSetup.Validate("Additional Fee Amount", LibraryRandom.RandDec(10, 2));

        // [THEN] Add. Fee per Line Amount and Additional Fee Amount are not changed and are still 0
        ReminderLevel.Get(AdditionalFeeSetup."Reminder Terms Code", AdditionalFeeSetup."Reminder Level No.");
        ReminderLevel.TestField("Add. Fee per Line Amount (LCY)", 0);
        ReminderLevel.TestField("Additional Fee (LCY)", 0);
    end;

    local procedure CalculateAddFeeFromSetupUT(var AdditionalFeeSetup: Record "Additional Fee Setup"; RemainingAmount: Decimal): Decimal
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.Get(AdditionalFeeSetup."Reminder Terms Code", AdditionalFeeSetup."Reminder Level No.");

        exit(ReminderLevel.GetAdditionalFee(RemainingAmount,
            AdditionalFeeSetup."Currency Code",
            AdditionalFeeSetup."Charge Per Line", Today));
    end;

    local procedure CreateAddFeeSetupUT(var AdditionalFeeSetup: Record "Additional Fee Setup"; ThresholdRemAmount: Decimal; CurrencyCode: Code[10]; ChargePerLine: Boolean; CalcType: Option "Fixed","Single Dynamic","Accumulated Dynamic")
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTermsCode: Code[10];
    begin
        ReminderTermsCode := CreateReminderTerms(true, true);
        CreateReminderLevel(ReminderLevel, ReminderTermsCode, CalcType);
        AdditionalFeeSetup.Init();
        AdditionalFeeSetup."Reminder Terms Code" := ReminderTermsCode;
        AdditionalFeeSetup."Charge Per Line" := ChargePerLine;
        AdditionalFeeSetup."Reminder Level No." := ReminderLevel."No.";
        AdditionalFeeSetup."Currency Code" := CurrencyCode;
        AdditionalFeeSetup."Threshold Remaining Amount" := ThresholdRemAmount;
        AdditionalFeeSetup."Additional Fee Amount" := LibraryRandom.RandDec(100, 2);
        AdditionalFeeSetup."Additional Fee %" := LibraryRandom.RandDec(10, 2);
        AdditionalFeeSetup."Min. Additional Fee Amount" := AdditionalFeeSetup."Additional Fee Amount" - 1;
        AdditionalFeeSetup."Max. Additional Fee Amount" := AdditionalFeeSetup."Additional Fee Amount" + LibraryRandom.RandDec(1000, 2);
        AdditionalFeeSetup.Insert(true);
    end;

    local procedure CreateCurrencyForReminderLevel(var ReminderLevel: Record "Reminder Level"; CurrencyCode: Code[10]; AdditionalFee: Decimal; AdditionalFeePerLine: Decimal)
    var
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
    begin
        CurrencyForReminderLevel.Init();
        CurrencyForReminderLevel."Reminder Terms Code" := ReminderLevel."Reminder Terms Code";
        CurrencyForReminderLevel."No." := ReminderLevel."No.";
        CurrencyForReminderLevel."Currency Code" := CurrencyCode;
        CurrencyForReminderLevel."Additional Fee" := AdditionalFee;
        CurrencyForReminderLevel."Add. Fee per Line" := AdditionalFeePerLine;
        CurrencyForReminderLevel.Insert(true);
    end;

    local procedure CreateReminderTerms(PostAddFee: Boolean; PostAddFeePerLine: Boolean): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.Init();
        ReminderTerms.Code := LibraryUtility.GenerateRandomCode(ReminderTerms.FieldNo(Code), DATABASE::"Reminder Terms");
        ReminderTerms."Post Additional Fee" := PostAddFee;
        ReminderTerms."Post Add. Fee per Line" := PostAddFeePerLine;
        ReminderTerms.Insert(true);
        exit(ReminderTerms.Code)
    end;

    local procedure CreateReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10]; CalcType: Option "Fixed","Single Dynamic","Accumulated Dynamic")
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        ReminderLevel."Add. Fee Calculation Type" := CalcType;
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderTermsAndLevel(var ReminderLevel: Record "Reminder Level"; PostAddFee: Boolean; PostAddFeePerLine: Boolean; CalcType: Option "Fixed","Single Dynamic","Accumulated Dynamic"): Code[10]
    var
        ReminderTermsCode: Code[10];
    begin
        ReminderTermsCode := CreateReminderTerms(PostAddFee, PostAddFeePerLine);
        CreateReminderLevel(ReminderLevel, ReminderTermsCode, CalcType);
        exit(ReminderTermsCode);
    end;

    local procedure GetAdditionalFee(AdditionalFeeSetup: Record "Additional Fee Setup"; ColumnIndex: Integer; var SingleDynamicAmount: Decimal; var AccumulatedDynamicAmount: Decimal)
    var
        RemainingAmount: Decimal;
        ColumnIndexMin: Integer;
    begin
        if AdditionalFeeSetup."Additional Fee Amount" < AdditionalFeeSetup."Min. Additional Fee Amount" then
            ColumnIndexMin := 2;

        if (AdditionalFeeSetup."Additional Fee %" > 0) and (AdditionalFeeSetup."Min. Additional Fee Amount" > 0) and
                       (AdditionalFeeSetup."Additional Fee Amount" < AdditionalFeeSetup."Min. Additional Fee Amount") then
            RemainingAmount := AdditionalFeeSetup."Threshold Remaining Amount" +
                          (AdditionalFeeSetup."Min. Additional Fee Amount" - AdditionalFeeSetup."Additional Fee Amount") /
                          (AdditionalFeeSetup."Additional Fee %" / 100);

        AccumulatedDynamicAmount := 0;

        case ColumnIndex of
            0:
                RemainingAmount := 0;
            1:
                RemainingAmount := AdditionalFeeSetup."Threshold Remaining Amount" - 1;
            2:
                RemainingAmount := AdditionalFeeSetup."Threshold Remaining Amount";
            3 + ColumnIndexMin:
                RemainingAmount := AdditionalFeeSetup."Threshold Remaining Amount" * 1.5;
        end;

        if RemainingAmount < AdditionalFeeSetup."Threshold Remaining Amount" then
            RemainingAmount := 0
        else begin
            SingleDynamicAmount := AdditionalFeeSetup."Additional Fee Amount" +
              ((AdditionalFeeSetup."Additional Fee %" / 100) * RemainingAmount);

            if AdditionalFeeSetup."Additional Fee Amount" > 0 then
                AccumulatedDynamicAmount += AdditionalFeeSetup."Additional Fee Amount";

            if AdditionalFeeSetup."Additional Fee %" > 0 then
                AccumulatedDynamicAmount += ((RemainingAmount - AdditionalFeeSetup."Threshold Remaining Amount") * AdditionalFeeSetup."Additional Fee %") / 100;

            if SingleDynamicAmount > AdditionalFeeSetup."Max. Additional Fee Amount" then
                SingleDynamicAmount := AdditionalFeeSetup."Max. Additional Fee Amount";

            if AccumulatedDynamicAmount > AdditionalFeeSetup."Max. Additional Fee Amount" then
                AccumulatedDynamicAmount := AdditionalFeeSetup."Max. Additional Fee Amount";

            if SingleDynamicAmount < AdditionalFeeSetup."Min. Additional Fee Amount" then
                SingleDynamicAmount := AdditionalFeeSetup."Min. Additional Fee Amount";

            if AccumulatedDynamicAmount < AdditionalFeeSetup."Min. Additional Fee Amount" then
                AccumulatedDynamicAmount := AdditionalFeeSetup."Min. Additional Fee Amount";
        end;
    end;

    local procedure SetUpAdditionalFeePropertiesUT(var AdditionalFeeSetup: Record "Additional Fee Setup"; MinAddFeeAmount: Decimal; MaxAddFeeAmount: Decimal; AddFeeAmount: Decimal; AddFeePerc: Decimal)
    begin
        AdditionalFeeSetup."Min. Additional Fee Amount" := MinAddFeeAmount;
        AdditionalFeeSetup."Max. Additional Fee Amount" := MaxAddFeeAmount;
        AdditionalFeeSetup."Additional Fee Amount" := AddFeeAmount;
        AdditionalFeeSetup."Additional Fee %" := AddFeePerc;
        AdditionalFeeSetup.Modify(true);
    end;

    local procedure OpenReminderLevelsPage(var ReminderLevels: TestPage "Reminder Levels"; "Code": Code[10]; No: Integer)
    var
        ReminderTerms: TestPage "Reminder Terms";
    begin
        ReminderTerms.OpenEdit();
        ReminderTerms.FILTER.SetFilter(Code, Code);
        ReminderLevels.Trap();
        ReminderTerms."&Levels".Invoke();
        ReminderLevels.FILTER.SetFilter("No.", Format(No));
    end;

    local procedure VerifyBufferData(var BusinessChartBuffer: Record "Business Chart Buffer"; AdditionalFeeSetup: Record "Additional Fee Setup"; ReminderLevel: Record "Reminder Level")
    var
        FixedAmountVariant: Variant;
        SingleDynamicAmountVariant: Variant;
        AccumulatedDynamicAmountVariant: Variant;
        FixedAmountExpected: Decimal;
        SingleDynamicAmountExpected: Decimal;
        AccumulatedDynamicAmountExpected: Decimal;
        FixedAmount: Decimal;
        SingleDynamicAmount: Decimal;
        AccumulatedDynamicAmount: Decimal;
        ColumnIndex: Integer;
    begin
        ColumnIndex := 0;
        repeat
            GetAdditionalFee(AdditionalFeeSetup, ColumnIndex, SingleDynamicAmountExpected, AccumulatedDynamicAmountExpected);
            FixedAmountExpected := ReminderLevel."Add. Fee per Line Amount (LCY)";

            // fixed fee
            BusinessChartBuffer.GetValue(Format(ReminderLevel."Add. Fee Calculation Type"::Fixed), ColumnIndex, FixedAmountVariant);
            Evaluate(FixedAmount, Format(FixedAmountVariant));

            Assert.AreEqual(FixedAmountExpected, FixedAmount, StrSubstNo(UnexpectedAddFeeAmountErr, FixedAmountExpected, FixedAmount));

            // single dynamic
            BusinessChartBuffer.GetValue(
              Format(ReminderLevel."Add. Fee Calculation Type"::"Single Dynamic"), ColumnIndex, SingleDynamicAmountVariant);
            Evaluate(SingleDynamicAmount, Format(SingleDynamicAmountVariant));

            Assert.AreNearlyEqual(SingleDynamicAmountExpected, SingleDynamicAmount, 0.01,
              StrSubstNo(UnexpectedAddFeeAmountErr, SingleDynamicAmountExpected, SingleDynamicAmount));

            // accumulated dynamic
            BusinessChartBuffer.GetValue(
              Format(ReminderLevel."Add. Fee Calculation Type"::"Accumulated Dynamic"), ColumnIndex, AccumulatedDynamicAmountVariant);
            Evaluate(AccumulatedDynamicAmount, Format(AccumulatedDynamicAmountVariant));
            Assert.AreNearlyEqual(AccumulatedDynamicAmountExpected, AccumulatedDynamicAmount, 0.01,
              StrSubstNo(UnexpectedAddFeeAmountErr, AccumulatedDynamicAmountExpected, AccumulatedDynamicAmount));

            ColumnIndex += 1;
        until ColumnIndex = 4;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AdditionalFeeChartPageHandler(var AdditionalFeeChart: TestPage "Additional Fee Chart")
    begin
        AdditionalFeeChart.Last();
        AdditionalFeeChart.ChargePerLine.SetValue(true);
        AdditionalFeeChart."Max. Remaining Amount".SetValue(LibraryRandom.RandDec(100, 2));
        AdditionalFeeChart.Currency.SetValue(LibraryERM.CreateCurrencyWithRandomExchRates());
        AdditionalFeeChart.OK().Invoke();
    end;
}

