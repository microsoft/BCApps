// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.EUDR;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.TestLibraries.Utilities;

codeunit 139557 "EUDR Certificate Capture"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [EUDR] [Sales] [Purchase] [Tracking]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        SalesLineStateErr: Label 'The EUDR relevance state on the sales line is incorrect.';
        PostedSalesLineStateErr: Label 'The EUDR relevance state on the posted sales invoice line is incorrect.';
        PurchaseLineStateErr: Label 'The EUDR relevance state on the purchase line is incorrect.';
        PostedPurchaseLineStateErr: Label 'The EUDR relevance state on the posted purchase line is incorrect.';
        ItemStateErr: Label 'The EUDR relevance state on the item is incorrect.';
        ItemTrackingCodeErr: Label 'The item tracking code on the item is incorrect.';
        EUDRCommodityErr: Label 'The EUDR commodity on the item is incorrect.';
        CertificateNoErr: Label 'The EUDR certificate number on the lot is incorrect.';
        CertificationSchemeErr: Label 'The certification scheme on the lot is incorrect.';
        CountryRegionOfProdErr: Label 'The country/region of production on the lot is incorrect.';
        DDSReferenceNoErr: Label 'The DDS reference number on the lot is incorrect.';
        DDSVerificationNoErr: Label 'The DDS verification number on the lot is incorrect.';
        EUDRFieldsVisibilityErr: Label 'The visibility of the EUDR fields on the lot information card is incorrect.';
        EUDRItemTrackingCodeErr: Label 'You cannot enable %1 because the current value in %2 is not valid for this %3.', Comment = '%1 = EUDR Relevant field caption, %2 = Item Tracking Code field caption, %3 = Item table caption';
        DialogErrorCodeTok: Label 'Dialog', Locked = true;
        TestFieldErrorCodeTok: Label 'TestField', Locked = true;

    [Test]
    procedure EUDRRelevantIsCopiedToSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 641591] An EUDR-relevant item is added to a sales document.
        Initialize();

        // [GIVEN] An item "I" is EUDR relevant.
        CreateItemWithEUDRState(Item, true);

        // [WHEN] A sales line is created for item "I".
        CreateSalesLineForItem(SalesHeader, SalesLine, Item);

        // [THEN] The sales line is marked as EUDR relevant.
        Assert.IsTrue(SalesLine."EUDR Relevant", SalesLineStateErr);
    end;

    [Test]
    procedure NonEUDRRelevantIsCopiedToSalesLine()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 641591] A non-EUDR item is added to a sales document.
        Initialize();

        // [GIVEN] An item "I" is not EUDR relevant.
        CreateItemWithEUDRState(Item, false);

        // [WHEN] A sales line is created for item "I".
        CreateSalesLineForItem(SalesHeader, SalesLine, Item);

        // [THEN] The sales line is not marked as EUDR relevant.
        Assert.IsFalse(SalesLine."EUDR Relevant", SalesLineStateErr);
    end;

    [Test]
    procedure SalesLineKeepsEUDRStateAfterItemChanges()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 641591] A sales line keeps the EUDR state captured when it was created.
        Initialize();

        // [GIVEN] An EUDR-relevant item "I" has a sales line.
        CreateItemWithEUDRState(Item, true);
        CreateSalesLineForItem(SalesHeader, SalesLine, Item);

        // [WHEN] Item "I" is changed to non-EUDR relevant.
        Item.Validate("EUDR Relevant", false);
        Item.Modify(true);

        // [THEN] The existing sales line remains EUDR relevant.
        Assert.IsTrue(SalesLine."EUDR Relevant", SalesLineStateErr);
    end;

    [Test]
    procedure NonEUDRSalesLineKeepsStateAfterItemChanges()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 641591] A non-EUDR sales line keeps its captured state.
        Initialize();

        // [GIVEN] A non-EUDR-relevant item "I" has a sales line.
        CreateEUDRItemTrackingCode(ItemTrackingCode);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        CreateSalesLineForItem(SalesHeader, SalesLine, Item);

        // [WHEN] Item "I" is changed to EUDR relevant.
        Item.Validate("EUDR Relevant", true);
        Item.Modify(true);

        // [THEN] The existing sales line remains non-EUDR relevant.
        Assert.IsFalse(SalesLine."EUDR Relevant", SalesLineStateErr);
    end;

    [Test]
    procedure EUDRRelevantIsPersistedToPostedSalesInvoiceLine()
    var
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 641591] EUDR state is transferred to a posted sales invoice line.
        Initialize();

        // [GIVEN] An EUDR-relevant item "I" is on inventory with lot "L".
        CreateEUDRItemWithLotInventory(Item, LotNoInformation);

        // [WHEN] A sales invoice for item "I" and lot "L" is posted.
        DocumentNo := PostSalesInvoiceForItemWithLot(Item, LotNoInformation."Lot No.");

        // [THEN] The posted line is marked as EUDR relevant.
        VerifyPostedSalesInvoiceLineEUDRState(DocumentNo, Item."No.", true);
    end;

    [Test]
    procedure NonEUDRRelevantIsPersistedToPostedSalesInvoiceLine()
    var
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 641591] Non-EUDR state is transferred to a posted sales invoice line.
        Initialize();

        // [GIVEN] An item "I" is not EUDR relevant.
        CreateItemWithEUDRState(Item, false);

        // [WHEN] A sales invoice for item "I" is posted.
        DocumentNo := PostSalesInvoiceForItem(Item);

        // [THEN] The posted line is not marked as EUDR relevant.
        VerifyPostedSalesInvoiceLineEUDRState(DocumentNo, Item."No.", false);
    end;

    [Test]
    procedure EUDRRelevantIsPersistedToPostedPurchaseLines()
    var
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 641591] EUDR state is mirrored to purchase history.
        Initialize();

        // [GIVEN] A purchase order for vendor "V" has a line for EUDR-relevant item "I" with lot "L".
        CreateEUDRItemWithLotInformation(Item, LotNoInformation);

        // [WHEN] The purchase order is received and invoiced.
        InvoiceNo := PostPurchaseOrderForItemWithLot(PurchaseHeader, Item, LotNoInformation."Lot No.");

        // [THEN] The posted receipt line and the posted invoice line are marked as EUDR relevant.
        VerifyPostedPurchaseLinesEUDRState(PurchaseHeader."No.", InvoiceNo, Item."No.", true);
    end;

    [Test]
    procedure EUDRCommodityIsStoredOnItem()
    var
        Item: Record Item;
    begin
        // [SCENARIO 641591] An EUDR commodity is assigned to an item.
        Initialize();

        // [GIVEN] An EUDR-relevant item "I" exists.
        CreateItemWithEUDRState(Item, true);

        // [WHEN] Commodity Wood is assigned to item "I".
        Item.Validate("EUDR Commodity", Enum::"EUDR Commodity"::Wood);
        Item.Modify(true);

        // [THEN] Commodity Wood is stored on item "I".
        Item.Get(Item."No.");
        Assert.AreEqual(Enum::"EUDR Commodity"::Wood, Item."EUDR Commodity", EUDRCommodityErr);
    end;

    [Test]
    procedure EUDRLotCertificateDetailsAreStored()
    var
        CountryRegion: Record "Country/Region";
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        CertificateNo: Code[50];
        CertificationScheme: Text[100];
        DDSReferenceNo: Code[50];
        DDSVerificationNo: Code[50];
    begin
        // [SCENARIO 641591] EUDR certificate details are stored for a lot.
        Initialize();

        // [GIVEN] An EUDR-relevant item "I", a lot "L", and a country/region exist.
        CreateEUDRItemWithLotInformation(Item, LotNoInformation);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CertificateNo := LibraryUtility.GenerateGUID();
        CertificationScheme := LibraryUtility.GenerateGUID();
        DDSReferenceNo := LibraryUtility.GenerateGUID();
        DDSVerificationNo := LibraryUtility.GenerateGUID();

        // [WHEN] Certificate, validity, origin, and DDS details are stored for lot "L".
        LotNoInformation.Validate("EUDR Certificate No.", CertificateNo);
        LotNoInformation.Validate("Certification Scheme", CertificationScheme);
        LotNoInformation.Validate("EUDR Valid From", WorkDate());
        LotNoInformation.Validate("EUDR Valid To", CalcDate('<+1Y>', WorkDate()));
        LotNoInformation.Validate("Country/Region of Prod. Code", CountryRegion.Code);
        LotNoInformation.Validate("DDS Reference Number", DDSReferenceNo);
        LotNoInformation.Validate("DDS Verification No.", DDSVerificationNo);
        LotNoInformation.Modify(true);

        // [THEN] All EUDR details can be read back from lot "L".
        LotNoInformation.Get(LotNoInformation."Item No.", LotNoInformation."Variant Code", LotNoInformation."Lot No.");
        VerifyEUDRLotDetails(LotNoInformation, CertificateNo, CertificationScheme, CountryRegion.Code, DDSReferenceNo, DDSVerificationNo);
    end;

    [Test]
    procedure EUDRRelevantOnItemWithEUDRItemTrackingCode()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 641591] EUDR relevance is enabled on an item that already has a compliant item tracking code.
        Initialize();

        // [GIVEN] An item tracking code "ITC" has Lot Specific Tracking, Lot Info. Inbound Must Exist, and Lot Info. Outbound Must Exist enabled.
        // [GIVEN] An inventory item "I" uses item tracking code "ITC".
        CreateEUDRItemTrackingCode(ItemTrackingCode);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [WHEN] EUDR Relevant is validated to true on item "I".
        Item.Validate("EUDR Relevant", true);
        Item.Modify(true);

        // [THEN] Item "I" is EUDR relevant and keeps item tracking code "ITC".
        Item.Get(Item."No.");
        Assert.IsTrue(Item."EUDR Relevant", ItemStateErr);
        Assert.AreEqual(ItemTrackingCode.Code, Item."Item Tracking Code", ItemTrackingCodeErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingCodesLookupOKModalPageHandler')]
    procedure EUDRRelevantOnItemWithNonEUDRTrackingCodeConfirmed()
    var
        EUDRItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        NonEUDRItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 641591] EUDR relevance is enabled on an item with a non-compliant item tracking code and the user accepts the suggested replacement.
        Initialize();

        // [GIVEN] An item tracking code "ITC1" has only Lot Specific Tracking enabled and an item tracking code "ITC2" is EUDR compliant.
        // [GIVEN] An inventory item "I" uses item tracking code "ITC1".
        LibraryItemTracking.CreateItemTrackingCode(NonEUDRItemTrackingCode, false, true);
        CreateEUDRItemTrackingCode(EUDRItemTrackingCode);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, NonEUDRItemTrackingCode);
        LibraryVariableStorage.Enqueue(EUDRItemTrackingCode.Code);

        // [WHEN] EUDR Relevant is validated to true on item "I", the confirmation is accepted, and "ITC2" is selected in the lookup.
        Item.Validate("EUDR Relevant", true);
        Item.Modify(true);

        // [THEN] Item "I" is EUDR relevant and uses item tracking code "ITC2".
        Item.Get(Item."No.");
        Assert.IsTrue(Item."EUDR Relevant", ItemStateErr);
        Assert.AreEqual(EUDRItemTrackingCode.Code, Item."Item Tracking Code", ItemTrackingCodeErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure EUDRRelevantOnItemWithNonEUDRTrackingCodeDeclined()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 641591] EUDR relevance is rejected when the user declines to replace a non-compliant item tracking code.
        Initialize();

        // [GIVEN] An item tracking code "ITC" has only Lot Specific Tracking enabled.
        // [GIVEN] An inventory item "I" uses item tracking code "ITC".
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [WHEN] EUDR Relevant is validated to true on item "I" and the confirmation is declined.
        asserterror Item.Validate("EUDR Relevant", true);

        // [THEN] An error is raised that the item tracking code is not valid for EUDR.
        Assert.ExpectedError(
          StrSubstNo(
            EUDRItemTrackingCodeErr, Item.FieldCaption("EUDR Relevant"), Item.FieldCaption("Item Tracking Code"), Item.TableCaption()));
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure EUDRRelevantOnItemWithoutTrackingCodeDeclined()
    var
        Item: Record Item;
    begin
        // [SCENARIO 641591] EUDR relevance is rejected when the item has no item tracking code and the user declines to assign one.
        Initialize();

        // [GIVEN] An inventory item "I" has no item tracking code.
        LibraryInventory.CreateItem(Item);

        // [WHEN] EUDR Relevant is validated to true on item "I" and the confirmation is declined.
        asserterror Item.Validate("EUDR Relevant", true);

        // [THEN] An error is raised that the item tracking code is not valid for EUDR.
        Assert.ExpectedError(
          StrSubstNo(
            EUDRItemTrackingCodeErr, Item.FieldCaption("EUDR Relevant"), Item.FieldCaption("Item Tracking Code"), Item.TableCaption()));
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingCodesCancelModalPageHandler')]
    procedure EUDRRelevantOnItemWhenTrackingCodeLookupCancelled()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 641591] EUDR relevance is rejected when the user accepts the confirmation but cancels the item tracking code lookup.
        Initialize();

        // [GIVEN] An EUDR compliant item tracking code exists.
        // [GIVEN] An inventory item "I" has no item tracking code.
        CreateEUDRItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateItem(Item);

        // [WHEN] EUDR Relevant is validated to true on item "I", the confirmation is accepted, and the lookup is cancelled.
        asserterror Item.Validate("EUDR Relevant", true);

        // [THEN] An error is raised that the item tracking code is not valid for EUDR.
        Assert.ExpectedError(
          StrSubstNo(
            EUDRItemTrackingCodeErr, Item.FieldCaption("EUDR Relevant"), Item.FieldCaption("Item Tracking Code"), Item.TableCaption()));
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
    end;

    [Test]
    procedure EUDRRelevantOnNonInventoryItem()
    var
        Item: Record Item;
    begin
        // [SCENARIO 641591] EUDR relevance cannot be enabled on an item that is not of type Inventory.
        Initialize();

        // [GIVEN] A service item "I" exists.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Type, Item.Type::Service);
        Item.Modify(true);

        // [WHEN] EUDR Relevant is validated to true on item "I".
        asserterror Item.Validate("EUDR Relevant", true);

        // [THEN] An error is raised that Type must be Inventory.
        Assert.ExpectedTestFieldError(Item.FieldCaption(Type), Format(Item.Type::Inventory));
        Assert.ExpectedErrorCode(TestFieldErrorCodeTok);
    end;

    [Test]
    procedure DisableEUDRRelevantOnItemWithNonEUDRTrackingCode()
    var
        Item: Record Item;
    begin
        // [SCENARIO 641591] EUDR relevance can be disabled without any item tracking code validation.
        Initialize();

        // [GIVEN] An inventory item "I" has no item tracking code.
        LibraryInventory.CreateItem(Item);

        // [WHEN] EUDR Relevant is validated to false on item "I".
        Item.Validate("EUDR Relevant", false);
        Item.Modify(true);

        // [THEN] Item "I" is not EUDR relevant and no confirmation is shown.
        Item.Get(Item."No.");
        Assert.IsFalse(Item."EUDR Relevant", ItemStateErr);
    end;

    [Test]
    procedure BlankItemTrackingCodeOnEUDRRelevantItem()
    var
        Item: Record Item;
    begin
        // [SCENARIO 641591] The item tracking code cannot be removed from an EUDR relevant item.
        Initialize();

        // [GIVEN] An EUDR relevant inventory item "I" uses an EUDR compliant item tracking code.
        CreateItemWithEUDRState(Item, true);

        // [WHEN] The item tracking code on item "I" is validated to a blank value.
        asserterror Item.Validate("Item Tracking Code", '');

        // [THEN] An error is raised that EUDR Relevant must be false.
        Assert.ExpectedTestFieldError(Item.FieldCaption("EUDR Relevant"), Format(false));
        Assert.ExpectedErrorCode(TestFieldErrorCodeTok);
    end;

    [Test]
    procedure NonEUDRItemTrackingCodeOnEUDRRelevantItem()
    var
        Item: Record Item;
        NonEUDRItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 641591] The item tracking code of an EUDR relevant item cannot be replaced by a non-compliant one.
        Initialize();

        // [GIVEN] An EUDR relevant inventory item "I" uses an EUDR compliant item tracking code.
        // [GIVEN] An item tracking code "ITC" has only Lot Specific Tracking enabled.
        CreateItemWithEUDRState(Item, true);
        LibraryItemTracking.CreateItemTrackingCode(NonEUDRItemTrackingCode, false, true);

        // [WHEN] The item tracking code on item "I" is validated to "ITC".
        asserterror Item.Validate("Item Tracking Code", NonEUDRItemTrackingCode.Code);

        // [THEN] An error is raised that EUDR Relevant must be false.
        Assert.ExpectedTestFieldError(Item.FieldCaption("EUDR Relevant"), Format(false));
        Assert.ExpectedErrorCode(TestFieldErrorCodeTok);
    end;

    [Test]
    procedure OtherEUDRItemTrackingCodeOnEUDRRelevantItem()
    var
        Item: Record Item;
        OtherEUDRItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 641591] The item tracking code of an EUDR relevant item can be replaced by another compliant one.
        Initialize();

        // [GIVEN] An EUDR relevant inventory item "I" uses EUDR compliant item tracking code "ITC1".
        // [GIVEN] An EUDR compliant item tracking code "ITC2" exists.
        CreateItemWithEUDRState(Item, true);
        CreateEUDRItemTrackingCode(OtherEUDRItemTrackingCode);

        // [WHEN] The item tracking code on item "I" is validated to "ITC2".
        Item.Validate("Item Tracking Code", OtherEUDRItemTrackingCode.Code);
        Item.Modify(true);

        // [THEN] Item "I" uses item tracking code "ITC2" and stays EUDR relevant.
        Item.Get(Item."No.");
        Assert.AreEqual(OtherEUDRItemTrackingCode.Code, Item."Item Tracking Code", ItemTrackingCodeErr);
        Assert.IsTrue(Item."EUDR Relevant", ItemStateErr);
    end;

    [Test]
    procedure BlankItemTrackingCodeOnNonEUDRItem()
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // [SCENARIO 641591] The item tracking code can be removed from an item that is not EUDR relevant.
        Initialize();

        // [GIVEN] A non-EUDR inventory item "I" uses an EUDR compliant item tracking code.
        CreateEUDRItemTrackingCode(ItemTrackingCode);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);

        // [WHEN] The item tracking code on item "I" is validated to a blank value.
        Item.Validate("Item Tracking Code", '');
        Item.Modify(true);

        // [THEN] Item "I" has a blank item tracking code.
        Item.Get(Item."No.");
        Assert.AreEqual('', Item."Item Tracking Code", ItemTrackingCodeErr);
    end;

    [Test]
    procedure EUDRCommodityIsBlankOnNewItem()
    var
        Item: Record Item;
    begin
        // [SCENARIO 641591] A newly created item has no EUDR commodity.
        Initialize();

        // [GIVEN] There is no EUDR setup on the item.

        // [WHEN] An item "I" is created.
        LibraryInventory.CreateItem(Item);

        // [THEN] The EUDR commodity on item "I" is blank.
        Item.Get(Item."No.");
        Assert.AreEqual(Enum::"EUDR Commodity"::" ", Item."EUDR Commodity", EUDRCommodityErr);
    end;

    [Test]
    procedure EUDRRelevantIsNotSetOnGLAccountSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 641591] The EUDR state is not set on sales lines that do not carry an item.
        Initialize();

        // [GIVEN] A sales invoice for customer "C" exists.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [WHEN] A sales line of type G/L Account is created.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(5));

        // [THEN] The sales line is not marked as EUDR relevant.
        Assert.IsFalse(SalesLine."EUDR Relevant", SalesLineStateErr);
    end;

    [Test]
    procedure EUDRRelevantIsSetWhenSalesLineItemIsReplaced()
    var
        EUDRItem: Record Item;
        NonEUDRItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 641591] The EUDR state is recaptured when the item on a sales line is replaced.
        Initialize();

        // [GIVEN] A sales line exists for non-EUDR item "I1".
        // [GIVEN] An EUDR relevant item "I2" exists.
        CreateItemWithEUDRState(NonEUDRItem, false);
        CreateItemWithEUDRState(EUDRItem, true);
        CreateSalesLineForItem(SalesHeader, SalesLine, NonEUDRItem);

        // [WHEN] The item on the sales line is validated to "I2".
        SalesLine.Validate("No.", EUDRItem."No.");
        SalesLine.Modify(true);

        // [THEN] The sales line is marked as EUDR relevant.
        Assert.IsTrue(SalesLine."EUDR Relevant", SalesLineStateErr);
    end;

    [Test]
    procedure EUDRRelevantIsClearedWhenSalesLineItemIsReplaced()
    var
        EUDRItem: Record Item;
        NonEUDRItem: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 641591] The EUDR state is cleared when an EUDR item on a sales line is replaced by a non-EUDR item.
        Initialize();

        // [GIVEN] A sales line exists for EUDR relevant item "I1".
        // [GIVEN] A non-EUDR item "I2" exists.
        CreateItemWithEUDRState(EUDRItem, true);
        CreateItemWithEUDRState(NonEUDRItem, false);
        CreateSalesLineForItem(SalesHeader, SalesLine, EUDRItem);

        // [WHEN] The item on the sales line is validated to "I2".
        SalesLine.Validate("No.", NonEUDRItem."No.");
        SalesLine.Modify(true);

        // [THEN] The sales line is not marked as EUDR relevant.
        Assert.IsFalse(SalesLine."EUDR Relevant", SalesLineStateErr);
    end;

    [Test]
    procedure EUDRRelevantIsCopiedToPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 641591] An EUDR relevant item is added to a purchase document.
        Initialize();

        // [GIVEN] An EUDR relevant item "I" and a vendor "V" exist.
        CreateItemWithEUDRState(Item, true);

        // [WHEN] A purchase line is created for item "I".
        CreatePurchaseLineForItem(PurchaseHeader, PurchaseLine, Item);

        // [THEN] The purchase line is marked as EUDR relevant.
        Assert.IsTrue(PurchaseLine."EUDR Relevant", PurchaseLineStateErr);
    end;

    [Test]
    procedure NonEUDRRelevantIsCopiedToPurchaseLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 641591] A non-EUDR item is added to a purchase document.
        Initialize();

        // [GIVEN] A non-EUDR item "I" and a vendor "V" exist.
        CreateItemWithEUDRState(Item, false);

        // [WHEN] A purchase line is created for item "I".
        CreatePurchaseLineForItem(PurchaseHeader, PurchaseLine, Item);

        // [THEN] The purchase line is not marked as EUDR relevant.
        Assert.IsFalse(PurchaseLine."EUDR Relevant", PurchaseLineStateErr);
    end;

    [Test]
    procedure EUDRRelevantIsNotSetOnGLAccountPurchaseLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 641591] The EUDR state is not set on purchase lines that do not carry an item.
        Initialize();

        // [GIVEN] A purchase invoice for vendor "V" exists.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] A purchase line of type G/L Account is created.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandInt(5));

        // [THEN] The purchase line is not marked as EUDR relevant.
        Assert.IsFalse(PurchaseLine."EUDR Relevant", PurchaseLineStateErr);
    end;

    [Test]
    procedure NonEUDRRelevantIsPersistedToPostedPurchaseLines()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 641591] A non-EUDR purchase line stays non-EUDR in purchase history.
        Initialize();

        // [GIVEN] A purchase order for vendor "V" has a line for non-EUDR item "I".
        CreateItemWithEUDRState(Item, false);

        // [WHEN] The purchase order is received and invoiced.
        InvoiceNo := PostPurchaseOrderForItem(PurchaseHeader, Item);

        // [THEN] The posted receipt line and the posted invoice line are not marked as EUDR relevant.
        VerifyPostedPurchaseLinesEUDRState(PurchaseHeader."No.", InvoiceNo, Item."No.", false);
    end;

    [Test]
    procedure EUDRLotCertificateDetailsAreBlankOnNewLotNoInformation()
    var
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
    begin
        // [SCENARIO 641591] A newly created lot information record has no EUDR certificate details.
        Initialize();

        // [GIVEN] An EUDR relevant item "I" exists.
        CreateItemWithEUDRState(Item, true);

        // [WHEN] Lot information for lot "L" is created for item "I".
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', LibraryUtility.GenerateGUID());

        // [THEN] All EUDR certificate fields on lot "L" are blank.
        LotNoInformation.Get(LotNoInformation."Item No.", LotNoInformation."Variant Code", LotNoInformation."Lot No.");
        VerifyEUDRLotDetails(LotNoInformation, '', '', '', '', '');
    end;

    [Test]
    procedure CountryRegionOfProductionIsValidatedOnLotNoInformation()
    var
        CountryRegion: Record "Country/Region";
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
    begin
        // [SCENARIO 641591] The country/region of production refers to an existing country/region.
        Initialize();

        // [GIVEN] Lot information for lot "L" exists for EUDR relevant item "I" and a country/region exists.
        CreateEUDRItemWithLotInformation(Item, LotNoInformation);
        LibraryERM.CreateCountryRegion(CountryRegion);

        // [WHEN] The country/region of production on lot "L" is set to an existing country/region.
        LotNoInformation.Validate("Country/Region of Prod. Code", CountryRegion.Code);
        LotNoInformation.Modify(true);

        // [THEN] The country/region of production is stored on lot "L".
        LotNoInformation.Get(LotNoInformation."Item No.", LotNoInformation."Variant Code", LotNoInformation."Lot No.");
        Assert.AreEqual(CountryRegion.Code, LotNoInformation."Country/Region of Prod. Code", CountryRegionOfProdErr);
    end;

    [Test]
    procedure EUDRFieldsAreVisibleOnLotNoInformationCardForEUDRItem()
    var
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        LotNoInformationCard: TestPage "Lot No. Information Card";
    begin
        // [SCENARIO 641591] The EUDR group on the lot information card is shown for an EUDR relevant item.
        Initialize();

        // [GIVEN] Lot information for lot "L" exists for EUDR relevant item "I".
        CreateEUDRItemWithLotInformation(Item, LotNoInformation);

        // [WHEN] The lot information card for lot "L" is opened.
        LotNoInformationCard.OpenEdit();
        LotNoInformationCard.GoToRecord(LotNoInformation);

        // [THEN] The EUDR certificate fields are visible.
        Assert.IsTrue(LotNoInformationCard."EUDR Certificate No.".Visible(), EUDRFieldsVisibilityErr);
        Assert.IsTrue(LotNoInformationCard."DDS Verification No.".Visible(), EUDRFieldsVisibilityErr);
        LotNoInformationCard.Close();
    end;

    [Test]
    procedure EUDRFieldsAreHiddenOnLotNoInformationCardForNonEUDRItem()
    var
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        LotNoInformationCard: TestPage "Lot No. Information Card";
    begin
        // [SCENARIO 641591] The EUDR group on the lot information card is hidden for an item that is not EUDR relevant.
        Initialize();

        // [GIVEN] Lot information for lot "L" exists for non-EUDR item "I".
        LibraryItemTracking.CreateLotItem(Item);
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', LibraryUtility.GenerateGUID());

        // [WHEN] The lot information card for lot "L" is opened.
        LotNoInformationCard.OpenEdit();
        LotNoInformationCard.GoToRecord(LotNoInformation);

        // [THEN] The EUDR certificate fields are not visible.
        Assert.IsFalse(LotNoInformationCard."EUDR Certificate No.".Visible(), EUDRFieldsVisibilityErr);
        Assert.IsFalse(LotNoInformationCard."DDS Verification No.".Visible(), EUDRFieldsVisibilityErr);
        LotNoInformationCard.Close();
    end;

    [Test]
    procedure EUDRCertificateDetailsAreSavedFromLotNoInformationCard()
    var
        CountryRegion: Record "Country/Region";
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        LotNoInformationCard: TestPage "Lot No. Information Card";
        CertificateNo: Code[50];
        CertificationScheme: Text[100];
        DDSReferenceNo: Code[50];
        DDSVerificationNo: Code[50];
    begin
        // [SCENARIO 641591] EUDR certificate details entered on the lot information card are stored.
        Initialize();

        // [GIVEN] Lot information for lot "L" exists for EUDR relevant item "I" and a country/region exists.
        CreateEUDRItemWithLotInformation(Item, LotNoInformation);
        LibraryERM.CreateCountryRegion(CountryRegion);
        CertificateNo := LibraryUtility.GenerateGUID();
        CertificationScheme := LibraryUtility.GenerateGUID();
        DDSReferenceNo := LibraryUtility.GenerateGUID();
        DDSVerificationNo := LibraryUtility.GenerateGUID();

        // [WHEN] Certificate, scheme, validity, origin, and DDS details are entered on the lot information card and the page is closed.
        LotNoInformationCard.OpenEdit();
        LotNoInformationCard.GoToRecord(LotNoInformation);
        LotNoInformationCard."EUDR Certificate No.".SetValue(CertificateNo);
        LotNoInformationCard."Certification Scheme".SetValue(CertificationScheme);
        LotNoInformationCard."EUDR Valid From".SetValue(WorkDate());
        LotNoInformationCard."EUDR Valid To".SetValue(CalcDate('<+1Y>', WorkDate()));
        LotNoInformationCard."Country/Region of Production Code".SetValue(CountryRegion.Code);
        LotNoInformationCard."DDS Reference Number".SetValue(DDSReferenceNo);
        LotNoInformationCard."DDS Verification No.".SetValue(DDSVerificationNo);
        LotNoInformationCard.Close();

        // [THEN] All EUDR details are stored on lot "L".
        LotNoInformation.Get(LotNoInformation."Item No.", LotNoInformation."Variant Code", LotNoInformation."Lot No.");
        VerifyEUDRLotDetails(LotNoInformation, CertificateNo, CertificationScheme, CountryRegion.Code, DDSReferenceNo, DDSVerificationNo);
    end;

    [Test]
    [HandlerFunctions('EUDRSalesInvoiceRequestPageHandler')]
    procedure EUDRSalesInvoiceReportShowsLotCertificateDetails()
    var
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CertificateNo: Code[50];
    begin
        // [SCENARIO 641591] The EUDR Sales Invoice report lists the lot certificate details of an EUDR relevant line.
        Initialize();

        // [GIVEN] EUDR relevant item "I" is on inventory with lot "L" that has an EUDR certificate.
        CreateEUDRItemWithLotInventory(Item, LotNoInformation);
        CertificateNo := LibraryUtility.GenerateGUID();
        LotNoInformation.Validate("EUDR Certificate No.", CertificateNo);
        LotNoInformation.Modify(true);

        // [GIVEN] A sales invoice for customer "C" with item "I" and lot "L" is posted.
        SalesInvoiceHeader.Get(PostSalesInvoiceForItemWithLot(Item, LotNoInformation."Lot No."));
        Commit();

        // [WHEN] The EUDR Sales Invoice report is run for the posted invoice.
        RunEUDRSalesInvoiceReport(SalesInvoiceHeader);

        // [THEN] The report dataset contains lot "L" with its certificate number.
        LibraryReportDataset.AssertElementWithValueExists('LotNo_EUDRLot', LotNoInformation."Lot No.");
        LibraryReportDataset.AssertElementWithValueExists('EUDRCertificateNo_EUDRLot', CertificateNo);
    end;

    [Test]
    [HandlerFunctions('EUDRSalesInvoiceRequestPageHandler')]
    procedure EUDRSalesInvoiceReportSkipsNonEUDRLine()
    var
        Item: Record Item;
        LotNoInformation: Record "Lot No. Information";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LotNo: Code[50];
    begin
        // [SCENARIO 641591] The EUDR Sales Invoice report does not list lot details for lines that are not EUDR relevant.
        Initialize();

        // [GIVEN] Non-EUDR item "I" is on inventory with lot "L" that has an EUDR certificate.
        LibraryItemTracking.CreateLotItem(Item);
        LotNo := LibraryUtility.GenerateGUID();
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', LotNo);
        LotNoInformation.Validate("EUDR Certificate No.", LibraryUtility.GenerateGUID());
        LotNoInformation.Modify(true);
        LibraryItemTracking.PostPositiveAdjustmentWithItemTracking(
          Item, '', '', LibraryRandom.RandIntInRange(10, 20), WorkDate(), '', LotNo);

        // [GIVEN] A sales invoice for customer "C" with item "I" and lot "L" is posted.
        SalesInvoiceHeader.Get(PostSalesInvoiceForItemWithLot(Item, LotNo));
        Commit();

        // [WHEN] The EUDR Sales Invoice report is run for the posted invoice.
        RunEUDRSalesInvoiceReport(SalesInvoiceHeader);

        // [THEN] The report dataset contains no lot rows.
        LibraryReportDataset.AssertElementWithValueNotExist('LotNo_EUDRLot', LotNo);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"EUDR Certificate Capture");
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"EUDR Certificate Capture");
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"EUDR Certificate Capture");
    end;

    local procedure CreateEUDRItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true);
        ItemTrackingCode.Validate("Lot Info. Inbound Must Exist", true);
        ItemTrackingCode.Validate("Lot Info. Outbound Must Exist", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemWithEUDRState(var Item: Record Item; EUDRRelevant: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        if not EUDRRelevant then begin
            LibraryInventory.CreateItem(Item);
            exit;
        end;

        CreateEUDRItemTrackingCode(ItemTrackingCode);
        LibraryItemTracking.CreateItemWithItemTrackingCode(Item, ItemTrackingCode);
        Item.Validate("EUDR Relevant", true);
        Item.Modify(true);
    end;

    local procedure CreateEUDRItemWithLotInformation(var Item: Record Item; var LotNoInformation: Record "Lot No. Information")
    begin
        CreateItemWithEUDRState(Item, true);
        LibraryItemTracking.CreateLotNoInformation(LotNoInformation, Item."No.", '', LibraryUtility.GenerateGUID());
    end;

    local procedure CreateEUDRItemWithLotInventory(var Item: Record Item; var LotNoInformation: Record "Lot No. Information")
    begin
        CreateEUDRItemWithLotInformation(Item, LotNoInformation);
        LibraryItemTracking.PostPositiveAdjustmentWithItemTracking(
          Item, '', '', LibraryRandom.RandIntInRange(10, 20), WorkDate(), '', LotNoInformation."Lot No.");
    end;

    local procedure CreateSalesLineForItem(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Item: Record Item)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
    end;

    local procedure CreatePurchaseLineForItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Item: Record Item)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
    end;

    local procedure PostSalesInvoiceForItem(Item: Record Item): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesLineForItem(SalesHeader, SalesLine, Item);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostSalesInvoiceForItemWithLot(Item: Record Item; LotNo: Code[50]): Code[20]
    var
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CreateSalesLineForItem(SalesHeader, SalesLine, Item);
        LibraryItemTracking.CreateSalesOrderItemTracking(ReservationEntry, SalesLine, '', LotNo, SalesLine.Quantity);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchaseOrderForItem(var PurchaseHeader: Record "Purchase Header"; Item: Record Item): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostPurchaseOrderForItemWithLot(var PurchaseHeader: Record "Purchase Header"; Item: Record Item; LotNo: Code[50]): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));
        LibraryItemTracking.CreatePurchOrderItemTracking(ReservationEntry, PurchaseLine, '', LotNo, PurchaseLine.Quantity);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure RunEUDRSalesInvoiceReport(var SalesInvoiceHeader: Record "Sales Invoice Header")
    begin
        SalesInvoiceHeader.SetRecFilter();
        REPORT.Run(REPORT::"EUDR Sales Invoice", true, false, SalesInvoiceHeader);
        LibraryReportDataset.LoadDataSetFile();
    end;

    local procedure VerifyPostedSalesInvoiceLineEUDRState(DocumentNo: Code[20]; ItemNo: Code[20]; ExpectedEUDRRelevant: Boolean)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", ItemNo);
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(ExpectedEUDRRelevant, SalesInvoiceLine."EUDR Relevant", PostedSalesLineStateErr);
    end;

    local procedure VerifyPostedPurchaseLinesEUDRState(OrderNo: Code[20]; InvoiceNo: Code[20]; ItemNo: Code[20]; ExpectedEUDRRelevant: Boolean)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
