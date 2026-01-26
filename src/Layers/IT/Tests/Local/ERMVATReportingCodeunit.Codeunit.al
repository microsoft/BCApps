codeunit 134055 "ERM VAT Reporting - Codeunit"
{
    // // [FEATURE] [VAT Report]

    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        VATReportMediator: Codeunit "VAT Report Mediator";
        LibraryVATUtils: Codeunit "Library - VAT Utils";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;
        SubmittedErr: Label 'This is not allowed because of the setup in the %1 window.', Comment = '%1=Table Caption;';
        EmptyErr: Label '%1 must be empty.', Comment = '%1=Table Caption';
        PrintErr: Label 'The expected and actual error does not match.';
        DecimalFormatTxt: Label '<sign><Integer Thousand><Decimals,3><Precision,2:2>', Locked = true;
        OriginalReportNoError: Label 'You must specify an original report for a report of type %1.', Comment = '%1=vat report type';

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLinesOrignalReportNo()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check Original Report No. Error comes after doing GetLines when VAT Report Type is Corrective.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Set VAT Report Type to Corrective and run Suggest Lines.
        VATReportHeader."VAT Report Type" := VATReportHeader."VAT Report Type"::Corrective;
        asserterror VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: Error occurs for Original Report No.
        Assert.ExpectedError(
          StrSubstNo(OriginalReportNoError, Format(VATReportHeader."VAT Report Type")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLinesStatus()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check Status Error comes after doing GetLines when the status is released.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Set Status to Release and run Suggest Lines.
        VATReportHeader.Status := VATReportHeader.Status::Released;
        asserterror VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: Error occurs for status.
        Assert.ExpectedTestFieldError(VATReportHeader.FieldCaption(Status), Format(VATReportHeader.Status::Released));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLinesVATReportConfigCode()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check VAT Report Config. Code Error comes after doing GetLines when VAT Report Config. Code is not set to option 1.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Set VAT Report Config. Code to blank and run Suggest Lines.
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::" ";
        asserterror VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: Error occurs for VAT Report Config Code.
        Assert.ExpectedTestFieldError(VATReportHeader.FieldCaption("VAT Report Config. Code"), ' ');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorGetLines()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // Check VAT Report Suggest Lines report gets run after doing GetLines and no lines come on date less than workdate in VAT Report Lines.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Update the start and end date to any date less than workdate and Run Suggest Lines.
        VATReportHeader."Start Date" := CalcDate('<-' + Format(LibraryRandom.RandInt(10) + 1) + 'Y>', WorkDate());
        VATReportHeader."End Date" := VATReportHeader."Start Date";
        VATReportHeader.Modify();
        VATReportMediator.GetLines(VATReportHeader);

        // 3. Verify: VAT Report Line is empty.
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        Assert.IsTrue(VATReportLine.IsEmpty, StrSubstNo(EmptyErr, VATReportLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RequestPageReport740Handler')]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorPrint()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // Check Print Function generates a report
        // The status is changed to release when the status is open.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);
        VATReportHeader.Status := VATReportHeader.Status::Open;
        VATReportHeader.Modify();
        CreateVATReportLine(VATReportHeader."No.", VATReportLine);

        // 2. Exercise: Run Print function.
        VATReportMediator.Print(VATReportHeader);

        // 3. Verify: A report is generated with the line
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('COMPANYNAME', COMPANYPROPERTY.DisplayName());
        Assert.AreEqual(7, LibraryReportDataset.RowCount(), PrintErr);

        // 3b. Verify: Status is released
        VATReportHeader.Get(VATReportHeader."No.");
        VATReportHeader.TestField(Status, VATReportHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,RequestPageReport740Handler')]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorPrintLines()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: array[7] of Record "VAT Report Line";
        VATEntry: Record "VAT Entry";
        I: Integer;
        Types: array[7] of Code[10];
    begin
        // Check Print Function generates a report containing all lines in the report with include in report = true
        // The status is changed to release when the status is open.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 1b. Setup: Create a set of lines of different types. Two lines of one type to check summing
        Types[1] := 'FE';
        Types[2] := 'FE';
        Types[3] := 'FR';
        Types[4] := 'NE';
        Types[5] := 'NR';
        Types[6] := 'FN';
        Types[7] := 'SE';
        VATEntry.FindLast();
        for I := 1 to 7 do begin
            CreateVATReportLine(VATReportHeader."No.", VATReportLine[I]);
            VATReportLine[I]."Record Identifier" := Types[I];
            VATReportLine[I].Base := LibraryRandom.RandDecInRange(1, 9999, 2);
            VATReportLine[I].Amount := LibraryRandom.RandDecInRange(1, 9999, 2);
            VATReportLine[I]."Posting Date" := LibraryUtility.GenerateRandomDate(20010101D, WorkDate());
            VATReportLine[I]."Document Type" := "Gen. Journal Document Type".FromInteger(LibraryRandom.RandIntInRange(2, 3)); // Maps to Invoice or Credit Memo
            VATReportLine[I]."Document No." :=
              LibraryUtility.GenerateRandomCode(VATReportLine[I].FieldNo("Document No."), DATABASE::"VAT Report Line");
            VATReportLine[I]."VAT Group Identifier" :=
              LibraryUtility.GenerateRandomCode(VATReportLine[I].FieldNo("VAT Group Identifier"), DATABASE::"VAT Report Line");
            VATReportLine[I]."Incl. in Report" := true;
            VATReportLine[I]."VAT Entry No." := VATEntry."Entry No.";
            VATReportLine[I].Modify();
        end;

        // 2. Exercise: Run Print function.
        VATReportMediator.Print(VATReportHeader);

        // 3. Verify: A report is generated with the lines
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('COMPANYNAME', COMPANYPROPERTY.DisplayName());
        for I := 1 to 7 do begin
            LibraryReportDataset.AssertElementWithValueExists(StrSubstNo('%1_Document_No', Types[I]), VATReportLine[I]."Document No.");
            LibraryReportDataset.AssertElementWithValueExists(
              StrSubstNo('%1_Document_Type', Types[I]), Format(VATReportLine[I]."Document Type"));
            LibraryReportDataset.AssertElementWithValueExists(
              StrSubstNo('%1_VAT_Group_Identifier', Types[I]), VATReportLine[I]."VAT Group Identifier");
            LibraryReportDataset.AssertElementWithValueExists(
              StrSubstNo('%1_Posting_Date', Types[I]), Format(VATReportLine[I]."Posting Date", 0, 3));
            LibraryReportDataset.AssertElementWithValueExists(
              StrSubstNo('%1_Base', Types[I]), Format(VATReportLine[I].Base, 0, DecimalFormatTxt));
            LibraryReportDataset.AssertElementWithValueExists(
              StrSubstNo('%1_Amount', Types[I]), Format(VATReportLine[I].Amount, 0, DecimalFormatTxt));
        end;

        // Check totals
        LibraryReportDataset.GetLastRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'FE_Total_Base', Format(VATReportLine[1].Base + VATReportLine[2].Base, 0, DecimalFormatTxt));
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'FE_Total_Amount', Format(VATReportLine[1].Amount + VATReportLine[2].Amount, 0, DecimalFormatTxt));
        for I := 3 to 7 do begin
            LibraryReportDataset.AssertCurrentRowValueEquals(
              StrSubstNo('%1_Total_Base', Types[I]), Format(VATReportLine[I].Base, 0, DecimalFormatTxt));
            LibraryReportDataset.AssertCurrentRowValueEquals(
              StrSubstNo('%1_Total_Amount', Types[I]), Format(VATReportLine[I].Amount, 0, DecimalFormatTxt));
        end;
        Assert.AreEqual(8, LibraryReportDataset.RowCount(), PrintErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorReopenAfterSubmit()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Check Error comes for Not allowed to reopen after submit when the Modify Submitted Reports is False in VAT Report Setup.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Update status to submitted and Reopen.
        VATReportHeader.Status := VATReportHeader.Status::Submitted;
        asserterror VATReportMediator.Reopen(VATReportHeader);

        // 3. Verify: Error occurs for not allowed to reopen due to the VAT Report Setup.
        Assert.ExpectedError(StrSubstNo(SubmittedErr, VATReportSetup.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorReopenAfterRelease()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check Status gets updated to open after reopen when the earlier status was released.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Update status to Released and Reopen.
        VATReportHeader.Status := VATReportHeader.Status::Released;
        VATReportMediator.Reopen(VATReportHeader);

        // 3. Verify: Status gets updated to Open.
        VATReportHeader.Get(VATReportHeader."No.");
        VATReportHeader.TestField(Status, VATReportHeader.Status::Open);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorRelease()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportErrorLog: TestPage "VAT Report Error Log";
    begin
        // Check Error comes for No VAT Report Lines when changing the status to release.
        // Report can be released without any VAT Report Lines, fixed in TFS330857

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Run the Release function.
        VATReportErrorLog.Trap();
        VATReportMediator.Release(VATReportHeader);

        // 3. Verify: Status gets updated to Released.
        VATReportHeader.Get(VATReportHeader."No.");
        VATReportHeader.TestField(Status, VATReportHeader.Status::Released);
    end;

    [Test]
    [HandlerFunctions('ExportVATTransactionsHandler')]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorExportForStatusReleased()
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        // Check the Export Report runs successfully when VAT Report Header status is released.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);

        // 2. Exercise: Update the status to released.
        VATReportHeader.Status := VATReportHeader.Status::Released;

        // 3. Verify: No error occurs while running the Export.
        VATReportMediator.Export(VATReportHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ExportVATTransactionsHandler')]
    [Scope('OnPrem')]
    procedure TestVATReportMediatorExportForStatusOpen()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportLine: Record "VAT Report Line";
    begin
        // Check that VAT Report Header Status gets changed to released while export when status is open.

        // 1. Setup: Create VAT Report Header.
        Initialize();
        CreateVATReportHeader(VATReportHeader);
        CreateVATReportLine(VATReportHeader."No.", VATReportLine);

        // 2. Exercise: Run Export.
        VATReportMediator.Export(VATReportHeader);

        // 3. Verify: Status get updated to released.
        VATReportHeader.Get(VATReportHeader."No.");
        VATReportHeader.TestField(Status, VATReportHeader.Status::Released);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        CreateVATReportSetup();
        UpdateCompanyInformation();
        Commit();
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Create VAT Report Setup.
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert();
        VATReportSetup."No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        VATReportSetup."Intermediary VAT Reg. No." := LibraryVATUtils.GenerateVATRegistrationNumber();
        VATReportSetup.Modify();
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.Init();
        VATReportHeader.Insert(true);
    end;

    local procedure CreateVATReportLine(VATReportHeaderNo: Code[20]; var VATReportLine: Record "VAT Report Line")
    var
        NextLineNo: Integer;
    begin
        NextLineNo := 1;
        if VATReportLine.FindLast() then
            NextLineNo := VATReportLine."Line No." + 1;

        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHeaderNo;
        VATReportLine."Line No." := NextLineNo;
        VATReportLine.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Message: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ExportVATTransactionsHandler(var ExportVATTransactions: TestRequestPage "Export VAT Transactions")
    begin
        ExportVATTransactions.Cancel().Invoke();
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation.County := LibraryUtility.GenerateGUID();
        CompanyInformation."Fiscal Code" := LibraryUtility.GenerateGUID();
        CompanyInformation."VAT Registration No." := LibraryVATUtils.GenerateVATRegistrationNumber();
        CompanyInformation."Industrial Classification" := '35.11.00';
        CompanyInformation.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageReport740Handler(var PrintReport: TestRequestPage "VAT Report Print")
    begin
        PrintReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

