codeunit 134072 "ERM ECSL Show VAT Entries"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ECSL Report]
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";

    [Test]
    [Scope('OnPrem')]
    procedure VATEntriesPageShownWhenSingleVATEntryConnectsToECSLLine()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        ECSLReport: TestPage "ECSL Report";
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 345778] VAT Entries page shown when single VAT Entry connects to the ECSL VAT Report Line

        // [GIVEN] An ECSL Report with line connects to the single VAT Entry
        MockVATReport(ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);

        // [GIVEN] An ECSL Report page opened
        ECSLReport.OpenEdit();
        ECSLReport.FILTER.SetFilter("No.", ECSLVATReportLine."Report No.");
        VATEntries.Trap();

        // [WHEN] User clicks "Show Lines" in the ECSL Report subpage
        ECSLReport.ECSLReportLines.ShowLines.Invoke();

        // [THEN] VAT Entries page shown
        VATEntry.Get(ECSLVATReportLineRelation."VAT Entry No.");
        VATEntries."Document No.".AssertEquals(VATEntry."Document No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATPreviewEntriesPageShownWhenMultipleVATEntriesConnectsToECSLLine()
    var
        ECSLVATReportLine: Record "ECSL VAT Report Line";
        ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation";
        VATEntry: Record "VAT Entry";
        ECSLReport: TestPage "ECSL Report";
        VATEntries: TestPage "VAT Entries";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 345778] VAT Entries page shown when multiple VAT Entries connects to the ECSL VAT Report Line

        // [GIVEN] An ECSL Report with line connects to multiple VAT Entries
        MockVATReport(ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);
        MockECSLToVATEntryRelation(ECSLVATReportLineRelation, ECSLVATReportLine);

        // [GIVEN] An ECSL Report page opened
        ECSLReport.OpenEdit();
        ECSLReport.FILTER.SetFilter("No.", ECSLVATReportLine."Report No.");
        VATEntries.Trap();

        // [WHEN] User clicks "Show Lines" in the ECSL Report subpage
        ECSLReport.ECSLReportLines.ShowLines.Invoke();

        // [THEN] VAT Entries page shown
        VATEntry.Get(ECSLVATReportLineRelation."VAT Entry No.");
        VATEntries."Document No.".AssertEquals(VATEntry."Document No.");
    end;

    local procedure MockVATReport(var ECSLVATReportLine: Record "ECSL VAT Report Line")
    var
        VATReportHeader: Record "VAT Report Header";
    begin
        MockVATReportConfiguration();
        VATReportHeader.Init();
        VATReportHeader."No." := LibraryUtility.GenerateGUID();
        VATReportHeader."VAT Report Config. Code" := VATReportHeader."VAT Report Config. Code"::"EC Sales List";
        VATReportHeader.Status := VATReportHeader.Status::Open;
        VATReportHeader.Insert();
        ECSLVATReportLine.Init();
        ECSLVATReportLine."Report No." := VATReportHeader."No.";
        ECSLVATReportLine."Line No." := 10000;
        ECSLVATReportLine.Insert();
    end;

    local procedure MockECSLToVATEntryRelation(var ECSLVATReportLineRelation: Record "ECSL VAT Report Line Relation"; ECSLVATReportLine: Record "ECSL VAT Report Line")
    begin
        ECSLVATReportLineRelation.Init();
        ECSLVATReportLineRelation."ECSL Report No." := ECSLVATReportLine."Report No.";
        ECSLVATReportLineRelation."ECSL Line No." := ECSLVATReportLine."Line No.";
        ECSLVATReportLineRelation."VAT Entry No." := MockVATEntry();
        ECSLVATReportLineRelation.Insert();
    end;

    local procedure MockVATEntry(): Integer
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.Init();
        VATEntry."Entry No." := LibraryUtility.GetNewRecNo(VATEntry, VATEntry.FieldNo("Entry No."));
        VATEntry."Document No." := LibraryUtility.GenerateGUID();
        VATEntry.Insert();
        exit(VATEntry."Entry No.");
    end;

    local procedure MockVATReportConfiguration()
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.DeleteAll();
        VATReportsConfiguration.Init();
        VATReportsConfiguration.Validate("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"EC Sales List");
        VATReportsConfiguration.Insert(true);
    end;
}

