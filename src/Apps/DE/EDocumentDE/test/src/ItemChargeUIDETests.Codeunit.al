// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Inventory.Item;

codeunit 148502 "Item Charge UI DE Tests"
{
    Subtype = Test;
    TestType = Uncategorized;

    trigger OnRun();
    begin
        // [FEATURE] [E-Document] [Item Charge] [UI]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryEdocument: Codeunit "Library - E-Document";
        Assert: Codeunit Assert;
        IncorrectValueErr: Label 'Incorrect value for %1', Locked = true;

    #region EDocumentService
    [Test]
    procedure ItemChargeMappingIsVisibleAndEditableOnServicePageForXRechnung()
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] The Item Charge E-Invoice Mapping setting can be changed on the E-Document Service page for an XRechnung service
        // [GIVEN] An E-Document service with XRechnung format
        EDocumentService.Get(LibraryEdocument.CreateService("E-Document Format"::XRechnung, "Service Integration"::"No Integration"));

        // [WHEN] The E-Document Service page is opened for the service
        EDocumentServicePage.Trap();
        Page.Run(Page::"E-Document Service", EDocumentService);

        // [THEN] The Item Charge E-Invoice Mapping field is visible and editable
        Assert.IsTrue(EDocumentServicePage."Item Charge E-Invoice Mapping".Visible(), 'Item Charge E-Invoice Mapping must be visible for XRechnung');
        Assert.IsTrue(EDocumentServicePage."Item Charge E-Invoice Mapping".Editable(), 'Item Charge E-Invoice Mapping must be editable for XRechnung');

        // [WHEN] A mapping is selected on the page
        EDocumentServicePage."Item Charge E-Invoice Mapping".SetValue(Format(Enum::"Item Charge E-Invoice Mapping"::"Line with Unit Code"));
        EDocumentServicePage.Close();

        // [THEN] The selected mapping is stored on the service record
        EDocumentService.Find();
        Assert.AreEqual(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code", EDocumentService."Item Charge E-Invoice Mapping", StrSubstNo(IncorrectValueErr, EDocumentService.FieldCaption("Item Charge E-Invoice Mapping")));
    end;

    [Test]
    procedure ItemChargeMappingIsVisibleOnServicePageForZUGFeRD()
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] The Item Charge E-Invoice Mapping setting is offered for a ZUGFeRD service
        // [GIVEN] An E-Document service with ZUGFeRD format
        EDocumentService.Get(LibraryEdocument.CreateService("E-Document Format"::ZUGFeRD, "Service Integration"::"No Integration"));

        // [WHEN] The E-Document Service page is opened for the service
        EDocumentServicePage.Trap();
        Page.Run(Page::"E-Document Service", EDocumentService);

        // [THEN] The Item Charge E-Invoice Mapping field is visible
        Assert.IsTrue(EDocumentServicePage."Item Charge E-Invoice Mapping".Visible(), 'Item Charge E-Invoice Mapping must be visible for ZUGFeRD');
        EDocumentServicePage.Close();
    end;

    [Test]
    procedure ItemChargeMappingIsVisibleOnServicePageForPeppolBisDE()
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] The Item Charge E-Invoice Mapping setting is offered for every German e-document format, including PEPPOL BIS 3.0 DE
        // [GIVEN] An E-Document service with PEPPOL BIS 3.0 DE format
        EDocumentService.Get(LibraryEdocument.CreateService("E-Document Format"::"PEPPOL BIS 3.0 DE", "Service Integration"::"No Integration"));

        // [WHEN] The E-Document Service page is opened for the service
        EDocumentServicePage.Trap();
        Page.Run(Page::"E-Document Service", EDocumentService);

        // [THEN] The Item Charge E-Invoice Mapping field is visible
        Assert.IsTrue(EDocumentServicePage."Item Charge E-Invoice Mapping".Visible(), 'Item Charge E-Invoice Mapping must be visible for PEPPOL BIS 3.0 DE');
        EDocumentServicePage.Close();
    end;
    #endregion

    #region ItemCharges
    [Test]
    procedure ItemChargeOverrideFieldsAreEditableOnItemChargesPage()
    var
        ItemCharge: Record "Item Charge";
        ItemChargesPage: TestPage "Item Charges";
    begin
        // [SCENARIO] The per-item-charge e-invoice override fields can be changed on the Item Charges page
        // [GIVEN] An item charge
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [WHEN] The Item Charges page is opened for the item charge
        ItemChargesPage.OpenEdit();
        ItemChargesPage.GoToRecord(ItemCharge);

        // [THEN] The four override fields are visible and editable
        Assert.IsTrue(ItemChargesPage."E-Invoice Mapping".Visible(), 'E-Invoice Mapping must be visible');
        Assert.IsTrue(ItemChargesPage."E-Invoice Mapping".Editable(), 'E-Invoice Mapping must be editable');
        Assert.IsTrue(ItemChargesPage."E-Invoice Reason Text".Visible(), 'E-Invoice Reason Text must be visible');
        Assert.IsTrue(ItemChargesPage."E-Invoice Reason Text".Editable(), 'E-Invoice Reason Text must be editable');
        Assert.IsTrue(ItemChargesPage."E-Invoice Reason Code".Visible(), 'E-Invoice Reason Code must be visible');
        Assert.IsTrue(ItemChargesPage."E-Invoice Reason Code".Editable(), 'E-Invoice Reason Code must be editable');
        Assert.IsTrue(ItemChargesPage."E-Invoice Unit Code".Visible(), 'E-Invoice Unit Code must be visible');
        Assert.IsTrue(ItemChargesPage."E-Invoice Unit Code".Editable(), 'E-Invoice Unit Code must be editable');

        // [WHEN] Values are entered in the override fields
        ItemChargesPage."E-Invoice Mapping".SetValue(Format(Enum::"Item Charge Mapping Override"::"Document Allowance/Charge"));
        ItemChargesPage."E-Invoice Reason Text".SetValue('Freight surcharge');
        ItemChargesPage."E-Invoice Reason Code".SetValue('FC');
        ItemChargesPage."E-Invoice Unit Code".SetValue('HUR');
        ItemChargesPage.Close();

        // [THEN] The values are stored on the item charge record
        ItemCharge.Find();
        Assert.AreEqual(ItemCharge."E-Invoice Mapping"::"Document Allowance/Charge", ItemCharge."E-Invoice Mapping", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Mapping")));
        Assert.AreEqual('Freight surcharge', ItemCharge."E-Invoice Reason Text", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Reason Text")));
        Assert.AreEqual('FC', ItemCharge."E-Invoice Reason Code", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Reason Code")));
        Assert.AreEqual('HUR', ItemCharge."E-Invoice Unit Code", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Unit Code")));
    end;

    [Test]
    procedure ItemChargeBlankMappingIsDistinctFromAutomaticOnItemChargesPage()
    var
        ItemCharge: Record "Item Charge";
        ItemChargesPage: TestPage "Item Charges";
    begin
        // [SCENARIO] A blank mapping override (use the service setting) and the Automatic override are two distinct states in the UI
        // [GIVEN] An item charge without a mapping override
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [WHEN] The Item Charges page is opened for the item charge
        ItemChargesPage.OpenEdit();
        ItemChargesPage.GoToRecord(ItemCharge);

        // [THEN] The mapping override is shown as blank, not as Automatic
        Assert.AreNotEqual(Format(Enum::"Item Charge Mapping Override"::Automatic), ItemChargesPage."E-Invoice Mapping".Value(), 'A blank override must not be rendered as Automatic');
        Assert.AreEqual('', DelChr(ItemChargesPage."E-Invoice Mapping".Value(), '<>', ' '), 'An item charge without override must show a blank mapping');

        // [WHEN] Automatic is selected on the page
        ItemChargesPage."E-Invoice Mapping".SetValue(Format(Enum::"Item Charge Mapping Override"::Automatic));
        ItemChargesPage.Close();

        // [THEN] The Automatic override is stored, distinct from the blank value
        ItemCharge.Find();
        Assert.AreEqual(ItemCharge."E-Invoice Mapping"::Automatic, ItemCharge."E-Invoice Mapping", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Mapping")));
        Assert.AreNotEqual(ItemCharge."E-Invoice Mapping"::" ", ItemCharge."E-Invoice Mapping", 'Automatic must be stored as an override, not as the blank value');
    end;
    #endregion
}
