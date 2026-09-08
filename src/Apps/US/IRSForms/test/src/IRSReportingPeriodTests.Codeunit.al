// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

codeunit 148016 "IRS Reporting Period Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryIRSReportingPeriod: Codeunit "Library IRS Reporting Period";
        LibraryIRS1099FormBox: Codeunit "Library IRS 1099 Form Box";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        StartingEndingDateOverlapErr: Label 'The starting date and ending date overlap with an existing reporting period.';
        AmountShouldBeResetErr: Label 'Amount should be reset to 0';

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapWithStartingDate()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20230101D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20240101D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapWithEndingDate()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20241231D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20250101D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapStartingInTheMiddle()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240501D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20250101D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodOverlapEndinggInTheMiddle()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan cannot create reporting periods where starting date and ending date overlap with existing reporting periods

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20230101D);
        asserterror IRSReportingPeriod.Validate("Ending Date", 20240501D);

        Assert.ExpectedError(StartingEndingDateOverlapErr);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodBeforeExisting()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan can create a new reporting period before the existing one

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20230101D);
        IRSReportingPeriod.Validate("Ending Date", 20231231D);
        IRSReportingPeriod.Insert();

        Assert.RecordCount(IRSReportingPeriod, 2);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ReportingPeriodAfterExisting()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
    begin
        // [SCENARIO 495389] Stan can create a new reporting period after the existing one

        Initialize();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20240101D);
        IRSReportingPeriod.Validate("Ending Date", 20241231D);
        IRSReportingPeriod.Insert();

        IRSReportingPeriod.Init();
        IRSReportingPeriod."No." := LibraryUtility.GenerateGUID();
        IRSReportingPeriod.Validate("Starting Date", 20250101D);
        IRSReportingPeriod.Validate("Ending Date", 20251231D);
        IRSReportingPeriod.Insert();

        Assert.RecordCount(IRSReportingPeriod, 2);
    end;

    [Test]
    procedure IRSFormsGuideCreatesReportingPeriodOnFinish()
    var
        IRSReportingPeriod: Record "IRS Reporting Period";
        IRS1099Form: Record "IRS 1099 Form";
        IRSFormsGuidePage: TestPage "IRS Forms Guide";
        ReportingYear: Integer;
    begin
        // [SCENARIO 615776] When user specifies the "Init Reporting Year" and finishes the IRS Forms Guide, a reporting period with forms is created

        Initialize();
        ReportingYear := Date2DMY(WorkDate(), 3) + 10;
        // [GIVEN] No reporting period exists for the year
        IRSReportingPeriod.SetRange("No.", Format(ReportingYear));
        IRSReportingPeriod.DeleteAll();

        // [GIVEN] IRS Forms Guide page is opened
        IRSFormsGuidePage.OpenEdit();
        // [GIVEN] User navigates to the Data step
        IRSFormsGuidePage.ActionNext.Invoke();
        // [GIVEN] User sets the Reporting Year to the specified year
        IRSFormsGuidePage.ReportingYearControl.SetValue(ReportingYear);
        // [GIVEN] User navigates to the Features step
        IRSFormsGuidePage.ActionNext.Invoke();
        // [GIVEN] User navigates to the Finish step
        IRSFormsGuidePage.ActionNext.Invoke();
        // [WHEN] User clicks Finish
        IRSFormsGuidePage.ActionFinish.Invoke();

        // [THEN] IRS Reporting Period is created for the specified year
        IRSReportingPeriod.SetRange("No.", Format(ReportingYear));
        Assert.RecordIsNotEmpty(IRSReportingPeriod);
        IRSReportingPeriod.FindFirst();
        Assert.AreEqual(DMY2Date(1, 1, ReportingYear), IRSReportingPeriod."Starting Date", 'Starting Date should be Jan 1');
        Assert.AreEqual(DMY2Date(31, 12, ReportingYear), IRSReportingPeriod."Ending Date", 'Ending Date should be Dec 31');
        // [THEN] IRS 1099 Forms are created for the reporting period
        IRS1099Form.SetRange("Period No.", IRSReportingPeriod."No.");
        Assert.RecordIsNotEmpty(IRS1099Form);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [HandlerFunctions('CopySetupMessageHandler')]
    procedure VendorFormBoxAdjustmentAmountIsResetWhenCopyingSetup()
    var
        IRS1099VendorFormBoxAdj: Record "IRS 1099 Vendor Form Box Adj.";
        FromPeriodNo: Code[20];
        ToPeriodNo: Code[20];
        FormNo: Code[20];
        FormBoxNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
        FromStartDate: Date;
        FromEndDate: Date;
        ToStartDate: Date;
        ToEndDate: Date;
    begin
        // [SCENARIO 623874] When copying reporting period setup with vendor form box adjustments, the Amount field is reset to 0 in the target period
        Initialize();

        // [GIVEN] Reporting period for current year with vendor form box adjustment "V" for form "MISC" box "01" with Amount = 1000
        FromStartDate := CalcDate('<-CY>', WorkDate());
        FromEndDate := CalcDate('<CY>', WorkDate());
        FromPeriodNo := LibraryIRSReportingPeriod.CreateReportingPeriod(FromStartDate, FromEndDate);
        FormNo := LibraryIRS1099FormBox.CreateSingleFormInReportingPeriod(FromStartDate, FromEndDate);
        FormBoxNo := LibraryIRS1099FormBox.CreateSingleFormBoxInReportingPeriod(FromStartDate, FromEndDate, FormNo);
        VendorNo := LibraryIRS1099FormBox.CreateVendorNoWithFormBox(FromStartDate, FromEndDate, FormNo, FormBoxNo);
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryIRS1099FormBox.AddAdjustmentAmountForVendor(FromStartDate, FromEndDate, VendorNo, FormNo, FormBoxNo, Amount);

        // [GIVEN] Reporting period for next year exists
        ToStartDate := CalcDate('<1Y>', FromStartDate);
        ToEndDate := CalcDate('<1Y>', FromEndDate);
        ToPeriodNo := LibraryIRSReportingPeriod.CreateReportingPeriod(ToStartDate, ToEndDate);

        // [WHEN] Copy setup from current year to next year
        LibraryIRSReportingPeriod.CopyPeriodSetup(FromPeriodNo, ToPeriodNo);

        // [THEN] Vendor form box adjustment is copied to next year with Amount = 0
        IRS1099VendorFormBoxAdj.SetRange("Period No.", ToPeriodNo);
        IRS1099VendorFormBoxAdj.SetRange("Vendor No.", VendorNo);
        IRS1099VendorFormBoxAdj.SetRange("Form No.", FormNo);
        IRS1099VendorFormBoxAdj.SetRange("Form Box No.", FormBoxNo);
        Assert.RecordIsNotEmpty(IRS1099VendorFormBoxAdj);
        IRS1099VendorFormBoxAdj.FindFirst();
        Assert.AreEqual(0, IRS1099VendorFormBoxAdj.Amount, AmountShouldBeResetErr);
    end;

    trigger OnRun()
    begin
        // [FEATURE] [1099]
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"IRS Reporting Period Tests");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"IRS Reporting Period Tests");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"IRS Reporting Period Tests");
    end;

    [MessageHandler]
    procedure CopySetupMessageHandler(Message: Text[1024])
    begin
        // Handle the setup copied message
    end;

}
