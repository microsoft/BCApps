// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument.Format;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 135647 "EDoc MLLM Tests"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibraryLowerPermission: Codeunit "Library - Lower Permissions";

    [Test]
    procedure MapHeader_FullInvoice()
    var
        TempHeader: Record "E-Document Purchase Header" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        HeaderObj: JsonObject;
    begin
        // [SCENARIO] MapHeaderFromJson maps all fields from a complete UBL invoice JSON
        LibraryLowerPermission.SetOutsideO365Scope();
        EnsureGLSetup();

        HeaderObj := BuildFullHeaderJson();

        EDocMLLMSchemaHelper.MapHeaderFromJson(HeaderObj, TempHeader);

        Assert.AreEqual('MLLM-INV-001', TempHeader."Sales Invoice No.", 'Sales Invoice No.');
        Assert.AreEqual(DMY2Date(15, 3, 2024), TempHeader."Document Date", 'Document Date');
        Assert.AreEqual(DMY2Date(15, 4, 2024), TempHeader."Due Date", 'Due Date');
        Assert.AreEqual('XYZ', TempHeader."Currency Code", 'Currency Code');
        Assert.AreEqual('PO-5678', TempHeader."Purchase Order No.", 'Purchase Order No.');
        Assert.AreEqual('Net 30', TempHeader."Payment Terms", 'Payment Terms');
        Assert.AreEqual('Contoso Supplies Ltd.', TempHeader."Vendor Company Name", 'Vendor Company Name');
        Assert.AreEqual('123 Bill Ave, Seattle 98101, US', TempHeader."Vendor Address", 'Vendor Address');
        Assert.AreEqual('US-VAT-12345', TempHeader."Vendor VAT Id", 'Vendor VAT Id');
        Assert.AreEqual('John Doe', TempHeader."Vendor Contact Name", 'Vendor Contact Name');
        Assert.AreEqual('Microsoft Corporation', TempHeader."Customer Company Name", 'Customer Company Name');
        Assert.AreEqual('456 Main St, Redmond 98052, US', TempHeader."Customer Address", 'Customer Address');
        Assert.AreEqual('US-VAT-67890', TempHeader."Customer VAT Id", 'Customer VAT Id');
        Assert.AreEqual('789 Ship Rd, Bellevue 98004, US', TempHeader."Shipping Address", 'Shipping Address');
        Assert.AreEqual('Warehouse Team', TempHeader."Shipping Address Recipient", 'Shipping Address Recipient');
        Assert.AreEqual('Contoso Billing Dept', TempHeader."Remittance Address Recipient", 'Remittance Address Recipient');
        Assert.AreEqual(37.5, TempHeader."Total VAT", 'Total VAT');
        Assert.AreEqual(250.0, TempHeader."Sub Total", 'Sub Total');
        Assert.AreEqual(5.0, TempHeader."Total Discount", 'Total Discount');
        Assert.AreEqual(287.5, TempHeader.Total, 'Total');
        Assert.AreEqual(287.5, TempHeader."Amount Due", 'Amount Due');
    end;

    [Test]
    procedure MapHeader_MissingOptionalFields()
    var
        TempHeader: Record "E-Document Purchase Header" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        HeaderObj: JsonObject;
    begin
        // [SCENARIO] Missing nested objects (delivery, payment_means) leave fields empty without error
        LibraryLowerPermission.SetOutsideO365Scope();
        EnsureGLSetup();

        HeaderObj.Add('id', 'INV-MINIMAL');
        HeaderObj.Add('issue_date', '2024-01-01');

        EDocMLLMSchemaHelper.MapHeaderFromJson(HeaderObj, TempHeader);

        Assert.AreEqual('INV-MINIMAL', TempHeader."Sales Invoice No.", 'Sales Invoice No.');
        Assert.AreEqual(DMY2Date(1, 1, 2024), TempHeader."Document Date", 'Document Date');
        Assert.AreEqual(0D, TempHeader."Due Date", 'Due Date should be empty');
        Assert.AreEqual('', TempHeader."Currency Code", 'Currency Code should be empty');
        Assert.AreEqual('', TempHeader."Purchase Order No.", 'Purchase Order No. should be empty');
        Assert.AreEqual('', TempHeader."Payment Terms", 'Payment Terms should be empty');
        Assert.AreEqual('', TempHeader."Vendor Company Name", 'Vendor Company Name should be empty');
        Assert.AreEqual('', TempHeader."Vendor Address", 'Vendor Address should be empty');
        Assert.AreEqual('', TempHeader."Customer Company Name", 'Customer Company Name should be empty');
        Assert.AreEqual('', TempHeader."Shipping Address", 'Shipping Address should be empty');
        Assert.AreEqual('', TempHeader."Shipping Address Recipient", 'Shipping Address Recipient should be empty');
        Assert.AreEqual('', TempHeader."Remittance Address Recipient", 'Remittance Address Recipient should be empty');
        Assert.AreEqual(0, TempHeader."Total VAT", 'Total VAT should be zero');
        Assert.AreEqual(0, TempHeader."Sub Total", 'Sub Total should be zero');
        Assert.AreEqual(0, TempHeader.Total, 'Total should be zero');
    end;

    [Test]
    procedure MapHeader_EmptyObject()
    var
        TempHeader: Record "E-Document Purchase Header" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        HeaderObj: JsonObject;
    begin
        // [SCENARIO] Empty JSON object leaves all fields empty/zero without error
        LibraryLowerPermission.SetOutsideO365Scope();
        EnsureGLSetup();

        EDocMLLMSchemaHelper.MapHeaderFromJson(HeaderObj, TempHeader);

        Assert.AreEqual('', TempHeader."Sales Invoice No.", 'Sales Invoice No. should be empty');
        Assert.AreEqual(0D, TempHeader."Document Date", 'Document Date should be empty');
        Assert.AreEqual(0D, TempHeader."Due Date", 'Due Date should be empty');
        Assert.AreEqual('', TempHeader."Currency Code", 'Currency Code should be empty');
        Assert.AreEqual('', TempHeader."Vendor Company Name", 'Vendor Company Name should be empty');
        Assert.AreEqual('', TempHeader."Customer Company Name", 'Customer Company Name should be empty');
        Assert.AreEqual(0, TempHeader."Sub Total", 'Sub Total should be zero');
        Assert.AreEqual(0, TempHeader.Total, 'Total should be zero');
        Assert.AreEqual(0, TempHeader."Amount Due", 'Amount Due should be zero');
    end;

    [Test]
    procedure MapLines_MultipleLines()
    var
        TempLine: Record "E-Document Purchase Line" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        LinesArray: JsonArray;
    begin
        // [SCENARIO] Three invoice lines produce correct line numbers and field values
        LibraryLowerPermission.SetOutsideO365Scope();

        LinesArray := BuildThreeLineArray();

        EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, 1, TempLine, '');

        TempLine.FindSet();
        Assert.AreEqual(10000, TempLine."Line No.", 'First line number');
        Assert.AreEqual('Consulting Services', TempLine.Description, 'Line 1 Description');
        Assert.AreEqual('SVC-001', TempLine."Product Code", 'Line 1 Product Code');
        Assert.AreEqual(5, TempLine.Quantity, 'Line 1 Quantity');
        Assert.AreEqual('HRS', TempLine."Unit of Measure", 'Line 1 Unit of Measure');
        Assert.AreEqual(40, TempLine."Unit Price", 'Line 1 Unit Price');
        Assert.AreEqual(200, TempLine."Sub Total", 'Line 1 Sub Total');
        Assert.AreEqual(15, TempLine."VAT Rate", 'Line 1 VAT Rate');
        Assert.AreEqual(5, TempLine."Total Discount", 'Line 1 Total Discount');

        TempLine.Next();
        Assert.AreEqual(20000, TempLine."Line No.", 'Second line number');
        Assert.AreEqual('Office Supplies', TempLine.Description, 'Line 2 Description');
        Assert.AreEqual('MAT-002', TempLine."Product Code", 'Line 2 Product Code');
        Assert.AreEqual(10, TempLine.Quantity, 'Line 2 Quantity');
        Assert.AreEqual('PCS', TempLine."Unit of Measure", 'Line 2 Unit of Measure');
        Assert.AreEqual(3, TempLine."Unit Price", 'Line 2 Unit Price');
        Assert.AreEqual(30, TempLine."Sub Total", 'Line 2 Sub Total');
        Assert.AreEqual(10, TempLine."VAT Rate", 'Line 2 VAT Rate');

        TempLine.Next();
        Assert.AreEqual(30000, TempLine."Line No.", 'Third line number');
        Assert.AreEqual('Express Delivery', TempLine.Description, 'Line 3 Description');
        Assert.AreEqual('DLV-003', TempLine."Product Code", 'Line 3 Product Code');
        Assert.AreEqual(1, TempLine.Quantity, 'Line 3 Quantity');
        Assert.AreEqual('EA', TempLine."Unit of Measure", 'Line 3 Unit of Measure');
        Assert.AreEqual(20, TempLine."Unit Price", 'Line 3 Unit Price');
        Assert.AreEqual(20, TempLine."Sub Total", 'Line 3 Sub Total');
        Assert.AreEqual(15, TempLine."VAT Rate", 'Line 3 VAT Rate');
    end;

    [Test]
    procedure MapLines_ZeroQuantity()
    var
        TempLine: Record "E-Document Purchase Line" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        LinesArray: JsonArray;
        LineObj: JsonObject;
        ItemObj: JsonObject;
        QuantityObj: JsonObject;
    begin
        // [SCENARIO] Line with an explicit quantity of 0 keeps 0
        LibraryLowerPermission.SetOutsideO365Scope();

        ItemObj.Add('name', 'Zero Qty Item');
        QuantityObj.Add('value', 0);
        QuantityObj.Add('unit_code', 'PCS');
        LineObj.Add('item', ItemObj);
        LineObj.Add('invoiced_quantity', QuantityObj);
        LinesArray.Add(LineObj);

        EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, 1, TempLine, '');

        TempLine.FindFirst();
        Assert.AreEqual(0, TempLine.Quantity, 'Explicit zero quantity should be kept as 0');
        Assert.AreEqual('Zero Qty Item', TempLine.Description, 'Description');
    end;

    [Test]
    procedure MapLines_MissingQuantity()
    var
        TempLine: Record "E-Document Purchase Line" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        LinesArray: JsonArray;
        LineObj: JsonObject;
        ItemObj: JsonObject;
    begin
        // [SCENARIO] Line without a quantity in the JSON defaults to 1
        LibraryLowerPermission.SetOutsideO365Scope();

        ItemObj.Add('name', 'No Qty Item');
        LineObj.Add('item', ItemObj);
        LinesArray.Add(LineObj);

        EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, 1, TempLine, '');

        TempLine.FindFirst();
        Assert.AreEqual(1, TempLine.Quantity, 'Missing quantity should default to 1');
        Assert.AreEqual('No Qty Item', TempLine.Description, 'Description');
    end;

    [Test]
    procedure MapLines_EmptyArray()
    var
        TempLine: Record "E-Document Purchase Line" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        LinesArray: JsonArray;
    begin
        // [SCENARIO] Empty lines array produces no line records
        LibraryLowerPermission.SetOutsideO365Scope();

        EDocMLLMSchemaHelper.MapLinesFromJson(LinesArray, 1, TempLine, '');

        Assert.IsTrue(TempLine.IsEmpty(), 'No lines should be inserted for empty array');
    end;

    [Test]
    procedure PreferredImpl_ReturnsMLLM()
    var
        EDocPDFFileFormat: Codeunit "E-Doc. PDF File Format";
    begin
        // [SCENARIO] PDF documents use MLLM as the preferred structure data implementation
        LibraryLowerPermission.SetOutsideO365Scope();

        Assert.AreEqual(
            "Structure Received E-Doc."::MLLM,
            EDocPDFFileFormat.PreferredStructureDataImplementation(),
            'PDF processing should return MLLM');
    end;

