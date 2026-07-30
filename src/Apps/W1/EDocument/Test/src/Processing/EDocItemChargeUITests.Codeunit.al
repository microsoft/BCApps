// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Inventory.Item;
using System.TestLibraries.Utilities;

codeunit 139522 "E-Doc. Item Charge UI Tests"
{
    Subtype = Test;
    TestType = Uncategorized;

    trigger OnRun();
    begin
        // [FEATURE] [E-Document] [Item Charge] [UI]
    end;

    var
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryInventory: Codeunit "Library - Inventory";
        IncorrectValueErr: Label 'Incorrect value for %1', Locked = true;

    // The E-Document Core controls are declared with Visible = false and an extension for a format that evaluates
    // them shows them with a page extension. Visibility is therefore not asserted here: a page extension applies to
    // the whole tenant, so once such an extension is installed the controls are visible for every test in the tenant.
    // What E-Document Core owns, and what these tests cover, is that the controls exist and are bound to the right fields.

    #region Core owns the controls
    [Test]
    procedure ItemChargeMappingOnServicePageIsBoundToTheServiceField()
    var
        EDocumentService: Record "E-Document Service";
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] E-Document Core owns the Item Charge Mapping control on the E-Document Service page and binds it to the service field, so any extension that shows it gets a working setting
        // [GIVEN] An E-Document service
        EDocumentService.Get(LibraryEDocument.CreateService("E-Document Format"::"PEPPOL BIS 3.0", "Service Integration"::"No Integration"));

        // [WHEN] A mapping is selected on the E-Document Service page
        EDocumentServicePage.Trap();
        Page.Run(Page::"E-Document Service", EDocumentService);
        EDocumentServicePage."Item Charge E-Invoice Mapping".SetValue(Format(Enum::"Item Charge E-Invoice Mapping"::"Line with Unit Code"));
        EDocumentServicePage.Close();

        // [THEN] The selected mapping is stored on the service record
        EDocumentService.Find();
        Assert.AreEqual(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code", EDocumentService."Item Charge E-Invoice Mapping", StrSubstNo(IncorrectValueErr, EDocumentService.FieldCaption("Item Charge E-Invoice Mapping")));
    end;

    [Test]
    procedure ItemChargeEInvoiceFieldsOnItemChargesPageAreBoundToTheirOwnFields()
    var
        ItemCharge: Record "Item Charge";
        ItemChargesPage: TestPage "Item Charges";
    begin
        // [SCENARIO] E-Document Core owns the four e-document override columns on the Item Charges page and binds each to its own field, so any extension that shows them gets working columns
        // [GIVEN] An item charge
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [WHEN] Values are entered in the four override columns
        ItemChargesPage.OpenEdit();
        ItemChargesPage.GoToRecord(ItemCharge);
        ItemChargesPage."E-Invoice Mapping".SetValue(Format(Enum::"Item Charge Mapping Override"::"Document Allowance/Charge"));
        ItemChargesPage."E-Invoice Reason Text".SetValue('Freight surcharge');
        ItemChargesPage."E-Invoice Reason Code".SetValue('FC');
        ItemChargesPage."E-Invoice Unit Code".SetValue('HUR');
        ItemChargesPage.Close();

        // [THEN] Each value is stored in its own field on the item charge record
        ItemCharge.Find();
        Assert.AreEqual(ItemCharge."E-Invoice Mapping"::"Document Allowance/Charge", ItemCharge."E-Invoice Mapping", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Mapping")));
        Assert.AreEqual('Freight surcharge', ItemCharge."E-Invoice Reason Text", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Reason Text")));
        Assert.AreEqual('FC', ItemCharge."E-Invoice Reason Code", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Reason Code")));
        Assert.AreEqual('HUR', ItemCharge."E-Invoice Unit Code", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Unit Code")));
    end;

    [Test]
    procedure BlankMappingOverrideIsDistinctFromAutomaticOnItemChargesPage()
    var
        ItemCharge: Record "Item Charge";
        ItemChargesPage: TestPage "Item Charges";
    begin
        // [SCENARIO] A blank mapping override (use the service setting) and the Automatic override are two distinct states in the UI that E-Document Core owns
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
