codeunit 142080 "Test ServiceRep"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Selection: Option Countries,"Type of Services",Both;

    [Test]
    [HandlerFunctions('RPHCrossborderServices')]
    [Scope('OnPrem')]
    procedure TestCrossborderServicesCountries()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();

        // Excercise
        LibraryVariableStorage.Enqueue(Selection::Countries);
        VATEntry.SetRange("Posting Date", CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        REPORT.Run(REPORT::"Crossborder Services", true, false, VATEntry);

        // Verify Report
        LibraryReportDataset.LoadDataSetFile();
        VerifyReport(VATEntry, 0, 0, Selection::Countries);
    end;

    [Test]
    [HandlerFunctions('RPHCrossborderServices')]
    [Scope('OnPrem')]
    procedure TestCrossborderServicesTypeOfService()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();

        // Excercise
        LibraryVariableStorage.Enqueue(Selection::"Type of Services");
        VATEntry.SetRange("Posting Date", CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        REPORT.Run(REPORT::"Crossborder Services", true, false, VATEntry);

        // Verify Report
        LibraryReportDataset.LoadDataSetFile();
        VerifyReport(VATEntry, 0, 0, Selection::"Type of Services");
    end;

    [Test]
    [HandlerFunctions('RPHCrossborderServices')]
    [Scope('OnPrem')]
    procedure TestCrossborderServicesBoth()
    var
        VATEntry: Record "VAT Entry";
    begin
        Initialize();

        // Excercise
        LibraryVariableStorage.Enqueue(Selection::Both);
        VATEntry.SetRange("Posting Date", CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        REPORT.Run(REPORT::"Crossborder Services", true, false, VATEntry);

        // Verify Report
        LibraryReportDataset.LoadDataSetFile();
        VerifyReport(VATEntry, 1, 2, Selection::Both);
    end;

    local procedure VerifyReport(var VATEntry: Record "VAT Entry"; GroupNoSection1: Integer; GroupNoSection2: Integer; SelectionNo: Integer)
    begin
        VATEntry.SetFilter("Country/Region Code", '<>%1', '');
        VATEntry.SetCurrentKey("Country/Region Code");
        VATEntry.FindSet();
        repeat
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('GroupNo', GroupNoSection1);
            LibraryReportDataset.AssertCurrentRowValueEquals('VATEntryCountrySelectionNo', SelectionNo);
            LibraryReportDataset.AssertCurrentRowValueEquals('VATEntryCountry_Entry_No_', VATEntry."Entry No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATEntryCountry__Country_Region_Code_', VATEntry."Country/Region Code");
            case VATEntry.Type of
                VATEntry.Type::Sale:
                    LibraryReportDataset.AssertCurrentRowValueEquals('SalesToCust', -Round(VATEntry.Base, 1));
                VATEntry.Type::Purchase:
                    LibraryReportDataset.AssertCurrentRowValueEquals('PurchFromVend', Round(VATEntry.Base, 1))
                else
                    Assert.Fail('Only Sales and Purchase expected');
            end;
        until VATEntry.Next() = 0;

        VATEntry.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        VATEntry.SetCurrentKey("Gen. Prod. Posting Group");
        VATEntry.FindSet();
        repeat
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('GroupNo', GroupNoSection2);
            LibraryReportDataset.AssertCurrentRowValueEquals('VATEntryGenProdPostingGroupSelectionNo', SelectionNo);
            LibraryReportDataset.AssertCurrentRowValueEquals('VATEntryGenProdPostingGroup_Entry_No_', VATEntry."Entry No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('VATEntryGenProdPostingGroup__Gen__Prod__Posting_Group_', VATEntry."Gen. Prod. Posting Group");
            case VATEntry.Type of
                VATEntry.Type::Sale:
                    LibraryReportDataset.AssertCurrentRowValueEquals('SalesToCust_Control1160023', -Round(VATEntry.Base, 1));
                VATEntry.Type::Purchase:
                    LibraryReportDataset.AssertCurrentRowValueEquals('PurchFromVend_Control1160025', Round(VATEntry.Base, 1))
                else
                    Assert.Fail('Only Sales and Purchase expected');
            end;
        until VATEntry.Next() = 0;
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'No more rows should exist');
    end;

    local procedure Initialize()
    begin
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RPHCrossborderServices(var RequestPage: TestRequestPage "Crossborder Services")
    var
        Selection: Variant;
    begin
        LibraryVariableStorage.Dequeue(Selection);

        RequestPage.Selection.SetValue(Selection);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());

        LibraryVariableStorage.AssertEmpty();
    end;
}

