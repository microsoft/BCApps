// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using System.Environment.Configuration;
using System.TestLibraries.Environment.Configuration;

codeunit 139999 "Subc. Feature Telemetry Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        Assert: Codeunit Assert;
        GuidedExperience: Codeunit "Guided Experience";
        SubcFeatureTelemetry: Codeunit "Subc. Feature Telemetry";

    [Test]
    procedure InstalledDefaultsDoNotCountAsSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcLibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
    begin
        // [SCENARIO 652154] Installed worksheet defaults alone do not mean subcontracting has been configured.
        Initialize();
        SubcLibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();

        ManufacturingSetup.Get();
        ManufacturingSetup.TestField("Subcontracting Template Name");
        ManufacturingSetup.TestField("Subcontracting Batch Name");

        Assert.IsFalse(SubcFeatureTelemetry.IsSetup(), 'Installation defaults must not count as subcontracting setup.');
    end;

    [Test]
    procedure PreviouslyConfiguredWorkCenterCountsAsSetup()
    var
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 652154] A company configured before uptake telemetry was introduced is recognized.
        Initialize();
        WorkCenter."No." := 'UPTAKE';
        WorkCenter.Insert();
        Assert.IsFalse(SubcFeatureTelemetry.IsSetup(), 'A work center without a subcontractor must not count as setup.');

        WorkCenter."Subcontractor No." := 'SUBCONTRACTOR';
        WorkCenter.Modify();

        Assert.IsTrue(SubcFeatureTelemetry.IsSetup(), 'An existing subcontracting work center must count as setup.');
    end;

    [Test]
    procedure PreviouslyConfiguredPriceCountsAsSetup()
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        // [SCENARIO 652154] An existing price with no work-center restriction is valid manual setup.
        Initialize();
        SubcontractorPrice."Vendor No." := 'SUBCONTRACTOR';
        SubcontractorPrice.Insert();
        Assert.IsFalse(SubcFeatureTelemetry.IsSetup(), 'An incomplete price must not count as setup.');

        SubcontractorPrice.Rename(
            SubcontractorPrice."Vendor No.", 'ITEM', '', '', '', 0D, '', 0, '');

        Assert.IsTrue(SubcFeatureTelemetry.IsSetup(), 'An existing vendor/item price must count as setup.');
    end;

    [Test]
    procedure TemporaryConfigurationDoesNotCountAsSetup()
    var
        TempSubcontractorPrice: Record "Subcontractor Price" temporary;
        TempWorkCenter: Record "Work Center" temporary;
    begin
        // [SCENARIO 652154] Unsaved or temporary configuration must not backfill company uptake.
        Initialize();
        TempWorkCenter."No." := 'UPTAKE';
        TempWorkCenter."Subcontractor No." := 'SUBCONTRACTOR';
        TempWorkCenter.Insert();
        TempSubcontractorPrice."Vendor No." := 'SUBCONTRACTOR';
        TempSubcontractorPrice."Item No." := 'ITEM';
        TempSubcontractorPrice.Insert();

        Assert.IsFalse(SubcFeatureTelemetry.IsSetup(), 'Temporary configuration must not count as company setup.');
    end;

    [Test]
    procedure CompletedAssistedSetupCountsAsSetup()
    begin
        // [SCENARIO 652154] Previously completed assisted setup is recognized without manual setup records.
        Initialize();
        Assert.IsFalse(SubcFeatureTelemetry.IsSetup(), 'Registering or starting assisted setup must not count as completion.');

        GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Subcontracting Setup Wizard");

        Assert.IsTrue(SubcFeatureTelemetry.IsSetup(), 'Completed assisted setup must count as company setup.');
    end;

    [Test]
    procedure SubcontractingServiceLineCountsAsUsage()
    var
        PurchaseLine: Record "Purchase Line";
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 652154] A purchase order line for a released subcontracting operation is actual usage.
        Initialize();
        CreateSubcontractingPurchaseLine(PurchaseLine, WorkCenter);

        Assert.IsTrue(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(PurchaseLine), 'A subcontracting service line must count as usage.');

        WorkCenter."Subcontractor No." := '';
        WorkCenter.Modify();
        Assert.IsFalse(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(PurchaseLine), 'An operation without a subcontractor must not count as usage.');
    end;

    [Test]
    procedure TemporaryAndZeroQuantityLinesDoNotCountAsUsage()
    var
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 652154] Temporary planning lines and zero-quantity lines are not operational uptake.
        Initialize();
        CreateSubcontractingPurchaseLine(PurchaseLine, WorkCenter);
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();

        Assert.IsFalse(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(TempPurchaseLine), 'A temporary purchase line must not count as usage.');

        PurchaseLine.Quantity := 0;
        Assert.IsFalse(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(PurchaseLine), 'A zero-quantity purchase line must not count as usage.');
    end;

    [Test]
    procedure UnrelatedPurchaseLinesDoNotCountAsUsage()
    var
        PurchaseLine: Record "Purchase Line";
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 652154] Invoices, comments and component purchases must not be mistaken for subcontracting service orders.
        Initialize();
        CreateSubcontractingPurchaseLine(PurchaseLine, WorkCenter);
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Invoice;
        Assert.IsFalse(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(PurchaseLine), 'An invoice must not count as purchase-order creation.');

        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine.Type := PurchaseLine.Type::" ";
        Assert.IsFalse(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(PurchaseLine), 'A comment must not count as usage.');

        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."Subc. Prod. Order No." := PurchaseLine."Prod. Order No.";
        PurchaseLine."Prod. Order No." := '';
        Assert.IsFalse(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(PurchaseLine), 'A component linked only through subcontracting component fields must not count as service usage.');
    end;

    [Test]
    procedure MissingReleasedOperationDoesNotCountAsUsage()
    var
        PurchaseLine: Record "Purchase Line";
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO 652154] Production references alone are insufficient without the released routing operation.
        Initialize();
        CreateSubcontractingPurchaseLine(PurchaseLine, WorkCenter);
        PurchaseLine."Operation No." := 'MISSING';

        Assert.IsFalse(SubcFeatureTelemetry.IsSubcontractingPurchaseOrderLine(PurchaseLine), 'A nonexistent released routing operation must not count as usage.');
    end;

    local procedure CreateSubcontractingPurchaseLine(var PurchaseLine: Record "Purchase Line"; var WorkCenter: Record "Work Center")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        WorkCenter."No." := 'UPTAKE';
        WorkCenter."Subcontractor No." := 'SUBCONTRACTOR';
        WorkCenter.Insert();

        ProdOrderRoutingLine.Status := ProdOrderRoutingLine.Status::Released;
        ProdOrderRoutingLine."Prod. Order No." := 'UPTAKE';
        ProdOrderRoutingLine."Routing Reference No." := 10000;
        ProdOrderRoutingLine."Routing No." := 'UPTAKE';
        ProdOrderRoutingLine."Operation No." := '10';
        ProdOrderRoutingLine."Work Center No." := WorkCenter."No.";
        ProdOrderRoutingLine.Insert();

        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := 'UPTAKE';
        PurchaseLine."Line No." := 10000;
        PurchaseLine.Type := PurchaseLine.Type::Item;
        PurchaseLine."No." := 'ITEM';
        PurchaseLine.Quantity := 1;
        PurchaseLine."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
        PurchaseLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        PurchaseLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        PurchaseLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        PurchaseLine.Insert();
    end;

    local procedure Initialize()
    var
        SubcontractorPrice: Record "Subcontractor Price";
        WorkCenter: Record "Work Center";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SubcManagementLibrary: Codeunit "Subc. Management Library";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Feature Telemetry Test");
        SubcManagementLibrary.Initialize();
        SubcontractorPrice.DeleteAll();
        WorkCenter.DeleteAll();
        AssistedSetupTestLibrary.CallOnRegister();
        GuidedExperience.ResetAssistedSetup(ObjectType::Page, Page::"Subcontracting Setup Wizard");
    end;
}
