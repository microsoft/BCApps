codeunit 141045 "Report Vendor - Labels"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Report] [Vendor - Labels]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        NoTxt: Label '%1..%2';
        TableKey: Label 'No.=CONST(%1)';
        VendorBarCodeCap: Label 'VendBarCode_1_';
        VendorBarCode2Cap: Label 'VendBarCode_2_';

    [Test]
    [HandlerFunctions('VendorLevelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSingleVendorOnVendorLabel()
    var
        VendorNo: Code[20];
    begin
        // [SCENARIO] validate Vendor - OnAfterGetRecord Trigger of Report - 310 Vendor - Labels with Single Vendor.

        // [GIVEN] Create Vendor with Address ID and Enqueue values for VendorLevelRequestPageHandler.
        Initialize();
        VendorNo := CreateVendorWithAddressID();
        LibraryVariableStorage.Enqueue(StrSubstNo(NoTxt, VendorNo, VendorNo));
        Commit();  // Commit is required as Commit is explicitly using on Vendor - OnAfterGetRecord Trigger of Report ID - 310 Vendor - Labels.

        // [WHEN] Run report "Vendor - Labels"
        REPORT.Run(REPORT::"Vendor - Labels");  // Opens VendorLevelRequestPageHandler.

        // [THEN] Verify Vendor Bar Code on generated XML of Report - Vendor - Labels.
        LibraryReportDataset.LoadDataSetFile();
        VerifyVendorBarCodeOnVendorLabel(VendorNo, 1, VendorBarCodeCap);  // Hardcode Value 1 required for Known Column Number.
    end;

    [Test]
    [HandlerFunctions('VendorLevelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordMultipleVendorOnVendorLabel()
    var
        VendorNo: Code[20];
        VendorNo2: Code[20];
    begin
        // [SCENARIO] validate Vendor - OnAfterGetRecord Trigger of Report - 310 Vendor - Labels with Multiple Vendor.

        // [GIVEN] Create Vendor with Address ID and Enqueue values for VendorLevelRequestPageHandler.
        Initialize();
        VendorNo := CreateVendorWithAddressID();
        VendorNo2 := CreateVendorWithAddressID();
        LibraryVariableStorage.Enqueue(StrSubstNo(NoTxt, VendorNo, VendorNo2));
        Commit();  // Commit is required as Commit is explicitly using on Vendor - OnAfterGetRecord Trigger of Report ID - 310 Vendor - Labels.

        // [WHEN] Run report "Vendor - Labels"
        REPORT.Run(REPORT::"Vendor - Labels");  // Opens VendorLevelRequestPageHandler.

        // [THEN] Verify Vendor Bar Code on generated XML of Report - Vendor - Labels.
        LibraryReportDataset.LoadDataSetFile();
        VerifyVendorBarCodeOnVendorLabel(VendorNo, 1, VendorBarCodeCap);  // Hardcode Value 1 required for Known Column Number.
        VerifyVendorBarCodeOnVendorLabel(VendorNo2, 2, VendorBarCode2Cap);  // Hardcode Value 2 required for Known Column Number.
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAddressID(VendorNo: Code[20])
    var
        AddressID: Record "Address ID";
    begin
        AddressID."Table No." := DATABASE::Vendor;
        AddressID."Table Key" := StrSubstNo(TableKey, VendorNo);
        AddressID."Address ID" := Format(LibraryRandom.RandIntInRange(10000000, 20000000));  // Address ID of lengh - 8 required.
        AddressID."Bar Code System" := AddressID."Bar Code System"::"4-State Bar Code";
        AddressID."Address ID Check Date" := WorkDate();
        AddressID.Insert();
    end;

    local procedure CreateVendorWithAddressID(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Insert();
        CreateAddressID(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure VerifyVendorBarCodeOnVendorLabel(VendorNo: Code[20]; ColumnIndex: Integer; VendorBarCode: Text[30])
    var
        Vendor: Record Vendor;
        FormatAddr: Codeunit "Format Address";
        VendAddr: array[2, 8] of Text[50];
    begin
        Vendor.Get(VendorNo);
        FormatAddr.Vendor(VendAddr[ColumnIndex], Vendor);
        LibraryReportDataset.AssertElementWithValueExists(VendorBarCode, Format(FormatAddr.PrintBarCode(0)));  // Hardcode value 0 required.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorLevelRequestPageHandler(var VendoLabels: TestRequestPage "Vendor - Labels")
    var
        No: Variant;
        Format: Option "36 x 70 mm (3 columns)","37 x 70 mm (3 columns)","36 x 105 mm (2 columns)","37 x 105 mm (2 columns)","48 x 105 mm (2 columns - Bar Code)";
    begin
        LibraryVariableStorage.Dequeue(No);
        VendoLabels.Format.SetValue(Format::"48 x 105 mm (2 columns - Bar Code)");
        VendoLabels.Vendor.SetFilter("No.", No);
        VendoLabels.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

