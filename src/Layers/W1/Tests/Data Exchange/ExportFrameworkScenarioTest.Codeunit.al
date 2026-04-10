codeunit 134662 "Export Framework Scenario Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Data Exchange] [Export Launcher]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPaymentExport: Codeunit "Library - Payment Export";
        ValueNotFoundErr: Label 'The value %1 is not found in the exported line %2.';
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Export Framework Scenario Test");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Export Framework Scenario Test");

        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Export Framework Scenario Test");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleCustomersToFile()
    var
        Customer: Record Customer;
        DataExch: Record "Data Exch.";
        DataExchMapping: Record "Data Exch. Mapping";
        ExportLauncher: Codeunit "Export Launcher";
        Source: Variant;
        FirstCustomerNo: Code[20];
        SecondCustomerNo: Code[20];
    begin
        // Pre-Setup
        Initialize();
        DefineExportFormat(DataExchMapping, DATABASE::Customer, Customer.FieldNo("No."));

        // Setup
        FirstCustomerNo := LibrarySales.CreateCustomerNo();
        SecondCustomerNo := LibrarySales.CreateCustomerNo();
        Customer.SetFilter("No.", '%1|%2', FirstCustomerNo, SecondCustomerNo);

        // Exercise
        Source := Customer;
        ExportLauncher.SetSourceRecord(Source);
        ExportLauncher.Run(DataExchMapping);

        // Pre-Verify
        DataExch.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExch.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExch.FindLast();

        // Verify
        VerifyFileContent(DataExch, FirstCustomerNo, SecondCustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportMultipleVendorsToFile()
    var
        DataExch: Record "Data Exch.";
        DataExchMapping: Record "Data Exch. Mapping";
        Vendor: Record Vendor;
        ExportLauncher: Codeunit "Export Launcher";
        Source: Variant;
        FirstVendorNo: Code[20];
        SecondVendorNo: Code[20];
    begin
        // Pre-Setup
        Initialize();
        DefineExportFormat(DataExchMapping, DATABASE::Vendor, Vendor.FieldNo("No."));

        // Setup
        FirstVendorNo := LibraryPurchase.CreateVendorNo();
        SecondVendorNo := LibraryPurchase.CreateVendorNo();
        Vendor.SetFilter("No.", '%1|%2', FirstVendorNo, SecondVendorNo);

        // Exercise
        Source := Vendor;
        ExportLauncher.SetSourceRecord(Source);
        ExportLauncher.Run(DataExchMapping);

        // Pre-Verify
        DataExch.SetRange("Data Exch. Def Code", DataExchMapping."Data Exch. Def Code");
        DataExch.SetRange("Data Exch. Line Def Code", DataExchMapping."Data Exch. Line Def Code");
        DataExch.FindLast();

        // Verify
        VerifyFileContent(DataExch, FirstVendorNo, SecondVendorNo);
    end;

    local procedure DefineExportFormat(var DataExchMapping: Record "Data Exch. Mapping"; TableID: Integer; FieldID: Integer)
    var
        DataExchDef: Record "Data Exch. Def";
        DataExchFieldMapping: Record "Data Exch. Field Mapping";
    begin
        LibraryPaymentExport.CreateSimpleDataExchDefWithMapping2(
          DataExchDef, DataExchMapping, DataExchFieldMapping, TableID, FieldID);

        DataExchDef."Reading/Writing Codeunit" := CODEUNIT::"Exp. Writing Gen. Jnl.";
        DataExchDef."Reading/Writing XMLport" := XMLPORT::"Export Generic CSV";
        DataExchDef."Ext. Data Handling Codeunit" := CODEUNIT::"Save Data Exch. Blob Sample";
        DataExchDef.Modify();

        DataExchMapping."Mapping Codeunit" := CODEUNIT::"Export Mapping";
        DataExchMapping.Modify();
    end;

    local procedure VerifyFileContent(DataExch: Record "Data Exch."; FirstValue: Text; SecondValue: Text)
    var
        Line: Text;
    begin
        Line := LibraryTextFileValidation.ReadLine(DataExch."File Name", 1);
        Assert.AreNotEqual(0, StrPos(Line, FirstValue), StrSubstNo(ValueNotFoundErr, FirstValue, Line));

        Line := LibraryTextFileValidation.ReadLine(DataExch."File Name", 2);
        Assert.AreNotEqual(0, StrPos(Line, SecondValue), StrSubstNo(ValueNotFoundErr, SecondValue, Line));
    end;
}