#pragma warning disable AA0210
        PurchRcptLine.SetRange("No.", ItemNo);
#pragma warning restore AA0210
        PurchRcptLine.FindFirst();
        Assert.AreEqual(ExpectedEUDRRelevant, PurchRcptLine."EUDR Relevant", PostedPurchaseLineStateErr);

        PurchInvLine.SetRange("Document No.", InvoiceNo);
        PurchInvLine.SetRange("No.", ItemNo);
        PurchInvLine.FindFirst();
        Assert.AreEqual(ExpectedEUDRRelevant, PurchInvLine."EUDR Relevant", PostedPurchaseLineStateErr);
    end;

    local procedure VerifyEUDRLotDetails(var LotNoInformation: Record "Lot No. Information"; CertificateNo: Code[50]; CertificationScheme: Text[100]; CountryRegionCode: Code[10]; DDSReferenceNo: Code[50]; DDSVerificationNo: Code[50])
    begin
        Assert.AreEqual(CertificateNo, LotNoInformation."EUDR Certificate No.", CertificateNoErr);
        Assert.AreEqual(CertificationScheme, LotNoInformation."Certification Scheme", CertificationSchemeErr);
        Assert.AreEqual(CountryRegionCode, LotNoInformation."Country/Region of Prod. Code", CountryRegionOfProdErr);
        Assert.AreEqual(DDSReferenceNo, LotNoInformation."DDS Reference Number", DDSReferenceNoErr);
        Assert.AreEqual(DDSVerificationNo, LotNoInformation."DDS Verification No.", DDSVerificationNoErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingCodesLookupOKModalPageHandler(var ItemTrackingCodes: TestPage "Item Tracking Codes")
    begin
        ItemTrackingCodes.GoToKey(CopyStr(LibraryVariableStorage.DequeueText(), 1, 10));
        ItemTrackingCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingCodesCancelModalPageHandler(var ItemTrackingCodes: TestPage "Item Tracking Codes")
    begin
        ItemTrackingCodes.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure EUDRSalesInvoiceRequestPageHandler(var EUDRSalesInvoice: TestRequestPage "EUDR Sales Invoice")
    begin
        EUDRSalesInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}