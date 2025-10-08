namespace Microsoft.Finance.ExcelReports.Test;

using Microsoft.Finance.ExcelReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.Consolidation;
using Microsoft.Foundation.Company;
using Microsoft.ExcelReports;
using System.TestLibraries.Utilities;

codeunit 135400 "EXR Trial Balance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    procedure TestConsolidatedTrialBalanceQueryVsLegacy()
    var
        EXRTrialBalanceBuffer1: Record "EXR Trial Balance Buffer" temporary;
        EXRTrialBalanceBuffer2: Record "EXR Trial Balance Buffer" temporary;
        GLAccount: Record "G/L Account";
        Dimension1Values: Record "Dimension Value" temporary;
        Dimension2Values: Record "Dimension Value" temporary;
        TrialBalance: Codeunit "Trial Balance";
    begin
        Initialize();
        CreateTestData();
        
        // Test legacy approach
        TrialBalance.ConfigureTrialBalance(true, true);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer1);
        
        // Test query-based approach
        TrialBalance.ConfigureTrialBalance(true, true);
        TrialBalance.InsertConsolidatedTrialBalanceReportDataFromQuery(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer2);
        
        // Compare results
        AssertTrialBalanceDataEqual(EXRTrialBalanceBuffer1, EXRTrialBalanceBuffer2, 'Consolidated Trial Balance');
    end;

    [Test]
    procedure TestTrialBalanceBudgetQueryVsLegacy()
    var
        EXRTrialBalanceBuffer1: Record "EXR Trial Balance Buffer" temporary;
        EXRTrialBalanceBuffer2: Record "EXR Trial Balance Buffer" temporary;
        GLAccount: Record "G/L Account";
        Dimension1Values: Record "Dimension Value" temporary;
        Dimension2Values: Record "Dimension Value" temporary;
        TrialBalance: Codeunit "Trial Balance";
    begin
        Initialize();
        CreateTestDataWithBudget();
        
        // Test legacy approach
        TrialBalance.ConfigureTrialBalance(true, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer1);
        
        // Test query-based approach
        TrialBalance.ConfigureTrialBalance(true, false);
        TrialBalance.InsertTrialBalanceBudgetReportDataFromQuery(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer2);
        
        // Compare results
        AssertTrialBalanceDataEqual(EXRTrialBalanceBuffer1, EXRTrialBalanceBuffer2, 'Trial Balance Budget');
    end;

    [Test]
    procedure TestTrialBalanceByPeriodQueryVsLegacy()
    var
        EXRTrialBalanceBuffer1: Record "EXR Trial Balance Buffer" temporary;
        EXRTrialBalanceBuffer2: Record "EXR Trial Balance Buffer" temporary;
        GLAccount: Record "G/L Account";
        Dimension1Values: Record "Dimension Value" temporary;
        Dimension2Values: Record "Dimension Value" temporary;
        TrialBalance: Codeunit "Trial Balance";
    begin
        Initialize();
        CreateTestDataMultiplePeriods();
        
        // Test legacy approach
        TrialBalance.ConfigureTrialBalance(true, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer1);
        
        // Test query-based approach
        TrialBalance.ConfigureTrialBalance(true, false);
        TrialBalance.InsertTrialBalanceByPeriodReportDataFromQuery(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer2);
        
        // Compare results
        AssertTrialBalanceDataEqual(EXRTrialBalanceBuffer1, EXRTrialBalanceBuffer2, 'Trial Balance by Period');
    end;

    [Test]
    procedure TestTrialBalancePrevYearQueryVsLegacy()
    var
        EXRTrialBalanceBuffer1: Record "EXR Trial Balance Buffer" temporary;
        EXRTrialBalanceBuffer2: Record "EXR Trial Balance Buffer" temporary;
        GLAccount: Record "G/L Account";
        Dimension1Values: Record "Dimension Value" temporary;
        Dimension2Values: Record "Dimension Value" temporary;
        TrialBalance: Codeunit "Trial Balance";
    begin
        Initialize();
        CreateTestDataPreviousYear();
        
        // Test legacy approach
        TrialBalance.ConfigureTrialBalance(true, false);
        TrialBalance.InsertTrialBalanceReportData(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer1);
        
        // Test query-based approach
        TrialBalance.ConfigureTrialBalance(true, false);
        TrialBalance.InsertTrialBalancePrevYearReportDataFromQuery(GLAccount, Dimension1Values, Dimension2Values, EXRTrialBalanceBuffer2);
        
        // Compare results
        AssertTrialBalanceDataEqual(EXRTrialBalanceBuffer1, EXRTrialBalanceBuffer2, 'Trial Balance Previous Year');
    end;

    [Test]
    procedure TestConsolidatedTrialBalanceReportEventActivation()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        CreateTestData();
        
        BindSubscription(MockPerformantFeatureEvents);
        SetPerformantFeatureActive(true);
        
        TempBlob.CreateOutStream(OutStream);
        Report.SaveAs(Report::"EXR Consolidated Trial Balance", '', ReportFormat::Excel, OutStream);
        
        UnbindSubscription(MockPerformantFeatureEvents);
        Assert.IsTrue(GetPerformantFeatureWasCalled(), 'Performant feature event should have been called');
    end;

    [Test]
    procedure TestTrialBalanceBudgetReportEventActivation()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        CreateTestDataWithBudget();
        
        BindSubscription(MockPerformantFeatureEvents);
        SetPerformantFeatureActive(true);
        
        TempBlob.CreateOutStream(OutStream);
        Report.SaveAs(Report::"EXR Trial Balance/Budget Excel", '', ReportFormat::Excel, OutStream);
        
        UnbindSubscription(MockPerformantFeatureEvents);
        Assert.IsTrue(GetPerformantFeatureWasCalled(), 'Performant feature event should have been called');
    end;

    [Test]
    procedure TestTrialBalanceByPeriodReportEventActivation()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        CreateTestDataMultiplePeriods();
        
        BindSubscription(MockPerformantFeatureEvents);
        SetPerformantFeatureActive(true);
        
        TempBlob.CreateOutStream(OutStream);
        Report.SaveAs(Report::"EXR Trial Bal by Period Excel", '', ReportFormat::Excel, OutStream);
        
        UnbindSubscription(MockPerformantFeatureEvents);
        Assert.IsTrue(GetPerformantFeatureWasCalled(), 'Performant feature event should have been called');
    end;

    [Test]
    procedure TestTrialBalancePrevYearReportEventActivation()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        Initialize();
        CreateTestDataPreviousYear();
        
        BindSubscription(MockPerformantFeatureEvents);
        SetPerformantFeatureActive(true);
        
        TempBlob.CreateOutStream(OutStream);
        Report.SaveAs(Report::"EXR Trial Bal. Prev Year Excel", '', ReportFormat::Excel, OutStream);
        
        UnbindSubscription(MockPerformantFeatureEvents);
        Assert.IsTrue(GetPerformantFeatureWasCalled(), 'Performant feature event should have been called');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;
        
        IsInitialized := true;
    end;

    local procedure CreateTestData()
    var
        GLAccount: Record "G/L Account";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        BusinessUnit: Record "Business Unit";
        i: Integer;
    begin
        // Create test G/L Accounts
        for i := 1 to 5 do begin
            LibraryERM.CreateGLAccount(GLAccount);
            GLAccount."Account Type" := "G/L Account Type"::Posting;
            GLAccount.Modify();
            
            // Create G/L Entries with dimensions
            CreateGLEntryWithDimensions(GLAccount."No.", LibraryRandom.RandDecInRange(100, 1000, 2));
        end;
        
        // Create Business Units for consolidation
        for i := 1 to 3 do begin
            BusinessUnit.Code := 'BU' + Format(i);
            BusinessUnit.Name := 'Business Unit ' + Format(i);
            BusinessUnit.Insert();
        end;
    end;

    local procedure CreateTestDataWithBudget()
    var
        GLAccount: Record "G/L Account";
        GLBudgetEntry: Record "G/L Budget Entry";
        i: Integer;
    begin
        CreateTestData();
        
        // Add budget entries
        GLAccount.FindSet();
        repeat
            for i := 1 to 3 do begin
                GLBudgetEntry."Entry No." := LibraryERM.GetNextGLBudgetEntryNo();
                GLBudgetEntry."G/L Account No." := GLAccount."No.";
                GLBudgetEntry.Date := WorkDate();
                GLBudgetEntry.Amount := LibraryRandom.RandDecInRange(50, 500, 2);
                GLBudgetEntry.Insert();
            end;
        until GLAccount.Next() = 0;
    end;

    local procedure CreateTestDataMultiplePeriods()
    var
        GLAccount: Record "G/L Account";
        StartDate: Date;
        i, j: Integer;
    begin
        StartDate := CalcDate('<-3M>', WorkDate());
        
        // Create test data across multiple periods
        for i := 1 to 3 do begin
            LibraryERM.CreateGLAccount(GLAccount);
            GLAccount."Account Type" := "G/L Account Type"::Posting;
            GLAccount.Modify();
            
            for j := 0 to 2 do
                CreateGLEntryWithDimensions(GLAccount."No.", LibraryRandom.RandDecInRange(100, 1000, 2), CalcDate('<+1M>', StartDate + j * 30));
        end;
    end;

    local procedure CreateTestDataPreviousYear()
    var
        GLAccount: Record "G/L Account";
        CurrentYearDate: Date;
        PreviousYearDate: Date;
        i: Integer;
    begin
        CurrentYearDate := WorkDate();
        PreviousYearDate := CalcDate('<-1Y>', CurrentYearDate);
        
        // Create test data for current and previous year
        for i := 1 to 3 do begin
            LibraryERM.CreateGLAccount(GLAccount);
            GLAccount."Account Type" := "G/L Account Type"::Posting;
            GLAccount.Modify();
            
            // Current year entries
            CreateGLEntryWithDimensions(GLAccount."No.", LibraryRandom.RandDecInRange(100, 1000, 2), CurrentYearDate);
            // Previous year entries
            CreateGLEntryWithDimensions(GLAccount."No.", LibraryRandom.RandDecInRange(100, 1000, 2), PreviousYearDate);
        end;
    end;

    local procedure CreateGLEntryWithDimensions(GLAccountNo: Code[20]; Amount: Decimal)
    begin
        CreateGLEntryWithDimensions(GLAccountNo, Amount, WorkDate());
    end;

    local procedure CreateGLEntryWithDimensions(GLAccountNo: Code[20]; Amount: Decimal; PostingDate: Date)
    var
        GLEntry: Record "G/L Entry";
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        // Create dimension values if they don't exist
        if not DimensionValue1.Get(LibraryERM.GetGlobalDimensionCode(1), 'DIM1_001') then begin
            LibraryDimension.CreateDimensionValue(DimensionValue1, LibraryERM.GetGlobalDimensionCode(1));
            DimensionValue1.Code := 'DIM1_001';
            DimensionValue1.Name := 'Dimension 1 Value 1';
            DimensionValue1.Modify();
        end;
        
        if not DimensionValue2.Get(LibraryERM.GetGlobalDimensionCode(2), 'DIM2_001') then begin
            LibraryDimension.CreateDimensionValue(DimensionValue2, LibraryERM.GetGlobalDimensionCode(2));
            DimensionValue2.Code := 'DIM2_001';
            DimensionValue2.Name := 'Dimension 2 Value 1';
            DimensionValue2.Modify();
        end;
        
        GLEntry."Entry No." := LibraryERM.GetNextGLEntryNo();
        GLEntry."G/L Account No." := GLAccountNo;
        GLEntry."Posting Date" := PostingDate;
        GLEntry.Amount := Amount;
        GLEntry."Global Dimension 1 Code" := DimensionValue1.Code;
        GLEntry."Global Dimension 2 Code" := DimensionValue2.Code;
        GLEntry.Insert();
    end;

    local procedure AssertTrialBalanceDataEqual(var Buffer1: Record "EXR Trial Balance Buffer" temporary; var Buffer2: Record "EXR Trial Balance Buffer" temporary; TestName: Text)
    begin
        Buffer1.Reset();
        Buffer2.Reset();
        
        Assert.AreEqual(Buffer1.Count, Buffer2.Count, StrSubstNo('%1: Record counts should match', TestName));
        
        if Buffer1.FindSet() then
            repeat
                Buffer2.SetRange("G/L Account No.", Buffer1."G/L Account No.");
                Buffer2.SetRange("Dimension 1 Code", Buffer1."Dimension 1 Code");
                Buffer2.SetRange("Dimension 2 Code", Buffer1."Dimension 2 Code");
                Buffer2.SetRange("Business Unit Code", Buffer1."Business Unit Code");
                
                Assert.IsTrue(Buffer2.FindFirst(), StrSubstNo('%1: Matching record not found', TestName));
                
                Assert.AreEqual(Buffer1."Net Change", Buffer2."Net Change", StrSubstNo('%1: Net Change should match', TestName));
                Assert.AreEqual(Buffer1.Balance, Buffer2.Balance, StrSubstNo('%1: Balance should match', TestName));
                Assert.AreEqual(Buffer1."Net Change (ACY)", Buffer2."Net Change (ACY)", StrSubstNo('%1: Net Change ACY should match', TestName));
                Assert.AreEqual(Buffer1."Balance (ACY)", Buffer2."Balance (ACY)", StrSubstNo('%1: Balance ACY should match', TestName));
                
                Buffer2.Reset();
            until Buffer1.Next() = 0;
    end;

    var
        MockPerformantFeatureEvents: Codeunit "Mock Performant Feature Events";
        PerformantFeatureActive: Boolean;
        PerformantFeatureWasCalled: Boolean;

    local procedure SetPerformantFeatureActive(Active: Boolean)
    begin
        PerformantFeatureActive := Active;
        PerformantFeatureWasCalled := false;
    end;

    local procedure GetPerformantFeatureWasCalled(): Boolean
    begin
        exit(PerformantFeatureWasCalled);
    end;

    [EventSubscriber(ObjectType::Report, Report::"EXR Consolidated Trial Balance", 'OnIsPerformantConsolidatedTrialBalanceFeatureActive', '', false, false)]
    local procedure OnIsPerformantConsolidatedTrialBalanceFeatureActive(var Active: Boolean)
    begin
        Active := PerformantFeatureActive;
        PerformantFeatureWasCalled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"EXR Trial Balance/Budget Excel", 'OnIsPerformantTrialBalanceBudgetFeatureActive', '', false, false)]
    local procedure OnIsPerformantTrialBalanceBudgetFeatureActive(var Active: Boolean)
    begin
        Active := PerformantFeatureActive;
        PerformantFeatureWasCalled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"EXR Trial Bal by Period Excel", 'OnIsPerformantTrialBalanceByPeriodFeatureActive', '', false, false)]
    local procedure OnIsPerformantTrialBalanceByPeriodFeatureActive(var Active: Boolean)
    begin
        Active := PerformantFeatureActive;
        PerformantFeatureWasCalled := true;
    end;

    [EventSubscriber(ObjectType::Report, Report::"EXR Trial Bal. Prev Year Excel", 'OnIsPerformantTrialBalancePrevYearFeatureActive', '', false, false)]
    local procedure OnIsPerformantTrialBalancePrevYearFeatureActive(var Active: Boolean)
    begin
        Active := PerformantFeatureActive;
        PerformantFeatureWasCalled := true;
    end;
}