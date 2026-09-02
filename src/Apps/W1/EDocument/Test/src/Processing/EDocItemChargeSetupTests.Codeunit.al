// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.Inventory.Item;

codeunit 139788 "E-Doc. Item Charge Setup Tests"
{
    Subtype = Test;
    TestType = Uncategorized;

    trigger OnRun();
    begin
        // [FEATURE] [E-Document] [Item Charge]
    end;

    var
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        LibraryInventory: Codeunit "Library - Inventory";
        IncorrectValueErr: Label 'Incorrect value for %1', Locked = true;

    // E-Document Core declares the controls for these fields with Visible = false, and the extension for a format
    // that evaluates them shows them with a page extension. These tests therefore stay at record level: a TestPage
    // cannot reach a control that is statically hidden, so a page test here would only pass in a tenant that happens
    // to have such an extension installed. The page bindings are covered where the controls are actually shown -
    // codeunit 148502 "Item Charge UI DE Tests" in the E-Document for Germany test app.

    #region Core owns the fields
    [Test]
    procedure ItemChargeMappingIsStoredOnTheService()
    var
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] E-Document Core owns the Item Charge E-Invoice Mapping setting on the E-Document service, so any format that reads it gets a working setting
        // [GIVEN] An E-Document service
        EDocumentService.Get(LibraryEDocument.CreateService("E-Document Format"::"PEPPOL BIS 3.0", "Service Integration"::"No Integration"));

        // [WHEN] A mapping is selected on the service
        EDocumentService.Validate("Item Charge E-Invoice Mapping", EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code");
        EDocumentService.Modify(true);

        // [THEN] The selected mapping is stored on the service record
        EDocumentService.Find();
        Assert.AreEqual(EDocumentService."Item Charge E-Invoice Mapping"::"Line with Unit Code", EDocumentService."Item Charge E-Invoice Mapping", StrSubstNo(IncorrectValueErr, EDocumentService.FieldCaption("Item Charge E-Invoice Mapping")));
    end;

    [Test]
    procedure ItemChargeEInvoiceFieldsAreStoredIndependently()
    var
        ItemCharge: Record "Item Charge";
    begin
        // [SCENARIO] E-Document Core owns the four e-document override fields on the item charge and keeps each value in its own field
        // [GIVEN] An item charge
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [WHEN] A distinct value is entered in each of the four override fields
        ItemCharge.Validate("E-Invoice Mapping", ItemCharge."E-Invoice Mapping"::"Document Allowance/Charge");
        ItemCharge.Validate("E-Invoice Reason Text", 'Freight surcharge');
        ItemCharge.Validate("E-Invoice Reason Code", 'FC');
        ItemCharge.Validate("E-Invoice Unit Code", 'HUR');
        ItemCharge.Modify(true);

        // [THEN] Each value is stored in its own field on the item charge record
        ItemCharge.Find();
        Assert.AreEqual(ItemCharge."E-Invoice Mapping"::"Document Allowance/Charge", ItemCharge."E-Invoice Mapping", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Mapping")));
        Assert.AreEqual('Freight surcharge', ItemCharge."E-Invoice Reason Text", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Reason Text")));
        Assert.AreEqual('FC', ItemCharge."E-Invoice Reason Code", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Reason Code")));
        Assert.AreEqual('HUR', ItemCharge."E-Invoice Unit Code", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Unit Code")));
    end;

    [Test]
    procedure BlankMappingOverrideIsDistinctFromAutomatic()
    var
        ItemCharge: Record "Item Charge";
    begin
        // [SCENARIO] A blank mapping override (use the service setting) and the Automatic override are two distinct states, so an item charge that was never configured does not silently behave as Automatic
        // [GIVEN] An item charge without a mapping override
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [THEN] The override is blank, not Automatic
        Assert.AreEqual(ItemCharge."E-Invoice Mapping"::" ", ItemCharge."E-Invoice Mapping", 'An item charge without override must keep a blank mapping');
        Assert.AreNotEqual(ItemCharge."E-Invoice Mapping"::Automatic, ItemCharge."E-Invoice Mapping", 'A blank override must not be stored as Automatic');

        // [WHEN] Automatic is selected
        ItemCharge.Validate("E-Invoice Mapping", ItemCharge."E-Invoice Mapping"::Automatic);
        ItemCharge.Modify(true);

        // [THEN] The Automatic override is stored, distinct from the blank value
        ItemCharge.Find();
        Assert.AreEqual(ItemCharge."E-Invoice Mapping"::Automatic, ItemCharge."E-Invoice Mapping", StrSubstNo(IncorrectValueErr, ItemCharge.FieldCaption("E-Invoice Mapping")));
        Assert.AreNotEqual(ItemCharge."E-Invoice Mapping"::" ", ItemCharge."E-Invoice Mapping", 'Automatic must be stored as an override, not as the blank value');
    end;
    #endregion
}