#if not CLEAN29
    [Test]
    procedure PreferredImpl_EventOverride_TakesPrecedence()
    var
        EDocPDFFileFormat: Codeunit "E-Doc. PDF File Format";
        EDocMLLMTests: Codeunit "EDoc MLLM Tests";
    begin
        // [SCENARIO] An event subscriber can override the default preferred implementation
        LibraryLowerPermission.SetOutsideO365Scope();

        BindSubscription(EDocMLLMTests);

        Assert.AreEqual(
            "Structure Received E-Doc."::ADI,
            EDocPDFFileFormat.PreferredStructureDataImplementation(),
            'Event override should take precedence over the default');

        UnbindSubscription(EDocMLLMTests);
    end;

#pragma warning disable AL0432
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. PDF File Format", OnAfterSetIStructureReceivedEDocumentForPdf, '', false, false)]
    local procedure OverrideToADI(var Result: Enum "Structure Received E-Doc.")
    begin
        Result := "Structure Received E-Doc."::ADI;
    end;
#pragma warning restore AL0432
#endif

    [Test]
    procedure MapHeader_TotalNotTaxRate()
    var
        TempHeader: Record "E-Document Purchase Header" temporary;
        EDocMLLMSchemaHelper: Codeunit "E-Doc. MLLM Schema Helper";
        HeaderObj: JsonObject;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] When payable_amount equals the tax rate (25), the corrected total should be 312.5
        // This reproduces the bug where the model emits the tax rate into payable_amount
        LibraryLowerPermission.SetOutsideO365Scope();
        EnsureGLSetup();

        HeaderObj.ReadFrom(NavApp.GetResourceAsText('mllm/mllm-header-tax-rate-as-total.json'));

        EDocMLLMSchemaHelper.MapHeaderFromJson(HeaderObj, TempHeader);

        // Before the fix: TempHeader.Total = 25 (the tax rate, not the true total)
        // After the fix: TempHeader.Total = 312.5 (tax_inclusive_amount)
        Assert.AreEqual(312.5, TempHeader.Total, 'Total must be the tax-inclusive amount (312.5), not the tax rate (25)');
        Assert.AreEqual(312.5, TempHeader."Amount Due", 'Amount Due must match the corrected Total');
    end;

    local procedure EnsureGLSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if not GeneralLedgerSetup.Get() then begin
            GeneralLedgerSetup.Init();
            GeneralLedgerSetup."LCY Code" := 'USD';
            GeneralLedgerSetup.Insert();
        end;
    end;

    local procedure BuildFullHeaderJson(): JsonObject
    var
        Result: JsonObject;
    begin
        Result.ReadFrom(NavApp.GetResourceAsText('mllm/mllm-header-full.json'));
        exit(Result);
    end;

    local procedure BuildThreeLineArray(): JsonArray
    var
        Result: JsonArray;
    begin
        Result.ReadFrom(NavApp.GetResourceAsText('mllm/mllm-lines-three.json'));
        exit(Result);
    end;
}
