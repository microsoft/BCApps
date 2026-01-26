codeunit 144119 "Remittance Agreement Table UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Remittance] [Agreement]
    end;

    var
        Assert: Codeunit Assert;
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [Scope('OnPrem')]
    procedure TableOnDelete()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        ReturnFileSetup: Record "Return File Setup";
        ReturnFileSetup2: Record "Return File Setup";
    begin
        // Purpose of the test is to validate Trigger OnDelete
        // The OnDelete triggers deletes all Return File Setup record related to the Remittance Agreement.

        // Setup
        ReturnFileSetup."Agreement Code" := LibraryUTUtility.GetNewCode10();
        ReturnFileSetup.Insert();
        ReturnFileSetup2."Agreement Code" := LibraryUTUtility.GetNewCode10();
        ReturnFileSetup2.Insert();
        RemittanceAgreement.Init();
        RemittanceAgreement.Code := ReturnFileSetup2."Agreement Code";
        RemittanceAgreement.Insert();

        // Exercise
        RemittanceAgreement.Delete(true);

        // Verify
        ReturnFileSetup.Get(ReturnFileSetup."Agreement Code");
        Assert.IsFalse(ReturnFileSetup2.Get(ReturnFileSetup2."Agreement Code"), 'Return File Setup is not deleted.');
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestSequenceNoOnValidateConfirmFalse()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestSequenceNoValue: Integer;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest Sequence No."))  = FALSE

        // Setup
        LibraryVariableStorage.Enqueue(false);
        RemittanceAgreement.Init();
        LatestSequenceNoValue := LibraryRandom.RandInt(10);
        RemittanceAgreement."Latest Sequence No." := LatestSequenceNoValue;

        // Exercise
        RemittanceAgreement.Validate("Latest Sequence No.", LatestSequenceNoValue + 1);

        // Verify
        Assert.AreEqual(LatestSequenceNoValue, RemittanceAgreement."Latest Sequence No.", 'Latest Sequence No. changed')
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestSequenceNoOnValidateConfirmTrue()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestSequenceNoValue: Integer;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest Sequence No."))  = TRUE

        // Setup
        LibraryVariableStorage.Enqueue(true);
        RemittanceAgreement.Init();
        LatestSequenceNoValue := LibraryRandom.RandInt(10);
        RemittanceAgreement."Latest Sequence No." := LatestSequenceNoValue;

        // Exercise
        RemittanceAgreement.Validate("Latest Sequence No.", LatestSequenceNoValue + 1);

        // Verify
        Assert.AreEqual(LatestSequenceNoValue + 1, RemittanceAgreement."Latest Sequence No.", 'Latest Sequence No. not changed')
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestDailySequenceNoOnValidateConfirmFalse()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestDailySequenceNoValue: Integer;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest Daily Sequence No."))  = FALSE

        // Setup
        LibraryVariableStorage.Enqueue(false);
        RemittanceAgreement.Init();
        LatestDailySequenceNoValue := LibraryRandom.RandInt(10);
        RemittanceAgreement."Latest Daily Sequence No." := LatestDailySequenceNoValue;

        // Exercise
        RemittanceAgreement.Validate("Latest Daily Sequence No.", LatestDailySequenceNoValue + 1);

        // Verify
        Assert.AreEqual(
          LatestDailySequenceNoValue,
          RemittanceAgreement."Latest Daily Sequence No.",
          'Latest Daily Sequence No. changed')
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestDailySequenceNoOnValidateConfirmTrue()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestDailySequenceNoValue: Integer;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest Daily Sequence No."))  = TRUE

        // Setup
        LibraryVariableStorage.Enqueue(true);
        RemittanceAgreement.Init();
        LatestDailySequenceNoValue := LibraryRandom.RandInt(10);
        RemittanceAgreement."Latest Daily Sequence No." := LatestDailySequenceNoValue;

        // Exercise
        RemittanceAgreement.Validate("Latest Daily Sequence No.", LatestDailySequenceNoValue + 1);

        // Verify
        Assert.AreEqual(
          LatestDailySequenceNoValue + 1,
          RemittanceAgreement."Latest Daily Sequence No.",
          'Latest Daily Sequence No. not changed')
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestBBSPaymentOrderNoOnValidateConfirmFalse()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestBBSPaymentOrderNoValue: Integer;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest BBS Payment Order No."))  = FALSE

        // Setup
        LibraryVariableStorage.Enqueue(false);
        RemittanceAgreement.Init();
        LatestBBSPaymentOrderNoValue := LibraryRandom.RandInt(10);
        RemittanceAgreement."Latest BBS Payment Order No." := LatestBBSPaymentOrderNoValue;

        // Exercise
        RemittanceAgreement.Validate("Latest BBS Payment Order No.", LatestBBSPaymentOrderNoValue + 1);

        // Verify
        Assert.AreEqual(
          LatestBBSPaymentOrderNoValue,
          RemittanceAgreement."Latest BBS Payment Order No.",
          'Latest BBS Payment Order No. changed')
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestBBSPaymentOrderNoOnValidateConfirmTrue()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestBBSPaymentOrderNoValue: Integer;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest BBS Payment Order No."))  = TRUE

        // Setup
        LibraryVariableStorage.Enqueue(true);
        RemittanceAgreement.Init();
        LatestBBSPaymentOrderNoValue := LibraryRandom.RandInt(10);
        RemittanceAgreement."Latest BBS Payment Order No." := LatestBBSPaymentOrderNoValue;

        // Exercise
        RemittanceAgreement.Validate("Latest BBS Payment Order No.", LatestBBSPaymentOrderNoValue + 1);

        // Verify
        Assert.AreEqual(
          LatestBBSPaymentOrderNoValue + 1,
          RemittanceAgreement."Latest BBS Payment Order No.",
          'Latest BBS Payment Order No. not changed')
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestExportOnValidateConfirmFalse()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestExportValue: Date;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest Export"))  = FALSE

        // Setup
        LibraryVariableStorage.Enqueue(false);
        RemittanceAgreement.Init();
        LatestExportValue := WorkDate();
        RemittanceAgreement."Latest Export" := LatestExportValue;

        // Exercise
        RemittanceAgreement.Validate("Latest Export", LatestExportValue + 1);

        // Verify
        Assert.AreEqual(
          LatestExportValue,
          RemittanceAgreement."Latest Export",
          'Latest Export changed')
    end;

    [Test]
    [HandlerFunctions('EditWarningConfirmHandler')]
    [Scope('OnPrem')]
    procedure FieldLatestExportOnValidateConfirmTrue()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        LatestExportValue: Date;
    begin
        // Purpose of the test is to validate Trigger OnValidate
        // under the following conditions:
        // 1.   NOT EditWarning(FIELDCAPTION("Latest Export"))  = TRUE

        // Setup
        LibraryVariableStorage.Enqueue(true);
        RemittanceAgreement.Init();
        LatestExportValue := WorkDate();
        RemittanceAgreement."Latest Export" := LatestExportValue;

        // Exercise
        RemittanceAgreement.Validate("Latest Export", LatestExportValue + 1);

        // Verify
        Assert.AreEqual(
          LatestExportValue + 1,
          RemittanceAgreement."Latest Export",
          'Latest Export not changed')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPaymentFileNameFromField()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        ExpectedFileName: Text;
    begin
        // [SCENARIO 404010] GetPaymentFileName function from Payment File Name field
        ExpectedFileName := LibraryUTUtility.GetNewCode10();
        RemittanceAgreement.Init();
        RemittanceAgreement.Code := LibraryUTUtility.GetNewCode10();
        RemittanceAgreement."Payment File Name" := ExpectedFileName;
        Assert.AreEqual(ExpectedFileName, RemittanceAgreement.GetPaymentFileName(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPaymentFileNameFromCode()
    var
        RemittanceAgreement: Record "Remittance Agreement";
        ExpectedFileName: Text;
    begin
        // [SCENARIO 404010] GetPaymentFileName function from Code field
        ExpectedFileName := LibraryUTUtility.GetNewCode10();
        RemittanceAgreement.Init();
        RemittanceAgreement.Code := ExpectedFileName;
        RemittanceAgreement."Payment File Name" := '';
        Assert.AreEqual(ExpectedFileName + '.txt', RemittanceAgreement.GetPaymentFileName(), '');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure EditWarningConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    var
        v: Variant;
    begin
        LibraryVariableStorage.Dequeue(v);
        Reply := v;
    end;
}

