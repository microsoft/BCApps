codeunit 137381 "CodeCoverage Performance Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Performance]
        isInitialized := false;
    end;

    var
        CodeCoverage: Record "Code Coverage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        LibraryCalcComplexity: Codeunit "Library - Calc. Complexity";
        isInitialized: Boolean;
        NotLinearCCErr: Label 'Time complexity is not O(n)';
        NotQuadraticCalcErr: Label 'Time complexity is not O(n^2)';

    [Test]
    procedure RerunTextMapperOnPaymentReconciliationLines()
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TextToAccMapping: Record "Text-to-Account Mapping";
        MatchBankPayments: Codeunit "Match Bank Payments";
        DebitAccNo: Code[20];
        CreditAccNo: Code[20];
        NoOfEntries: array[3] of Integer;
        NoOfHits: array[3] of Integer;
        TryNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [Bank Payment Application] [Bank Reconciliation] [Match]
        // [SCENARIO 410963] Rerun text mapper for Payment Reconciliation Lines.
        Initialize();

        NoOfEntries[1] := 4;
        NoOfEntries[2] := 40;
        NoOfEntries[3] := 200;

        // [GIVEN] Three Text-to-Account-Mapping lines with Mapping Text "text 1", "text 2", "text 3".
        DebitAccNo := LibraryERM.CreateGLAccountNo();
        CreditAccNo := LibraryERM.CreateGLAccountNo();
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, 'text 1', CreditAccNo, DebitAccNo);
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, 'text 2', CreditAccNo, DebitAccNo);
        LibraryERM.CreateAccountMappingGLAccount(TextToAccMapping, 'text 3', CreditAccNo, DebitAccNo);

        // [GIVEN] Try 1: Create 4 Payment Reconciliation Lines with Transaction Text "text 2".
        // [GIVEN] Try 2: Create 40 Payment Reconciliation Lines with Transaction Text "text 2".
        // [GIVEN] Try 3: Create 200 Payment Reconciliation Lines with Transaction Text "text 2".
        for TryNo := 1 to ArrayLen(NoOfEntries) do begin
            LibraryERM.CreateBankAccReconciliation(
                BankAccReconciliation, LibraryERM.CreateBankAccountNo(), BankAccReconciliation."Statement Type"::"Payment Application");

            BankAccReconciliation."Statement Date" := WorkDate();
            BankAccReconciliation.Modify();

            for i := 1 to NoOfEntries[TryNo] do
                CreateBankAccReconLineWithTransactionText(BankAccReconciliationLine, BankAccReconciliation, 'text 2');

            // [WHEN] Turn on code coverage and run re-apply text to account mapping rules to reconciliation lines.
            CodeCoverageMgt.StartApplicationCoverage();
            MatchBankPayments.RerunTextMapper(BankAccReconciliationLine);
            CodeCoverageMgt.StopApplicationCoverage();
            NoOfHits[TryNo] :=
                GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, Codeunit::"Match Bank Payments", 'StatementLineAlreadyApplied');
        end;

        // [THEN] Time complexity is O(n), where n is a number of Payment Reconciliation Lines.
        Assert.IsTrue(
          LibraryCalcComplexity.IsLinear(NoOfEntries[1], NoOfEntries[2], NoOfEntries[3], NoOfHits[1], NoOfHits[2], NoOfHits[3]),
          NotLinearCCErr);

        // tear down
        TextToAccMapping.DeleteAll();
    end;

    [Test]
    procedure CertifyRoutingWhenEachOperationPointsToTwoNext()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        OperationNo: Code[10];
        NextOperationNo: Code[30];
        NoOfEntries: array[4] of Integer;
        NoOfHits: array[4] of Integer;
        TryNo: Integer;
        i: Integer;
    begin
        // [FEATURE] [SCM] [Routing]
        // [SCENARIO 403568] Certify Routing when multiple routing lines points to the next two routing lines.
        Initialize();

        NoOfEntries[1] := 10;
        NoOfEntries[2] := 20;
        NoOfEntries[3] := 30;
        NoOfEntries[4] := 40;

        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);

        for TryNo := 1 to ArrayLen(NoOfEntries) do begin
            // [GIVEN] Try 1: Routing with 10 lines. Next Operation No. for 01 is '02|03', for 02 is '03|04',..,for 09 is '10', 10 is ''.
            // [GIVEN] Try 2: Routing with 20 lines. Next Operation No. for 01 is '02|03', for 02 is '03|04',..,for 19 is '20', 20 is ''.
            // [GIVEN] Try 3: Routing with 30 lines. Next Operation No. for 01 is '02|03', for 02 is '03|04',..,for 19 is '20', 20 is ''.
            // [GIVEN] Try 4: Routing with 40 lines. Next Operation No. for 01 is '02|03', for 02 is '03|04',..,for 39 is '40', 40 is ''.
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);

            OperationNo := '00';
            for i := 1 to NoOfEntries[TryNo] do begin
                OperationNo := IncStr(OperationNo);
                NextOperationNo := StrSubstNo('%1|%2', IncStr(OperationNo), IncStr(IncStr(OperationNo)));
                if i = NoOfEntries[TryNo] - 1 then
                    NextOperationNo := IncStr(OperationNo);
                if i = NoOfEntries[TryNo] then
                    NextOperationNo := '';
                CreateRoutingLineForWorkCenter(RoutingLine, RoutingHeader, OperationNo, WorkCenter."No.", NextOperationNo);
            end;

            // [WHEN] Turn on code coverage and certify routing.
            CodeCoverageMgt.StartApplicationCoverage();
            UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);
            CodeCoverageMgt.StopApplicationCoverage();
            NoOfHits[TryNo] :=
                GetCodeCoverageForObject(CodeCoverage."Object Type"::Codeunit, Codeunit::"Check Routing Lines", 'NameValueBufferEnqueue');
        end;

        // [THEN] Time complexity of certifying routing is better than O(n^2), where n is a number of routing lines that point to the next two lines.
        Assert.IsTrue(
            LibraryCalcComplexity.IsQuadratic(NoOfEntries[1], NoOfEntries[2], NoOfEntries[3], NoOfEntries[4], NoOfHits[1], NoOfHits[2], NoOfHits[3], NoOfHits[4]),
            NotQuadraticCalcErr);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"CodeCoverage Performance Tests");
        CodeCoverageMgt.StopApplicationCoverage();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"CodeCoverage Performance Tests");

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"CodeCoverage Performance Tests");
    end;

    local procedure CreateBankAccReconLineWithTransactionText(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation"; TransactionText: Text[140])
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Text", TransactionText);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateRoutingLineForWorkCenter(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; OperationNo: Code[10]; WorkCenterNo: Code[20]; NextOperationNo: Code[30])
    begin
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', OperationNo, "Capacity Type Routing"::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Next Operation No.", NextOperationNo);
        RoutingLine.Modify(true);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
    end;

    local procedure UpdateRoutingStatus(var RoutingHeader: Record "Routing Header"; Status: Enum "Routing Status")
    begin
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
    end;
}

