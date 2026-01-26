codeunit 134059 "ERM VAT Reporting - Pages"
{
    // // [FEATURE] [VAT Report] [UI]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        RecordNotCreatedError: Label '%1 record was not created as expected.';
        ValueNotAssignedError: Label 'Value was not assigned as expected.';

    [Test]
    [HandlerFunctions('VATEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure VATReportSubformAmount_OnAssistEdit()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReport: TestPage "VAT Report";
    begin
        // Check VAT Entries Page is running successfully and displaying the correct VAT Entries when click OnAssitEdit for Amount field.

        Initialize();
        CreateVATReportSetup();

        // 1. Setup: Create VAT Report Header, VAT Report Line and VAT Report Line Mapping.
        CreateVATReportHeader(VATReportHeader);
        CreateVATReportLine(VATReportHeader."No.");
        CreateVATReportLineMapping(VATReportHeader."No.");

        // 2. Exercise: Open VAT Report Page and click AssistEdit for Amount field on VAT Report Subform.
        VATReport.OpenEdit();
        VATReport.FILTER.SetFilter("No.", VATReportHeader."No.");
        VATReport.VATReportLines.Base.AssistEdit();

        // 3. Verify: Verify VAT Entry No. Verification done in VATEntriesPageHandler.
    end;

    [Test]
    [HandlerFunctions('NoSeriesHandler')]
    [Scope('OnPrem')]
    procedure VATReportNo_OnAssistEdit()
    var
        VATReportPage: TestPage "VAT Report";
    begin
        Initialize();
        CreateVATReportSetup();

        // Open VAT Report Page.
        VATReportPage.OpenNew();
        VATReportPage."No.".AssistEdit();
        Assert.AreNotEqual(VATReportPage."No.".Value, '', ValueNotAssignedError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportList_Card()
    var
        VATReportHeader: Record "VAT Report Header";
        VATReportPage: TestPage "VAT Report";
        VATReportListPage: TestPage "VAT Report List";
    begin
        Initialize();
        CreateVATReportSetup();

        // Open VAT Report List.
        CreateVATReportHeader(VATReportHeader);
        VATReportListPage.OpenView();
        VATReportListPage.GotoRecord(VATReportHeader);

        // Open VAT Report Page.
        VATReportPage.Trap();
        VATReportListPage.Card.Invoke();

        // Verify correct VAT Report was opened.
        VATReportPage."No.".AssertEquals(VATReportHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATReportSetup_OnOpen()
    var
        VATReportSetup: Record "VAT Report Setup";
        VATReportSetupPage: TestPage "VAT Report Setup";
    begin
        Initialize();

        // Delete VAT Report Setup.
        VATReportSetup.DeleteAll();

        // Open VAT Report Setup Page.
        VATReportSetupPage.OpenEdit();
        VATReportSetupPage.OK().Invoke();

        // Verify that VAT Report Setup was created.
        Assert.IsTrue(VATReportSetup.Get(), RecordNotCreatedError);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateVATReportSetup()
    var
        VATReportSetup: Record "VAT Report Setup";
    begin
        // Create VAT Report Setup.
        if VATReportSetup.IsEmpty() then
            VATReportSetup.Insert();
        VATReportSetup."No. Series" := LibraryUtility.GetGlobalNoSeriesCode();
        VATReportSetup.Modify();
    end;

    local procedure CreateVATReportHeader(var VATReportHeader: Record "VAT Report Header")
    begin
        VATReportHeader.Init();
        VATReportHeader.Insert(true);
    end;

    local procedure CreateVATReportLine(VATReportHeaderNo: Code[20])
    var
        VATReportLine: Record "VAT Report Line";
    begin
        VATReportLine.Init();
        VATReportLine."VAT Report No." := VATReportHeaderNo;
        VATReportLine."Line No." := 1;
        VATReportLine.Insert();
    end;

    local procedure CreateVATReportLineMapping(VATReportHeaderNo: Code[20])
    var
        VATReportLineRelation: Record "VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.FindFirst();
        VATReportLineRelation.Init();
        VATReportLineRelation."VAT Report No." := VATReportHeaderNo;
        VATReportLineRelation."VAT Report Line No." := 1;
        VATReportLineRelation."Table No." := DATABASE::"VAT Entry";
        VATReportLineRelation."Entry No." := VATEntry."Entry No.";
        LibraryVariableStorage.Enqueue(VATEntry."Entry No.");
        VATReportLineRelation.Insert();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VATEntriesPageHandler(var VATEntries: TestPage "VAT Entries")
    var
        EntryNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(EntryNo);
        VATEntries.First();
        VATEntries."Entry No.".AssertEquals(EntryNo);
        VATEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesHandler(var NoSeriesPage: TestPage "No. Series")
    begin
        NoSeriesPage.OK().Invoke();
    end;
}

