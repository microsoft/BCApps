codeunit 142071 "UT REP Order Entry"
{
    Permissions = TableData "Sales Shipment Header" = rimd,
                  TableData "Sales Shipment Line" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Sales Shipment per Package]
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    [HandlerFunctions('SalesShipmentPerPackageRequestPageHandler')]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesShipmentLine()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
    begin
        // Purpose of the test is to validate SalesShipment Line - OnAfterGetRecord trigger of Report ID - 10080.

        // Setup.
        Initialize();
        DocumentNo := CreateSalesShipmentDocument();
        Commit();  // Codeunit 314 Sales Shpt.-Printed OnRun trigger calls Commit();

        // Exercise.
        REPORT.Run(REPORT::"Sales Shipment per Package");  // Opens SalesShipmentPerPackageRequestPageHandler.

        // Verify: Package Tracking No. created on Sales Shipment Header.
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("Package Tracking No.", SalesShipmentHeader."Package Tracking No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateSalesShipmentDocument(): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        SalesShipmentHeader."Sell-to Customer No." := LibraryUTUtility.GetNewCode();
        SalesShipmentHeader."Package Tracking No." := LibraryUTUtility.GetNewCode();
        SalesShipmentHeader.Insert();
        SalesShipmentLine."Document No." := SalesShipmentHeader."No.";
        SalesShipmentLine."Sell-to Customer No." := SalesShipmentHeader."Sell-to Customer No.";
        SalesShipmentLine.Type := SalesShipmentLine.Type::Item;
        SalesShipmentLine.Insert();

        // Enqueue values for SalesShipmentPerPackageRequestPageHandler.
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");
        exit(SalesShipmentHeader."No.");
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentPerPackageRequestPageHandler(var SalesShipmentPerPackage: TestRequestPage "Sales Shipment per Package")
    var
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        SalesShipmentPerPackage."Sales Shipment Header".SetFilter("No.", DocumentNo);
        SalesShipmentPerPackage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

