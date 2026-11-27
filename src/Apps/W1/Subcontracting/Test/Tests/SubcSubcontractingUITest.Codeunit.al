// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Transfer;
using Microsoft.Foundation.Enums;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;
using System.Reflection;
using System.TestLibraries.Environment.Configuration;
using System.TestLibraries.Utilities;

codeunit 139990 "Subc. Subcontracting UI Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management
        IsInitialized := false;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure AcceptedVendorUpdatesPreconfiguredConsignment()
    var
        Component: Record "Prod. Order Component";
        BeforeComponent: Record "Prod. Order Component";
        OrdinaryComponent: Record "Prod. Order Component";
        BeforeOrdinaryComponent: Record "Prod. Order Component";
        OtherComponent: Record "Prod. Order Component";
        BeforeOtherComponent: Record "Prod. Order Component";
        BeforeArtifacts: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 654802] Accepting V2 updates existing consignment without changing ordinary or independent components.
        Initialize();

        // [GIVEN] C is already at V1, and an ordinary sibling remains at MAIN.
        CreateVendorRoutingFixture(0, 12);
        CreatePreconfiguredConsignmentComponent(Component);
        BeforeComponent := Component;
        FilterVendorRoutingComponents(OrdinaryComponent);
        OrdinaryComponent.FindFirst();
        BeforeOrdinaryComponent := OrdinaryComponent;
        OtherComponent.SetRange(Status, VROtherOrder.Status);
        OtherComponent.SetRange("Prod. Order No.", VROtherOrder."No.");
        OtherComponent.SetRange("Item No.", Component."Item No.");
        OtherComponent.FindFirst();
        OtherComponent.Validate("Component Supply Method", OtherComponent."Component Supply Method"::"Consignment at Vendor");
        OtherComponent.Modify(true);
        OtherComponent.Get(OtherComponent.Status, OtherComponent."Prod. Order No.", OtherComponent."Prod. Order Line No.", OtherComponent."Line No.");
        BeforeOtherComponent := OtherComponent;
        BeforeArtifacts := VendorRoutingPurchaseState() + VendorRoutingArtifactState();

        // [WHEN] The worksheet accepts V2 for the selected operation.
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);

        // [THEN] Only C follows V2; its original location, demand and flushing remain intact.
        VerifyPreconfiguredConsignmentComponent(Component, BeforeComponent, VRVendor[2]."Subc. Location Code");
        OrdinaryComponent.Get(BeforeOrdinaryComponent.Status, BeforeOrdinaryComponent."Prod. Order No.", BeforeOrdinaryComponent."Prod. Order Line No.", BeforeOrdinaryComponent."Line No.");
        OtherComponent.Get(BeforeOtherComponent.Status, BeforeOtherComponent."Prod. Order No.", BeforeOtherComponent."Prod. Order Line No.", BeforeOtherComponent."Line No.");
        Assert.AreEqual(BeforeOrdinaryComponent.SystemRowVersion, OrdinaryComponent.SystemRowVersion, 'The ordinary sibling must not be written.');
        Assert.AreEqual(BeforeOtherComponent.SystemRowVersion, OtherComponent.SystemRowVersion, 'Another order sharing the work center and routing link must not be written.');
        Assert.AreEqual(BeforeArtifacts, VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Accepting a vendor must not create purchases, transfer documents or posted stock.');
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure DeclinedVendorPreservesPreconfiguredConsignment()
    var
        Component: Record "Prod. Order Component";
        BeforeComponent: Record "Prod. Order Component";
        BeforeBusiness: Text;
        BeforeVersions: Text;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 654802] Declining V2 retains existing consignment at V1 without writing routing or components.
        Initialize();

        // [GIVEN] C is configured for consignment at V1 before the vendor choice.
        CreateVendorRoutingFixture(0, 12);
        CreatePreconfiguredConsignmentComponent(Component);
        BeforeComponent := Component;
        BeforeBusiness := VendorRoutingBusinessState();
        BeforeVersions := VendorRoutingRowVersions();

        // [WHEN] The worksheet selects V2 but declines the routing update.
        ChangeWorksheetVendor(VRVendor[2]."No.", false, true);

        // [THEN] C, its siblings and routing retain their original state.
        VerifyPreconfiguredConsignmentComponent(Component, BeforeComponent, VRVendor[1]."Subc. Location Code");
        Assert.AreEqual(BeforeBusiness, VendorRoutingBusinessState(), 'Declining must preserve all production and component business state.');
        Assert.AreEqual(BeforeVersions, VendorRoutingRowVersions(), 'Declining must not write routing or components on either order.');
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure PreconfiguredVendorSupplyRefusesReverseChoiceFlow()
    var
        Component: Record "Prod. Order Component";
        BeforeBusiness: Text;
        BeforeArtifacts: Text;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [Component Purchasing]
        // [SCENARIO 654802] A supplier-specific component configured before Yes refuses the inconsistent replacement before purchasing.
        // [GIVEN] One real linked component belongs to V1; its stock-backed sibling remains Transfer-to-Vendor at MAIN.
        CreateVendorRoutingFixture(0, 12);
        FilterVendorRoutingComponents(Component);
        Component.FindFirst();
        Component.Validate("Component Supply Method", Component."Component Supply Method"::"Vendor-Supplied");
        Component.Modify(true);
        Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
        Assert.AreEqual(VRVendor[1]."Subc. Location Code", Component."Location Code", 'Supply validation under V1 must genuinely persist its supplier-specific receiving location before Yes.');
        BeforeBusiness := VendorRoutingBusinessState();
        BeforeArtifacts := VendorRoutingPurchaseState() + VendorRoutingArtifactState();
        Commit();

        // [WHEN] The dependent replacement/carryout flow attempts to buy the preconfigured V1 component from V2.
        asserterror ChooseReplacementAndCarryOutVendorSupply();

        // [THEN] A contextual association refusal, not a generic purchase failure, leaves no purchase/transfer/component/history artifacts.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(VROrder."No.");
        Assert.ExpectedError(VRRouting[1]."Operation No.");
        Assert.ExpectedError(Component."Item No.");
        Assert.AreEqual(BeforeArtifacts, VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Neither the routing-choice boundary nor native carryout may create any artifacts for an inconsistent supplier association.');
        Assert.AreEqual(BeforeBusiness, VendorRoutingBusinessState(), 'Fail-closed must preserve MAIN, dates, cost, both component associations, bins and flushing.');
        Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
        Assert.AreEqual(VRVendor[1]."Subc. Location Code", Component."Location Code", 'Refusal must not move existing supplier-specific stock or history.');
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure VendorBeforeSupplyCarriesOutCoherentComponentPurchase()
    var
        Component: Record "Prod. Order Component";
        OtherComponent: Record "Prod. Order Component";
        Purchase: Record "Purchase Header";
        ServiceLine: Record "Purchase Line";
        ComponentLine: Record "Purchase Line";
        BeforeBusiness: Text;
        BeforeArtifacts: Text;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [Component Purchasing]
        // [SCENARIO 654802] Choosing V2 before supply configuration still purchases that component from V2 at V2's receiving location.
        // [GIVEN] The legal opposite field order resolves only one linked supplier component to the already accepted vendor.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        FilterVendorRoutingComponents(Component);
        Component.FindFirst();
        Component.Validate("Component Supply Method", Component."Component Supply Method"::"Vendor-Supplied");
        Component.Modify(true);
        Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
        Assert.AreEqual(VRVendor[2]."Subc. Location Code", Component."Location Code", 'Vendor-before-supply must resolve the genuine component association to V2.');
        BeforeBusiness := VendorRoutingBusinessState();
        BeforeArtifacts := VendorRoutingArtifactState();

        // [WHEN] Native carryout consumes the edited worksheet line, without recalculating it.
        VRReq.SetRecFilter();
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);

        // [THEN] Service purchasing retains MAIN while the persisted component purchase has BOTH the correct vendor and receiving location.
        FindVendorRoutingPurchase(VRRouting[1], Purchase, ServiceLine);
        VerifyVendorRoutingPurchase(Purchase, ServiceLine, VRRouting[1], VRVendor[2]);
        ComponentLine.SetRange("Document Type", Purchase."Document Type");
        ComponentLine.SetRange("Document No.", Purchase."No.");
        ComponentLine.SetRange(Type, ComponentLine.Type::Item);
        ComponentLine.SetRange("No.", Component."Item No.");
        ComponentLine.SetRange("Subc. Prod. Order No.", Component."Prod. Order No.");
        ComponentLine.SetRange("Subc. Prod. Order Line No.", Component."Prod. Order Line No.");
        ComponentLine.SetRange("Subc. Routing No.", VRRouting[1]."Routing No.");
        ComponentLine.SetRange("Subc. Rtng Reference No.", VRRouting[1]."Routing Reference No.");
        ComponentLine.SetRange("Subc. Operation No.", VRRouting[1]."Operation No.");
        Assert.AreEqual(1, ComponentLine.Count(), 'Native carryout must persist exactly the selected supplier component association.');
        ComponentLine.FindFirst();
        Assert.AreEqual(VRVendor[2]."No.", ComponentLine."Buy-from Vendor No.", 'The component, not only the service/header, must buy from V2.');
        Assert.AreEqual(VRVendor[2]."Subc. Location Code", ComponentLine."Location Code", 'V2 component purchasing must not receive at the former V1 supplier location.');
        Assert.AreEqual(12, ComponentLine.Quantity, 'The complete native component demand must remain intact.');
        FilterVendorRoutingComponents(OtherComponent);
        OtherComponent.SetFilter("Line No.", '<>%1', Component."Line No.");
        Assert.AreEqual(1, OtherComponent.Count(), 'The real stock-backed sibling must remain independently present.');
        OtherComponent.FindFirst();
        Assert.AreEqual(OtherComponent."Component Supply Method"::"Transfer to Vendor", OtherComponent."Component Supply Method", 'Do not turn the ordinary sibling into supplier purchasing.');
        Assert.AreEqual(VRMain.Code, OtherComponent."Location Code", 'The ordinary stocked sibling must remain at MAIN.');
        Assert.AreEqual(BeforeArtifacts, VendorRoutingArtifactState(), 'Carryout must not post, transfer or relocate component stock.');
        Assert.AreEqual(BeforeBusiness, VendorRoutingBusinessState(), 'Component purchase creation must preserve production dates, schedule, costs and component state.');
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure NativeReturnSameSourceSeparatesOrderIdentity()
    var
        Precursor: Record "Purchase Header";
        Successor: Record "Purchase Header";
        PrecursorLine: Record "Purchase Line";
        SuccessorLine: Record "Purchase Line";
        OtherPurchase: Record "Purchase Header";
        OtherLine: Record "Purchase Line";
        OtherRouting: Record "Prod. Order Routing Line";
        Forward: Record "Transfer Header";
        ItemUOM: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Subcontracting] [WIP] [Return Source Identity]
        // [SCENARIO 654802] A genuine same-source return claim on another order cannot consume this order's six remaining unpromised units.
        // [GIVEN] Both orders keep V1, identical native item/variant/line/reference/routing/operation and the SAME physical source.
        PrepareSameSourceSerialReturn(Precursor, Successor, PrecursorLine, SuccessorLine, ItemUOM);
        FindVendorRoutingOperation(VROtherOrder, '10', OtherRouting);
        CreateVendorRoutingPurchase(OtherRouting, OtherPurchase, OtherLine);
        CreateVendorRoutingForward(OtherPurchase);
        FindVendorRoutingTransfer(OtherPurchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CreateVendorRoutingReturn(OtherPurchase);
        Assert.AreNotEqual(PrecursorLine."Prod. Order No.", OtherLine."Prod. Order No.", 'Order number must be the distinguishing production identity.');
        Assert.AreEqual(PrecursorLine."Prod. Order Line No.", OtherLine."Prod. Order Line No.", 'Native production line numbers must match across orders.');
        Assert.AreEqual(PrecursorLine."Routing Reference No.", OtherLine."Routing Reference No.", 'Native routing references must match across orders.');
        VerifySameSourceClaimAxes(Precursor, PrecursorLine, OtherPurchase, OtherLine);
        VerifyNativeReturnUOM(OtherLine, Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyVendorRoutingWIP(OtherRouting, Precursor."Subc. Location Code", false, 12);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", ItemUOM.Code, 1, 6, 6);

        // [WHEN] The selected order invokes the native return action.
        CreateVendorRoutingReturn(Precursor);

        // [THEN] The selected source promises six, while the actual competing same-location original remains twelve.
        VerifyNativeReturnUOM(PrecursorLine, Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);
        VerifyNativeReturnUOM(OtherLine, Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", ItemUOM.Code, 1, 6, 6);
        VerifyVendorRoutingWIP(VRRouting[1], Precursor."Subc. Location Code", false, 12);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure NativeReturnSameSourceSeparatesNativeLines()
    var
        ProductionLine: Record "Prod. Order Line";
        OriginalProductionLine: Record "Prod. Order Line";
        OtherRouting: Record "Prod. Order Routing Line";
        OtherSuccessor: Record "Prod. Order Routing Line";
        Precursor: Record "Purchase Header";
        Successor: Record "Purchase Header";
        PrecursorLine: Record "Purchase Line";
        SuccessorLine: Record "Purchase Line";
        OtherPurchase: Record "Purchase Header";
        OtherLine: Record "Purchase Line";
        Forward: Record "Transfer Header";
        ItemUOM: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Subcontracting] [WIP] [Return Source Identity]
        // [SCENARIO 654802] Native same-order, same-item, same-variant lines at the same source retain separate return claims.
        // [GIVEN] CalcLines=false preserves a genuine second blank-variant line before any purchase or posting.
        CreateVendorRoutingFixture(1, 12);
        LibraryManufacturing.CreateProdOrderLine(ProductionLine, VROrder.Status, VROrder."No.", VRItem."No.", '', VRMain.Code, 12);
        LibraryManufacturing.RefreshProdOrder(VROrder, false, false, true, true, false);
        ProductionLine.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", ProductionLine."Line No.");
        ReloadVendorRoutingOperation(VRRouting[1]);
        ReloadVendorRoutingOperation(VRRouting[4]);
        OriginalProductionLine.Get(VROrder.Status, VROrder."No.", VendorRoutingProductionLineNo(VRRouting[1]));
        Assert.AreEqual(VRItem."No.", ProductionLine."Item No.", 'The library-created second line must retain the same item.');
        Assert.AreEqual('', ProductionLine."Variant Code", 'Variant must not mask this production-line/reference control.');
        Assert.AreEqual(OriginalProductionLine."Variant Code", ProductionLine."Variant Code", 'Both native lines must have the same variant.');
        Assert.AreEqual(VRMain.Code, ProductionLine."Location Code", 'Refresh must retain the real second-line production location.');
        Assert.AreEqual(12, ProductionLine.Quantity, 'Refresh must retain the real second-line document demand.');
        Assert.AreEqual(12, ProductionLine."Quantity (Base)", 'Refresh must retain twelve base on the second line.');
        Assert.AreEqual(12, OriginalProductionLine."Quantity (Base)", 'CalcLines=false must also preserve the first line.');
        Assert.AreEqual(VRItem."Routing No.", ProductionLine."Routing No.", 'The second line must use the same certified routing.');
        Assert.AreEqual(ProductionLine."Line No.", ProductionLine."Routing Reference No.", 'Native item validation requires the second line to have its own reference.');
        Assert.AreNotEqual(OriginalProductionLine."Routing Reference No.", ProductionLine."Routing Reference No.", 'Distinct native references are unavoidable; this is a line/reference control, not a variant control.');
        OtherRouting.Get(VROrder.Status, VROrder."No.", ProductionLine."Routing Reference No.", ProductionLine."Routing No.", '10');
        OtherSuccessor.Get(VROrder.Status, VROrder."No.", ProductionLine."Routing Reference No.", ProductionLine."Routing No.", '40');
        Assert.AreEqual(VRWorkCenter[1]."No.", OtherRouting."Work Center No.", 'The second predecessor must be the genuine native subcontract operation.');
        Assert.AreEqual('40', OtherRouting."Next Operation No.", 'The second predecessor must retain its native serial edge.');
        Assert.IsTrue(OtherRouting."Transfer WIP Item", 'The second predecessor must retain its native WIP flag.');
        Assert.AreEqual(VRWorkCenter[4]."No.", OtherSuccessor."Work Center No.", 'The second successor must retain its own native work center.');
        Assert.AreEqual('10', OtherSuccessor."Previous Operation No.", 'The second successor must retain its native predecessor.');
        Assert.IsTrue(OtherSuccessor."Transfer WIP Item", 'The second successor must retain its native WIP flag.');
        PrepareSameSourceSerialReturnPurchases(Precursor, Successor, PrecursorLine, SuccessorLine, ItemUOM);
        CreateNativeScopedPurchase(ProductionLine, OtherRouting, OtherPurchase, OtherLine);
        CreateVendorRoutingForward(OtherPurchase);
        FindVendorRoutingTransfer(OtherPurchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CreateVendorRoutingReturn(OtherPurchase);
        Assert.AreEqual(PrecursorLine."Prod. Order No.", OtherLine."Prod. Order No.", 'Order must not mask this line/reference control.');
        Assert.AreNotEqual(PrecursorLine."Prod. Order Line No.", OtherLine."Prod. Order Line No.", 'The competing claim must belong to the genuine second line.');
        Assert.AreNotEqual(PrecursorLine."Routing Reference No.", OtherLine."Routing Reference No.", 'The competing claim must retain its unavoidable native reference.');
        VerifySameSourceClaimAxes(Precursor, PrecursorLine, OtherPurchase, OtherLine);
        VerifyNativeReturnUOM(OtherLine, Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);

        // [WHEN] The original production line invokes its native return action.
        CreateVendorRoutingReturn(Precursor);

        // [THEN] Same-source originals retain separate full identities, own UOM conversion and stored native zero fields.
        VerifyNativeReturnUOM(PrecursorLine, Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);
        VerifyNativeReturnUOM(OtherLine, Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", ItemUOM.Code, 1, 6, 6);
        VerifyVendorRoutingWIP(VRRouting[1], Precursor."Subc. Location Code", false, 12);
        VerifyAuthorSourceWIP(OtherLine, '10', Precursor."Subc. Location Code", 12);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NativeReturnSameSourceSeparatesHistoricalVariant()
    var
        ProductionLine: Record "Prod. Order Line";
        OldPurchase: Record "Purchase Header";
        Purchase: Record "Purchase Header";
        OldLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Subcontracting] [WIP] [Return Source Identity]
        // [SCENARIO 654802] A genuine A return at the SAME order/line/reference/item/operation/location cannot reserve matching B stock.
        // [GIVEN] Native A4 and its return precede a legal committed variant edit and native matching B8 purchase/receipt.
        PrepareSameIdentityVariantSources(true, ProductionLine, OldPurchase, OldLine, Purchase, PurchaseLine);
        VerifyNativeReturnUOM(OldLine, Purchase."Subc. Location Code", VRItem."Base Unit of Measure", 4, 4, 4);
        Assert.AreEqual(ProductionLine."Variant Code", PurchaseLine."Variant Code", 'The selected purchase must match current production B, not be stale purchase A.');
        Assert.AreNotEqual(OldLine."Variant Code", PurchaseLine."Variant Code", 'Variant must be the differing source identity.');

        // [WHEN] Matching B invokes its native return action.
        CreateVendorRoutingReturn(Purchase);

        // [THEN] B returns its full eight; A's real four-base original and both native posted histories remain untouched.
        VerifyNativeReturnUOM(PurchaseLine, Purchase."Subc. Location Code", VRItem."Base Unit of Measure", 8, 8, 8);
        VerifyNativeReturnUOM(OldLine, Purchase."Subc. Location Code", VRItem."Base Unit of Measure", 4, 4, 4);
        VerifyAuthorSourceWIP(OldLine, '10', Purchase."Subc. Location Code", 4);
        VerifyAuthorSourceWIP(PurchaseLine, '10', Purchase."Subc. Location Code", 8);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NativeReturnSameSourceSeparatesCurrentOperation()
    var
        Purchase: Record "Purchase Header";
        OtherPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OtherLine: Record "Purchase Line";
        Forward: Record "Transfer Header";
    begin
        // [FEATURE] [Subcontracting] [WIP] [Return Source Identity]
        // [SCENARIO 654802] Parallel native operations sharing one location retain independent current-operation return promises.
        // [GIVEN] Both branches lawfully receive from the non-WIP company predecessor into the same supplier location.
        CreateVendorRoutingFixture(2, 12);
        VRVendor[5].Validate("Subc. Location Code", VRVendor[1]."Subc. Location Code");
        VRVendor[5].Modify(true);
        CreateVendorRoutingPurchase(VRRouting[1], Purchase, PurchaseLine);
        CreateVendorRoutingForward(Purchase);
        FindVendorRoutingTransfer(Purchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CreateVendorRoutingPurchase(VRRouting[3], OtherPurchase, OtherLine);
        CreateVendorRoutingForward(OtherPurchase);
        FindVendorRoutingTransfer(OtherPurchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CreateVendorRoutingReturn(OtherPurchase);
        Assert.AreEqual(Purchase."Subc. Location Code", OtherPurchase."Subc. Location Code", 'Location must not mask operation isolation.');
        Assert.AreEqual(PurchaseLine."Prod. Order No.", OtherLine."Prod. Order No.", 'The native order must match.');
        Assert.AreEqual(PurchaseLine."Prod. Order Line No.", OtherLine."Prod. Order Line No.", 'The native production line must match.');
        Assert.AreEqual(PurchaseLine."Routing Reference No.", OtherLine."Routing Reference No.", 'The native routing reference must match.');
        Assert.AreEqual(PurchaseLine."Routing No.", OtherLine."Routing No.", 'Routing must not mask operation isolation.');
        Assert.AreEqual(PurchaseLine."No.", OtherLine."No.", 'The WIP item must match.');
        Assert.AreEqual(PurchaseLine."Variant Code", OtherLine."Variant Code", 'Variant must not mask operation isolation.');
        Assert.AreNotEqual(PurchaseLine."Operation No.", OtherLine."Operation No.", 'Only the current source operation differs.');
        VerifyNativeReturnUOM(OtherLine, Purchase."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyAuthorSourceWIP(PurchaseLine, '20', Purchase."Subc. Location Code", 12);
        VerifyAuthorSourceWIP(OtherLine, '30', Purchase."Subc. Location Code", 12);

        // [WHEN] Operation 20 invokes its native return action against that same source.
        CreateVendorRoutingReturn(Purchase);

        // [THEN] Neither original spends the other current operation; both native return previous-operation fields remain blank.
        VerifyNativeReturnUOM(PurchaseLine, Purchase."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyNativeReturnUOM(OtherLine, Purchase."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyAuthorSourceWIP(PurchaseLine, '20', Purchase."Subc. Location Code", 12);
        VerifyAuthorSourceWIP(OtherLine, '30', Purchase."Subc. Location Code", 12);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure SerialGrowingSourceCountsOwnOriginalInOwnUOM()
    var
        Precursor: Record "Purchase Header";
        Successor: Record "Purchase Header";
        PrecursorLine: Record "Purchase Line";
        SuccessorLine: Record "Purchase Line";
        Forward: Record "Transfer Header";
        Original: Record "Transfer Line";
        OriginalUOM: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Subcontracting] [WIP] [Serial Physical Availability]
        // [SCENARIO 654802] Source growth four to eight leaves only four physical units after the current serial original's own four.
        // [GIVEN] A native shipment of twelve has received four; demand twelve has its own unshipped original four.
        CreateVendorRoutingFixture(1, 12);
        CreateVendorRoutingPurchase(VRRouting[1], Precursor, PrecursorLine);
        CreateVendorRoutingForward(Precursor);
        FindVendorRoutingTransfer(Precursor, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, false);
        SetVendorRoutingWIPReceipt(Forward, 4);
        LibraryWarehouse.PostTransferOrder(Forward, false, true);
        VerifyVendorRoutingWIP(VRRouting[1], Precursor."Subc. Location Code", false, 4);
        CreateVendorRoutingPurchase(VRRouting[4], Successor, SuccessorLine);
        CreateVendorRoutingForward(Successor);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 4, 4, 4);
        FilterVendorRoutingOverlapTuple(Original, SuccessorLine, '10', Precursor."Subc. Location Code");
        Original.FindFirst();
        LibraryInventory.CreateItemUnitOfMeasureCode(OriginalUOM, VRItem."No.", 2);
        Original.Validate("Unit of Measure Code", OriginalUOM.Code);
        Original.Validate("Transfer WIP Item", true);
        Original.Validate(Quantity, 2);
        Original.Modify(true);
        SetVendorRoutingWIPReceipt(Forward, 4);
        LibraryWarehouse.PostTransferOrder(Forward, false, true);
        Assert.AreEqual(12, SuccessorLine.Quantity, 'The native successor demand must remain twelve, not be resized to fit stock.');
        VerifyVendorRoutingWIP(VRRouting[1], Precursor."Subc. Location Code", false, 8);
        VerifyVendorRoutingWIP(VRRouting[4], Successor."Subc. Location Code", false, 0);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", OriginalUOM.Code, 2, 4, 4);

        // [WHEN] The serial successor requests another native forward transfer after the additional receipt.
        CreateVendorRoutingForward(Successor);

        // [THEN] Native min(residual, available) creates four, not eight; FULL original coverage and own-UOM conversion remain intact.
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", OriginalUOM.Code, 2, 4, 4);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 4, 4, 4);
        VerifyAuthorForwardSourceTotals(SuccessorLine, '10', Precursor."Subc. Location Code", 8, 8);
        VerifyVendorRoutingWIP(VRRouting[1], Precursor."Subc. Location Code", false, 8);
        VerifyVendorRoutingWIP(VRRouting[1], Forward."In-Transit Code", true, 4);
        VerifyVendorRoutingWIP(VRRouting[4], Successor."Subc. Location Code", false, 0);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure SerialExpectedExcludesHistoricalVariantStock()
    var
        ProductionLine: Record "Prod. Order Line";
        OldPurchase: Record "Purchase Header";
        Precursor: Record "Purchase Header";
        Successor: Record "Purchase Header";
        OldLine: Record "Purchase Line";
        PrecursorLine: Record "Purchase Line";
        SuccessorLine: Record "Purchase Line";
        BeforeArtifacts: Text;
    begin
        // [FEATURE] [Subcontracting] [WIP] [Serial Physical Availability]
        // [SCENARIO 654802] Compatible Expected uses B8, not old A4 plus B8, once FULL matching B original eight already covers that native source preset.
        // [GIVEN] Same-source A4 history is retained; committed production B and both native purchases match B exactly.
        PrepareSameIdentityVariantSources(false, ProductionLine, OldPurchase, OldLine, Precursor, PrecursorLine);
        CreateAuthorScopedNativePurchase(ProductionLine, VRRouting[4], Successor, SuccessorLine);
        Assert.AreEqual(ProductionLine."Variant Code", SuccessorLine."Variant Code", 'This is matching B purchasing, not the already-refused stale A association.');
        Assert.AreEqual(12, SuccessorLine.Quantity, 'The successor must retain native demand twelve.');
        CreateAuthorScopedNativeForward(SuccessorLine);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 8, 8, 8);
        VerifyAuthorSourceWIP(OldLine, '10', Precursor."Subc. Location Code", 4);
        VerifyAuthorSourceWIP(PrecursorLine, '10', Precursor."Subc. Location Code", 8);
        BeforeArtifacts := NativeVariantArtifactState(ProductionLine);
        Commit();

        // [WHEN] The matching B successor requests its native forward transfer again.
        asserterror CreateAuthorScopedNativeForward(SuccessorLine);

        // [THEN] Exact native source coverage is already satisfied, not an availability error caused by treating A as additional B stock.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('covered');
        Assert.AreEqual(BeforeArtifacts, NativeVariantArtifactState(ProductionLine), 'Exact Expected must preserve every original, component, purchase and posted artifact.');
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", VRItem."Base Unit of Measure", 8, 8, 8);
        VerifyAuthorSourceWIP(OldLine, '10', Precursor."Subc. Location Code", 4);
        VerifyAuthorSourceWIP(PrecursorLine, '10', Precursor."Subc. Location Code", 8);
        FinishVendorRoutingFixture();
    end;

    local procedure ChooseReplacementAndCarryOutVendorSupply()
    begin
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        VRReq.SetRecFilter();
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);
    end;

    local procedure PrepareSameSourceSerialReturn(var Precursor: Record "Purchase Header"; var Successor: Record "Purchase Header"; var PrecursorLine: Record "Purchase Line"; var SuccessorLine: Record "Purchase Line"; var ItemUOM: Record "Item Unit of Measure")
    begin
        CreateVendorRoutingFixture(1, 12);
        PrepareSameSourceSerialReturnPurchases(Precursor, Successor, PrecursorLine, SuccessorLine, ItemUOM);
    end;

    local procedure PrepareSameSourceSerialReturnPurchases(var Precursor: Record "Purchase Header"; var Successor: Record "Purchase Header"; var PrecursorLine: Record "Purchase Line"; var SuccessorLine: Record "Purchase Line"; var ItemUOM: Record "Item Unit of Measure")
    var
        Forward: Record "Transfer Header";
    begin
        CreateVendorRoutingPurchase(VRRouting[1], Precursor, PrecursorLine);
        Assert.AreEqual(VRVendor[1]."Subc. Location Code", Precursor."Subc. Location Code", 'The selected precursor must keep V1 so another native V1 source cannot be masked by location.');
        CreateVendorRoutingForward(Precursor);
        FindVendorRoutingTransfer(Precursor, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CreateVendorRoutingPurchase(VRRouting[4], Successor, SuccessorLine);
        SetNativePurchaseUOM(SuccessorLine, 6, 1, ItemUOM);
        CreateVendorRoutingForward(Successor);
        VerifyNativeForwardUOM(SuccessorLine, '10', Precursor."Subc. Location Code", ItemUOM.Code, 1, 6, 6);
        VerifyVendorRoutingWIP(VRRouting[1], Precursor."Subc. Location Code", false, 12);
    end;

    local procedure VerifySameSourceClaimAxes(Purchase: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; OtherPurchase: Record "Purchase Header"; OtherLine: Record "Purchase Line")
    begin
        Assert.AreEqual(Purchase."Subc. Location Code", OtherPurchase."Subc. Location Code", 'Both genuine claims must compete at the SAME selected physical source.');
        Assert.AreEqual(PurchaseLine."No.", OtherLine."No.", 'Item must not mask the selected identity axis.');
        Assert.AreEqual(PurchaseLine."Variant Code", OtherLine."Variant Code", 'Variant must not mask the selected identity axis.');
        Assert.AreEqual(PurchaseLine."Routing No.", OtherLine."Routing No.", 'Routing must not mask the selected identity axis.');
        Assert.AreEqual(PurchaseLine."Operation No.", OtherLine."Operation No.", 'Current source operation must not mask the selected identity axis.');
    end;

    local procedure PrepareSameIdentityVariantSources(CreateOldReturn: Boolean; var ProductionLine: Record "Prod. Order Line"; var OldPurchase: Record "Purchase Header"; var OldLine: Record "Purchase Line"; var Purchase: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        VariantA: Record "Item Variant";
        VariantB: Record "Item Variant";
        Forward: Record "Transfer Header";
        CurrentLine: Record "Purchase Line";
    begin
        CreateVendorRoutingFixture(1, 12);
        ProductionLine.Get(VROrder.Status, VRReq."Prod. Order No.", VRReq."Prod. Order Line No.");
        Assert.AreEqual(VROrder."No.", ProductionLine."Prod. Order No.", 'The calculated native suggestion must identify the selected production order.');
        Assert.AreEqual(VRReq."No.", ProductionLine."Item No.", 'The calculated native suggestion must identify the production item.');
        Assert.AreEqual(VRReq."Variant Code", ProductionLine."Variant Code", 'The initial variant must come from the actual native suggestion.');
        Assert.AreEqual(VRRouting[1]."Routing No.", ProductionLine."Routing No.", 'The selected line must retain the native routing.');
        Assert.AreEqual(VRRouting[1]."Routing Reference No.", ProductionLine."Routing Reference No.", 'The selected line must retain the native routing reference.');
        LibraryInventory.CreateItemVariant(VariantA, VRItem."No.");
        LibraryInventory.CreateItemVariant(VariantB, VRItem."No.");
        ProductionLine.Validate("Variant Code", VariantA.Code);
        ProductionLine.Modify(true);
        CreateNativeScopedPurchase(ProductionLine, VRRouting[1], OldPurchase, OldLine);
        OldLine.Validate(Quantity, 4);
        OldLine.Modify(true);
        CreateAuthorScopedNativeForward(OldLine);
        FindVendorRoutingTransfer(OldPurchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        if CreateOldReturn then begin
            CreateVendorRoutingReturn(OldPurchase);
            VerifyNativeReturnUOM(OldLine, OldPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 4, 4, 4);
        end;
        ProductionLine.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", ProductionLine."Line No.");
        ProductionLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)", "Put-away Qty. (Base)");
        Assert.AreEqual(0, ProductionLine."Finished Quantity", 'WIP receipt must not create finished production output.');
        Assert.AreEqual(0, ProductionLine."Reserved Quantity", 'The native production variant edit must have no output reservations.');
        Assert.AreEqual(0, ProductionLine."Reserved Qty. (Base)", 'The native production output base reservation must be zero.');
        Assert.AreEqual(0, ProductionLine."Put-away Qty. (Base)", 'The fixture must have no production warehouse output.');
        ProductionLine.Validate("Variant Code", VariantB.Code);
        ProductionLine.Modify(true);
        Commit();
        ProductionLine.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", ProductionLine."Line No.");
        Assert.AreEqual(VariantB.Code, ProductionLine."Variant Code", 'B must genuinely persist before native B purchasing.');
        Assert.AreEqual(OldLine."Routing No.", ProductionLine."Routing No.", 'Native variant validation must preserve routing.');
        Assert.AreEqual(OldLine."Routing Reference No.", ProductionLine."Routing Reference No.", 'Native variant validation must preserve reference.');
        CreateAuthorScopedNativePurchase(ProductionLine, VRRouting[1], Purchase, PurchaseLine);
        Assert.AreEqual(8, PurchaseLine.Quantity, 'Native routing purchasing must create the remaining eight after the existing A service four, without faking a B association.');
        Assert.AreNotEqual(OldPurchase."No.", Purchase."No.", 'B must use a separate native purchase selection, not include stale A.');
        Assert.AreEqual(OldLine."Prod. Order No.", PurchaseLine."Prod. Order No.", 'Order must not mask the variant control.');
        Assert.AreEqual(OldLine."Prod. Order Line No.", PurchaseLine."Prod. Order Line No.", 'Production line must not mask the variant control.');
        Assert.AreEqual(OldLine."Routing Reference No.", PurchaseLine."Routing Reference No.", 'Reference must not mask the variant control.');
        Assert.AreEqual(OldLine."Routing No.", PurchaseLine."Routing No.", 'Routing must not mask the variant control.');
        Assert.AreEqual(OldLine."Operation No.", PurchaseLine."Operation No.", 'Source operation must not mask the variant control.');
        Assert.AreEqual(OldLine."No.", PurchaseLine."No.", 'Item must not mask the variant control.');
        Assert.AreEqual(OldPurchase."Subc. Location Code", Purchase."Subc. Location Code", 'A and B must share the same actual source location.');
        Assert.AreEqual(VariantB.Code, PurchaseLine."Variant Code", 'The native B purchase must match committed production B.');
        CreateAuthorScopedNativeForward(PurchaseLine);
        FindVendorRoutingTransfer(Purchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CurrentLine.Get(OldLine."Document Type", OldLine."Document No.", OldLine."Line No.");
        Assert.AreEqual(OldLine.SystemRowVersion, CurrentLine.SystemRowVersion, 'Native B creation/posting must not rewrite the old A purchase.');
        Assert.AreEqual(VariantA.Code, CurrentLine."Variant Code", 'Old purchasing must retain A.');
        Assert.AreEqual(4, CurrentLine.Quantity, 'The native old service four must remain unchanged.');
        VerifyAuthorSourceWIP(OldLine, '10', Purchase."Subc. Location Code", 4);
        VerifyAuthorSourceWIP(PurchaseLine, '10', Purchase."Subc. Location Code", 8);
    end;

    local procedure CreateAuthorScopedNativePurchase(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; var Purchase: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Creator: Codeunit "Subc. Purchase Order Creator";
    begin
        // Use the existing public native creation entry point, not the UI's optional ShowExistingPurchaseOrders dialog.
        Assert.AreEqual(1, Creator.CreateSubcontractingPurchaseOrderFromRoutingLine(Routing), 'Native routing creation must carry out exactly this production-line purchase.');
        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
        PurchaseLine.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        PurchaseLine.SetRange("Routing No.", Routing."Routing No.");
        PurchaseLine.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        PurchaseLine.SetRange("Operation No.", Routing."Operation No.");
        PurchaseLine.SetRange("No.", ProductionLine."Item No.");
        PurchaseLine.SetRange("Variant Code", ProductionLine."Variant Code");
        Assert.AreEqual(1, PurchaseLine.Count(), 'The native creator must persist a genuine matching item/variant/full-source purchase.');
        PurchaseLine.FindFirst();
        Purchase.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
    end;

    local procedure CreateAuthorScopedNativeForward(PurchaseLine: Record "Purchase Line")
    var
        ProductionLine: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
        Purchase: Record "Purchase Header";
        WIP: Record "Subcontractor WIP Ledger Entry";
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Purchase.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        ProductionLine.SetRange(Status, ProductionLine.Status::Released);
        ProductionLine.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        ProductionLine.SetRange("Line No.", PurchaseLine."Prod. Order Line No.");
        ProductionLine.SetRange("Routing No.", PurchaseLine."Routing No.");
        ProductionLine.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        ProductionLine.SetRange("Item No.", PurchaseLine."No.");
        ProductionLine.SetRange("Variant Code", PurchaseLine."Variant Code");
        Assert.AreEqual(1, ProductionLine.Count(), 'The actual native purchase must resolve to one exact current item/variant/order/line/routing/reference identity.');
        ProductionLine.FindFirst();
        Routing.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.");
        Assert.AreEqual(PurchaseLine."Work Center No.", Routing."Work Center No.", 'The native purchase must identify the selected routing operation and work center.');
        EnsureVendorRoutingRoute(ProductionLine."Location Code", Purchase."Subc. Location Code");
        WIP.SetRange("Prod. Order Status", ProductionLine.Status);
        WIP.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
        WIP.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        WIP.SetRange("Routing No.", Routing."Routing No.");
        WIP.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        WIP.SetRange("Operation No.", Routing."Previous Operation No.");
        WIP.SetRange("Item No.", ProductionLine."Item No.");
        WIP.SetRange("Variant Code", ProductionLine."Variant Code");
        WIP.SetRange("In Transit", false);
        WIP.SetFilter("Quantity (Base)", '>0');
        if WIP.FindSet() then
            repeat
                EnsureVendorRoutingRoute(WIP."Location Code", Purchase."Subc. Location Code");
            until WIP.Next() = 0;
        InvokeNativeVariantForward(Purchase);
    end;

    local procedure VerifyAuthorForwardSourceTotals(PurchaseLine: Record "Purchase Line"; PreviousOperation: Code[10]; SourceLocation: Code[10]; ExpectedFullBase: Decimal; ExpectedUnshippedBase: Decimal)
    var
        Line: Record "Transfer Line";
        FullBase: Decimal;
        UnshippedBase: Decimal;
    begin
        FilterVendorRoutingOverlapTuple(Line, PurchaseLine, PreviousOperation, SourceLocation);
        Assert.AreEqual(2, Line.Count(), 'The mixed-UOM source must retain both genuine originals.');
        Line.FindSet();
        repeat
            FullBase += Line.CalcBaseQty(Line.Quantity);
            UnshippedBase += Line.CalcBaseQty(Line.Quantity - Line."Quantity Shipped");
        until Line.Next() = 0;
        Assert.AreEqual(ExpectedFullBase, FullBase, 'FULL original coverage must convert each original in its own UOM before adding.');
        Assert.AreEqual(ExpectedUnshippedBase, UnshippedBase, 'Physical claims must convert each original unshipped quantity in its own UOM before adding.');
    end;

    local procedure VerifyAuthorSourceWIP(PurchaseLine: Record "Purchase Line"; OperationNo: Code[10]; SourceLocation: Code[10]; ExpectedBase: Decimal)
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
    begin
        Entry.SetRange("Prod. Order Status", VROrder.Status);
        Entry.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        Entry.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        Entry.SetRange("Routing No.", PurchaseLine."Routing No.");
        Entry.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        Entry.SetRange("Operation No.", OperationNo);
        Entry.SetRange("Item No.", PurchaseLine."No.");
        Entry.SetRange("Variant Code", PurchaseLine."Variant Code");
        Entry.SetRange("Location Code", SourceLocation);
        Entry.SetRange("In Transit", false);
        Assert.IsFalse(Entry.IsEmpty(), 'The fixture must have genuine native posted source evidence with the complete item/variant identity.');
        Entry.CalcSums("Quantity (Base)");
        Assert.AreEqual(ExpectedBase, Entry."Quantity (Base)", 'Only the exact persisted source identity may contribute physical WIP.');
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure StaleProductionVariantRefusesForwardBeforeArtifacts()
    var
        ProductionLine: Record "Prod. Order Line";
        BeforeEdit: Record "Prod. Order Line";
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReplacementVariant: Record "Item Variant";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] A committed legal production variant edit cannot attach new B WIP to the unchanged A purchase.
        Initialize();

        // [GIVEN] Native report creation left an unshipped FULL original A12, with no finished output or production reservation.
        PrepareNativeVariantFullOriginal(ProductionLine, Purchase, PurchaseLine, ReplacementVariant);
        BeforeEdit := ProductionLine;
        ProductionLine.Validate("Variant Code", ReplacementVariant.Code);
        ProductionLine.Modify(true);
        Commit();
        ProductionLine.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", ProductionLine."Line No.");
        Assert.AreEqual(ReplacementVariant.Code, ProductionLine."Variant Code", 'The legal native A-to-B edit must actually persist before selection.');
        Assert.AreNotEqual(BeforeEdit.SystemRowVersion, ProductionLine.SystemRowVersion, 'Native Modify(true) must persist the production edit.');
        Assert.AreEqual(BeforeEdit."Item No.", ProductionLine."Item No.", 'Changing variant must retain the production item.');
        Assert.AreEqual(BeforeEdit."Routing No.", ProductionLine."Routing No.", 'Changing variant must retain the existing routing.');
        Assert.AreEqual(BeforeEdit."Routing Reference No.", ProductionLine."Routing Reference No.", 'Changing variant must retain the existing routing reference.');
        VerifyNativeVariantSelection(ProductionLine, PurchaseLine);
        VerifyNativeVariantFullCoverage(PurchaseLine, ReplacementVariant.Code);
        BeforeState := NativeVariantArtifactState(ProductionLine);

        // [WHEN] The real purchase action selects the stale A association only after production B was committed.
        asserterror InvokeNativeVariantForward(Purchase);

        // [THEN] Protected preflight refuses contextually, preserving B, purchase A and every original/artifact.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(
            'The selected operation %1 of production order %2 has changed. Reopen the order and try again.',
            PurchaseLine."Operation No.", PurchaseLine."Prod. Order No."));
        VerifyNativeVariantSelection(ProductionLine, PurchaseLine);
        VerifyNativeVariantFullCoverage(PurchaseLine, ReplacementVariant.Code);
        Assert.AreEqual(BeforeState, NativeVariantArtifactState(ProductionLine), 'Stale selection must create no headers, components or WIP and must not rewrite any original order.');
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure MatchingProductionVariantKeepsFullOriginalCoverage()
    var
        ProductionLine: Record "Prod. Order Line";
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReplacementVariant: Record "Item Variant";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] Matching production A and purchase A retain native FULL original twelve coverage without another order.
        Initialize();

        // [GIVEN] The same genuine native original A12 has neither shipped nor produced any finished output.
        PrepareNativeVariantFullOriginal(ProductionLine, Purchase, PurchaseLine, ReplacementVariant);
        Assert.AreEqual(PurchaseLine."Variant Code", ProductionLine."Variant Code", 'The control must keep a matching nonblank native variant.');
        Commit();
        VerifyNativeVariantSelection(ProductionLine, PurchaseLine);
        BeforeState := NativeVariantArtifactState(ProductionLine);

        // [WHEN] The matching purchase requests the same native forward transfer again.
        asserterror InvokeNativeVariantForward(Purchase);

        // [THEN] Native coverage, not an identity mismatch, refuses duplication and preserves the complete original orders.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('covered');
        VerifyNativeVariantSelection(ProductionLine, PurchaseLine);
        VerifyNativeVariantFullCoverage(PurchaseLine, ReplacementVariant.Code);
        Assert.AreEqual(BeforeState, NativeVariantArtifactState(ProductionLine), 'Matching FULL original coverage must create no duplicates or rewrite headers, components or originals.');
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    local procedure PrepareNativeVariantFullOriginal(var ProductionLine: Record "Prod. Order Line"; var Purchase: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var ReplacementVariant: Record "Item Variant")
    var
        OriginalVariant: Record "Item Variant";
    begin
        CreateVendorRoutingFixture(0, 12);
        ProductionLine.Get(VROrder.Status, VROrder."No.", VendorRoutingProductionLineNo(VRRouting[1]));
        LibraryInventory.CreateItemVariant(OriginalVariant, VRItem."No.");
        LibraryInventory.CreateItemVariant(ReplacementVariant, VRItem."No.");
        Assert.AreNotEqual(OriginalVariant.Code, ReplacementVariant.Code, 'The two library-created variants must distinguish stale coverage.');
        ProductionLine.Validate("Variant Code", OriginalVariant.Code);
        ProductionLine.Modify(true);
        CreateNativeScopedPurchase(ProductionLine, VRRouting[1], Purchase, PurchaseLine);
        Assert.AreEqual(OriginalVariant.Code, PurchaseLine."Variant Code", 'Native routing purchase creation must retain production variant A.');
        EnsureVendorRoutingRoute(VRMain.Code, Purchase."Subc. Location Code");
        InvokeNativeVariantForward(Purchase);
        ProductionLine.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", ProductionLine."Line No.");
        VerifyNativeVariantSelection(ProductionLine, PurchaseLine);
        VerifyNativeVariantFullCoverage(PurchaseLine, ReplacementVariant.Code);
    end;

    local procedure InvokeNativeVariantForward(Purchase: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        VRDisplayedPurchase := Purchase."No.";
        VRDisplayedReturn := false;
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(Purchase);
        PurchaseOrder.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure VerifyNativeVariantSelection(ExpectedProductionLine: Record "Prod. Order Line"; ExpectedPurchaseLine: Record "Purchase Line")
    var
        ProductionLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
        Routing: Record "Prod. Order Routing Line";
    begin
        ProductionLine.Get(ExpectedProductionLine.Status, ExpectedProductionLine."Prod. Order No.", ExpectedProductionLine."Line No.");
        ProductionLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)", "Put-away Qty. (Base)");
        Assert.AreEqual(ExpectedProductionLine.SystemRowVersion, ProductionLine.SystemRowVersion, 'Selection must not revert or write the persisted production edit.');
        Assert.AreEqual(ExpectedProductionLine."Item No.", ProductionLine."Item No.", 'Production item must remain unchanged.');
        Assert.AreEqual(ExpectedProductionLine."Variant Code", ProductionLine."Variant Code", 'Persisted production variant must survive refusal.');
        Assert.AreEqual(0, ProductionLine."Finished Quantity", 'Native variant editing must remain legal without finished output.');
        Assert.AreEqual(0, ProductionLine."Reserved Quantity", 'Component transfer reservations must not become production output reservations.');
        Assert.AreEqual(0, ProductionLine."Reserved Qty. (Base)", 'Production output must have no reserved base quantity.');
        Assert.AreEqual(0, ProductionLine."Put-away Qty. (Base)", 'The fixture must have no production output warehouse activity.');
        Assert.IsFalse(VRMain."Require Receive" or VRMain."Require Shipment" or VRMain."Require Pick" or VRMain."Require Put-away" or VRMain."Bin Mandatory", 'The library fixture must remain a simple nonwarehouse production location.');
        Assert.AreEqual(12, ProductionLine."Quantity (Base)", 'Native variant editing must retain the complete twelve-base demand.');
        Assert.AreEqual(ExpectedProductionLine."Routing No.", ProductionLine."Routing No.", 'Production routing must remain unchanged.');
        Assert.AreEqual(ExpectedProductionLine."Routing Reference No.", ProductionLine."Routing Reference No.", 'Production routing reference must remain unchanged.');
        PurchaseLine.Get(ExpectedPurchaseLine."Document Type", ExpectedPurchaseLine."Document No.", ExpectedPurchaseLine."Line No.");
        Assert.AreEqual(ExpectedPurchaseLine.SystemRowVersion, PurchaseLine.SystemRowVersion, 'Selection and native variant editing must not rewrite the purchase association.');
        Assert.AreEqual(ExpectedPurchaseLine."No.", PurchaseLine."No.", 'The existing purchase item must remain unchanged.');
        Assert.AreEqual(ExpectedPurchaseLine."Variant Code", PurchaseLine."Variant Code", 'The existing purchase must stay on variant A.');
        Assert.AreEqual(12, PurchaseLine.Quantity, 'The existing purchase must retain its full service demand.');
        Assert.AreEqual(ProductionLine."Prod. Order No.", PurchaseLine."Prod. Order No.", 'Purchase production order must remain unchanged.');
        Assert.AreEqual(ProductionLine."Line No.", PurchaseLine."Prod. Order Line No.", 'Purchase must retain the same production line.');
        Assert.AreEqual(ProductionLine."Routing No.", PurchaseLine."Routing No.", 'Purchase and production must retain the same routing.');
        Assert.AreEqual(ProductionLine."Routing Reference No.", PurchaseLine."Routing Reference No.", 'Purchase and production must retain the same routing reference.');
        Routing.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", PurchaseLine."Routing Reference No.", PurchaseLine."Routing No.", PurchaseLine."Operation No.");
        Assert.AreEqual(VRRouting[1].SystemRowVersion, Routing.SystemRowVersion, 'Neither variant editing nor refusal may rewrite the operation.');
        Assert.AreEqual(VRRouting[1]."Operation No.", Routing."Operation No.", 'The original operation must remain unchanged.');
    end;

    local procedure VerifyNativeVariantFullCoverage(PurchaseLine: Record "Purchase Line"; ReplacementVariant: Code[10])
    var
        Original: Record "Transfer Line";
        WIP: Record "Subcontractor WIP Ledger Entry";
    begin
        Assert.IsTrue(PurchaseLine."Variant Code" <> '', 'Variant A must be a genuine nonblank native variant.');
        VerifyNativeForwardUOM(PurchaseLine, '', VRMain.Code, VRItem."Base Unit of Measure", 12, 12, 12);
        FilterVendorRoutingOverlapTuple(Original, PurchaseLine, '', VRMain.Code);
        Original.FindFirst();
        Assert.AreEqual(0, Original."Quantity Shipped", 'FULL original A12 must be unshipped, not reduced coverage.');
        Assert.AreEqual(0, Original."Quantity Received", 'No receipt may provide destination coverage in this fixture.');
        Original.SetRange("Variant Code", ReplacementVariant);
        Assert.RecordIsEmpty(Original);
        WIP.SetRange("Prod. Order Status", VROrder.Status);
        WIP.SetRange("Prod. Order No.", PurchaseLine."Prod. Order No.");
        WIP.SetRange("Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        WIP.SetRange("Routing No.", PurchaseLine."Routing No.");
        WIP.SetRange("Routing Reference No.", PurchaseLine."Routing Reference No.");
        WIP.SetRange("Operation No.", PurchaseLine."Operation No.");
        WIP.SetRange("Item No.", PurchaseLine."No.");
        WIP.SetRange("Variant Code", PurchaseLine."Variant Code");
        Assert.RecordIsEmpty(WIP);
        WIP.CalcSums("Quantity (Base)");
        Assert.AreEqual(0, WIP."Quantity (Base)", 'Unshipped original A12 must have zero posted destination A coverage.');
        WIP.SetRange("Variant Code", ReplacementVariant);
        Assert.RecordIsEmpty(WIP);
    end;

    local procedure NativeVariantArtifactState(ProductionLine: Record "Prod. Order Line"): Text
    var
        Header: Record "Transfer Header";
        Line: Record "Transfer Line";
        Component: Record "Prod. Order Component";
        Shipment: Record "Transfer Shipment Line";
        Receipt: Record "Transfer Receipt Line";
        DirectLine: Record "Direct Trans. Line";
        WIP: Record "Subcontractor WIP Ledger Entry";
        ItemEntry: Record "Item Ledger Entry";
        Result: Text;
    begin
        Result := StrSubstNo('|H%1|L%2|C%3|S%4|R%5|D%6|W%7|I%8', Header.Count(), Line.Count(), Component.Count(), Shipment.Count(), Receipt.Count(), DirectLine.Count(), WIP.Count(), ItemEntry.Count());
        Line.SetRange("Subc. Prod. Order No.", ProductionLine."Prod. Order No.");
        Line.SetRange("Subc. Prod. Order Line No.", ProductionLine."Line No.");
        if Line.FindSet() then
            repeat
                Header.Get(Line."Document No.");
                Result += '|' + Format(Header.RecordId) + '|' + Format(Header.SystemRowVersion) +
                    '|' + Format(Line.RecordId) + '|' + Format(Line.SystemRowVersion) +
                    '|' + Line."Item No." + '|' + Line."Variant Code" + '|' + Line."Unit of Measure Code" +
                    '|' + Format(Line.Quantity) + '|' + Format(Line."Quantity Shipped") + '|' + Format(Line."Quantity Received");
            until Line.Next() = 0;
        exit(Result + VendorRoutingPurchaseState() + VendorRoutingRowVersions());
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingCardHandler')]
    procedure WorksheetVendorYesKeepsProductionLocation()
    var
        Factbox: TestPage "Subc. Routing Info Factbox";
        Topology: Integer;
        BeforeSiblingVendors: Text;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Yes changes only the selected operation, preserving production location, costs and scheduling.
        for Topology := 0 to 1 do begin
            // [GIVEN] A calculated twelve-unit suggestion and independently captured production, components and masters.
            CreateVendorRoutingFixture(Topology, 12);
            BeforeSiblingVendors := VendorRoutingSiblingVendors();
            // [WHEN] The actual worksheet vendor control is replaced and the exact operation question is accepted.
            ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
            Assert.AreEqual(BeforeSiblingVendors, VendorRoutingSiblingVendors(), 'Yes must preserve the public effective vendor of every full-key nonselected operation.');
            // [THEN] A fresh public reader, factbox and vendor card identify the replacement, without other business writes.
            VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
            VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
            Factbox.OpenView();
            Factbox.GoToRecord(VRRouting[1]);
            LibraryVariableStorage.Enqueue(VRVendor[2]."No.");
            Factbox.ShowSubcontractor.DrillDown();
            Factbox.Close();
            VerifyVendorRoutingUnchanged();
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure WorksheetVendorNoKeepsChosenVendor()
    var
        RowVersion: BigInteger;
        BeforeSiblingVendors: Text;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] No preserves both the chosen worksheet vendor and the untouched routing row.
        // [GIVEN] A real production-linked suggestion, with MAIN different from the new vendor's ordinary EAST.
        CreateVendorRoutingFixture(0, 12);
        RowVersion := VRRouting[1].SystemRowVersion;
        BeforeSiblingVendors := VendorRoutingSiblingVendors();
        // [WHEN] The user declines the routing update on page 20504.
        ChangeWorksheetVendor(VRVendor[2]."No.", false, true);
        Assert.AreEqual(BeforeSiblingVendors, VendorRoutingSiblingVendors(), 'No must preserve the public effective vendor of every full-key nonselected operation.');
        // [THEN] Missing confirmation or EAST is a failure even though the old routing vendor itself is unchanged.
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
        Assert.AreEqual(RowVersion, VRRouting[1].SystemRowVersion, 'No must not write the routing row.');
        VerifyVendorRoutingUnchanged();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure ConsecutiveNoUsesEffectiveRoutingVendor()
    var
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
        Reopen: Boolean;
        Variant: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Saved and kept-open second declines name the routing vendor, not the last worksheet vendor.
        for Variant := 1 to 3 do begin
            // [GIVEN] An explicitly declined first replacement; the persisted routing still belongs to the old vendor.
            CreateVendorRoutingFixture(0, 12);
            Reopen := Variant <> 2;
            OpenVendorRoutingWorksheet(Worksheet);
            QueueVendorRoutingChoice(VRVendor[2]."No.", false);
            Worksheet."Vendor No.".SetValue(VRVendor[2]."No.");
            Assert.AreEqual(1, VRVendorQuestionCount, 'The first decline must have asked exactly once.');
            LibraryVariableStorage.AssertEmpty();
            if Reopen then begin
                Worksheet.Close();
                ReloadVendorRoutingSuggestion();
                OpenVendorRoutingWorksheet(Worksheet);
            end;
            // [WHEN] The next selection is a third vendor, or is already the actual effective routing vendor.
            if Variant = 3 then
                Worksheet."Vendor No.".SetValue(VRVendor[1]."No.")
            else begin
                QueueVendorRoutingChoice(VRVendor[3]."No.", false);
                Worksheet."Vendor No.".SetValue(VRVendor[3]."No.");
            end;
            Worksheet.Close();
            // [THEN] The full second question says old-to-third; choosing old suppresses the question altogether.
            if Variant = 3 then begin
                Assert.AreEqual(1, VRVendorQuestionCount, 'Matching the effective vendor must not ask.');
                VerifyWorksheetVendor(VRVendor[1]."No.", VRMain.Code);
            end else begin
                Assert.AreEqual(2, VRVendorQuestionCount, 'Both real replacements must ask exactly once.');
                VerifyWorksheetVendor(VRVendor[3]."No.", VRMain.Code);
            end;
            VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
            VerifyVendorRoutingUnchanged();
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure WorksheetVendorLocationBoundaries()
    var
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
        Variant: Integer;
        ExpectedLocation: Code[10];
        ExpectedVendor: Code[20];
        ExpectedWorkCenter: Integer;
        ExpectedQuestions: Integer;
        RowVersion: BigInteger;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Location ordering and incomplete routing links never default EAST or update a different row.
        for Variant := 1 to 8 do begin
            // [GIVEN] Fresh blank, unchanged, stale-key, mismatched-work-center and backend boundary variants.
            CreateVendorRoutingFixture(0, 12);
            RowVersion := VRRouting[1].SystemRowVersion;
            ExpectedLocation := VRMain.Code;
            ExpectedVendor := VRVendor[2]."No.";
            ExpectedWorkCenter := 1;
            ExpectedQuestions := 0;
            case Variant of
                1:
                    begin
                        ChangeWorksheetVendor(VRVendor[2]."No.", false, true);
                        OpenVendorRoutingWorksheet(Worksheet);
                        Worksheet."Location Code".SetValue(VRWest.Code);
                        Worksheet."Vendor No.".AssertEquals('');
                        Worksheet.Close();
                        ExpectedLocation := VRWest.Code;
                        ExpectedQuestions := 1;
                    end;
                3:
                    ExpectedVendor := VRVendor[1]."No.";
                4:
                    begin
                        VRReq."Operation No." := 'MISSING';
                        VRReq.Modify(true);
                    end;
                5:
                    begin
                        VRReq."Work Center No." := VRWorkCenter[2]."No.";
                        VRReq.Modify(true);
                        ExpectedWorkCenter := 2;
                    end;
                6:
                    begin
                        VRReq."Routing Reference No." += 1;
                        VRReq.Modify(true);
                    end;
                7:
                    begin
                        VRReq."Prod. Order Line No." += 1;
                        VRReq.Modify(true);
                    end;
            end;
            // [WHEN] Vendor validation is invoked in its actual interactive or headless context.
            if Variant = 8 then begin
                VRReq.Validate("Vendor No.", ExpectedVendor);
                VRReq.Modify(true);
            end else begin
                OpenVendorRoutingWorksheet(Worksheet);
                if Variant = 2 then begin
                    ExpectedVendor := '';
                    Worksheet."Vendor No.".SetValue('');
                end else
                    Worksheet."Vendor No.".SetValue(ExpectedVendor);
                Worksheet.Close();
            end;
            // [THEN] Only the real replacement in variant 1 asked; every boundary retains its ordinary location.
            VerifyWorksheetVendor(ExpectedVendor, ExpectedLocation);
            Assert.AreEqual(ExpectedQuestions, VRVendorQuestionCount, 'Only the initial replacement may ask, exactly once.');
            if Variant in [4, 5, 6, 7] then begin
                Assert.AreEqual(VRWorkCenter[ExpectedWorkCenter].Name, VRReq.Description, 'An unusable link uses the selected worksheet work center.');
                Assert.AreEqual(VRWorkCenter[ExpectedWorkCenter]."Name 2", VRReq."Description 2", 'Both fallback descriptions must identify the selected work center.');
            end;
            VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
            Assert.AreEqual(RowVersion, VRRouting[1].SystemRowVersion, 'Boundary validations must not write any routing row.');
            VerifyVendorRoutingUnchanged();
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    procedure OrdinaryReqVendorStillDefaultsLocation()
    var
        Template: Record "Req. Wksh. Template";
        Batch: Record "Requisition Wksh. Name";
        ReqLine: Record "Requisition Line";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryUtility: Codeunit "Library - Utility";
        Worksheet: TestPage "Req. Worksheet";
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Ordinary page 291 keeps native EAST defaulting; untouched subcontract calculation keeps MAIN.
        // [GIVEN] A genuine ordinary requisition template, not LibraryPlanning's Planning-type template.
        CreateVendorRoutingFixture(0, 12);
        Template.Init();
        Template.Name := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Template.Name));
        Template.Insert(true);
        Template.Validate(Type, Template.Type::"Req.");
        Template.Validate("Page ID", Page::"Req. Worksheet");
        Template.Modify(true);
        LibraryPlanning.CreateRequisitionWkshName(Batch, Template.Name);
        LibraryPlanning.CreateRequisitionLine(ReqLine, Template.Name, Batch.Name);
        ReqLine.Validate(Type, ReqLine.Type::Item);
        ReqLine.Validate("No.", VRItem."No.");
        ReqLine.Validate("Vendor No.", VRVendor[1]."No.");
        ReqLine.Validate("Location Code", VRMain.Code);
        ReqLine.Modify(true);
        VRVendor[1].Validate("Location Code", VRWest.Code);
        VRVendor[1].Modify(true);
        // [WHEN] An ordinary interactive vendor replacement and an untouched subcontract calculation use native entrypoints.
        Worksheet.OpenEdit();
        Worksheet.CurrentJnlBatchName.SetValue(Batch.Name);
        Worksheet.GoToRecord(ReqLine);
        Worksheet."Vendor No.".SetValue(VRVendor[2]."No.");
        Worksheet.Close();
        CalculateVendorRoutingSuggestions('');
        // [THEN] Ordinary requisition defaults EAST, while programmatic subcontract defaults old/MAIN without a question.
        ReqLine.Get(ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", ReqLine."Line No.");
        Assert.AreEqual(VREast.Code, ReqLine."Location Code", 'Ordinary vendor defaulting must remain native.');
        Assert.AreEqual(VRVendor[2]."No.", ReqLine."Vendor No.", 'Ordinary requisition must retain its chosen vendor.');
        VerifyWorksheetVendor(VRVendor[1]."No.", VRMain.Code);
        Assert.AreEqual(0, VRVendorQuestionCount, 'No interactive subcontract replacement occurred.');
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure AcceptedVendorUsedByCalculationAndDirectFlow()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OtherRouting: Record "Prod. Order Routing Line";
        Variant: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Accepted operation identity drives calculation filters and the real direct-order action.
        for Variant := 1 to 2 do begin
            // [GIVEN] The user accepted the replacement, without changing a shared work center.
            CreateVendorRoutingFixture(0, 12);
            ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
            // [WHEN] Calculate is filtered by the effective vendor, or the exact routing row creates a purchase order.
            if Variant = 1 then begin
                CalculateVendorRoutingSuggestions(VRVendor[1]."No.");
                Assert.RecordIsEmpty(VRReq);
                CalculateVendorRoutingSuggestions(VRVendor[2]."No.");
                FindVendorRoutingSuggestion();
                VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
            end else begin
                CreateVendorRoutingPurchase(VRRouting[1], PurchaseHeader, PurchaseLine);
                VerifyVendorRoutingPurchase(PurchaseHeader, PurchaseLine, VRRouting[1], VRVendor[2]);
                FindVendorRoutingOperation(VROtherOrder, VRRouting[1]."Operation No.", OtherRouting);
                CreateVendorRoutingPurchase(OtherRouting, PurchaseHeader, PurchaseLine);
                Assert.AreEqual(VRVendor[1]."No.", PurchaseHeader."Buy-from Vendor No.", 'Another order retains the master vendor.');
            end;
            // [THEN] Recalculation and direct purchasing retain the override and all untouched production/master state.
            VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
            VerifyVendorRoutingUnchanged();
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure AcceptedVendorDrivesStandardTaskPrice()
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] A later task validation uses effective-vendor price 22 rather than master-vendor price 11.
        // [GIVEN] Accepted replacement and a baseline-public blank explicit pricing vendor.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        VRRouting[1].Validate("Vendor No. Subc. Price", '');
        VRRouting[1].Modify(true);
        // [WHEN] The native Standard Task field is validated.
        VRRouting[1].Validate("Standard Task Code", VRTask.Code);
        VRRouting[1].Modify(true);
        // [THEN] Pricing changes only when requested, uses 22, and leaves effective identity on the accepted vendor.
        Assert.AreEqual(22, VRRouting[1]."Direct Unit Cost", 'Effective subcontractor must supply fallback task price.');
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure ExplicitPricingVendorStillWins()
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Explicit pricing vendor 33 wins over the accepted vendor's fallback price 22.
        // [GIVEN] An accepted routing vendor and the existing public pricing-vendor field set to a third vendor.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        VRRouting[1].Validate("Vendor No. Subc. Price", VRVendor[3]."No.");
        VRRouting[1].Modify(true);
        // [WHEN] Native task validation requests a price lookup.
        VRRouting[1].Validate("Standard Task Code", VRTask.Code);
        VRRouting[1].Modify(true);
        // [THEN] Price is 33, but subcontractor identity is still the accepted vendor, not the pricing vendor.
        Assert.AreEqual(33, VRRouting[1]."Direct Unit Cost", 'Explicit pricing vendor must retain precedence.');
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure AcceptedVendorComponentBoundaries()
    var
        Component: Record "Prod. Order Component";
        BeforeComponent: Record "Prod. Order Component";
        OtherComponent: Record "Prod. Order Component";
        BeforeOtherComponents: array[2] of Record "Prod. Order Component";
        OtherRouting: Record "Prod. Order Routing Line";
        ExpectedSupply: Enum "Component Supply Method";
        RoutingRowVersion: BigInteger;
        ComponentIndex: Integer;
        Variant: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Supported supply and subsequent link validations resolve the accepted vendor without moving transfer components.
        for Variant := 1 to 5 do begin
            // [GIVEN] Accepted vendor, two genuine Pick+Manual components and their original business state.
            CreateVendorRoutingFixture(0, 12);
            ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
            ReloadVendorRoutingOperation(VRRouting[1]);
            RoutingRowVersion := VRRouting[1].SystemRowVersion;
            Assert.AreNotEqual(VRVendor[1]."Subc. Location Code", VRVendor[2]."Subc. Location Code", 'Old and accepted subcontractor locations must discriminate the consumers.');
            FindVendorRoutingOperation(VROtherOrder, '10', OtherRouting);
            OtherComponent.SetRange(Status, VROtherOrder.Status);
            OtherComponent.SetRange("Prod. Order No.", VROtherOrder."No.");
            OtherComponent.SetRange("Prod. Order Line No.", VendorRoutingProductionLineNo(OtherRouting));
            Assert.AreEqual(ArrayLen(BeforeOtherComponents), OtherComponent.Count(), 'The independent order must have both native components.');
            OtherComponent.FindSet();
            ComponentIndex := 0;
            repeat
                ComponentIndex += 1;
                BeforeOtherComponents[ComponentIndex] := OtherComponent;
            until OtherComponent.Next() = 0;
            case Variant of
                1, 4:
                    ExpectedSupply := ExpectedSupply::"Consignment at Vendor";
                2, 5:
                    ExpectedSupply := ExpectedSupply::"Vendor-Supplied";
                3:
                    ExpectedSupply := ExpectedSupply::"Transfer to Vendor";
            end;
            FilterVendorRoutingComponents(Component);
            Component.FindSet();
            repeat
                if Variant >= 3 then begin
                    // Clear while still Transfer-to-Vendor, then configure non-transfer supply with no link.
                    // This keeps native MAIN/original/bin semantics and cannot pre-resolve the vendor through the supply updater.
                    Component.Validate("Routing Link Code", '');
                    Component.Modify(true);
                    Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
                    if Variant >= 4 then begin
                        Component.Validate("Component Supply Method", ExpectedSupply);
                        Component.Modify(true);
                        Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
                        Assert.AreEqual(VRMain.Code, Component."Location Code", 'Unlinked non-transfer supply must still be at the real production location.');
                        Assert.AreEqual('', Component."Subc. Original Location Code", 'Setup must not manufacture a saved original location.');
                    end;
                end;
                BeforeComponent := Component;
                // [WHEN] A supported supply-method or subsequent routing-link validation runs.
                case Variant of
                    1, 2:
                        Component.Validate("Component Supply Method", ExpectedSupply);
                    3, 4, 5:
                        Component.Validate("Routing Link Code", VRLink.Code);
                end;
                Component.Modify(true);
                Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
                // [THEN] Consignment/vendor supply use S-new; Transfer-to-Vendor remains at MAIN with original/bin/flushing intact.
                Assert.AreEqual(ExpectedSupply, Component."Component Supply Method", 'The selected supply boundary must persist.');
                Assert.AreEqual(VRLink.Code, Component."Routing Link Code", 'The native component must be linked to the accepted operation.');
                if Variant = 3 then begin
                    Assert.AreEqual(BeforeComponent."Location Code", Component."Location Code", 'Transfer supply must not move.');
                    Assert.AreEqual(BeforeComponent."Subc. Original Location Code", Component."Subc. Original Location Code", 'Original location must not change.');
                end else begin
                    Assert.AreEqual(VRVendor[2]."Subc. Location Code", Component."Location Code", 'Component consumer must use effective subcontractor.');
                    Assert.AreEqual(VRMain.Code, Component."Subc. Original Location Code", 'The native original location must be preserved.');
                end;
                Assert.AreEqual(BeforeComponent."Bin Code", Component."Bin Code", 'Vendor-only routing changes must not rewrite bins.');
                Assert.AreEqual(BeforeComponent."Subc. Orig. Bin Code", Component."Subc. Orig. Bin Code", 'Original bin must be retained.');
                Assert.AreEqual(BeforeComponent."Flushing Method", Component."Flushing Method", 'Pick+Manual must be retained.');
                Assert.AreEqual(BeforeComponent."Quantity per", Component."Quantity per", 'Supply and link validation must not change BOM demand.');
                Assert.AreEqual(BeforeComponent."Expected Qty. (Base)", Component."Expected Qty. (Base)", 'Both native component base quantities must be retained.');
            until Component.Next() = 0;
            for ComponentIndex := 1 to ArrayLen(BeforeOtherComponents) do begin
                OtherComponent.Get(
                    BeforeOtherComponents[ComponentIndex].Status, BeforeOtherComponents[ComponentIndex]."Prod. Order No.",
                    BeforeOtherComponents[ComponentIndex]."Prod. Order Line No.", BeforeOtherComponents[ComponentIndex]."Line No.");
                Assert.AreEqual(BeforeOtherComponents[ComponentIndex].SystemRowVersion, OtherComponent.SystemRowVersion, 'The independent order component must not be written.');
            end;
            VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
            VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
            Assert.AreEqual(RoutingRowVersion, VRRouting[1].SystemRowVersion, 'Component validation must not write the accepted routing operation.');
            VerifyVendorRoutingMasters();
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingUpdateMessageHandler')]
    procedure RoutingIdentityValidationBoundaries()
    var
        Variant: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Same Type invalidates identity, intact same No retains it, and real work-center replacement uses third-vendor defaults.
        for Variant := 1 to 4 do begin
            // [GIVEN] An accepted operation with no document/stock commitments.
            CreateVendorRoutingFixture(0, 12);
            ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
            // [WHEN] Native Type or No validation establishes the requested identity boundary.
            case Variant of
                1:
                    VRRouting[1].Validate(Type, VRRouting[1].Type);
                2:
                    VRRouting[1].Validate("No.", VRRouting[1]."No.");
                3:
                    begin
                        LibraryVariableStorage.Enqueue(StrSubstNo(
                            'If you change the Work Center, you will also change the default location for components with Routing Link Code=%1.\Do you want to continue anyway?', VRLink.Code));
                        LibraryVariableStorage.Enqueue(true);
                        VRRouting[1].Validate("No.", VRWorkCenter[2]."No.");
                    end;
                4:
                    VRRouting[1].Validate(Type, VRRouting[1].Type::"Machine Center");
            end;
            VRRouting[1].Modify(true);
            // [THEN] Persisted public identity follows native clearing/replacement, not the stale accepted vendor.
            case Variant of
                1, 4:
                    begin
                        Assert.AreEqual('', VRRouting[1]."No.", 'Type validation clears the native identity even for the same enum.');
                        Assert.AreEqual('', VRRouting[1]."Work Center No.", 'Type validation clears the work center.');
                        VerifyEffectiveVendor(VRRouting[1], '');
                    end;
                2:
                    VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
                3:
                    begin
                        VerifyEffectiveVendor(VRRouting[1], VRVendor[3]."No.");
                        Assert.AreEqual(33, VRRouting[1]."Direct Unit Cost", 'Replacement work center must price from its own vendor.');
                    end;
            end;
            VerifyVendorRoutingMasters();
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure AcceptedVendorStatusCopyReopenFlow()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FinishedOrder: Record "Production Order";
        ReopenedOrder: Record "Production Order";
        Routing: Record "Prod. Order Routing Line";
        StatusManagement: Codeunit "Prod. Order Status Management";
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Dependent flow: real purchase output, finish, then one-time reopen retain the operation vendor.
        // [GIVEN] An accepted operation and native purchase receipt/output; no manufactured output or status rows.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        CreateVendorRoutingPurchase(VRRouting[1], PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        // [WHEN] Native finish and reopen copy the resulting routing identities in a single dependent lifecycle.
        LibraryVariableStorage.Enqueue(StrSubstNo(
            '%1 %2 has not been finished:\\  * Some consumption is still missing.\\ Do you still want to finish the order?', VROrder.TableCaption(), VROrder."No."));
        LibraryVariableStorage.Enqueue(true);
        StatusManagement.ChangeProdOrderStatus(VROrder, FinishedOrder, FinishedOrder.Status::Finished, WorkDate(), false);
        LibraryVariableStorage.AssertEmpty();
        FindVendorRoutingOperation(FinishedOrder, '10', Routing);
        VerifyEffectiveVendor(Routing, VRVendor[2]."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo('Do you want to reopen the production order %1 ?', FinishedOrder."No."));
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(StrSubstNo(
            'The production order is reopened and moved to the %1 Production Order with status Released.\\Do you want to open the production order?', FinishedOrder."No."));
        LibraryVariableStorage.Enqueue(false);
        StatusManagement.ReopenFinishedProdOrder(FinishedOrder);
        // [THEN] Returned Released keys retain the vendor, output and untouched other order/master identity.
        ReopenedOrder.Get(ReopenedOrder.Status::Released, FinishedOrder."No.");
        FindVendorRoutingOperation(ReopenedOrder, '10', Routing);
        VerifyEffectiveVendor(Routing, VRVendor[2]."No.");
        Assert.IsTrue(ReopenedOrder.Reopened, 'The native one-time reopen must have happened.');
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure RoutingRebuildRestoresMasterVendor()
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Deliberate native routing reconstruction starts again from master defaults.
        // [GIVEN] Accepted override without stock, purchases or transfers.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        // [WHEN] Native Refresh recalculates routing from the master, rather than recalculating worksheet suggestions.
        LibraryManufacturing.RefreshProdOrder(VROrder, false, false, true, false, false);
        // [THEN] The rebuilt operation belongs to the old master vendor; masters/other order remain unchanged.
        FindVendorRoutingOperation(VROrder, '10', VRRouting[1]);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure AcceptedVendorGuardsRollBack()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        BeforeState: Text;
        Variant: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Open, posted, orphan and transit commitments reject Yes atomically but permit No.
        for Variant := 1 to 4 do begin
            // [GIVEN] Native documents establish each guard after a separate calculated suggestion has been saved.
            CreateVendorRoutingFixture(0, 12);
            CreateVendorRoutingPurchase(VRRouting[1], PurchaseHeader, PurchaseLine);
            CreateVendorRoutingForward(PurchaseHeader);
            FindVendorRoutingTransfer(PurchaseHeader, VRMain.Code, false, TransferHeader);
            case Variant of
                2, 3:
                    LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
                4:
                    LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
            end;
            if Variant = 3 then
                MoveVendorRoutingLocation(1, VRVendor[3]."Subc. Location Code");
            BeforeState := VendorRoutingBusinessState() + VendorRoutingArtifactState();
            QueueVendorRoutingChoice(VRVendor[2]."No.", true);
            // [WHEN] The actual worksheet replacement is accepted despite the native commitment.
            asserterror SetVendorRoutingWorksheetControl(VRVendor[2]."No.");
            // [THEN] It is a contextual business guard, not a fixture/handler error, and all persisted state rolled back.
            Assert.ExpectedError(VROrder."No.");
            Assert.ExpectedErrorCode('Dialog');
            Assert.AreEqual(1, VRVendorQuestionCount, 'The accepted question must be the action that reached the guard.');
            VerifyWorksheetVendor(VRVendor[1]."No.", VRMain.Code);
            VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
            Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingArtifactState(), 'A rejected edit must be atomic.');
            ChangeWorksheetVendor(VRVendor[2]."No.", false, true);
            VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
            VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingCalculateHandler,VendorRoutingCarryOutHandler,VendorRoutingTransferHandler')]
    procedure WorksheetVendorPurchaseReceiptReturnFlow()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
        Variant: Integer;
        ExpectedRoutingVendor: Code[20];
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Dependent Yes/No flow: selected purchase, outbound twelve, receipt eight and native component-four/WIP-twelve return.
        for Variant := 1 to 2 do begin
            // [GIVEN] Two linked Pick+Manual components, base UOM one and a twelve-unit production demand.
            CreateVendorRoutingFixture(0, 12);
            OpenVendorRoutingWorksheet(Worksheet);
            // [WHEN] Round 1 uses the actual page report callbacks, replacement and carry-out of that edited line.
            Worksheet."Calculate Subcontracts".Invoke();
            Worksheet.Close();
            FindVendorRoutingSuggestion();
            ChangeWorksheetVendor(VRVendor[2]."No.", Variant = 1, true);
            OpenVendorRoutingWorksheet(Worksheet);
            Worksheet.CarryOutActionMessage.Invoke();
            Worksheet.Close();
            FindVendorRoutingPurchase(VRRouting[1], PurchaseHeader, PurchaseLine);
            VerifyVendorRoutingPurchase(PurchaseHeader, PurchaseLine, VRRouting[1], VRVendor[2]);
            CreateVendorRoutingForward(PurchaseHeader);
            FindVendorRoutingTransfer(PurchaseHeader, VRMain.Code, false, TransferHeader);
            VerifyVendorRoutingTransferContents(TransferHeader, 12, 12);
            LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
            VerifyVendorRoutingPostedTransfer(TransferHeader, VRMain.Code, VRVendor[2]."Subc. Location Code", 12, 12);
            // [WHEN] Round 2 receives eight service units and creates/posts the resulting native return.
            PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
            PurchaseLine.Validate("Qty. to Receive", 8);
            PurchaseLine.Modify(true);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
            PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
            Assert.AreEqual(8, PurchaseLine."Quantity Received", 'Receive-only must post eight service units.');
            Assert.AreEqual(4, PurchaseLine."Qty. to Receive", 'Four service units remain.');
            CreateVendorRoutingReturn(PurchaseHeader);
            FindVendorRoutingTransfer(PurchaseHeader, VRVendor[2]."Subc. Location Code", true, ReturnHeader);
            VerifyVendorRoutingTransferContents(ReturnHeader, 4, 12);
            LibraryWarehouse.PostTransferOrder(ReturnHeader, true, true);
            // [THEN] Accumulated posted documents, item ledger and native WIP agree, while routing follows the explicit choice.
            VerifyVendorRoutingPostedTransfer(ReturnHeader, VRVendor[2]."Subc. Location Code", VRMain.Code, 4, 12);
            VerifyVendorRoutingComponentNet(VRMain.Code, -8);
            VerifyVendorRoutingComponentNet(VRVendor[2]."Subc. Location Code", 8);
            VerifyVendorRoutingWIP(VRRouting[1], VRVendor[2]."Subc. Location Code", false, 0);
            ExpectedRoutingVendor := VRVendor[1]."No.";
            if Variant = 1 then
                ExpectedRoutingVendor := VRVendor[2]."No.";
            VerifyEffectiveVendor(VRRouting[1], ExpectedRoutingVendor);
            Assert.AreEqual(1, VRCalculateCallbackCount, 'The actual Calculate request page must be handled once.');
            Assert.AreEqual(1, VRCarryOutCallbackCount, 'The actual Carry Out request page must be handled once.');
            VerifyVendorRoutingMasters();
            FinishVendorRoutingFixture();
        end;
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure PhysicalPredecessorSourceBoundariesFlow()
    var
        Variant: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [WIP]
        // [SCENARIO 654802] Dependent native posting flows distinguish physical stock, planned fallback, exhaustion and missing-debit evidence.
        // [GIVEN] Fresh serial predecessor/successor fixtures; no ledger or posted-document rows are fabricated.
        // [WHEN] Actual posting, lawful vendor-location changes and the successor purchase action discover sources.
        for Variant := 1 to 8 do
            RunVendorRoutingPhysicalBoundary(Variant);
        // [THEN] Each flow checks its exact source/previous-operation/quantity or contextual evidence error and zero artifacts.
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure WIPNativeCoverageBoundaryFlow()
    var
        Variant: Integer;
        Moved: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [WIP]
        // [SCENARIO 654802] Dependent coverage rounds retain native destination-net plus full-original-quantity policy.
        // [GIVEN] Native precursor 24 and successor demand 12, with baseline-compatible and moved physical sources.
        // [WHEN] Originals are open, in transit, received, partially received or returned before another actual report request.
        for Moved := 0 to 1 do
            for Variant := 1 to 6 do
                RunVendorRoutingCoverageBoundary(Variant, Moved = 1);
        // [THEN] K/R is 4/8, 16/0, 12/0 or 0/12 as appropriate, never a lifetime or outstanding-only substitute.
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure PhysicalSplitAndParallelBoundaries()
    var
        Variant: Integer;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [WIP]
        // [SCENARIO 654802] Split and expanded parallel discovery preserve exact tuple identity and reject ambiguous allocations before any artifacts.
        // [GIVEN] Native split receipts and genuine subcontracting Work Centers at all true-WIP parallel predecessors.
        // [WHEN] The selected purchase action plans a split or parallel residual on a fresh fixture for each boundary.
        RunVendorRoutingSplitBoundary(4, 8, false);
        RunVendorRoutingSplitBoundary(8, 8, true);
        for Variant := 1 to 9 do
            RunVendorRoutingParallelBoundary(Variant);
        // [THEN] Helpers assert 4+8, guarded 8+8, native D policy, expanded 8/12, exact mixed remainder and evidence guards.
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure CompatibleSourceCountsOwnAndOtherUnshipped()
    var
        Purchase: Record "Purchase Header";
        OtherPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OtherLine: Record "Purchase Line";
        Source20, Source30: Code[10];
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [WIP]
        // [SCENARIO 654802] Returning to compatible discovery cannot omit the current line's physical claim when another line overlaps.
        // [GIVEN] Native moved-source transfers retain own 4 and another purchase line's 4 against physical 12 at predecessor 20.
        PrepareVendorRoutingOverlap(12, 12, true, false, Purchase, PurchaseLine, OtherLine, Source20, Source30);
        CreateVendorRoutingForward(Purchase);
        RetainVendorRoutingOverlapClaim(PurchaseLine, Source20, Source30, 4, 4);
        OtherPurchase.Get(OtherLine."Document Type", OtherLine."Document No.");
        CreateVendorRoutingForward(OtherPurchase);
        RetainVendorRoutingOverlapClaim(OtherLine, Source20, Source30, 4, 4);
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '20', Source20, 4, 4);
        VerifyVendorRoutingOverlapTuple(OtherLine, '20', Source20, 4, 4);
        RestoreVendorRoutingOverlapSources(Source20, Source30);

        // [WHEN] The selected purchase requests transfers again through its native action with compatible source locations.
        CreateVendorRoutingForward(Purchase);

        // [THEN] Only 4 more can claim predecessor 20; the distinct predecessor 30 still retains its native 12-unit preset.
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '20', Source20, 8, 8);
        VerifyVendorRoutingOverlapTuple(OtherLine, '20', Source20, 4, 4);
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '30', Source30, 12, 12);
        VerifyVendorRoutingOverlapTuple(OtherLine, '30', Source30, 0, 0);
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, 12);
        VerifyVendorRoutingWIP(VRRouting[4], Purchase."Subc. Location Code", false, 0);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure CompatibleSourceDoesNotDoubleCountShipped()
    var
        Purchase: Record "Purchase Header";
        OtherPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OtherLine: Record "Purchase Line";
        Transfer: Record "Transfer Header";
        Source20, Source30: Code[10];
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [WIP]
        // [SCENARIO 654802] Physical availability deducts only unshipped claims, not a shipment already debited from source WIP.
        // [GIVEN] From native physical 14, own original 6 has shipped/received 2 and another line retains an unshipped 4.
        PrepareVendorRoutingOverlap(14, 12, true, false, Purchase, PurchaseLine, OtherLine, Source20, Source30);
        CreateVendorRoutingForward(Purchase);
        RetainVendorRoutingOverlapClaim(PurchaseLine, Source20, Source30, 6, 2);
        OtherPurchase.Get(OtherLine."Document Type", OtherLine."Document No.");
        CreateVendorRoutingForward(OtherPurchase);
        RetainVendorRoutingOverlapClaim(OtherLine, Source20, Source30, 4, 4);
        FindVendorRoutingTransfer(Purchase, Source20, false, Transfer);
        LibraryWarehouse.PostTransferOrder(Transfer, true, false);
        SetVendorRoutingWIPReceipt(Transfer, 2);
        LibraryWarehouse.PostTransferOrder(Transfer, false, true);
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '20', Source20, 6, 4);
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, 12);
        VerifyVendorRoutingWIP(VRRouting[4], Purchase."Subc. Location Code", false, 2);
        RestoreVendorRoutingOverlapSources(Source20, Source30);

        // [WHEN] The selected purchase requests another native compatible parallel transfer.
        CreateVendorRoutingForward(Purchase);

        // [THEN] New 4 plus own unshipped 4 plus other 4 uses physical 12; own full original 6 still counts for coverage.
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '20', Source20, 10, 8);
        VerifyVendorRoutingOverlapTuple(OtherLine, '20', Source20, 4, 4);
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '30', Source30, 12, 12);
        VerifyVendorRoutingOverlapTuple(OtherLine, '30', Source30, 0, 0);
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, 12);
        VerifyVendorRoutingWIP(VRRouting[4], Purchase."Subc. Location Code", false, 2);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure CompatibleSourceCountsEarlierPrivatePlan()
    var
        Purchase: Record "Purchase Header";
        FirstLine: Record "Purchase Line";
        LaterLine: Record "Purchase Line";
        Transfer: Record "Transfer Header";
        Line: Record "Transfer Line";
        ReleaseTransfer: Codeunit "Release Transfer Document";
        Source20, Source30: Code[10];
        BeforeState: Text;
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [WIP]
        // [SCENARIO 654802] Earlier selected-line plans and the later line's own physical claim cannot reserve the same source twice.
        // [GIVEN] Two native 12-unit lines share one order; receipt 12 leaves source 20 net 12 and destination net 12.
        PrepareVendorRoutingOverlap(24, 24, true, true, Purchase, FirstLine, LaterLine, Source20, Source30);
        Assert.IsTrue(FirstLine."Line No." < LaterLine."Line No.", 'The native append must establish deterministic report planning order.');
        CreateVendorRoutingForward(Purchase);
        RetainVendorRoutingOverlapClaim(FirstLine, Source20, Source30, 12, 12);
        RetainVendorRoutingOverlapClaim(LaterLine, Source20, Source30, 4, 0);
        FindVendorRoutingTransfer(Purchase, Source20, false, Transfer);
        LibraryWarehouse.PostTransferOrder(Transfer, true, false);
        FilterVendorRoutingOverlapTuple(Line, FirstLine, '20', Source20);
        Line.FindFirst();
        Line.Validate("Qty. to Receive", 12);
        Line.Modify(true);
        LibraryWarehouse.PostTransferOrder(Transfer, false, true);
        Transfer.Get(Transfer."No.");
        ReleaseTransfer.Reopen(Transfer);
        FilterVendorRoutingOverlapTuple(Line, FirstLine, '20', Source20);
        Line.FindFirst();
        Line.TestField("Quantity Shipped", 12);
        Line.TestField("Quantity Received", 12);
        // Delete only the fully received original through its normal trigger; posted lineage and WIP remain untouched.
        Line.Delete(true);
        VerifyVendorRoutingOverlapTuple(FirstLine, '20', Source20, 0, 0);
        VerifyVendorRoutingOverlapTuple(LaterLine, '20', Source20, 4, 4);
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, 12);
        VerifyVendorRoutingWIP(VRRouting[3], Source30, false, 24);
        VerifyVendorRoutingWIP(VRRouting[4], Purchase."Subc. Location Code", false, 12);
        RestoreVendorRoutingOverlapSources(Source20, Source30);
        BeforeState := VendorRoutingArtifactState();

        // [WHEN] Compatible preflight plans first-line 8 before considering the later line's existing 4.
        asserterror CreateVendorRoutingForward(Purchase);

        // [THEN] No physical source remains for that later line; the contextual evidence guard rolls back every proposed artifact.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(
            'Cannot verify WIP availability for operation %1 of production order %2 at location %3, document %4. Retain the source documents and reconcile the WIP evidence before creating another transfer.',
            '20', VROrder."No.", Source20, ''));
        Assert.AreEqual(BeforeState, VendorRoutingArtifactState(), 'A later-line availability failure must leave no transfer, posted, ledger or component artifacts from earlier plans.');
        VerifyVendorRoutingOverlapTuple(FirstLine, '20', Source20, 0, 0);
        VerifyVendorRoutingOverlapTuple(LaterLine, '20', Source20, 4, 4);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure CompatibleSourceKeepsOwnOnlyParallelPreset()
    var
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnusedLine: Record "Purchase Line";
        Source20, Source30: Code[10];
    begin
        // [FEATURE] [Subcontracting] [Worksheet Vendor] [WIP]
        // [SCENARIO 654802] An own-only compatible parallel request retains the native preset even after moved-source discovery.
        // [GIVEN] Only this purchase line retains original 4; no other purchase-line or earlier private-plan claim exists.
        PrepareVendorRoutingOverlap(12, 12, false, false, Purchase, PurchaseLine, UnusedLine, Source20, Source30);
        CreateVendorRoutingForward(Purchase);
        RetainVendorRoutingOverlapClaim(PurchaseLine, Source20, Source30, 4, 4);
        RestoreVendorRoutingOverlapSources(Source20, Source30);

        // [WHEN] The native action discovers two distinct compatible predecessor locations again.
        CreateVendorRoutingForward(Purchase);

        // [THEN] Native aggregate coverage 4 is below expected 24, so each predecessor retains preset 12, not residual 8.
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '20', Source20, 16, 16);
        VerifyVendorRoutingOverlapTuple(PurchaseLine, '30', Source30, 12, 12);
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, 12);
        VerifyVendorRoutingWIP(VRRouting[4], Purchase."Subc. Location Code", false, 0);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure OpenPredecessorReturnBlocksSuccessor()
    var
        SuccessorPurchase: Record "Purchase Header";
        ReturnLine: Record "Transfer Line";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] An original return reserves current-operation physical stock even though its previous operation is blank.
        Initialize();

        // [GIVEN] Operation 10 has native physical 12 at S-new after No, and an unshipped native return of all 12.
        PrepareVendorRoutingPredecessorReturn(12, 0, SuccessorPurchase, ReturnLine);
        VerifyVendorRoutingReturnClaim(ReturnLine, 12, 0);
        VerifyVendorRoutingWIP(VRRouting[1], ReturnLine."Transfer-from Code", false, 12);
        BeforeState := VendorRoutingArtifactState();

        // [WHEN] The purchase action requests operation 40's twelve-unit forward transfer.
        asserterror CreateVendorRoutingForward(SuccessorPurchase);

        // [THEN] No components, headers or lines can be created against stock already promised to the return.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError('Cannot verify WIP availability');
        Assert.ExpectedError(VROrder."No.");
        Assert.ExpectedError(ReturnLine."Transfer-from Code");
        Assert.AreEqual(BeforeState, VendorRoutingArtifactState(), 'An open return must be included in preflight before any component or WIP artifacts.');
        VerifyVendorRoutingReturnClaim(ReturnLine, 12, 0);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure PartialPredecessorReturnCapsSuccessor()
    var
        SuccessorPurchase: Record "Purchase Header";
        ReturnLine: Record "Transfer Line";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] Physical net eight less original-return outstanding four permits only four new WIP units.
        Initialize();

        // [GIVEN] Native return quantity eight has shipped four without receipt, debiting operation 10's physical twelve to eight.
        PrepareVendorRoutingPredecessorReturn(8, 4, SuccessorPurchase, ReturnLine);
        VerifyVendorRoutingReturnClaim(ReturnLine, 8, 4);
        VerifyVendorRoutingWIP(VRRouting[1], ReturnLine."Transfer-from Code", false, 8);

        // [WHEN] The actual successor purchase action discovers S-new rather than the old master location.
        CreateVendorRoutingForward(SuccessorPurchase);

        // [THEN] The shipped four is already debited; only the outstanding four is subtracted once more.
        VerifyVendorRoutingTuple(SuccessorPurchase, '10', ReturnLine."Transfer-from Code", 4);
        VerifyVendorRoutingReturnClaim(ReturnLine, 8, 4);
        VerifyVendorRoutingWIP(VRRouting[1], ReturnLine."Transfer-from Code", false, 8);
        VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 0);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure ShippedPredecessorReturnNotCountedTwice()
    var
        SuccessorPurchase: Record "Purchase Header";
        ReturnLine: Record "Transfer Line";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] A fully shipped four-unit predecessor return leaves physical eight available, not four.
        Initialize();

        // [GIVEN] The return has shipped four but is not received, preserving the original and derived native lines.
        PrepareVendorRoutingPredecessorReturn(4, 4, SuccessorPurchase, ReturnLine);
        VerifyVendorRoutingReturnClaim(ReturnLine, 4, 4);
        VerifyVendorRoutingWIP(VRRouting[1], ReturnLine."Transfer-from Code", false, 8);

        // [WHEN] The successor purchase requests its native forward transfer.
        CreateVendorRoutingForward(SuccessorPurchase);

        // [THEN] Neither the original's shipped quantity nor its derived transit line is a second physical claim.
        VerifyVendorRoutingTuple(SuccessorPurchase, '10', ReturnLine."Transfer-from Code", 8);
        VerifyVendorRoutingReturnClaim(ReturnLine, 4, 4);
        VerifyVendorRoutingWIP(VRRouting[1], ReturnLine."Transfer-from Code", false, 8);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure WorksheetAcceptsPaymentBlockedVendor()
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Payment blocking is purchasing-compatible and must not reject an accepted operation vendor.
        Initialize();

        // [GIVEN] V2 is blocked only for payments and has a valid subcontracting location.
        CreateVendorRoutingFixture(0, 12);
        VRVendor[2].Validate(Blocked, VRVendor[2].Blocked::Payment);
        VRVendor[2].Modify(true);

        // [WHEN] The real worksheet vendor replacement is accepted.
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);

        // [THEN] The persisted worksheet and public operation reader agree, with production and masters untouched.
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        VerifyVendorRoutingUnchanged();
        FinishVendorRoutingFixture();
    end;

    [Test]
    procedure WorksheetRejectsAllBlockedVendor()
    var
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Native All blocking still rejects a worksheet replacement without routing or purchase side effects.
        Initialize();

        // [GIVEN] V2 is blocked for all purchasing documents.
        CreateVendorRoutingFixture(0, 12);
        VRVendor[2].Validate(Blocked, VRVendor[2].Blocked::All);
        VRVendor[2].Modify(true);
        BeforeState := VendorRoutingPurchaseState() + VendorRoutingArtifactState() + VendorRoutingRowVersions();

        // [WHEN] The actual vendor control is replaced.
        asserterror SetVendorRoutingWorksheetControl(VRVendor[2]."No.");

        // [THEN] Native vendor eligibility rejects before any routing question and rolls back the saved suggestion.
        Assert.ExpectedError('blocked');
        Assert.ExpectedError(VRVendor[2]."No.");
        Assert.ExpectedErrorCode('Dialog');
        VerifyVendorRoutingRejectedChoice(BeforeState);
        FinishVendorRoutingFixture();
    end;

    [Test]
    procedure WorksheetRejectsPrivacyBlockedVendor()
    var
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] The native privacy guard must remain effective independently of Payment acceptance.
        Initialize();

        // [GIVEN] Native privacy validation blocks V2 and also sets its All flag.
        CreateVendorRoutingFixture(0, 12);
        VRVendor[2].Validate("Privacy Blocked", true);
        VRVendor[2].Modify(true);
        BeforeState := VendorRoutingPurchaseState() + VendorRoutingArtifactState() + VendorRoutingRowVersions();

        // [WHEN] The actual worksheet vendor control is replaced.
        asserterror SetVendorRoutingWorksheetControl(VRVendor[2]."No.");

        // [THEN] The privacy-specific native error precedes the question and leaves all business rows unchanged.
        Assert.ExpectedError('blocked for privacy');
        Assert.ExpectedError(VRVendor[2]."No.");
        Assert.ExpectedErrorCode('Dialog');
        VerifyVendorRoutingRejectedChoice(BeforeState);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure WorksheetNoIsolatesParallelSiblings()
    var
        BeforeSiblingVendors: Text;
        BeforeVersions: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] No preserves every nonselected operation's full-key public vendor, including parallel and internal siblings.
        Initialize();

        // [GIVEN] A genuine four-operation parallel order and independent order.
        CreateVendorRoutingFixture(2, 12);
        BeforeSiblingVendors := VendorRoutingSiblingVendors();
        BeforeVersions := VendorRoutingRowVersions();

        // [WHEN] The worksheet replacement on operation 20 is declined.
        ChangeWorksheetVendor(VRVendor[2]."No.", false, true);

        // [THEN] Override-only sibling corruption is observable through fresh public resolution, not private storage.
        Assert.AreEqual(BeforeSiblingVendors, VendorRoutingSiblingVendors(), 'Every nonselected full-key public vendor must survive No.');
        Assert.AreEqual(BeforeVersions, VendorRoutingRowVersions(), 'No must write no production routing or component row.');
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
        VerifyVendorRoutingUnchanged();
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure MasterClearRetainsOverridesFlow()
    var
        OtherRouting: Record "Prod. Order Routing Line";
        DefaultOrder: Record "Production Order";
        DefaultRouting: Record "Prod. Order Routing Line";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Dependent clear/restore flow disables readers without deleting either order's accepted selection.
        Initialize();

        // [GIVEN] Independent native orders accepted V2 and V3; an untouched third order still uses the shared master V1.
        CreateVendorRoutingFixture(0, 12);
        AcceptVendorRoutingOtherOrder();
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        CreateVendorRoutingOrder(DefaultOrder, 12);
        FindVendorRoutingOperation(DefaultOrder, '10', DefaultRouting);
        FindVendorRoutingOperation(VROtherOrder, '10', OtherRouting);
        VerifyEffectiveVendor(OtherRouting, VRVendor[3]."No.");
        BeforeState := VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState();

        // [WHEN] Native master validation clears the shared subcontractor; the dependent restoration uses a different valid V4.
        SetVendorRoutingMaster('');

        // [THEN] Public readers/factboxes and the native FlowField are disabled, with no production or document write.
        VerifyVendorRoutingEligibility(VRRouting[1], '', false);
        VerifyVendorRoutingEligibility(OtherRouting, '', false);
        VerifyVendorRoutingEligibility(DefaultRouting, '', false);
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Master clear must not sweep production rows, components or documents.');
        SetVendorRoutingMaster(VRVendor[4]."No.");
        VerifyVendorRoutingEligibility(VRRouting[1], VRVendor[2]."No.", true);
        VerifyVendorRoutingEligibility(OtherRouting, VRVendor[3]."No.", true);
        VerifyVendorRoutingEligibility(DefaultRouting, VRVendor[4]."No.", true);
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Restoration must reveal retained selections without rewriting either order.');
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure MasterClearWorksheetEditFlow()
    var
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] A saved suggestion can change vendor while disabled but cannot replace the dormant accepted operation selection.
        Initialize();

        // [GIVEN] V2 was accepted and its genuine saved New suggestion survives native master clear.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        SetVendorRoutingMaster('');
        BeforeState := VendorRoutingBusinessState() + VendorRoutingRowVersions();

        // [WHEN] The saved worksheet vendor is changed to V3 while eligibility is disabled.
        ChangeWorksheetVendor(VRVendor[3]."No.", false, false);

        // [THEN] No second question or routing write occurs; restore reveals V2 rather than the worksheet-only V3.
        VerifyWorksheetVendor(VRVendor[3]."No.", VRMain.Code);
        Assert.AreEqual(1, VRVendorQuestionCount, 'Only the original enabled acceptance may ask.');
        VerifyVendorRoutingEligibility(VRRouting[1], '', false);
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingRowVersions(), 'Disabled editing must preserve scheduling, costs, components and routing rowversions.');
        SetVendorRoutingMaster(VRVendor[4]."No.");
        VerifyVendorRoutingEligibility(VRRouting[1], VRVendor[2]."No.", true);
        VerifyWorksheetVendor(VRVendor[3]."No.", VRMain.Code);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure MasterClearFallbackPriceFlow()
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Pricing]
        // [SCENARIO 654802] Dependent task-price flow suppresses dormant fallback but restores the retained V2 price 22.
        Initialize();

        // [GIVEN] Accepted V2, blank explicit pricing vendor and distinguishable existing cost 11.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        VRRouting[1].Validate("Vendor No. Subc. Price", '');
        VRRouting[1].Modify(true);
        Assert.AreEqual(11, VRRouting[1]."Direct Unit Cost", 'Acceptance must not pre-price the operation.');
        SetVendorRoutingMaster('');

        // [WHEN] Native task validation requests a price while the master is disabled.
        ValidateVendorRoutingTaskPrice();

        // [THEN] Cost stays 11, and restoration to master V3 reveals retained V2 fallback 22, not master price 33.
        Assert.AreEqual(11, VRRouting[1]."Direct Unit Cost", 'A dormant override must not supply fallback pricing.');
        VerifyVendorRoutingEligibility(VRRouting[1], '', false);
        SetVendorRoutingMaster(VRVendor[3]."No.");
        ValidateVendorRoutingTaskPrice();
        Assert.AreEqual(22, VRRouting[1]."Direct Unit Cost", 'Restored eligibility must price from the retained accepted vendor.');
        VerifyVendorRoutingEligibility(VRRouting[1], VRVendor[2]."No.", true);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure MasterClearExplicitPriceFlow()
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Pricing]
        // [SCENARIO 654802] Explicit pricing remains allowed while disabled and retains precedence after restoration.
        Initialize();

        // [GIVEN] Accepted V2 and an explicit, baseline-public pricing vendor V3.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        VRRouting[1].Validate("Vendor No. Subc. Price", VRVendor[3]."No.");
        VRRouting[1].Modify(true);
        SetVendorRoutingMaster('');

        // [WHEN] Native task validation requests the explicit price while disabled.
        ValidateVendorRoutingTaskPrice();

        // [THEN] Explicit 33 works without granting subcontracting eligibility; restored fallback identity remains V2.
        Assert.AreEqual(33, VRRouting[1]."Direct Unit Cost", 'Disabling subcontracting must not disable explicit pricing.');
        VerifyVendorRoutingEligibility(VRRouting[1], '', false);
        SetVendorRoutingMaster(VRVendor[4]."No.");
        ValidateVendorRoutingTaskPrice();
        Assert.AreEqual(33, VRRouting[1]."Direct Unit Cost", 'Explicit pricing must still win after master restoration.');
        VerifyVendorRoutingEligibility(VRRouting[1], VRVendor[2]."No.", true);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure MasterClearComponentConsumersFlow()
    var
        Variant: Integer;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Components]
        // [SCENARIO 654802] Dependent disabled/restored supply and link flows never resolve a dormant override destination.
        Initialize();

        // [GIVEN] Each independent fixture accepts V2 with two real MAIN Pick+Manual components.
        // [WHEN] Native supply or link validation runs with the master disabled and then restored.
        for Variant := 1 to 5 do
            RunVendorRoutingMasterComponentFlow(Variant);

        // [THEN] Helpers verify location, original/bin/flushing, quantities, routing identity and native link dates.
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure MasterClearCalculationDirectFlow()
    var
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingPage: TestPage "Prod. Order Routing";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Purchasing]
        // [SCENARIO 654802] Dependent disable/restore flow gates calculation and direct purchasing without erasing the selection.
        Initialize();

        // [GIVEN] V2 was accepted, then the native master was disabled.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        SetVendorRoutingMaster('');

        // [WHEN] Calculation is requested both unfiltered and by retained V2, and the actual routing action is attempted.
        CalculateVendorRoutingSuggestions('');
        Assert.RecordIsEmpty(VRReq);
        CalculateVendorRoutingSuggestions(VRVendor[2]."No.");
        Assert.RecordIsEmpty(VRReq);
        BeforeState := VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState();
        RoutingPage.OpenView();
        RoutingPage.GoToRecord(VRRouting[1]);
        asserterror RoutingPage.CreateSubcontracting.Invoke();

        // [THEN] Direct creation rejects master eligibility before artifacts; restoration uses V2, not the new master V3.
        Assert.ExpectedError('Subcontractor No.');
        Assert.ExpectedError(VRWorkCenter[1]."No.");
        Assert.ExpectedErrorCode('TestField');
        RoutingPage.Close();
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Disabled direct creation must create no business artifacts.');
        SetVendorRoutingMaster(VRVendor[3]."No.");
        CalculateVendorRoutingSuggestions(VRVendor[3]."No.");
        Assert.RecordIsEmpty(VRReq);
        CalculateVendorRoutingSuggestions(VRVendor[2]."No.");
        FindVendorRoutingSuggestion();
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        CreateVendorRoutingPurchase(VRRouting[1], Purchase, PurchaseLine);
        VerifyVendorRoutingPurchase(Purchase, PurchaseLine, VRRouting[1], VRVendor[2]);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure SavedNewSuggestionRefusesDisabledMaster()
    var
        BeforeState: Text;
        BeforeQuantity: Decimal;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Purchasing]
        // [SCENARIO 654802] A coherent saved New suggestion cannot bypass master disable at native carryout.
        Initialize();

        // [GIVEN] A genuine saved suggestion predates the clear; it is not recalculated, fabricated or relinked.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        ReloadVendorRoutingSuggestion();
        Assert.AreEqual(VRReq."Action Message"::New, VRReq."Action Message", 'The preflight is specifically a New purchase boundary.');
        BeforeQuantity := VRReq.Quantity;
        SetVendorRoutingMaster('');
        BeforeState := VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState();
        VRReq.SetRecFilter();

        // [WHEN] The native carryout report consumes that exact saved line.
        asserterror SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);

        // [THEN] The live master eligibility error precedes any purchase, preserving the saved target and production.
        Assert.ExpectedError('Subcontractor No.');
        Assert.ExpectedError(VRWorkCenter[1]."No.");
        Assert.ExpectedErrorCode('TestField');
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Saved New carryout must not create or append a purchase while disabled.');
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        Assert.AreEqual(BeforeQuantity, VRReq.Quantity, 'The rejected saved suggestion must retain its quantity.');
        Assert.AreEqual(VRReq."Action Message"::New, VRReq."Action Message", 'The saved suggestion must remain New.');
        VerifyVendorRoutingEligibility(VRRouting[1], '', false);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure RestoredSavedSuggestionCarriesChosenVendor()
    var
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Purchasing]
        // [SCENARIO 654802] Restored eligibility still permits native saved-suggestion No semantics and purchasing.
        Initialize();

        // [GIVEN] V2 was accepted before a native clear/restore to master V4.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        SetVendorRoutingMaster('');
        SetVendorRoutingMaster(VRVendor[4]."No.");
        ChangeWorksheetVendor(VRVendor[3]."No.", false, true);
        VRReq.SetRecFilter();

        // [WHEN] Native carryout consumes the chosen V3 suggestion without recalculation.
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);

        // [THEN] V3 buys at MAIN/S-third, but public operation identity remains retained V2.
        FindVendorRoutingPurchase(VRRouting[1], Purchase, PurchaseLine);
        VerifyVendorRoutingPurchase(Purchase, PurchaseLine, VRRouting[1], VRVendor[3]);
        VerifyVendorRoutingEligibility(VRRouting[1], VRVendor[2]."No.", true);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure RestoredMasterRetainsCommitmentGuards()
    var
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Worksheet Vendor]
        // [SCENARIO 654802] Clearing and restoring a master never bypasses the existing operation commitment guard.
        Initialize();

        // [GIVEN] V2 was accepted before native transfer commitments and master clear/restore.
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        CreateVendorRoutingPurchase(VRRouting[1], Purchase, PurchaseLine);
        CreateVendorRoutingForward(Purchase);
        BeforeState := VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState();
        SetVendorRoutingMaster('');
        SetVendorRoutingMaster(VRVendor[4]."No.");
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Master changes must not migrate or rewrite committed documents.');
        QueueVendorRoutingChoice(VRVendor[3]."No.", true);

        // [WHEN] A later worksheet replacement is accepted against the retained V2 identity.
        asserterror SetVendorRoutingWorksheetControl(VRVendor[3]."No.");

        // [THEN] The operation guard rejects and atomically preserves worksheet, stock, documents and public identity.
        Assert.ExpectedError(VROrder."No.");
        Assert.ExpectedErrorCode('Dialog');
        Assert.AreEqual(2, VRVendorQuestionCount, 'The later accepted question must actually reach the commitment guard.');
        VerifyWorksheetVendor(VRVendor[2]."No.", VRMain.Code);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingRowVersions() + VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'Rejected replacement after restore must be atomic.');
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NonbaseForwardRoundingOverCapCreatesNothing()
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemUOM: Record "Item Unit of Measure";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] Native factor-1000 rounding must refuse a 2.01-base debit against physical 2.006 before creating anything.
        Initialize();

        // [GIVEN] A native receipt supplies exactly 2.006 base; the successor purchases twelve base in a genuine nonbase UOM.
        PrepareNativeUOMSerial(2.006, PrecursorPurchase, SuccessorPurchase, PurchaseLine);
        SetNativePurchaseUOM(PurchaseLine, 1000, 0.012, ItemUOM);
        BeforeState := VendorRoutingArtifactState() + VendorRoutingPurchaseState();

        // [WHEN] The purchase action would round 0.002006 document units to 0.00201, not downsize to 0.002.
        asserterror CreateVendorRoutingForward(SuccessorPurchase);

        // [THEN] The contextual refusal preserves headers, components, original lines and the exact physical stock.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(VROrder."No.");
        Assert.ExpectedError(PrecursorPurchase."Subc. Location Code");
        Assert.AreEqual(BeforeState, VendorRoutingArtifactState() + VendorRoutingPurchaseState(), 'Over-cap rounding must refuse before any forward artifacts.');
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 2.006);
        VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 0);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NonbaseReturnRoundingOverCapCreatesNothing()
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemUOM: Record "Item Unit of Measure";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] Return preflight must reject the native rounded debit before either WIP or component artifacts.
        Initialize();

        // [GIVEN] The production UOM, not the purchase UOM, converts the native return's physical 2.006.
        PrepareNativeUOMSerial(2.006, PrecursorPurchase, SuccessorPurchase, PurchaseLine);
        SetNativeProductionUOM(1000, 0.012, ItemUOM);
        BeforeState := VendorRoutingArtifactState() + VendorRoutingPurchaseState();

        // [WHEN] The real return action would create document quantity 0.00201 and debit 2.01 base.
        asserterror CreateVendorRoutingReturn(PrecursorPurchase);

        // [THEN] Nothing is inserted or resized to disguise the 0.004-base excess.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(VROrder."No.");
        Assert.ExpectedError(PrecursorPurchase."Subc. Location Code");
        Assert.AreEqual(BeforeState, VendorRoutingArtifactState() + VendorRoutingPurchaseState(), 'Return rounding must be checked before every artifact.');
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 2.006);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure NonbaseSelectedClaimsUseRepresentableBase()
    var
        Purchase: Record "Purchase Header";
        FirstLine: Record "Purchase Line";
        LaterLine: Record "Purchase Line";
        FirstUOM: Record "Item Unit of Measure";
        LaterUOM: Record "Item Unit of Measure";
        Source20, Source30: Code[10];
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] Two selected native six-base requests share each physical twelve without sharing raw document quantities.
        Initialize();

        // [GIVEN] Native parallel receipts and two ordered purchase lines use distinct library-created factors six and two.
        PrepareVendorRoutingOverlap(12, 12, true, true, Purchase, FirstLine, LaterLine, Source20, Source30);
        Assert.IsTrue(FirstLine."Line No." < LaterLine."Line No.", 'Native append must establish selected-line planning order.');
        SetNativePurchaseUOM(FirstLine, 6, 1, FirstUOM);
        SetNativePurchaseUOM(LaterLine, 2, 3, LaterUOM);

        // [WHEN] One native action plans both selected service lines before insertion.
        CreateVendorRoutingForward(Purchase);

        // [THEN] Each source has first document one/base six and later document three/base six, with no posted debit yet.
        VerifyNativeForwardUOM(FirstLine, '20', Source20, FirstUOM.Code, 1, 6, 6);
        VerifyNativeForwardUOM(FirstLine, '30', Source30, FirstUOM.Code, 1, 6, 6);
        VerifyNativeForwardUOM(LaterLine, '20', Source20, LaterUOM.Code, 3, 6, 6);
        VerifyNativeForwardUOM(LaterLine, '30', Source30, LaterUOM.Code, 3, 6, 6);
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, 12);
        VerifyVendorRoutingWIP(VRRouting[3], Source30, false, 12);
        VerifyVendorRoutingWIP(VRRouting[4], Purchase."Subc. Location Code", false, 0);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure MixedOriginalOwnUOMKeepsFullCoverageFlow()
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseUOM: Record "Item Unit of Measure";
        OriginalUOM: Record "Item Unit of Measure";
        Transfer: Record "Transfer Header";
        Original: Record "Transfer Line";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] Received two plus full original four plus new original six covers twelve in mixed own UOMs.
        Initialize();

        // [GIVEN] A native successor original uses factor two, full quantity two/base four, and has received one/base two.
        PrepareNativeUOMSerial(12, PrecursorPurchase, SuccessorPurchase, PurchaseLine);
        SetNativePurchaseUOM(PurchaseLine, 6, 2, PurchaseUOM);
        CreateVendorRoutingForward(SuccessorPurchase);
        FilterVendorRoutingOverlapTuple(Original, PurchaseLine, '10', PrecursorPurchase."Subc. Location Code");
        Assert.AreEqual(1, Original.Count(), 'The fixture must start with one native original.');
        Original.FindFirst();
        LibraryInventory.CreateItemUnitOfMeasureCode(OriginalUOM, VRItem."No.", 2);
        Original.Validate("Unit of Measure Code", OriginalUOM.Code);
        Original.Validate("Transfer WIP Item", true);
        Original.Validate(Quantity, 2);
        Original.Validate("Qty. to Ship", 1);
        Original.Modify(true);
        Transfer.Get(Original."Document No.");
        LibraryWarehouse.PostTransferOrder(Transfer, true, false);
        SetVendorRoutingWIPReceipt(Transfer, 1);
        LibraryWarehouse.PostTransferOrder(Transfer, false, true);
        VerifyNativeForwardUOM(PurchaseLine, '10', PrecursorPurchase."Subc. Location Code", OriginalUOM.Code, 2, 4, 2);

        // [WHEN] Round one creates the six-base residual in the current purchase UOM.
        CreateVendorRoutingForward(SuccessorPurchase);

        // [WHEN] Round two consumes the accumulated native N plus FULL O policy, not outstanding-only coverage.
        ExpectVendorRoutingNoCreation(SuccessorPurchase, '', '', '');

        // [THEN] Full originals four and six remain, while posted destination two makes coverage twelve, not ten.
        VerifyNativeForwardUOM(PurchaseLine, '10', PrecursorPurchase."Subc. Location Code", OriginalUOM.Code, 2, 4, 2);
        VerifyNativeForwardUOM(PurchaseLine, '10', PrecursorPurchase."Subc. Location Code", PurchaseUOM.Code, 1, 6, 6);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 10);
        VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 2);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler,VendorRoutingTransfersHandler')]
    procedure NonbasePartialReturnCapsNativeSuccessor()
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrecursorLine: Record "Purchase Line";
        ProductionUOM: Record "Item Unit of Measure";
        PurchaseUOM: Record "Item Unit of Measure";
        ReturnHeader: Record "Transfer Header";
        ReturnLine: Record "Transfer Line";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] A factor-two return full eight/base with shipped four/base leaves only four/base for the successor.
        Initialize();

        // [GIVEN] A genuine return original has document four and has shipped document two through native posting.
        PrepareNativeUOMSerial(12, PrecursorPurchase, SuccessorPurchase, PurchaseLine);
        SetNativeProductionUOM(2, 6, ProductionUOM);
        SetNativePurchaseUOM(PurchaseLine, 2, 6, PurchaseUOM);
        CreateVendorRoutingReturn(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, PrecursorPurchase."Subc. Location Code", true, ReturnHeader);
        FindVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PrecursorLine);
        GetNativeReturnOriginal(PrecursorLine, PrecursorPurchase."Subc. Location Code", ReturnLine);
        ReturnLine.Validate(Quantity, 4);
        ReturnLine.Validate("Qty. to Ship", 2);
        ReturnLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, true, false);
        VerifyNativeReturnUOM(PrecursorLine, PrecursorPurchase."Subc. Location Code", ProductionUOM.Code, 4, 8, 4);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 8);

        // [WHEN] The successor requests twelve base through its actual purchase action.
        CreateVendorRoutingForward(SuccessorPurchase);

        // [THEN] Source net eight less return outstanding four permits document two/base four, never a derived second spend.
        VerifyNativeForwardUOM(PurchaseLine, '10', PrecursorPurchase."Subc. Location Code", PurchaseUOM.Code, 2, 4, 4);
        VerifyNativeReturnUOM(PrecursorLine, PrecursorPurchase."Subc. Location Code", ProductionUOM.Code, 4, 8, 4);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 8);
        VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 0);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NonbaseForwardThenMasterClearedReturnFlow()
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrecursorLine: Record "Purchase Line";
        ItemUOM: Record "Item Unit of Measure";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] A native forward commitment survives master clear and limits an ordinary native return to the remaining six.
        Initialize();

        // [GIVEN] Physical twelve belongs to accepted V2; a factor-six successor purchases six base.
        PrepareNativeUOMSerial(12, PrecursorPurchase, SuccessorPurchase, PurchaseLine);
        SetNativePurchaseUOM(PurchaseLine, 6, 1, ItemUOM);
        FindVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PrecursorLine);

        // [WHEN] Round one creates a real unshipped document one/base six forward commitment.
        CreateVendorRoutingForward(SuccessorPurchase);
        SetVendorRoutingMaster('');

        // [WHEN] Round two returns existing stock despite disabled NEW-purchasing eligibility.
        CreateVendorRoutingReturn(PrecursorPurchase);

        // [THEN] The return spends current operation 10, retaining six for the forward, without clearing the stored choice.
        VerifyNativeForwardUOM(PurchaseLine, '10', PrecursorPurchase."Subc. Location Code", ItemUOM.Code, 1, 6, 6);
        VerifyNativeReturnUOM(PrecursorLine, PrecursorPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 12);
        SetVendorRoutingMaster(VRVendor[1]."No.");
        VerifyEffectiveVendor(VRRouting[1], VRVendor[2]."No.");
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NativeReturnIgnoresOtherOperationClaim()
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrecursorLine: Record "Purchase Line";
        ItemUOM: Record "Item Unit of Measure";
        Forward: Record "Transfer Header";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] A return promise against operation 40 cannot reserve operation 10's distinct remaining physical six.
        Initialize();

        // [GIVEN] Native forward posting moves six from 10 to 40; operation 40 then has its own genuine open return.
        PrepareNativeUOMSerial(12, PrecursorPurchase, SuccessorPurchase, PurchaseLine);
        SetNativePurchaseUOM(PurchaseLine, 6, 1, ItemUOM);
        CreateVendorRoutingForward(SuccessorPurchase);
        FindVendorRoutingTransfer(SuccessorPurchase, PrecursorPurchase."Subc. Location Code", false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CreateVendorRoutingReturn(SuccessorPurchase);
        FindVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PrecursorLine);
        VerifyNativeReturnUOM(PurchaseLine, SuccessorPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);

        // [WHEN] The predecessor's real return action spends the current operation's remaining source.
        CreateVendorRoutingReturn(PrecursorPurchase);

        // [THEN] Each current-operation/source tuple retains its own six; neither return invents a previous operation.
        VerifyNativeReturnUOM(PrecursorLine, PrecursorPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);
        VerifyNativeReturnUOM(PurchaseLine, SuccessorPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 6);
        VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 6);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NativeReturnIgnoresOtherOrderCommitment()
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PrecursorLine: Record "Purchase Line";
        OtherPurchase: Record "Purchase Header";
        OtherLine: Record "Purchase Line";
        OtherRouting: Record "Prod. Order Routing Line";
        OtherForward: Record "Transfer Header";
        ItemUOM: Record "Item Unit of Measure";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] Another released order's original return cannot consume this order's same-item/current-operation availability.
        Initialize();

        // [GIVEN] This order promises six forward; the other order separately posts twelve and promises a native return.
        PrepareNativeUOMSerial(12, PrecursorPurchase, SuccessorPurchase, PurchaseLine);
        SetNativePurchaseUOM(PurchaseLine, 6, 1, ItemUOM);
        CreateVendorRoutingForward(SuccessorPurchase);
        FindVendorRoutingOperation(VROtherOrder, '10', OtherRouting);
        CreateVendorRoutingPurchase(OtherRouting, OtherPurchase, OtherLine);
        CreateVendorRoutingForward(OtherPurchase);
        FindVendorRoutingTransfer(OtherPurchase, VRMain.Code, false, OtherForward);
        LibraryWarehouse.PostTransferOrder(OtherForward, true, true);
        CreateVendorRoutingReturn(OtherPurchase);
        FindVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PrecursorLine);

        // [WHEN] The selected order creates its native return.
        CreateVendorRoutingReturn(PrecursorPurchase);

        // [THEN] Exact order identity separates the six-base and twelve-base original returns.
        VerifyNativeReturnUOM(PrecursorLine, PrecursorPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);
        VerifyNativeReturnUOM(OtherLine, OtherPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 12);
        VerifyVendorRoutingWIP(OtherRouting, OtherPurchase."Subc. Location Code", false, 12);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler,VendorRoutingTransferHandler')]
    procedure NativeReturnIgnoresOtherLineVariantClaim()
    var
        ProductionLine: Record "Prod. Order Line";
        OriginalProductionLine: Record "Prod. Order Line";
        ItemVariant: Record "Item Variant";
        OtherRouting: Record "Prod. Order Routing Line";
        OtherSuccessorRouting: Record "Prod. Order Routing Line";
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PrecursorLine: Record "Purchase Line";
        PurchaseLine: Record "Purchase Line";
        OtherPurchase: Record "Purchase Header";
        OtherLine: Record "Purchase Line";
        Forward: Record "Transfer Header";
        OtherForward: Record "Transfer Header";
        ItemUOM: Record "Item Unit of Measure";
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [WIP]
        // [SCENARIO 654802] A native second production line and variant retain their own routing reference and return commitment.
        Initialize();

        // [GIVEN] Two genuine production lines are refreshed before any purchase, override or WIP posting.
        CreateVendorRoutingFixture(1, 12);
        LibraryInventory.CreateItemVariant(ItemVariant, VRItem."No.");
        LibraryManufacturing.CreateProdOrderLine(ProductionLine, VROrder.Status, VROrder."No.", VRItem."No.", ItemVariant.Code, VRMain.Code, 12);
        LibraryManufacturing.RefreshProdOrder(VROrder, false, false, true, true, false);
        ProductionLine.Get(ProductionLine.Status, ProductionLine."Prod. Order No.", ProductionLine."Line No.");
        ReloadVendorRoutingOperation(VRRouting[1]);
        ReloadVendorRoutingOperation(VRRouting[4]);
        OriginalProductionLine.Get(VROrder.Status, VROrder."No.", VendorRoutingProductionLineNo(VRRouting[1]));
        Assert.AreEqual(VRItem."No.", ProductionLine."Item No.", 'Routing refresh must retain the second production item.');
        Assert.AreEqual(ItemVariant.Code, ProductionLine."Variant Code", 'Routing refresh must retain the second production variant.');
        Assert.AreEqual(VRMain.Code, ProductionLine."Location Code", 'Routing refresh must retain the second production location.');
        Assert.AreEqual(12, ProductionLine.Quantity, 'Routing refresh must retain the second production quantity.');
        Assert.AreEqual(12, ProductionLine."Quantity (Base)", 'The second production line must retain twelve base units.');
        Assert.AreEqual(VRItem."Routing No.", ProductionLine."Routing No.", 'The second production line must retain the certified item routing.');
        Assert.AreEqual(ProductionLine."Line No.", ProductionLine."Routing Reference No.", 'Native item validation must give the second line its own routing reference.');
        Assert.AreEqual('', OriginalProductionLine."Variant Code", 'The original production line must retain its blank variant.');
        Assert.AreEqual(12, OriginalProductionLine."Quantity (Base)", 'Routing refresh must retain the original twelve-base demand.');
        Assert.IsTrue(ProductionLine."Routing Reference No." <> OriginalProductionLine."Routing Reference No.", 'The two production lines must keep distinct routing references before purchasing.');
        Assert.AreEqual(OriginalProductionLine."Routing Reference No.", VRRouting[4]."Routing Reference No.", 'The original successor must remain on the original production line.');
        OtherRouting.Get(VROrder.Status, VROrder."No.", ProductionLine."Routing Reference No.", ProductionLine."Routing No.", '10');
        OtherSuccessorRouting.Get(VROrder.Status, VROrder."No.", ProductionLine."Routing Reference No.", ProductionLine."Routing No.", '40');
        Assert.AreEqual(VRWorkCenter[1]."No.", OtherRouting."Work Center No.", 'The second line must have its own native subcontracting predecessor.');
        Assert.AreEqual('40', OtherRouting."Next Operation No.", 'The second-line predecessor must retain the native serial link.');
        Assert.IsTrue(OtherRouting."Transfer WIP Item", 'The second-line predecessor must support native WIP posting.');
        Assert.AreEqual(VRWorkCenter[4]."No.", OtherSuccessorRouting."Work Center No.", 'The second line must have its own native subcontracting successor.');
        Assert.AreEqual('10', OtherSuccessorRouting."Previous Operation No.", 'The second-line successor must retain the native serial link.');
        Assert.IsTrue(OtherSuccessorRouting."Transfer WIP Item", 'The second-line successor must retain its native WIP routing flag.');
        CalculateVendorRoutingSuggestions('');
        VRReq.SetRange("Prod. Order Line No.", VendorRoutingProductionLineNo(VRRouting[1]));
        FindVendorRoutingSuggestion();
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        CreateVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PrecursorLine);
        CreateVendorRoutingForward(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        CreateVendorRoutingPurchase(VRRouting[4], SuccessorPurchase, PurchaseLine);
        SetNativePurchaseUOM(PurchaseLine, 6, 1, ItemUOM);
        CreateVendorRoutingForward(SuccessorPurchase);
        OtherRouting.Get(VROrder.Status, VROrder."No.", ProductionLine."Routing Reference No.", ProductionLine."Routing No.", '10');
        CreateNativeScopedPurchase(ProductionLine, OtherRouting, OtherPurchase, OtherLine);
        CreateVendorRoutingForward(OtherPurchase);
        FindVendorRoutingTransfer(OtherPurchase, VRMain.Code, false, OtherForward);
        LibraryWarehouse.PostTransferOrder(OtherForward, true, true);
        CreateVendorRoutingReturn(OtherPurchase);

        // [WHEN] The original blank-variant production line creates its own return.
        CreateVendorRoutingReturn(PrecursorPurchase);

        // [THEN] The original returns persist separate production line, routing reference, item variant and quantities.
        Assert.IsTrue(OtherLine."Prod. Order Line No." <> PrecursorLine."Prod. Order Line No.", 'The library must create a distinct production line.');
        Assert.IsTrue(OtherLine."Routing Reference No." <> PrecursorLine."Routing Reference No.", 'Native refresh must isolate routing references.');
        Assert.AreEqual(ItemVariant.Code, OtherLine."Variant Code", 'The second native purchase must retain its real variant.');
        VerifyNativeReturnUOM(PrecursorLine, PrecursorPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 6, 6, 6);
        VerifyNativeReturnUOM(OtherLine, OtherPurchase."Subc. Location Code", VRItem."Base Unit of Measure", 12, 12, 12);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 12);
        FinishVendorRoutingFixture();
    end;

    [Test]
    [HandlerFunctions('VendorRoutingConfirmHandler')]
    procedure SavedTargetGroupMasterClearRestoreFlow()
    var
        TargetPurchase: Record "Purchase Header";
        TargetLine: Record "Purchase Line";
        OtherRouting: Record "Prod. Order Routing Line";
        BeforeState: Text;
    begin
        // [FEATURE] [AI test 1.0] [Subcontracting] [Purchasing]
        // [SCENARIO 654802] A saved target after a native completed group cannot append while disabled and retains its chosen vendor after restore.
        Initialize();

        // [GIVEN] A native other-order group already created a target; this saved New suggestion chooses that vendor and target.
        CreateVendorRoutingFixture(0, 12);
        FindVendorRoutingOperation(VROtherOrder, '10', OtherRouting);
        CreateVendorRoutingPurchase(OtherRouting, TargetPurchase, TargetLine);
        ChangeWorksheetVendor(VRVendor[1]."No.", false, false);
        VRReq.Validate("Ref. Order No.", TargetPurchase."No.");
        VRReq.Modify(true);
        ReloadVendorRoutingSuggestion();
        Assert.AreEqual(VRReq."Action Message"::New, VRReq."Action Message", 'The saved assigned suggestion must still be New.');
        SetVendorRoutingMaster('');
        BeforeState := VendorRoutingBusinessState() + VendorRoutingPurchaseState() + VendorRoutingArtifactState();
        VRReq.SetRecFilter();

        // [WHEN] Round one consumes the exact saved target without recalculation while the live master is disabled.
        asserterror SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);
        Assert.ExpectedError('Subcontractor No.');
        Assert.ExpectedError(VRWorkCenter[1]."No.");
        Assert.ExpectedErrorCode('TestField');
        Assert.AreEqual(BeforeState, VendorRoutingBusinessState() + VendorRoutingPurchaseState() + VendorRoutingArtifactState(), 'The existing completed group remains; the rejected group appends no service or components.');

        // [WHEN] Round two restores eligibility and carries out the same saved target in a new native action.
        SetVendorRoutingMaster(VRVendor[1]."No.");
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);

        // [THEN] Native target selection appends this exact production identity, preserving the first group's service.
        FindVendorRoutingPurchase(VRRouting[1], TargetPurchase, TargetLine);
        Assert.AreEqual(VRReq."Ref. Order No.", TargetPurchase."No.", 'The restored suggestion must retain its saved target.');
        VerifyVendorRoutingPurchase(TargetPurchase, TargetLine, VRRouting[1], VRVendor[1]);
        FindVendorRoutingPurchase(OtherRouting, TargetPurchase, TargetLine);
        Assert.AreEqual(VROtherOrder."No.", TargetLine."Prod. Order No.", 'The earlier native group must remain intact.');
        Assert.AreEqual(12, TargetLine.Quantity, 'The earlier group quantity must not be enlarged or rewritten.');
        FinishVendorRoutingFixture();
    end;

    local procedure CreateNativeScopedPurchase(ProductionLine: Record "Prod. Order Line"; Routing: Record "Prod. Order Routing Line"; var Header: Record "Purchase Header"; var Line: Record "Purchase Line")
    var
        RoutingPage: TestPage "Prod. Order Routing";
    begin
        LibraryVariableStorage.Enqueue('A purchase order was created.\\Do you want to view it?');
        LibraryVariableStorage.Enqueue(false);
        RoutingPage.OpenView();
        RoutingPage.GoToRecord(Routing);
        RoutingPage.CreateSubcontracting.Invoke();
        RoutingPage.Close();
        LibraryVariableStorage.AssertEmpty();
        Line.Reset();
        Line.SetRange("Document Type", Line."Document Type"::Order);
        Line.SetRange("Prod. Order No.", ProductionLine."Prod. Order No.");
        Line.SetRange("Prod. Order Line No.", ProductionLine."Line No.");
        Line.SetRange("Routing No.", Routing."Routing No.");
        Line.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        Line.SetRange("Operation No.", Routing."Operation No.");
        Line.SetRange(Type, Line.Type::Item);
        Line.SetRange("No.", ProductionLine."Item No.");
        Line.SetRange("Variant Code", ProductionLine."Variant Code");
        Assert.AreEqual(1, Line.Count(), 'The native routing action must create exactly this second-line/variant purchase.');
        Line.FindFirst();
        Header.Get(Line."Document Type", Line."Document No.");
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(Line."Gen. Bus. Posting Group", Line."Gen. Prod. Posting Group");
    end;

    local procedure GetNativeReturnOriginal(PurchaseLine: Record "Purchase Line"; SourceLocation: Code[10]; var Line: Record "Transfer Line")
    begin
        Line.Reset();
        Line.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        Line.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        Line.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
        Line.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        Line.SetRange("Subc. Routing No.", PurchaseLine."Routing No.");
        Line.SetRange("Subc. Routing Reference No.", PurchaseLine."Routing Reference No.");
        Line.SetRange("Subc. Operation No.", PurchaseLine."Operation No.");
        Line.SetRange("Item No.", PurchaseLine."No.");
        Line.SetRange("Variant Code", PurchaseLine."Variant Code");
        Line.SetRange("Transfer-from Code", SourceLocation);
        Line.SetRange("Transfer-to Code", VRMain.Code);
        Line.SetRange("Transfer WIP Item", true);
        Line.SetRange("Derived From Line No.", 0);
        Line.SetRange("Subc. Return Order", true);
        Assert.AreEqual(1, Line.Count(), 'A return must have one original with its complete current-operation source identity.');
        Line.FindFirst();
        Assert.AreEqual('', Line."Prev. Operation No.", 'Native returns must not be patched into forward-shaped claims.');
    end;

    local procedure PrepareNativeUOMSerial(SourceBaseQuantity: Decimal; var PrecursorPurchase: Record "Purchase Header"; var SuccessorPurchase: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Forward: Record "Transfer Header";
    begin
        CreateVendorRoutingFixture(1, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        CreateVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PurchaseLine);
        CreateVendorRoutingForward(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, Forward);
        SetVendorRoutingWIPShipment(Forward, SourceBaseQuantity, SourceBaseQuantity);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, SourceBaseQuantity);
        CreateVendorRoutingPurchase(VRRouting[4], SuccessorPurchase, PurchaseLine);
    end;

    local procedure SetNativeProductionUOM(Factor: Decimal; DocumentQuantity: Decimal; var ItemUOM: Record "Item Unit of Measure")
    var
        ProductionLine: Record "Prod. Order Line";
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, VRItem."No.", Factor);
        ProductionLine.Get(VROrder.Status, VROrder."No.", VendorRoutingProductionLineNo(VRRouting[1]));
        ProductionLine.Validate("Unit of Measure Code", ItemUOM.Code);
        ProductionLine.Validate(Quantity, DocumentQuantity);
        ProductionLine.Modify(true);
        Assert.AreEqual(Factor, ProductionLine."Qty. per Unit of Measure", 'Public production validation must resolve the genuine item UOM.');
        Assert.AreEqual(12, ProductionLine."Quantity (Base)", 'Opt-in production UOM must preserve the twelve-base demand.');
    end;

    local procedure SetNativePurchaseUOM(var PurchaseLine: Record "Purchase Line"; Factor: Decimal; DocumentQuantity: Decimal; var ItemUOM: Record "Item Unit of Measure")
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, PurchaseLine."No.", Factor);
        PurchaseLine.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchaseLine.Validate(Quantity, DocumentQuantity);
        PurchaseLine.Modify(true);
        Assert.AreEqual(Factor, PurchaseLine."Qty. per Unit of Measure", 'Public purchase validation must resolve the genuine item UOM.');
        Assert.AreEqual(DocumentQuantity * Factor, PurchaseLine."Quantity (Base)", 'The native purchase must persist its intended base demand.');
    end;

    local procedure VerifyNativeForwardUOM(PurchaseLine: Record "Purchase Line"; PreviousOperation: Code[10]; SourceLocation: Code[10]; UOMCode: Code[10]; DocumentQuantity: Decimal; FullBase: Decimal; UnshippedBase: Decimal)
    var
        Line: Record "Transfer Line";
    begin
        FilterVendorRoutingOverlapTuple(Line, PurchaseLine, PreviousOperation, SourceLocation);
        Line.SetRange("Unit of Measure Code", UOMCode);
        Assert.AreEqual(1, Line.Count(), 'The native original must retain its exact purchase/production/routing/item/variant/source/UOM tuple.');
        Line.FindFirst();
        Assert.IsTrue(Line."Transfer WIP Item", 'Only a native WIP original may satisfy the physical claim.');
        Assert.AreEqual(DocumentQuantity, Line.Quantity, 'The persisted document quantity must be native-rounded, not bespoke downsized.');
        Assert.AreEqual(0, Line."Qty. per Unit of Measure", 'Intentional WIP stored factor zero must remain untouched.');
        Assert.AreEqual(0, Line."Quantity (Base)", 'Intentional WIP stored base zero is not the actual debit.');
        Assert.AreEqual(FullBase, Line.CalcBaseQty(Line.Quantity), 'Each original full quantity converts in its own real item UOM.');
        Assert.AreEqual(UnshippedBase, Line.CalcBaseQty(Line.Quantity - Line."Quantity Shipped"), 'Only original unshipped quantity claims physical stock.');
    end;

    local procedure VerifyNativeReturnUOM(PurchaseLine: Record "Purchase Line"; SourceLocation: Code[10]; UOMCode: Code[10]; DocumentQuantity: Decimal; FullBase: Decimal; UnshippedBase: Decimal)
    var
        Line: Record "Transfer Line";
    begin
        GetNativeReturnOriginal(PurchaseLine, SourceLocation, Line);
        Assert.AreEqual(UOMCode, Line."Unit of Measure Code", 'Native return insertion must use the production UOM.');
        Assert.AreEqual(DocumentQuantity, Line.Quantity, 'The persisted native return quantity must be exact.');
        Assert.AreEqual(0, Line."Qty. per Unit of Measure", 'Native WIP validation retains the intentional stored zero factor.');
        Assert.AreEqual(0, Line."Quantity (Base)", 'Stored base zero must not be used as the physical return claim.');
        Assert.AreEqual(FullBase, Line.CalcBaseQty(Line.Quantity), 'The native return full original converts in its own UOM.');
        Assert.AreEqual(UnshippedBase, Line.CalcBaseQty(Line.Quantity - Line."Quantity Shipped"), 'A derived or already shipped return is not a second spend.');
    end;

    local procedure AcceptVendorRoutingOtherOrder()
    var
        SelectedOrder: Record "Production Order";
        SelectedRouting: Record "Prod. Order Routing Line";
    begin
        SelectedOrder := VROrder;
        SelectedRouting := VRRouting[1];
        VROrder := VROtherOrder;
        FindVendorRoutingOperation(VROrder, SelectedRouting."Operation No.", VRRouting[1]);
        CalculateVendorRoutingSuggestions('');
        FindVendorRoutingSuggestion();
        ChangeWorksheetVendor(VRVendor[3]."No.", true, true);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[3]."No.");
        VROrder := SelectedOrder;
        VRRouting[1] := SelectedRouting;
        CalculateVendorRoutingSuggestions('');
        FindVendorRoutingSuggestion();
    end;

    local procedure PrepareVendorRoutingPredecessorReturn(ReturnQuantity: Decimal; ShippedQuantity: Decimal; var SuccessorPurchase: Record "Purchase Header"; var ReturnLine: Record "Transfer Line")
    var
        PrecursorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Forward: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
    begin
        CreateVendorRoutingFixture(1, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", false, true);
        VRReq.SetRecFilter();
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);
        FindVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PurchaseLine);
        VerifyVendorRoutingPurchase(PrecursorPurchase, PurchaseLine, VRRouting[1], VRVendor[2]);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        CreateVendorRoutingForward(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, Forward);
        LibraryWarehouse.PostTransferOrder(Forward, true, true);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, 12);
        CreateVendorRoutingPurchase(VRRouting[4], SuccessorPurchase, PurchaseLine);
        CreateVendorRoutingReturn(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, PrecursorPurchase."Subc. Location Code", true, ReturnHeader);
        ReturnLine.Reset();
        ReturnLine.SetRange("Document No.", ReturnHeader."No.");
        ReturnLine.SetRange("Derived From Line No.", 0);
        ReturnLine.SetRange("Transfer WIP Item", true);
        Assert.AreEqual(1, ReturnLine.Count(), 'The real return action must produce one original predecessor WIP line.');
        ReturnLine.FindFirst();
        VerifyVendorRoutingReturnClaim(ReturnLine, 12, 0);
        ReturnLine.Validate(Quantity, ReturnQuantity);
        ReturnLine.Validate("Qty. to Ship", ShippedQuantity);
        ReturnLine.Modify(true);
        case ShippedQuantity of
            4:
                LibraryWarehouse.PostTransferOrder(ReturnHeader, true, false);
        end;
        ReturnLine.Get(ReturnLine."Document No.", ReturnLine."Line No.");
    end;

    local procedure VerifyVendorRoutingReturnClaim(ReturnLine: Record "Transfer Line"; ExpectedQuantity: Decimal; ExpectedShipped: Decimal)
    var
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        ReturnLine.Get(ReturnLine."Document No.", ReturnLine."Line No.");
        FindVendorRoutingPurchase(VRRouting[1], Purchase, PurchaseLine);
        Assert.AreEqual(Purchase."No.", ReturnLine."Subc. Purch. Order No.", 'Return must retain its own predecessor purchase identity, not the successor purchase.');
        Assert.AreEqual(PurchaseLine."Line No.", ReturnLine."Subc. Purch. Order Line No.", 'Return purchase-line identity must be exact.');
        Assert.AreEqual(VROrder."No.", ReturnLine."Subc. Prod. Order No.", 'Return order identity must match the discovered source.');
        Assert.AreEqual(VendorRoutingProductionLineNo(VRRouting[1]), ReturnLine."Subc. Prod. Order Line No.", 'Return production line must match the physical tuple.');
        Assert.AreEqual(VRRouting[1]."Routing No.", ReturnLine."Subc. Routing No.", 'Return routing must match.');
        Assert.AreEqual(VRRouting[1]."Routing Reference No.", ReturnLine."Subc. Routing Reference No.", 'Return routing reference must match.');
        Assert.AreEqual('10', ReturnLine."Subc. Operation No.", 'A return spends its current operation, unlike a forward previous-operation claim.');
        Assert.AreEqual('', ReturnLine."Prev. Operation No.", 'The native return must not be rewritten into a forward-shaped fixture.');
        Assert.AreEqual(VRItem."No.", ReturnLine."Item No.", 'The parent WIP item must match.');
        Assert.AreEqual('', ReturnLine."Variant Code", 'The physical variant must match.');
        Assert.AreEqual(VRVendor[2]."Subc. Location Code", ReturnLine."Transfer-from Code", 'Physical stock after No is at S-new, not the old master location.');
        Assert.AreEqual(VRMain.Code, ReturnLine."Transfer-to Code", 'The original return is bound for the production location.');
        Assert.IsTrue(ReturnLine."Subc. Return Order", 'This must be a genuine native return.');
        Assert.IsTrue(ReturnLine."Transfer WIP Item", 'This must be native WIP, not a component claim.');
        Assert.AreEqual(0, ReturnLine."Derived From Line No.", 'Only the original reserves unshipped stock.');
        Assert.AreEqual(VRItem."Base Unit of Measure", ReturnLine."Unit of Measure Code", 'Return quantity must use the native one-to-one UOM.');
        Assert.AreEqual(0, ReturnLine."Qty. per Unit of Measure", 'Native WIP validation stores zero; physical quantity conversion uses the item UOM, not this stored factor.');
        Assert.AreEqual(0, ReturnLine."Quantity (Base)", 'Native WIP storage remains zero; it is not the physical claim.');
        Assert.AreEqual(ExpectedQuantity, ReturnLine.Quantity, 'Native original quantity must be exact.');
        Assert.AreEqual(ExpectedShipped, ReturnLine."Quantity Shipped", 'The native posted shipment must establish the shipped quantity.');
        Assert.AreEqual(ExpectedQuantity - ExpectedShipped, ReturnLine.Quantity - ReturnLine."Quantity Shipped", 'The physical claim is quantity minus shipped once.');
    end;

    local procedure SetVendorRoutingMaster(VendorNo: Code[20])
    begin
        VRWorkCenter[1].Get(VRWorkCenter[1]."No.");
        VRWorkCenter[1].Validate("Subcontractor No.", VendorNo);
        VRWorkCenter[1].Modify(true);
        ReloadVendorRoutingOperation(VRRouting[1]);
    end;

    local procedure ValidateVendorRoutingTaskPrice()
    begin
        ReloadVendorRoutingOperation(VRRouting[1]);
        VRRouting[1].Validate("Standard Task Code", VRTask.Code);
        VRRouting[1].Modify(true);
        ReloadVendorRoutingOperation(VRRouting[1]);
    end;

    local procedure VerifyVendorRoutingEligibility(var Routing: Record "Prod. Order Routing Line"; ExpectedVendor: Code[20]; ExpectedEnabled: Boolean)
    begin
        VerifyEffectiveVendor(Routing, ExpectedVendor);
        Routing.CalcFields(Subcontracting);
        Assert.AreEqual(ExpectedEnabled, Routing.Subcontracting, 'Public identity and native master-based eligibility must agree.');
    end;

    local procedure VerifyVendorRoutingRejectedChoice(BeforeState: Text)
    begin
        Assert.AreEqual(0, VRVendorQuestionCount, 'Native ineligible vendors must be rejected before the routing question.');
        VerifyWorksheetVendor(VRVendor[1]."No.", VRMain.Code);
        VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
        VerifyVendorRoutingUnchanged();
        Assert.AreEqual(BeforeState, VendorRoutingPurchaseState() + VendorRoutingArtifactState() + VendorRoutingRowVersions(), 'Vendor rejection must not change production, purchases, transfers or stock.');
    end;

    local procedure VendorRoutingSiblingVendors(): Text
    var
        Routing: Record "Prod. Order Routing Line";
        Management: Codeunit "Subc. Routing Factbox Mgmt.";
        Result: Text;
    begin
        Routing.SetRange(Status, VROrder.Status);
        Routing.SetRange("Prod. Order No.", VROrder."No.");
        Routing.FindSet();
        repeat
            if Routing.RecordId <> VRRouting[1].RecordId then
                Result += '|' + Format(Routing.RecordId) + '|' + Format(VendorRoutingProductionLineNo(Routing)) + '|' + Management.GetSubcontractorNo(Routing);
        until Routing.Next() = 0;
        exit(Result);
    end;

    local procedure VendorRoutingRowVersions(): Text
    var
        Routing: Record "Prod. Order Routing Line";
        Component: Record "Prod. Order Component";
        Result: Text;
    begin
        Routing.SetRange(Status, VROrder.Status);
        Routing.SetFilter("Prod. Order No.", '%1|%2', VROrder."No.", VROtherOrder."No.");
        Routing.FindSet();
        repeat
            Result += '|' + Format(Routing.RecordId) + '|' + Format(Routing.SystemRowVersion);
        until Routing.Next() = 0;
        Component.SetRange(Status, VROrder.Status);
        Component.SetFilter("Prod. Order No.", '%1|%2', VROrder."No.", VROtherOrder."No.");
        Component.FindSet();
        repeat
            Result += '|' + Format(Component.RecordId) + '|' + Format(Component.SystemRowVersion);
        until Component.Next() = 0;
        exit(Result);
    end;

    local procedure VendorRoutingPurchaseState(): Text
    var
        Header: Record "Purchase Header";
        Line: Record "Purchase Line";
        Result: Text;
    begin
        Result := StrSubstNo('|PH%1|PL%2', Header.Count(), Line.Count());
        Line.SetRange("Prod. Order No.", VROrder."No.");
        if Line.FindSet() then
            repeat
                Header.Get(Line."Document Type", Line."Document No.");
                Result += '|' + Format(Header.RecordId) + '|' + Format(Header.SystemRowVersion) +
                    '|' + Header."Buy-from Vendor No." + '|' + Header."Location Code" + '|' + Header."Subc. Location Code" +
                    '|' + Format(Line.RecordId) + '|' + Format(Line.SystemRowVersion) + '|' + Line."No." + '|' + Line."Variant Code" +
                    '|' + Format(Line.Quantity) + '|' + Format(Line."Quantity Received") + '|' + Line."Location Code" +
                    '|' + Line."Prod. Order No." + '|' + Format(Line."Prod. Order Line No.") +
                    '|' + Line."Routing No." + '|' + Format(Line."Routing Reference No.") + '|' + Line."Operation No.";
            until Line.Next() = 0;
        exit(Result);
    end;

    local procedure RunVendorRoutingMasterComponentFlow(Variant: Integer)
    var
        Component: Record "Prod. Order Component";
        BeforeComponent: Record "Prod. Order Component";
        Supply: Enum "Component Supply Method";
        ExpectedLocation: Code[10];
        Round: Integer;
    begin
        CreateVendorRoutingFixture(0, 12);
        ChangeWorksheetVendor(VRVendor[2]."No.", true, true);
        case Variant of
            1, 4:
                Supply := Supply::"Consignment at Vendor";
            2, 5:
                Supply := Supply::"Vendor-Supplied";
            3:
                Supply := Supply::"Transfer to Vendor";
        end;
        for Round := 1 to 2 do begin
            SetVendorRoutingMaster('');
            case Round of
                2:
                    SetVendorRoutingMaster(VRVendor[3]."No.");
            end;
            FilterVendorRoutingComponents(Component);
            Component.FindSet();
            repeat
                Component.Validate("Component Supply Method", Component."Component Supply Method"::"Transfer to Vendor");
                Component.Modify(true);
                case Variant of
                    3, 4, 5:
                        begin
                            Component.Validate("Routing Link Code", '');
                            Component.Modify(true);
                            Component.Validate("Component Supply Method", Supply);
                            Component.Modify(true);
                        end;
                end;
                Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
                BeforeComponent := Component;
                Assert.AreEqual(VRMain.Code, Component."Location Code", 'The focal validation must start with real MAIN components.');
                case Variant of
                    1, 2:
                        Component.Validate("Component Supply Method", Supply);
                    3, 4, 5:
                        Component.Validate("Routing Link Code", VRLink.Code);
                end;
                Component.Modify(true);
                Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
                ExpectedLocation := VRMain.Code;
                case Round of
                    2:
                        case Variant of
                            1, 2, 4, 5:
                                ExpectedLocation := VRVendor[2]."Subc. Location Code";
                        end;
                end;
                VerifyVendorRoutingMasterComponent(Component, BeforeComponent, ExpectedLocation, Variant);
            until Component.Next() = 0;
        end;
        VerifyVendorRoutingEligibility(VRRouting[1], VRVendor[2]."No.", true);
        FinishVendorRoutingFixture();
    end;

    local procedure VerifyVendorRoutingMasterComponent(Component: Record "Prod. Order Component"; BeforeComponent: Record "Prod. Order Component"; ExpectedLocation: Code[10]; Variant: Integer)
    begin
        Assert.AreEqual(ExpectedLocation, Component."Location Code", 'Only restored eligibility may resolve the retained vendor destination.');
        Assert.AreEqual(BeforeComponent."Bin Code", Component."Bin Code", 'Native bin semantics must survive.');
        Assert.AreEqual(BeforeComponent."Subc. Orig. Bin Code", Component."Subc. Orig. Bin Code", 'Saved bin must survive.');
        Assert.AreEqual(BeforeComponent."Flushing Method", Component."Flushing Method", 'Pick+Manual must survive.');
        Assert.AreEqual(BeforeComponent."Expected Qty. (Base)", Component."Expected Qty. (Base)", 'Demand must not change.');
        Assert.AreEqual(BeforeComponent."Quantity per", Component."Quantity per", 'BOM quantity must not change.');
        Assert.AreEqual(VRLink.Code, Component."Routing Link Code", 'The focal validation must retain the real production link.');
        case ExpectedLocation of
            VRMain.Code:
                Assert.AreEqual(BeforeComponent."Subc. Original Location Code", Component."Subc. Original Location Code", 'Disabled or Transfer-to-Vendor consumers must not change the original location.');
            else
                Assert.AreEqual(VRMain.Code, Component."Subc. Original Location Code", 'Restored non-transfer supply must remember MAIN.');
        end;
        case Variant of
            4, 5:
                begin
                    Assert.AreEqual(VRRouting[1]."Starting Date", Component."Due Date", 'Routing-link validation must keep native operation scheduling.');
                    Assert.AreEqual(VRRouting[1]."Starting Time", Component."Due Time", 'Routing-link validation must keep native operation time.');
                end;
        end;
    end;

    local procedure PrepareVendorRoutingOverlap(Quantity20: Decimal; Quantity30: Decimal; WithSecondLine: Boolean; SamePurchase: Boolean; var Purchase: Record "Purchase Header"; var FirstLine: Record "Purchase Line"; var SecondLine: Record "Purchase Line"; var Source20: Code[10]; var Source30: Code[10])
    var
        PrecursorPurchase: Record "Purchase Header";
        PrecursorLine: Record "Purchase Line";
        Transfer: Record "Transfer Header";
        Predecessor: Record "Prod. Order Routing Line";
        SourceQuantity: Decimal;
        i: Integer;
    begin
        CreateVendorRoutingFixture(2, 24);
        Source20 := VRVendor[1]."Subc. Location Code";
        Source30 := VRVendor[5]."Subc. Location Code";
        CreateVendorRoutingPurchase(VRRouting[4], Purchase, FirstLine);
        FirstLine.Validate(Quantity, 12);
        FirstLine.Validate("Planning Flexibility", FirstLine."Planning Flexibility"::None);
        FirstLine.Modify(true);
        if WithSecondLine then
            CreateVendorRoutingOverlapRemainder(FirstLine, SamePurchase, SecondLine);
        for i := 1 to 2 do begin
            if i = 1 then begin
                Predecessor := VRRouting[1];
                SourceQuantity := Quantity20;
            end else begin
                Predecessor := VRRouting[3];
                SourceQuantity := Quantity30;
            end;
            CreateVendorRoutingPurchase(Predecessor, PrecursorPurchase, PrecursorLine);
            CreateVendorRoutingForward(PrecursorPurchase);
            FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, Transfer);
            SetVendorRoutingWIPShipment(Transfer, SourceQuantity, SourceQuantity);
            LibraryWarehouse.PostTransferOrder(Transfer, true, true);
        end;
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, Quantity20);
        VerifyVendorRoutingWIP(VRRouting[3], Source30, false, Quantity30);
        // Native posting debits only registered subcontracting locations, even while the effective predecessor vendor moves.
        MoveVendorRoutingLocation(2, Source20);
        MoveVendorRoutingLocation(3, Source30);
        MoveVendorRoutingLocation(1, VREast.Code);
        MoveVendorRoutingLocation(5, VRWest.Code);
    end;

    local procedure CreateVendorRoutingOverlapRemainder(FirstLine: Record "Purchase Line"; SamePurchase: Boolean; var SecondLine: Record "Purchase Line")
    begin
        CalculateVendorRoutingSuggestions('');
        VRReq.SetRange("Operation No.", VRRouting[4]."Operation No.");
        Assert.IsTrue(VRReq.FindFirst(), 'The real calculation must produce the remaining service demand.');
        VRReq.TestField(Quantity, 12);
        VRReq.TestField("Action Message", VRReq."Action Message"::New);
        VRReq.TestField("Ref. Line No.", 0);
        if SamePurchase then begin
            VRReq.Validate("Ref. Order No.", FirstLine."Document No.");
            VRReq.Modify(true);
        end;
        VRReq.SetRecFilter();
        SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);
        SecondLine.SetRange("Document Type", FirstLine."Document Type");
        SecondLine.SetRange(Type, FirstLine.Type);
        SecondLine.SetRange("No.", FirstLine."No.");
        SecondLine.SetRange("Variant Code", FirstLine."Variant Code");
        SecondLine.SetRange("Prod. Order No.", FirstLine."Prod. Order No.");
        SecondLine.SetRange("Prod. Order Line No.", FirstLine."Prod. Order Line No.");
        SecondLine.SetRange("Routing No.", FirstLine."Routing No.");
        SecondLine.SetRange("Routing Reference No.", FirstLine."Routing Reference No.");
        SecondLine.SetRange("Operation No.", FirstLine."Operation No.");
        if SamePurchase then begin
            SecondLine.SetRange("Document No.", FirstLine."Document No.");
            SecondLine.SetFilter("Line No.", '>%1', FirstLine."Line No.");
        end else
            SecondLine.SetFilter("Document No.", '<>%1', FirstLine."Document No.");
        Assert.AreEqual(1, SecondLine.Count(), 'Native Carry Out must create one distinct service line, not enlarge the fixed first line.');
        SecondLine.FindFirst();
        SecondLine.TestField(Quantity, 12);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(SecondLine."Gen. Bus. Posting Group", SecondLine."Gen. Prod. Posting Group");
        FirstLine.Get(FirstLine."Document Type", FirstLine."Document No.", FirstLine."Line No.");
        FirstLine.TestField(Quantity, 12);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure RetainVendorRoutingOverlapClaim(PurchaseLine: Record "Purchase Line"; Source20: Code[10]; Source30: Code[10]; Quantity: Decimal; QtyToShip: Decimal)
    var
        Line: Record "Transfer Line";
    begin
        FilterVendorRoutingOverlapTuple(Line, PurchaseLine, '20', Source20);
        Assert.AreEqual(1, Line.Count(), 'Setup must narrow exactly one native predecessor-20 original.');
        Line.FindFirst();
        Line.Validate(Quantity, Quantity);
        Line.Validate("Qty. to Ship", QtyToShip);
        Line.Validate("Qty. to Receive", 0);
        Line.Modify(true);
        FilterVendorRoutingOverlapTuple(Line, PurchaseLine, '30', Source30);
        Assert.AreEqual(1, Line.Count(), 'Setup must remove exactly the unshipped predecessor-30 original.');
        Line.FindFirst();
        Line.Delete(true);
    end;

    local procedure RestoreVendorRoutingOverlapSources(Source20: Code[10]; Source30: Code[10])
    begin
        MoveVendorRoutingLocation(1, Source20);
        MoveVendorRoutingLocation(5, Source30);
        VerifyVendorRoutingWIP(VRRouting[1], Source20, false, 12);
    end;

    local procedure FilterVendorRoutingOverlapTuple(var Line: Record "Transfer Line"; PurchaseLine: Record "Purchase Line"; PreviousOperation: Code[10]; SourceLocation: Code[10])
    var
        Purchase: Record "Purchase Header";
    begin
        Purchase.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        Line.Reset();
        Line.SetRange("Subc. Purch. Order No.", PurchaseLine."Document No.");
        Line.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        Line.SetRange("Subc. Prod. Order No.", PurchaseLine."Prod. Order No.");
        Line.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        Line.SetRange("Subc. Routing No.", PurchaseLine."Routing No.");
        Line.SetRange("Subc. Routing Reference No.", PurchaseLine."Routing Reference No.");
        Line.SetRange("Subc. Operation No.", PurchaseLine."Operation No.");
        Line.SetRange("Item No.", PurchaseLine."No.");
        Line.SetRange("Variant Code", PurchaseLine."Variant Code");
        Line.SetRange("Prev. Operation No.", PreviousOperation);
        Line.SetRange("Transfer-from Code", SourceLocation);
        Line.SetRange("Transfer-to Code", Purchase."Subc. Location Code");
        Line.SetRange("Transfer WIP Item", true);
        Line.SetRange("Derived From Line No.", 0);
        Line.SetRange("Subc. Return Order", false);
    end;

    local procedure VerifyVendorRoutingOverlapTuple(PurchaseLine: Record "Purchase Line"; PreviousOperation: Code[10]; SourceLocation: Code[10]; ExpectedQuantity: Decimal; ExpectedUnshipped: Decimal)
    var
        Line: Record "Transfer Line";
    begin
        FilterVendorRoutingOverlapTuple(Line, PurchaseLine, PreviousOperation, SourceLocation);
        Line.CalcSums(Quantity, "Quantity Shipped");
        Assert.AreEqual(ExpectedQuantity, Line.Quantity, 'The exact persisted purchase-line/predecessor/source tuple must retain full-original coverage quantity.');
        Assert.AreEqual(ExpectedUnshipped, Line.Quantity - Line."Quantity Shipped", 'Only the unshipped part may claim physical source WIP again.');
    end;

    local procedure CreateVendorRoutingFixture(Topology: Integer; Quantity: Decimal)
    var
        BOMHeader: Record "Production BOM Header";
        BOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Template: Record "Req. Wksh. Template";
        InHouse: Record "Work Center";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        i: Integer;
        ComponentOperation: Code[10];
    begin
        VRSavedWorkDate := WorkDate();
        WorkDate(DMY2Date(1, 10, 2027));
        InitializeSummaryPurchasing();
        LibraryApplicationArea.EnablePremiumSetup();
        ApplicationAreaMgmtFacade.RefreshExperienceTierCurrentCompany();
        Clear(VRVendor);
        Clear(VRWorkCenter);
        Clear(VRRouting);
        Clear(VRComponentItem);
        Clear(VRReq);
        Clear(VRBatch);
        VRVendorQuestionCount := 0;
        VRCalculateCallbackCount := 0;
        VRCarryOutCallbackCount := 0;
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(VRMain);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(VREast);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(VRWest);
        for i := 1 to ArrayLen(VRVendor) do begin
            SubcontractingMgmtLibrary.CreateSubcontractor(VRVendor[i]);
            VRVendor[i].Validate("Location Code", '');
            VRVendor[i].Modify(true);
        end;
        VRVendor[2].Validate("Location Code", VREast.Code);
        VRVendor[2].Modify(true);
        CreateVendorRoutingWorkCenter(VRWorkCenter[1], VRVendor[1], 11);
        CreateVendorRoutingWorkCenter(VRWorkCenter[2], VRVendor[3], 33);
        CreateVendorRoutingWorkCenter(VRWorkCenter[3], VRVendor[5], 11);
        CreateVendorRoutingWorkCenter(VRWorkCenter[4], VRVendor[4], 11);
        LibraryManufacturing.CreateRoutingLink(VRLink);
        LibraryManufacturing.CreateStandardTask(VRTask);
        if Topology = 2 then begin
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Parallel);
            LibraryMfgManagement.CreateWorkCenterWithCalendar(InHouse, 0);
            LibraryManufacturing.CalculateWorkCenterCalendar(InHouse, WorkDate(), DMY2Date(31, 10, 2027));
            LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", InHouse."No.");
            RoutingLine.Validate("Next Operation No.", '20|30');
            RoutingLine.Modify(true);
            AddVendorRoutingMasterOperation(RoutingHeader, '20', VRWorkCenter[1]."No.", '10', '40', '');
            AddVendorRoutingMasterOperation(RoutingHeader, '30', VRWorkCenter[3]."No.", '10', '40', '');
            AddVendorRoutingMasterOperation(RoutingHeader, '40', VRWorkCenter[4]."No.", '20|30', '', VRLink.Code);
            ComponentOperation := '40';
        end else begin
            LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
            ComponentOperation := '10';
            if Topology = 1 then begin
                AddVendorRoutingMasterOperation(RoutingHeader, '10', VRWorkCenter[1]."No.", '', '40', '');
                AddVendorRoutingMasterOperation(RoutingHeader, '40', VRWorkCenter[4]."No.", '10', '', VRLink.Code);
                ComponentOperation := '40';
            end else
                AddVendorRoutingMasterOperation(RoutingHeader, '10', VRWorkCenter[1]."No.", '', '', VRLink.Code);
        end;
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        LibraryInventory.CreateItem(VRItem);
        VerifyVendorRoutingBaseUOM(VRItem);
        VRItem.Validate("Replenishment System", VRItem."Replenishment System"::"Prod. Order");
        VRItem.Validate("Routing No.", RoutingHeader."No.");
        VRItem.Validate("Scrap %", 0);
        VRItem.Modify(true);
        LibraryManufacturing.CreateProductionBOMHeader(BOMHeader, VRItem."Base Unit of Measure");
        for i := 1 to ArrayLen(VRComponentItem) do begin
            LibraryInventory.CreateItem(VRComponentItem[i]);
            VerifyVendorRoutingBaseUOM(VRComponentItem[i]);
            VRComponentItem[i].Validate("Flushing Method", VRComponentItem[i]."Flushing Method"::"Pick + Manual");
            VRComponentItem[i].Validate("Scrap %", 0);
            VRComponentItem[i].Modify(true);
            LibraryManufacturing.CreateProductionBOMLine(BOMHeader, BOMLine, '', BOMLine.Type::Item, VRComponentItem[i]."No.", 1);
            BOMLine.Validate("Routing Link Code", VRLink.Code);
            BOMLine.Validate("Component Supply Method", BOMLine."Component Supply Method"::"Transfer to Vendor");
            BOMLine.Validate("Scrap %", 0);
            BOMLine.Modify(true);
            LibraryInventory.PostPositiveAdjustment(VRComponentItem[i], VRMain.Code, '', '', 100, WorkDate(), 1);
        end;
        BOMHeader.Validate(Status, BOMHeader.Status::Certified);
        BOMHeader.Modify(true);
        VRItem.Validate("Production BOM No.", BOMHeader."No.");
        VRItem.Modify(true);
        CreateVendorRoutingPrice(VRVendor[1]."No.", VRWorkCenter[1]."No.", '', 11);
        CreateVendorRoutingPrice(VRVendor[1]."No.", VRWorkCenter[1]."No.", VRTask.Code, 11);
        CreateVendorRoutingPrice(VRVendor[2]."No.", VRWorkCenter[1]."No.", VRTask.Code, 22);
        CreateVendorRoutingPrice(VRVendor[3]."No.", VRWorkCenter[1]."No.", VRTask.Code, 33);
        CreateVendorRoutingPrice(VRVendor[3]."No.", VRWorkCenter[2]."No.", '', 33);
        CreateVendorRoutingOrder(VROrder, Quantity);
        CreateVendorRoutingOrder(VROtherOrder, Quantity);
        if Topology = 2 then begin
            FindVendorRoutingOperation(VROrder, '20', VRRouting[1]);
            FindVendorRoutingOperation(VROrder, '30', VRRouting[3]);
        end else
            FindVendorRoutingOperation(VROrder, '10', VRRouting[1]);
        FindVendorRoutingOperation(VROrder, ComponentOperation, VRRouting[4]);
        SubcontractingMgmtLibrary.CreateReqWkshTemplateAndName(Template, VRBatch);
        CalculateVendorRoutingSuggestions('');
        FindVendorRoutingSuggestion();
        VerifyVendorRoutingFixtureQuantities(Quantity);
        VRBusinessBefore := VendorRoutingBusinessState();
        VRMastersBefore := VendorRoutingMasterState();
    end;

    local procedure CreateVendorRoutingWorkCenter(var WorkCenter: Record "Work Center"; Vendor: Record Vendor; Price: Decimal)
    begin
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate(Name, CopyStr('Routing vendor ' + Vendor."No.", 1, MaxStrLen(WorkCenter.Name)));
        WorkCenter.Validate("Name 2", CopyStr('Second name ' + Vendor."No.", 1, MaxStrLen(WorkCenter."Name 2")));
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Direct Unit Cost", Price);
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, WorkDate(), DMY2Date(31, 10, 2027));
    end;

    local procedure VerifyVendorRoutingBaseUOM(Item: Record Item)
    var
        ItemUOM: Record "Item Unit of Measure";
    begin
        Item.TestField("Base Unit of Measure");
        ItemUOM.Get(Item."No.", Item."Base Unit of Measure");
        Assert.AreEqual(1, ItemUOM."Qty. per Unit of Measure", 'Native item creation must give one base unit per document unit.');
    end;

    local procedure VerifyVendorRoutingFixtureQuantities(Quantity: Decimal)
    var
        ProductionLine: Record "Prod. Order Line";
        Component: Record "Prod. Order Component";
    begin
        ProductionLine.Get(VROrder.Status, VROrder."No.", VendorRoutingProductionLineNo(VRRouting[1]));
        Assert.AreEqual(VRItem."Base Unit of Measure", ProductionLine."Unit of Measure Code", 'Production must use the native base UOM.');
        Assert.AreEqual(1, ProductionLine."Qty. per Unit of Measure", 'Production quantity must convert one-to-one.');
        Assert.AreEqual(Quantity, ProductionLine."Quantity (Base)", 'The refreshed production base quantity must equal the intended demand.');
        Assert.AreEqual(Quantity, VRReq.Quantity, 'The calculated service demand must equal the production base quantity without scrap.');
        FilterVendorRoutingComponents(Component);
        Component.FindSet();
        repeat
            Assert.AreEqual(1, Component."Quantity per", 'Both certified BOM links must retain quantity per one.');
            Assert.AreEqual(1, Component."Qty. per Unit of Measure", 'Each component must use one base unit per document unit.');
            Assert.AreEqual(Quantity, Component."Expected Qty. (Base)", 'Each refreshed component must require the complete production quantity.');
        until Component.Next() = 0;
    end;

    local procedure AddVendorRoutingMasterOperation(var Header: Record "Routing Header"; Operation: Code[10]; WorkCenterNo: Code[20]; Previous: Code[10]; NextOperation: Code[10]; LinkCode: Code[10])
    var
        Line: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingLine(Header, Line, '', Operation, Line.Type::"Work Center", WorkCenterNo);
        Line.Validate("Previous Operation No.", Previous);
        Line.Validate("Next Operation No.", NextOperation);
        Line.Validate("Routing Link Code", LinkCode);
        Line.Validate("Run Time", 1);
        Line.Validate("Scrap Factor %", 0);
        Line.Validate("Transfer WIP Item", true);
        Line.Modify(true);
    end;

    local procedure CreateVendorRoutingOrder(var ProductionOrder: Record "Production Order"; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, VRItem."No.", Quantity);
        ProductionOrder.Validate("Location Code", VRMain.Code);
        ProductionOrder.Validate("Due Date", DMY2Date(15, 10, 2027));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateVendorRoutingPrice(VendorNo: Code[20]; WorkCenterNo: Code[20]; TaskCode: Code[10]; UnitCost: Decimal)
    var
        Price: Record "Subcontractor Price";
    begin
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            Price, WorkCenterNo, VendorNo, VRItem."No.", TaskCode, '', DMY2Date(1, 1, 2027), VRItem."Base Unit of Measure", 0, '');
        Price.Validate("Direct Unit Cost", UnitCost);
        Price.Modify(true);
    end;

    local procedure CalculateVendorRoutingSuggestions(VendorFilter: Code[20])
    var
        OrderRouting: Record "Prod. Order Routing Line";
        WorkCenter: Record "Work Center";
        Calculate: Report "Subc. Calculate Subcontracts";
    begin
        Clear(VRReq);
        VRReq."Worksheet Template Name" := VRBatch."Worksheet Template Name";
        VRReq."Journal Batch Name" := VRBatch.Name;
        Calculate.SetWkShLine(VRReq);
        OrderRouting.SetRange("Prod. Order No.", VROrder."No.");
        Calculate.SetTableView(OrderRouting);
        if VendorFilter <> '' then begin
            WorkCenter.SetRange("Subcontractor No.", VendorFilter);
            Calculate.SetTableView(WorkCenter);
        end;
        Calculate.SetOnlyOperationsReadyToStart(false);
        Calculate.UseRequestPage(false);
        Calculate.RunModal();
        VRReq.SetRange("Worksheet Template Name", VRBatch."Worksheet Template Name");
        VRReq.SetRange("Journal Batch Name", VRBatch.Name);
        VRReq.SetRange("Prod. Order No.", VROrder."No.");
        VRReq.SetRange("Operation No.", VRRouting[1]."Operation No.");
    end;

    local procedure FindVendorRoutingSuggestion()
    begin
        VRReq.SetRange("Worksheet Template Name", VRBatch."Worksheet Template Name");
        VRReq.SetRange("Journal Batch Name", VRBatch.Name);
        VRReq.SetRange("Prod. Order No.", VROrder."No.");
        VRReq.SetRange("Operation No.", VRRouting[1]."Operation No.");
        Assert.IsTrue(VRReq.FindFirst(), 'The real calculation must produce the selected production operation.');
    end;

    local procedure ReloadVendorRoutingSuggestion()
    begin
        VRReq.Get(VRReq."Worksheet Template Name", VRReq."Journal Batch Name", VRReq."Line No.");
    end;

    local procedure OpenVendorRoutingWorksheet(var Worksheet: TestPage "Subc. Subcontracting Worksheet")
    begin
        ReloadVendorRoutingSuggestion();
        Worksheet.OpenEdit();
        Worksheet.CurrentJnlBatchName.SetValue(VRReq."Journal Batch Name");
        Worksheet.GoToRecord(VRReq);
        Worksheet.Filter.SetFilter("Line No.", Format(VRReq."Line No."));
    end;

    local procedure QueueVendorRoutingChoice(NewVendor: Code[20]; Reply: Boolean)
    var
        FactboxMgmt: Codeunit "Subc. Routing Factbox Mgmt.";
    begin
        ReloadVendorRoutingOperation(VRRouting[1]);
        LibraryVariableStorage.Enqueue(StrSubstNo(
            'Do you want to update the subcontractor on operation %1 of production order %2 from %3 to %4?',
            VRRouting[1]."Operation No.", VROrder."No.", FactboxMgmt.GetSubcontractorNo(VRRouting[1]), NewVendor));
        LibraryVariableStorage.Enqueue(Reply);
    end;

    local procedure ChangeWorksheetVendor(NewVendor: Code[20]; Reply: Boolean; ExpectQuestion: Boolean)
    var
        BeforeCount: Integer;
    begin
        BeforeCount := VRVendorQuestionCount;
        if ExpectQuestion then
            QueueVendorRoutingChoice(NewVendor, Reply);
        SetVendorRoutingWorksheetControl(NewVendor);
        if ExpectQuestion then
            Assert.AreEqual(BeforeCount + 1, VRVendorQuestionCount, 'Exactly one routing question must be asked.')
        else
            Assert.AreEqual(BeforeCount, VRVendorQuestionCount, 'This validation must not ask a routing question.');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure SetVendorRoutingWorksheetControl(NewVendor: Code[20])
    var
        Worksheet: TestPage "Subc. Subcontracting Worksheet";
    begin
        OpenVendorRoutingWorksheet(Worksheet);
        Worksheet."Vendor No.".SetValue(NewVendor);
        Worksheet.Close();
    end;

    local procedure VerifyWorksheetVendor(ExpectedVendor: Code[20]; ExpectedLocation: Code[10])
    begin
        ReloadVendorRoutingSuggestion();
        Assert.AreEqual(ExpectedVendor, VRReq."Vendor No.", 'Persisted worksheet choice must not be reverted.');
        Assert.AreEqual(ExpectedLocation, VRReq."Location Code", 'Vendor-only validation must preserve ordinary production location.');
    end;

    local procedure FindVendorRoutingOperation(ProductionOrder: Record "Production Order"; Operation: Code[10]; var Routing: Record "Prod. Order Routing Line")
    begin
        Clear(Routing);
        Routing.SetRange(Status, ProductionOrder.Status);
        Routing.SetRange("Prod. Order No.", ProductionOrder."No.");
        Routing.SetRange("Operation No.", Operation);
        Assert.IsTrue(Routing.FindFirst(), 'A native production routing operation must exist.');
    end;

    local procedure ReloadVendorRoutingOperation(var Routing: Record "Prod. Order Routing Line")
    begin
        Routing.Get(Routing.Status, Routing."Prod. Order No.", Routing."Routing Reference No.", Routing."Routing No.", Routing."Operation No.");
    end;

    local procedure VendorRoutingProductionLineNo(Routing: Record "Prod. Order Routing Line"): Integer
    var
        ProductionLine: Record "Prod. Order Line";
    begin
        ProductionLine.SetRange(Status, Routing.Status);
        ProductionLine.SetRange("Prod. Order No.", Routing."Prod. Order No.");
        ProductionLine.SetRange("Routing No.", Routing."Routing No.");
        ProductionLine.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        ProductionLine.SetRange("Item No.", VRItem."No.");
        ProductionLine.SetRange("Variant Code", '');
        Assert.AreEqual(1, ProductionLine.Count(), 'The routing must resolve to one exact native production line.');
        ProductionLine.FindFirst();
        exit(ProductionLine."Line No.");
    end;

    local procedure VerifyEffectiveVendor(var Routing: Record "Prod. Order Routing Line"; ExpectedVendor: Code[20])
    var
        Management: Codeunit "Subc. Routing Factbox Mgmt.";
        Factbox: TestPage "Subc. Routing Info Factbox";
    begin
        ReloadVendorRoutingOperation(Routing);
        Assert.AreEqual(ExpectedVendor, Management.GetSubcontractorNo(Routing), 'Public routing identity must reflect the effective operation vendor.');
        Factbox.OpenView();
        Factbox.GoToRecord(Routing);
        Factbox.ShowSubcontractor.AssertEquals(ExpectedVendor);
        Factbox.Close();
    end;

    local procedure CreatePreconfiguredConsignmentComponent(var Component: Record "Prod. Order Component")
    begin
        FilterVendorRoutingComponents(Component);
        Component.FindLast();
        Component.Validate("Component Supply Method", Component."Component Supply Method"::"Consignment at Vendor");
        Component.Modify(true);
        Component.Get(Component.Status, Component."Prod. Order No.", Component."Prod. Order Line No.", Component."Line No.");
        Assert.AreEqual(VRVendor[1]."Subc. Location Code", Component."Location Code", 'Native supply validation must put the preconfigured component at V1.');
        Assert.AreEqual(VRMain.Code, Component."Subc. Original Location Code", 'The preconfigured component must retain its genuine shop-floor origin.');
    end;

    local procedure VerifyPreconfiguredConsignmentComponent(var Component: Record "Prod. Order Component"; BeforeComponent: Record "Prod. Order Component"; ExpectedLocation: Code[10])
    begin
        Component.Get(BeforeComponent.Status, BeforeComponent."Prod. Order No.", BeforeComponent."Prod. Order Line No.", BeforeComponent."Line No.");
        Assert.AreEqual(ExpectedLocation, Component."Location Code", 'Consignment location must follow the accepted operation vendor only.');
        Assert.AreEqual(BeforeComponent."Subc. Original Location Code", Component."Subc. Original Location Code", 'Changing subcontractor must retain the shop-floor origin.');
        Assert.AreEqual(BeforeComponent."Subc. Orig. Bin Code", Component."Subc. Orig. Bin Code", 'Changing subcontractor must retain the original bin.');
        Assert.AreEqual(BeforeComponent."Flushing Method", Component."Flushing Method", 'Changing subcontractor must preserve flushing.');
        Assert.AreEqual(BeforeComponent."Component Supply Method", Component."Component Supply Method", 'Changing subcontractor must preserve supply method.');
        Assert.AreEqual(BeforeComponent."Quantity per", Component."Quantity per", 'Changing subcontractor must preserve BOM demand.');
        Assert.AreEqual(BeforeComponent."Expected Qty. (Base)", Component."Expected Qty. (Base)", 'Changing subcontractor must preserve expected base quantity.');
        Assert.AreEqual(BeforeComponent."Remaining Qty. (Base)", Component."Remaining Qty. (Base)", 'Changing subcontractor must preserve remaining base quantity.');
    end;

    local procedure FilterVendorRoutingComponents(var Component: Record "Prod. Order Component")
    begin
        Component.Reset();
        Component.SetRange(Status, VROrder.Status);
        Component.SetRange("Prod. Order No.", VROrder."No.");
        Component.SetRange("Prod. Order Line No.", VendorRoutingProductionLineNo(VRRouting[4]));
        Assert.AreEqual(2, Component.Count(), 'Both real BOM components must survive refresh.');
    end;

    local procedure VendorRoutingBusinessState(): Text
    var
        ProductionOrder: Record "Production Order";
        Line: Record "Prod. Order Line";
        Routing: Record "Prod. Order Routing Line";
        Result: Text;
    begin
        ProductionOrder.Get(VROrder.Status, VROrder."No.");
        Result := Format(ProductionOrder.RecordId) + '|' + Format(ProductionOrder.Quantity) + '|' + ProductionOrder."Location Code" +
            '|' + Format(ProductionOrder."Due Date") + '|' + Format(ProductionOrder."Starting Date") + '|' + Format(ProductionOrder."Ending Date");
        Line.SetRange(Status, VROrder.Status);
        Line.SetRange("Prod. Order No.", VROrder."No.");
        Line.FindSet();
        repeat
            Result += '|' + Format(Line.RecordId) + '|' + Line."Location Code" + '|' + Format(Line.Quantity) +
                '|' + Format(Line."Unit Cost") + '|' + Format(Line."Cost Amount") + '|' + Format(Line."Due Date") +
                '|' + Format(Line."Starting Date") + '|' + Format(Line."Starting Time") + '|' + Format(Line."Ending Date") + '|' + Format(Line."Ending Time");
        until Line.Next() = 0;
        Routing.SetRange(Status, VROrder.Status);
        Routing.SetRange("Prod. Order No.", VROrder."No.");
        Routing.FindSet();
        repeat
            Result += '|' + Format(Routing.RecordId) + '|' + Format(Routing.Type) + '|' + Routing."No." + '|' + Routing."Work Center No." +
                '|' + Routing."Routing Link Code" + '|' + Format(Routing."Starting Date") + '|' + Format(Routing."Starting Time") +
                '|' + Format(Routing."Ending Date") + '|' + Format(Routing."Ending Time") + '|' + Format(Routing."Run Time") +
                '|' + Format(Routing."Setup Time") + '|' + Format(Routing."Direct Unit Cost") + '|' + Format(Routing."Indirect Cost %") +
                '|' + Format(Routing."Overhead Rate") + '|' + Format(Routing."Expected Operation Cost Amt.") + '|' + Format(Routing."Expected Capacity Ovhd. Cost");
        until Routing.Next() = 0;
        exit(Result + VendorRoutingComponentState());
    end;

    local procedure VendorRoutingComponentState(): Text
    var
        Component: Record "Prod. Order Component";
        Result: Text;
    begin
        FilterVendorRoutingComponents(Component);
        Component.FindSet();
        repeat
            Result += '|' + Format(Component.RecordId) + '|' + Component."Item No." + '|' + Component."Location Code" +
                '|' + Component."Subc. Original Location Code" + '|' + Component."Bin Code" + '|' + Component."Subc. Orig. Bin Code" +
                '|' + Format(Component."Component Supply Method") + '|' + Format(Component."Flushing Method") +
                '|' + Component."Routing Link Code" + '|' + Format(Component."Expected Quantity") + '|' + Format(Component."Remaining Quantity") +
                '|' + Format(Component."Due Date") + '|' + Format(Component."Due Time");
        until Component.Next() = 0;
        exit(Result);
    end;

    local procedure VendorRoutingMasterState(): Text
    var
        WorkCenter: Record "Work Center";
        Routing: Record "Routing Line";
        BOM: Record "Production BOM Line";
        OtherRouting: Record "Prod. Order Routing Line";
        OtherOrder: Record "Production Order";
        Result: Text;
        i: Integer;
    begin
        for i := 1 to ArrayLen(VRWorkCenter) do begin
            WorkCenter.Get(VRWorkCenter[i]."No.");
            Result += '|' + WorkCenter."No." + '|' + WorkCenter."Subcontractor No." + '|' + Format(WorkCenter."Direct Unit Cost");
        end;
        Routing.SetRange("Routing No.", VRItem."Routing No.");
        Routing.FindSet();
        repeat
            Result += '|' + Format(Routing.RecordId) + '|' + Format(Routing.Type) + '|' + Routing."No." + '|' +
                Format(Routing."Transfer WIP Item") + '|' + Routing."Routing Link Code" + '|' + Format(Routing."Run Time");
        until Routing.Next() = 0;
        BOM.SetRange("Production BOM No.", VRItem."Production BOM No.");
        BOM.FindSet();
        repeat
            Result += '|' + Format(BOM.RecordId) + '|' + BOM."No." + '|' + BOM."Routing Link Code" +
                '|' + Format(BOM."Component Supply Method") + '|' + Format(BOM."Quantity per");
        until BOM.Next() = 0;
        OtherOrder.Get(VROtherOrder.Status, VROtherOrder."No.");
        Result += '|' + Format(OtherOrder.RecordId) + '|' + OtherOrder."Location Code" + '|' + Format(OtherOrder."Due Date");
        OtherRouting.SetRange(Status, OtherOrder.Status);
        OtherRouting.SetRange("Prod. Order No.", OtherOrder."No.");
        OtherRouting.FindSet();
        repeat
            Result += '|' + Format(OtherRouting.RecordId) + '|' + OtherRouting."No." + '|' +
                Format(OtherRouting."Starting Date") + '|' + Format(OtherRouting."Ending Date") + '|' + Format(OtherRouting."Direct Unit Cost");
        until OtherRouting.Next() = 0;
        exit(Result);
    end;

    local procedure VerifyVendorRoutingUnchanged()
    begin
        Assert.AreEqual(VRBusinessBefore, VendorRoutingBusinessState(), 'Vendor-only edits must preserve production dates, schedule, costs and component business state.');
        VerifyVendorRoutingMasters();
    end;

    local procedure VerifyVendorRoutingMasters()
    var
        Routing: Record "Prod. Order Routing Line";
    begin
        Assert.AreEqual(VRMastersBefore, VendorRoutingMasterState(), 'Masters and the independent order must not be rewritten.');
        FindVendorRoutingOperation(VROtherOrder, VRRouting[1]."Operation No.", Routing);
        VerifyEffectiveVendor(Routing, VRVendor[1]."No.");
    end;

    local procedure FinishVendorRoutingFixture()
    begin
        LibraryVariableStorage.AssertEmpty();
        WorkDate(VRSavedWorkDate);
    end;

    local procedure CreateVendorRoutingPurchase(Routing: Record "Prod. Order Routing Line"; var Header: Record "Purchase Header"; var Line: Record "Purchase Line")
    var
        RoutingPage: TestPage "Prod. Order Routing";
    begin
        LibraryVariableStorage.Enqueue('A purchase order was created.\\Do you want to view it?');
        LibraryVariableStorage.Enqueue(false);
        RoutingPage.OpenView();
        RoutingPage.GoToRecord(Routing);
        RoutingPage.CreateSubcontracting.Invoke();
        RoutingPage.Close();
        LibraryVariableStorage.AssertEmpty();
        FindVendorRoutingPurchase(Routing, Header, Line);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(Line."Gen. Bus. Posting Group", Line."Gen. Prod. Posting Group");
    end;

    local procedure FindVendorRoutingPurchase(Routing: Record "Prod. Order Routing Line"; var Header: Record "Purchase Header"; var Line: Record "Purchase Line")
    begin
        Clear(Line);
        Line.SetRange("Document Type", Line."Document Type"::Order);
        Line.SetRange("Prod. Order No.", Routing."Prod. Order No.");
        Line.SetRange("Prod. Order Line No.", VendorRoutingProductionLineNo(Routing));
        Line.SetRange("Routing No.", Routing."Routing No.");
        Line.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        Line.SetRange("Operation No.", Routing."Operation No.");
        Line.SetRange(Type, Line.Type::Item);
        Line.SetRange("No.", VRItem."No.");
        Line.SetRange("Variant Code", '');
        Assert.IsTrue(Line.FindFirst(), 'The selected native routing action must create its purchase line.');
        Header.Get(Line."Document Type", Line."Document No.");
    end;

    local procedure VerifyVendorRoutingPurchase(Header: Record "Purchase Header"; Line: Record "Purchase Line"; Routing: Record "Prod. Order Routing Line"; Vendor: Record Vendor)
    begin
        Assert.AreEqual(Vendor."No.", Header."Buy-from Vendor No.", 'The selected vendor must buy the subcontract service.');
        Assert.AreEqual(VRMain.Code, Header."Location Code", 'Purchase ordinary receiving location must remain MAIN.');
        Assert.AreEqual(Vendor."Subc. Location Code", Header."Subc. Location Code", 'Subcontracting destination is separate from ordinary location.');
        Assert.AreEqual(VRMain.Code, Line."Location Code", 'Service line must keep production location.');
        Assert.AreEqual(12, Line.Quantity, 'The complete selected demand must be purchased.');
        Assert.AreEqual(Routing."Prod. Order No.", Line."Prod. Order No.", 'Purchase must retain its exact production order.');
        Assert.AreEqual(VendorRoutingProductionLineNo(Routing), Line."Prod. Order Line No.", 'Purchase must retain its exact production line.');
        Assert.AreEqual(Routing."Routing Reference No.", Line."Routing Reference No.", 'Purchase must retain its routing reference.');
        Assert.AreEqual(Routing."Routing No.", Line."Routing No.", 'Purchase must retain its routing.');
        Assert.AreEqual(Routing."Operation No.", Line."Operation No.", 'Purchase must retain its exact operation.');
    end;

    local procedure EnsureVendorRoutingRoute(FromLocation: Code[10]; ToLocation: Code[10])
    var
        Route: Record "Transfer Route";
        Transit: Record Location;
    begin
        if FromLocation = ToLocation then
            exit;
        if Route.Get(FromLocation, ToLocation) then
            exit;
        LibraryWarehouse.CreateInTransitLocation(Transit);
        LibraryWarehouse.CreateAndUpdateTransferRoute(Route, FromLocation, ToLocation, Transit.Code, '', '');
    end;

    local procedure CreateVendorRoutingForward(Header: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
        WIP: Record "Subcontractor WIP Ledger Entry";
        i: Integer;
    begin
        EnsureVendorRoutingRoute(VRMain.Code, Header."Subc. Location Code");
        for i := 1 to ArrayLen(VRVendor) do
            if VRVendor[i]."Subc. Location Code" <> '' then
                EnsureVendorRoutingRoute(VRVendor[i]."Subc. Location Code", Header."Subc. Location Code");
        WIP.SetRange("Prod. Order No.", VROrder."No.");
        WIP.SetRange("Prod. Order Status", VROrder.Status);
        WIP.SetRange("Prod. Order Line No.", VendorRoutingProductionLineNo(VRRouting[4]));
        WIP.SetRange("Routing No.", VRRouting[4]."Routing No.");
        WIP.SetRange("Routing Reference No.", VRRouting[4]."Routing Reference No.");
        WIP.SetRange("Item No.", VRItem."No.");
        WIP.SetRange("Variant Code", '');
        WIP.SetRange("In Transit", false);
        WIP.SetFilter("Quantity (Base)", '>0');
        if WIP.FindSet() then
            repeat
                EnsureVendorRoutingRoute(WIP."Location Code", Header."Subc. Location Code");
            until WIP.Next() = 0;
        VRDisplayedPurchase := Header."No.";
        VRDisplayedReturn := false;
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(Header);
        PurchaseOrder.CreateTransfOrdToSubcontractor.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure CreateVendorRoutingReturn(Header: Record "Purchase Header")
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        EnsureVendorRoutingRoute(Header."Subc. Location Code", VRMain.Code);
        VRDisplayedPurchase := Header."No.";
        VRDisplayedReturn := true;
        PurchaseOrder.OpenView();
        PurchaseOrder.GoToRecord(Header);
        PurchaseOrder.CreateReturnFromSubcontractor.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure FindVendorRoutingTransfer(Purchase: Record "Purchase Header"; FromLocation: Code[10]; ReturnOrder: Boolean; var Header: Record "Transfer Header")
    begin
        Clear(Header);
        Header.SetRange("Subcontr. Purch. Order No.", Purchase."No.");
        Header.SetRange("Subc. Return Order", ReturnOrder);
        Header.SetRange("Transfer-from Code", FromLocation);
        Assert.IsTrue(Header.FindFirst(), 'The native action must create the exact source transfer.');
    end;

    local procedure VerifyVendorRoutingTransferContents(Header: Record "Transfer Header"; ComponentQuantity: Decimal; WIPQuantity: Decimal)
    var
        Line: Record "Transfer Line";
        i: Integer;
    begin
        Line.SetRange("Document No.", Header."No.");
        Line.SetRange("Derived From Line No.", 0);
        Assert.AreEqual(3, Line.Count(), 'Exactly two component originals and one WIP original are required.');
        Line.SetRange("Subc. Purch. Order No.", Header."Subcontr. Purch. Order No.");
        Line.SetRange("Subc. Prod. Order No.", VROrder."No.");
        Line.SetRange("Subc. Prod. Order Line No.", VendorRoutingProductionLineNo(VRRouting[1]));
        Line.SetRange("Subc. Routing No.", VRRouting[1]."Routing No.");
        Line.SetRange("Subc. Routing Reference No.", VRRouting[1]."Routing Reference No.");
        Line.SetRange("Subc. Operation No.", VRRouting[1]."Operation No.");
        Line.SetRange("Variant Code", '');
        Line.SetRange("Transfer-from Code", Header."Transfer-from Code");
        Line.SetRange("Transfer-to Code", Header."Transfer-to Code");
        Line.SetRange("Subc. Return Order", Header."Subc. Return Order");
        Assert.AreEqual(3, Line.Count(), 'All three originals must belong to this exact operation, production line and direction.');
        for i := 1 to ArrayLen(VRComponentItem) do begin
            Line.SetRange("Item No.", VRComponentItem[i]."No.");
            Line.FindFirst();
            Assert.AreEqual(ComponentQuantity, Line.Quantity, 'Each real component must have the exact proposed quantity.');
            Assert.AreEqual(VROrder."No.", Line."Subc. Prod. Order No.", 'Component transfer must retain production identity.');
        end;
        Line.SetRange("Item No.", VRItem."No.");
        Line.FindFirst();
        Assert.IsTrue(Line."Transfer WIP Item", 'Parent item must be a native WIP transfer.');
        Assert.AreEqual(WIPQuantity, Line.Quantity, 'WIP retains its independent native return policy.');
        Assert.AreEqual(0, Line."Quantity (Base)", 'Native WIP quantity-base storage remains zero; document UOM is used.');
    end;

    local procedure VerifyVendorRoutingPostedTransfer(Header: Record "Transfer Header"; FromLocation: Code[10]; ToLocation: Code[10]; ComponentQuantity: Decimal; WIPQuantity: Decimal)
    var
        Shipment: Record "Transfer Shipment Line";
        Receipt: Record "Transfer Receipt Line";
        Purchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        FindVendorRoutingPurchase(VRRouting[1], Purchase, PurchaseLine);
        Shipment.SetRange("Transfer Order No.", Header."No.");
        Receipt.SetRange("Transfer Order No.", Header."No.");
        Shipment.SetRange("Subc. Purch. Order No.", Purchase."No.");
        Receipt.SetRange("Subc. Purch. Order No.", Purchase."No.");
        Shipment.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        Receipt.SetRange("Subc. Purch. Order Line No.", PurchaseLine."Line No.");
        Shipment.SetRange("Subc. Prod. Order No.", VROrder."No.");
        Receipt.SetRange("Subc. Prod. Order No.", VROrder."No.");
        Shipment.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        Receipt.SetRange("Subc. Prod. Order Line No.", PurchaseLine."Prod. Order Line No.");
        Shipment.SetRange("Subc. Routing No.", PurchaseLine."Routing No.");
        Receipt.SetRange("Subc. Routing No.", PurchaseLine."Routing No.");
        Shipment.SetRange("Subc. Routing Reference No.", PurchaseLine."Routing Reference No.");
        Receipt.SetRange("Subc. Routing Reference No.", PurchaseLine."Routing Reference No.");
        Shipment.SetRange("Subc. Operation No.", PurchaseLine."Operation No.");
        Receipt.SetRange("Subc. Operation No.", PurchaseLine."Operation No.");
        Shipment.SetRange("Subc. Return Order", Header."Subc. Return Order");
        Receipt.SetRange("Subc. Return Order", Header."Subc. Return Order");
        Shipment.SetRange("Transfer-from Code", FromLocation);
        Receipt.SetRange("Transfer-from Code", FromLocation);
        Shipment.SetRange("Transfer-to Code", ToLocation);
        Receipt.SetRange("Transfer-to Code", ToLocation);
        Shipment.SetRange("In-Transit Code", Header."In-Transit Code");
        Receipt.SetRange("In-Transit Code", Header."In-Transit Code");
        Shipment.SetRange("Variant Code", '');
        Receipt.SetRange("Variant Code", '');
        Assert.AreEqual(3, Shipment.Count(), 'All three native shipment lines must retain full purchase/production/routing identity.');
        Assert.AreEqual(3, Receipt.Count(), 'All three native receipt lines must retain full purchase/production/routing identity.');
        Shipment.SetRange("Transfer WIP Item", false);
        Receipt.SetRange("Transfer WIP Item", false);
        for i := 1 to ArrayLen(VRComponentItem) do begin
            Shipment.SetRange("Item No.", VRComponentItem[i]."No.");
            Receipt.SetRange("Item No.", VRComponentItem[i]."No.");
            Shipment.CalcSums(Quantity);
            Receipt.CalcSums(Quantity);
            Assert.AreEqual(ComponentQuantity, Shipment.Quantity, 'A native shipment must contain each component.');
            Assert.AreEqual(ComponentQuantity, Receipt.Quantity, 'A native receipt must contain each component.');
        end;
        Shipment.SetRange("Item No.", VRItem."No.");
        Receipt.SetRange("Item No.", VRItem."No.");
        Shipment.SetRange("Transfer WIP Item", true);
        Receipt.SetRange("Transfer WIP Item", true);
        Assert.AreEqual(1, Shipment.Count(), 'Exactly one posted WIP shipment must belong to the full operation identity.');
        Assert.AreEqual(1, Receipt.Count(), 'Exactly one posted WIP receipt must belong to the full operation identity.');
        Shipment.FindFirst();
        Receipt.FindFirst();
        Assert.AreEqual(WIPQuantity, Shipment.Quantity, 'Posted WIP shipment quantity must be exact.');
        Assert.AreEqual(WIPQuantity, Receipt.Quantity, 'Posted WIP receipt quantity must be exact.');
        Assert.AreEqual(FromLocation, Shipment."Transfer-from Code", 'Posted source is physical, not ordinary vendor location.');
        Assert.AreEqual(ToLocation, Receipt."Transfer-to Code", 'Posted destination must be the selected subcontract location.');
        Assert.AreEqual(VROrder."No.", Shipment."Subc. Prod. Order No.", 'Native posted lineage must retain the order.');
        Assert.AreEqual(Shipment."Trans. Order Line No.", Receipt."Line No.", 'Shipment and receipt must join the same original transfer line.');
        Assert.AreNotEqual('', Header."In-Transit Code", 'This flow must exercise genuine routed shipment and receipt.');
        VerifyVendorRoutingWIPDocument(VRRouting[1], Shipment."Document No.", Shipment."Line No.", Header."In-Transit Code", true, WIPQuantity);
        VerifyVendorRoutingWIPDocument(VRRouting[1], Receipt."Document No.", Receipt."Line No.", Header."In-Transit Code", true, -WIPQuantity);
        VerifyVendorRoutingWIP(VRRouting[1], Header."In-Transit Code", true, 0);
        if Header."Subc. Return Order" then begin
            VerifyVendorRoutingWIPDocument(VRRouting[1], Shipment."Document No.", Shipment."Line No.", FromLocation, false, -WIPQuantity);
            VerifyVendorRoutingWIPDocument(VRRouting[1], Receipt."Document No.", Receipt."Line No.", ToLocation, false, 0);
            VerifyVendorRoutingWIP(VRRouting[1], FromLocation, false, 0);
            VerifyVendorRoutingWIP(VRRouting[1], ToLocation, false, 0);
        end else begin
            VerifyVendorRoutingWIPDocument(VRRouting[1], Shipment."Document No.", Shipment."Line No.", FromLocation, false, 0);
            VerifyVendorRoutingWIPDocument(VRRouting[1], Receipt."Document No.", Receipt."Line No.", ToLocation, false, WIPQuantity);
            VerifyVendorRoutingWIP(VRRouting[1], FromLocation, false, 0);
            VerifyVendorRoutingWIP(VRRouting[1], ToLocation, false, WIPQuantity);
        end;
    end;

    local procedure VerifyVendorRoutingComponentNet(LocationCode: Code[10]; Expected: Decimal)
    var
        Entry: Record "Item Ledger Entry";
        i: Integer;
    begin
        for i := 1 to ArrayLen(VRComponentItem) do begin
            Entry.Reset();
            Entry.SetRange("Item No.", VRComponentItem[i]."No.");
            Entry.SetRange("Subc. Prod. Order No.", VROrder."No.");
            Entry.SetRange("Subc. Prod. Order Line No.", VendorRoutingProductionLineNo(VRRouting[1]));
            Entry.SetRange("Variant Code", '');
            Entry.SetRange("Entry Type", Entry."Entry Type"::Transfer);
            Entry.SetRange("Location Code", LocationCode);
            Entry.CalcSums(Quantity);
            Assert.AreEqual(Expected, Entry.Quantity, 'Each component must have its exact signed native transfer net.');
        end;
    end;

    local procedure VerifyVendorRoutingWIP(Routing: Record "Prod. Order Routing Line"; LocationCode: Code[10]; InTransit: Boolean; Expected: Decimal)
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
    begin
        FilterVendorRoutingWIP(Entry, Routing, LocationCode, InTransit);
        Entry.CalcSums("Quantity (Base)");
        Assert.AreEqual(Expected, Entry."Quantity (Base)", 'Native WIP must retain exact production-line/operation/location/transit identity.');
    end;

    local procedure FilterVendorRoutingWIP(var Entry: Record "Subcontractor WIP Ledger Entry"; Routing: Record "Prod. Order Routing Line"; LocationCode: Code[10]; InTransit: Boolean)
    begin
        Entry.Reset();
        Entry.SetRange("Prod. Order Status", Routing.Status);
        Entry.SetRange("Prod. Order No.", Routing."Prod. Order No.");
        Entry.SetRange("Prod. Order Line No.", VendorRoutingProductionLineNo(Routing));
        Entry.SetRange("Routing No.", Routing."Routing No.");
        Entry.SetRange("Routing Reference No.", Routing."Routing Reference No.");
        Entry.SetRange("Operation No.", Routing."Operation No.");
        Entry.SetRange("Item No.", VRItem."No.");
        Entry.SetRange("Variant Code", '');
        Entry.SetRange("Location Code", LocationCode);
        Entry.SetRange("In Transit", InTransit);
    end;

    local procedure VerifyVendorRoutingWIPDocument(Routing: Record "Prod. Order Routing Line"; DocumentNo: Code[20]; DocumentLineNo: Integer; LocationCode: Code[10]; InTransit: Boolean; Expected: Decimal)
    var
        Entry: Record "Subcontractor WIP Ledger Entry";
    begin
        FilterVendorRoutingWIP(Entry, Routing, LocationCode, InTransit);
        Entry.SetRange("Document Type", Entry."Document Type"::"Transfer Order");
        Entry.SetRange("Document No.", DocumentNo);
        Entry.SetRange("Document Line No.", DocumentLineNo);
        if Expected = 0 then
            Assert.RecordIsEmpty(Entry)
        else begin
            Assert.AreEqual(1, Entry.Count(), 'The signed WIP leg must come from this exact native posted document line.');
            Entry.FindFirst();
            if Expected > 0 then
                Assert.AreEqual(Entry."Entry Type"::"Positive Adjustment", Entry."Entry Type", 'The incoming leg must be positive.')
            else
                Assert.AreEqual(Entry."Entry Type"::"Negative Adjustment", Entry."Entry Type", 'The outgoing leg must be negative.');
        end;
        Entry.CalcSums("Quantity (Base)");
        Assert.AreEqual(Expected, Entry."Quantity (Base)", 'The native posted WIP leg must have its exact signed base quantity.');
    end;

    local procedure MoveVendorRoutingLocation(VendorIndex: Integer; LocationCode: Code[10])
    begin
        VRVendor[VendorIndex].Get(VRVendor[VendorIndex]."No.");
        VRVendor[VendorIndex].Validate("Subc. Location Code", LocationCode);
        VRVendor[VendorIndex].Modify(true);
    end;

    local procedure VendorRoutingArtifactState(): Text
    var
        Header: Record "Transfer Header";
        Line: Record "Transfer Line";
        Shipment: Record "Transfer Shipment Line";
        Receipt: Record "Transfer Receipt Line";
        DirectLine: Record "Direct Trans. Line";
        WIP: Record "Subcontractor WIP Ledger Entry";
        ItemEntry: Record "Item Ledger Entry";
        Result: Text;
    begin
        Result := StrSubstNo('|H%1|L%2|S%3|R%4|D%5|W%6|I%7', Header.Count(), Line.Count(), Shipment.Count(), Receipt.Count(), DirectLine.Count(), WIP.Count(), ItemEntry.Count());
        Line.SetRange("Subc. Prod. Order No.", VROrder."No.");
        if Line.FindSet() then
            repeat
                Result += '|' + Format(Line.RecordId) + '|' + Format(Line.Quantity) + '|' + Format(Line."Quantity Shipped") +
                    '|' + Format(Line."Quantity Received") + '|' + Line."Transfer-from Code" + '|' + Line."Transfer-to Code" +
                    '|' + Line."Prev. Operation No." + '|' + Format(Line."Derived From Line No.");
            until Line.Next() = 0;
        exit(Result + VendorRoutingComponentState());
    end;

    local procedure ExpectVendorRoutingNoCreation(Purchase: Record "Purchase Header"; EvidenceOperation: Code[10]; EvidenceLocation: Code[10]; EvidenceDocument: Code[20])
    var
        BeforeState: Text;
    begin
        BeforeState := VendorRoutingArtifactState();
        asserterror CreateVendorRoutingForward(Purchase);
        Assert.ExpectedErrorCode('Dialog');
        if EvidenceOperation <> '' then begin
            Assert.ExpectedError(EvidenceOperation);
            Assert.ExpectedError(EvidenceLocation);
            if EvidenceDocument <> '' then
                Assert.ExpectedError(EvidenceDocument);
        end else
            Assert.ExpectedError('covered');
        Assert.AreEqual(BeforeState, VendorRoutingArtifactState(), 'Failure/covered demand must leave zero new or changed transfer, posted, ledger or component artifacts.');
    end;

    local procedure SetVendorRoutingWIPShipment(Header: Record "Transfer Header"; Quantity: Decimal; QtyToShip: Decimal)
    var
        Line: Record "Transfer Line";
    begin
        Line.SetRange("Document No.", Header."No.");
        Line.SetRange("Derived From Line No.", 0);
        Line.SetRange("Transfer WIP Item", true);
        Line.FindSet();
        repeat
            if Quantity >= 0 then
                Line.Validate(Quantity, Quantity);
            Line.Validate("Qty. to Ship", QtyToShip);
            Line.Modify(true);
        until Line.Next() = 0;
    end;

    local procedure SetVendorRoutingWIPReceipt(Header: Record "Transfer Header"; QtyToReceive: Decimal)
    var
        Line: Record "Transfer Line";
    begin
        Header.TestField("Direct Transfer", false);
        Header.TestField("In-Transit Code");
        Line.SetRange("Document No.", Header."No.");
        Line.SetRange("Derived From Line No.", 0);
        Line.SetRange("Transfer WIP Item", true);
        Line.FindSet();
        repeat
            Assert.IsTrue(Line."Qty. in Transit" >= QtyToReceive, 'Native shipment must establish sufficient transit before partial receipt validation.');
            Line.Validate("Qty. to Receive", QtyToReceive);
            Line.Modify(true);
        until Line.Next() = 0;
    end;

    local procedure PostVendorRoutingDirect(var Header: Record "Transfer Header"; SourceDebitExpected: Boolean)
    var
        OriginalLine: Record "Transfer Line";
        DirectHeader: Record "Direct Trans. Header";
        DirectLine: Record "Direct Trans. Line";
        Routing: Record "Prod. Order Routing Line";
        SourceRouting: Record "Prod. Order Routing Line";
        DirectPost: Codeunit "TransferOrder-Post Transfer";
    begin
        Header.Validate("Direct Transfer", true);
        Header.Validate("Direct Transfer Posting", Header."Direct Transfer Posting"::"Direct Transfer");
        Header.Modify(true);
        Header.TestField("In-Transit Code", '');
        OriginalLine.SetRange("Document No.", Header."No.");
        OriginalLine.SetRange("Derived From Line No.", 0);
        OriginalLine.SetRange("Transfer WIP Item", true);
        Assert.AreEqual(1, OriginalLine.Count(), 'Each direct boundary posts one exact predecessor WIP original.');
        OriginalLine.FindFirst();
        Routing.Get(Routing.Status::Released, OriginalLine."Subc. Prod. Order No.", OriginalLine."Subc. Routing Reference No.", OriginalLine."Subc. Routing No.", OriginalLine."Subc. Operation No.");
        SourceRouting := Routing;
        if OriginalLine."Prev. Operation No." <> '' then
            SourceRouting.Get(Routing.Status, Routing."Prod. Order No.", Routing."Routing Reference No.", Routing."Routing No.", OriginalLine."Prev. Operation No.");
        DirectPost.SetHideValidationDialog(true);
        DirectPost.Run(Header);
        DirectHeader.SetRange("Transfer Order No.", Header."No.");
        Assert.AreEqual(1, DirectHeader.Count(), 'The native direct-posting API must create its actual direct document.');
        DirectHeader.FindFirst();
        DirectLine.Get(DirectHeader."No.", OriginalLine."Line No.");
        Assert.IsTrue(DirectLine."Transfer WIP Item", 'The native direct document must identify WIP.');
        Assert.AreEqual(OriginalLine.Quantity, DirectLine.Quantity, 'The direct line must post the full original quantity.');
        Assert.AreEqual(OriginalLine."Item No.", DirectLine."Item No.", 'Direct posting must retain the parent item.');
        Assert.AreEqual(OriginalLine."Variant Code", DirectLine."Variant Code", 'Direct posting must retain the variant.');
        Assert.AreEqual(OriginalLine."Subc. Purch. Order No.", DirectLine."Subcontr. Purch. Order No.", 'Direct posting must retain the selected purchase.');
        Assert.AreEqual(OriginalLine."Subc. Purch. Order Line No.", DirectLine."Subcontr. PO Line No.", 'Direct posting must retain the purchase line.');
        Assert.AreEqual(OriginalLine."Subc. Prod. Order No.", DirectLine."Prod. Order No.", 'Direct posting must retain the production order.');
        Assert.AreEqual(VendorRoutingProductionLineNo(Routing), DirectLine."Prod. Order Line No.", 'Direct posting must retain the exact production line.');
        Assert.AreEqual(Routing."Routing No.", DirectLine."Routing No.", 'Direct posting must retain the routing.');
        Assert.AreEqual(Routing."Routing Reference No.", DirectLine."Routing Reference No.", 'Direct posting must retain the routing reference.');
        Assert.AreEqual(Routing."Operation No.", DirectLine."Operation No.", 'Direct posting must retain the current operation.');
        Assert.AreEqual(Header."Transfer-from Code", DirectLine."Transfer-from Code", 'Direct posting must retain the physical source.');
        Assert.AreEqual(Header."Transfer-to Code", DirectLine."Transfer-to Code", 'Direct posting must retain the destination.');
        VerifyVendorRoutingWIPDocument(Routing, DirectLine."Document No.", DirectLine."Line No.", Header."Transfer-to Code", false, OriginalLine.Quantity);
        if SourceDebitExpected then
            VerifyVendorRoutingWIPDocument(SourceRouting, DirectLine."Document No.", DirectLine."Line No.", Header."Transfer-from Code", false, -OriginalLine.Quantity)
        else
            VerifyVendorRoutingWIPDocument(SourceRouting, DirectLine."Document No.", DirectLine."Line No.", Header."Transfer-from Code", false, 0);
    end;

    local procedure VerifyVendorRoutingTuple(Purchase: Record "Purchase Header"; PreviousOperation: Code[10]; FromLocation: Code[10]; ExpectedQuantity: Decimal)
    var
        Line: Record "Transfer Line";
    begin
        Line.SetRange("Subc. Purch. Order No.", Purchase."No.");
        Line.SetRange("Subc. Prod. Order No.", VROrder."No.");
        Line.SetRange("Subc. Prod. Order Line No.", VendorRoutingProductionLineNo(VRRouting[4]));
        Line.SetRange("Subc. Routing No.", VRRouting[4]."Routing No.");
        Line.SetRange("Subc. Routing Reference No.", VRRouting[4]."Routing Reference No.");
        Line.SetRange("Subc. Operation No.", VRRouting[4]."Operation No.");
        Line.SetRange("Prev. Operation No.", PreviousOperation);
        Line.SetRange("Transfer-from Code", FromLocation);
        Line.SetRange("Transfer-to Code", Purchase."Subc. Location Code");
        Line.SetRange("Transfer WIP Item", true);
        Line.SetRange("Derived From Line No.", 0);
        Line.SetRange("Subc. Return Order", false);
        Line.SetRange("Item No.", VRItem."No.");
        Line.SetRange("Variant Code", '');
        Line.CalcSums(Quantity);
        Assert.AreEqual(ExpectedQuantity, Line.Quantity, 'Each complete predecessor/location tuple must retain its own exact demand.');
    end;

    local procedure PrepareVendorRoutingSerial(Quantity: Decimal; PrecursorQuantity: Decimal; var PrecursorPurchase: Record "Purchase Header"; var SuccessorPurchase: Record "Purchase Header"; var PrecursorTransfer: Record "Transfer Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreateVendorRoutingFixture(1, Quantity);
        CreateVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PurchaseLine);
        CreateVendorRoutingForward(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, PrecursorTransfer);
        SetVendorRoutingWIPShipment(PrecursorTransfer, PrecursorQuantity, PrecursorQuantity);
        LibraryWarehouse.PostTransferOrder(PrecursorTransfer, true, true);
        VerifyVendorRoutingWIP(VRRouting[1], PrecursorPurchase."Subc. Location Code", false, PrecursorQuantity);
        CreateVendorRoutingPurchase(VRRouting[4], SuccessorPurchase, PurchaseLine);
        if PurchaseLine.Quantity <> 12 then begin
            PurchaseLine.Validate(Quantity, 12);
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure RunVendorRoutingPhysicalBoundary(Variant: Integer)
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        SuccessorTransfer: Record "Transfer Header";
        SourceLocation: Code[10];
        PostedDocument: Code[20];
    begin
        CreateVendorRoutingFixture(1, 12);
        SourceLocation := VRVendor[1]."Subc. Location Code";
        if Variant = 1 then begin
            ChangeWorksheetVendor(VRVendor[2]."No.", false, true);
            VRReq.SetRecFilter();
            SubcontractingMgmtLibrary.CarryOutSubcontractingAction(VRReq);
            FindVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PurchaseLine);
            SourceLocation := VRVendor[2]."Subc. Location Code";
        end else
            if Variant <> 4 then
                CreateVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PurchaseLine);
        if Variant <> 4 then begin
            CreateVendorRoutingForward(PrecursorPurchase);
            FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, TransferHeader);
            if Variant = 7 then
                SetVendorRoutingWIPShipment(TransferHeader, 8, 8);
            if Variant = 3 then
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, false)
            else
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        end;
        CreateVendorRoutingPurchase(VRRouting[4], SuccessorPurchase, PurchaseLine);
        if Variant in [5, 6, 7, 8] then
            MoveVendorRoutingLocation(1, VRVendor[3]."Subc. Location Code");
        if Variant = 3 then begin
            ExpectVendorRoutingNoCreation(SuccessorPurchase, VRRouting[1]."Operation No.", SourceLocation, '');
            FinishVendorRoutingFixture();
            exit;
        end;
        CreateVendorRoutingForward(SuccessorPurchase);
        if Variant = 7 then
            VerifyVendorRoutingTuple(SuccessorPurchase, '10', SourceLocation, 8)
        else
            VerifyVendorRoutingTuple(SuccessorPurchase, '10', SourceLocation, 12);
        FindVendorRoutingTransfer(SuccessorPurchase, SourceLocation, false, SuccessorTransfer);
        if Variant in [2, 5, 6, 7, 8] then begin
            case Variant of
                6:
                    SetVendorRoutingWIPShipment(SuccessorTransfer, 4, 4);
                7:
                    SetVendorRoutingWIPShipment(SuccessorTransfer, 4, 2);
            end;
            if Variant = 8 then
                PostVendorRoutingDirect(SuccessorTransfer, false)
            else
                if Variant = 7 then begin
                    LibraryWarehouse.PostTransferOrder(SuccessorTransfer, true, false);
                    SetVendorRoutingWIPReceipt(SuccessorTransfer, 2);
                    LibraryWarehouse.PostTransferOrder(SuccessorTransfer, false, true);
                end else
                    LibraryWarehouse.PostTransferOrder(SuccessorTransfer, true, true);
            if Variant >= 5 then begin
                if Variant = 7 then
                    VerifyVendorRoutingWIP(VRRouting[1], SourceLocation, false, 8)
                else
                    VerifyVendorRoutingWIP(VRRouting[1], SourceLocation, false, 12);
            end;
            if Variant = 2 then begin
                CreateVendorRoutingReturn(SuccessorPurchase);
                FindVendorRoutingTransfer(SuccessorPurchase, SuccessorPurchase."Subc. Location Code", true, TransferHeader);
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
                ExpectVendorRoutingNoCreation(SuccessorPurchase, '10', SourceLocation, '');
            end else
                if Variant = 6 then begin
                    PostedDocument := FindVendorRoutingPostedReceipt(SuccessorTransfer."No.");
                    ExpectVendorRoutingNoCreation(SuccessorPurchase, '10', SourceLocation, PostedDocument);
                end else
                    if Variant = 7 then begin
                        CreateVendorRoutingForward(SuccessorPurchase);
                        VerifyVendorRoutingTuple(SuccessorPurchase, '10', SourceLocation, 8);
                    end else
                        ExpectVendorRoutingNoCreation(SuccessorPurchase, '', '', '');
        end;
        VerifyEffectiveVendor(VRRouting[1], VRVendor[1]."No.");
        VerifyVendorRoutingMasters();
        FinishVendorRoutingFixture();
    end;

    local procedure FindVendorRoutingPostedReceipt(TransferNo: Code[20]): Code[20]
    var
        Receipt: Record "Transfer Receipt Line";
    begin
        Receipt.SetRange("Transfer Order No.", TransferNo);
        Receipt.SetRange("Transfer WIP Item", true);
        Receipt.SetRange("Subc. Prod. Order No.", VROrder."No.");
        Receipt.SetRange("Subc. Prod. Order Line No.", VendorRoutingProductionLineNo(VRRouting[4]));
        Receipt.SetRange("Subc. Routing No.", VRRouting[4]."Routing No.");
        Receipt.SetRange("Subc. Routing Reference No.", VRRouting[4]."Routing Reference No.");
        Receipt.SetRange("Subc. Operation No.", VRRouting[4]."Operation No.");
        Receipt.SetRange("Item No.", VRItem."No.");
        Receipt.SetRange("Variant Code", '');
        Assert.AreEqual(1, Receipt.Count(), 'Evidence must identify the exact successor WIP receipt.');
        Receipt.FindFirst();
        exit(Receipt."Document No.");
    end;

    local procedure RunVendorRoutingCoverageBoundary(Variant: Integer; MovePhysicalSource: Boolean)
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PrecursorTransfer: Record "Transfer Header";
        TransferHeader: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
        SourceLocation: Code[10];
        ExpectedOpen: Decimal;
    begin
        PrepareVendorRoutingSerial(24, 24, PrecursorPurchase, SuccessorPurchase, PrecursorTransfer);
        SourceLocation := PrecursorPurchase."Subc. Location Code";
        CreateVendorRoutingForward(SuccessorPurchase);
        FindVendorRoutingTransfer(SuccessorPurchase, SourceLocation, false, TransferHeader);
        if Variant <= 3 then
            SetVendorRoutingWIPShipment(TransferHeader, 4, 4);
        case Variant of
            2:
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
            3:
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
            4:
                begin
                    SetVendorRoutingWIPShipment(TransferHeader, 12, 12);
                    LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);
                    SetVendorRoutingWIPReceipt(TransferHeader, 4);
                    LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);
                    VerifyVendorRoutingTuple(SuccessorPurchase, '10', SourceLocation, 12);
                    VerifyVendorRoutingWIP(VRRouting[4], TransferHeader."In-Transit Code", true, 8);
                end;
            5, 6:
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        end;
        if Variant = 6 then begin
            CreateVendorRoutingReturn(SuccessorPurchase);
            FindVendorRoutingTransfer(SuccessorPurchase, SuccessorPurchase."Subc. Location Code", true, ReturnHeader);
            LibraryWarehouse.PostTransferOrder(ReturnHeader, true, true);
        end;
        if MovePhysicalSource then begin
            MoveVendorRoutingLocation(2, SourceLocation);
            MoveVendorRoutingLocation(1, VRVendor[3]."Subc. Location Code");
        end;
        if Variant in [4, 5] then
            ExpectVendorRoutingNoCreation(SuccessorPurchase, '', '', '')
        else begin
            CreateVendorRoutingForward(SuccessorPurchase);
            ExpectedOpen := 12;
            if Variant = 3 then
                ExpectedOpen := 8;
            VerifyVendorRoutingTuple(SuccessorPurchase, '10', SourceLocation, ExpectedOpen);
        end;
        case Variant of
            3, 4:
                VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 4);
            5:
                VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 12);
            6:
                begin
                    VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 0);
                    VerifyVendorRoutingWIP(VRRouting[1], SourceLocation, false, 12);
                end;
        end;
        FinishVendorRoutingFixture();
    end;

    local procedure RunVendorRoutingSplitBoundary(FirstQuantity: Decimal; SecondQuantity: Decimal; Ambiguous: Boolean)
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FirstTransfer: Record "Transfer Header";
        SecondTransfer: Record "Transfer Header";
        SecondLocation: Record Location;
        FirstLocation: Code[10];
    begin
        CreateVendorRoutingFixture(1, FirstQuantity + SecondQuantity);
        FirstLocation := VRVendor[1]."Subc. Location Code";
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(SecondLocation);
        CreateVendorRoutingPurchase(VRRouting[1], PrecursorPurchase, PurchaseLine);
        CreateVendorRoutingForward(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, FirstTransfer);
        SetVendorRoutingWIPShipment(FirstTransfer, FirstQuantity, FirstQuantity);
        LibraryWarehouse.PostTransferOrder(FirstTransfer, true, true);
        // Residual is created while the vendor still points at L1. Only this unposted residual is redirected.
        CreateVendorRoutingForward(PrecursorPurchase);
        FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, SecondTransfer);
        SetVendorRoutingWIPShipment(SecondTransfer, SecondQuantity, SecondQuantity);
        EnsureVendorRoutingRoute(VRMain.Code, SecondLocation.Code);
        LibraryVariableStorage.Enqueue('Do you want to change Transfer-to Code?');
        LibraryVariableStorage.Enqueue(true);
        SecondTransfer.Validate("Transfer-to Code", SecondLocation.Code);
        SecondTransfer.Modify(true);
        MoveVendorRoutingLocation(1, SecondLocation.Code);
        LibraryWarehouse.PostTransferOrder(SecondTransfer, true, true);
        VerifyVendorRoutingWIP(VRRouting[1], FirstLocation, false, FirstQuantity);
        VerifyVendorRoutingWIP(VRRouting[1], SecondLocation.Code, false, SecondQuantity);
        CreateVendorRoutingPurchase(VRRouting[4], SuccessorPurchase, PurchaseLine);
        if PurchaseLine.Quantity <> 12 then begin
            PurchaseLine.Validate(Quantity, 12);
            PurchaseLine.Modify(true);
        end;
        if Ambiguous then
            ExpectVendorRoutingNoCreation(SuccessorPurchase, '10', FirstLocation, '')
        else begin
            CreateVendorRoutingForward(SuccessorPurchase);
            VerifyVendorRoutingTuple(SuccessorPurchase, '10', FirstLocation, 4);
            VerifyVendorRoutingTuple(SuccessorPurchase, '10', SecondLocation.Code, 8);
            ExpectVendorRoutingNoCreation(SuccessorPurchase, '', '', '');
        end;
        FinishVendorRoutingFixture();
    end;

    local procedure RunVendorRoutingParallelBoundary(Variant: Integer)
    var
        PrecursorPurchase: Record "Purchase Header";
        SuccessorPurchase: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        Line: Record "Transfer Line";
        Source20: Code[10];
        Source30: Code[10];
        Company20: Boolean;
        i: Integer;
        Predecessor: Record "Prod. Order Routing Line";
        BeforeState: Text;
    begin
        CreateVendorRoutingFixture(2, 12);
        Company20 := Variant in [1, 6, 7, 9];
        Source20 := VRVendor[1]."Subc. Location Code";
        Source30 := VRVendor[5]."Subc. Location Code";
        if Variant = 4 then begin
            MoveVendorRoutingLocation(5, Source20);
            Source30 := Source20;
        end;
        // All strict component/supply/refresh and selected purchase creation occur before any supported blank location.
        CreateVendorRoutingPurchase(VRRouting[4], SuccessorPurchase, PurchaseLine);
        for i := 1 to 2 do begin
            if i = 1 then
                Predecessor := VRRouting[1]
            else
                Predecessor := VRRouting[3];
            if not ((i = 1) and Company20) and (Variant <> 9) then begin
                CreateVendorRoutingPurchase(Predecessor, PrecursorPurchase, PurchaseLine);
                CreateVendorRoutingForward(PrecursorPurchase);
                FindVendorRoutingTransfer(PrecursorPurchase, VRMain.Code, false, TransferHeader);
                LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
            end;
        end;
        if Company20 then begin
            MoveVendorRoutingLocation(1, '');
            Source20 := VRMain.Code;
        end;
        if Variant = 9 then begin
            MoveVendorRoutingLocation(5, '');
            Source30 := VRMain.Code;
        end;
        ReloadVendorRoutingOperation(VRRouting[1]);
        ReloadVendorRoutingOperation(VRRouting[3]);
        VRRouting[1].CalcFields(Subcontracting);
        VRRouting[3].CalcFields(Subcontracting);
        Assert.IsTrue(VRRouting[1].Subcontracting and VRRouting[3].Subcontracting, 'Both predecessors remain genuine subcontracting Work Centers.');
        VRRouting[1].Validate("Transfer WIP Item", true);
        VRRouting[3].Validate("Transfer WIP Item", true);
        CreateVendorRoutingForward(SuccessorPurchase);
        if Variant = 1 then begin
            VerifyVendorRoutingTuple(SuccessorPurchase, '20', Source20, 12);
            VerifyVendorRoutingTuple(SuccessorPurchase, '30', Source30, 12);
            FinishVendorRoutingFixture();
            exit;
        end;
        Line.SetRange("Subc. Purch. Order No.", SuccessorPurchase."No.");
        Line.SetRange("Transfer WIP Item", true);
        Line.SetRange("Derived From Line No.", 0);
        Line.FindSet();
        repeat
            if Line."Prev. Operation No." = '20' then begin
                Line.Validate(Quantity, 4);
                Line.Modify(true);
            end else
                if Variant in [5, 7] then begin
                    Line.Validate(Quantity, 12);
                    Line.Modify(true);
                end else
                    if Variant = 8 then begin
                        Line.Validate(Quantity, 4);
                        Line.Modify(true);
                    end else
                        Line.Delete(true);
        until Line.Next() = 0;
        if Variant in [3, 4, 5, 6, 7] then begin
            // Real registrations keep physical P30 (and P20 when applicable) debit-backed after divergence.
            MoveVendorRoutingLocation(2, Source30);
            if not Company20 then
                MoveVendorRoutingLocation(3, Source20);
            if not Company20 then
                MoveVendorRoutingLocation(1, VREast.Code);
            MoveVendorRoutingLocation(5, VRWest.Code);
        end;
        if Variant = 8 then begin
            MoveVendorRoutingLocation(1, VREast.Code);
            MoveVendorRoutingLocation(5, VRWest.Code);
        end;
        if Variant in [5, 7, 8, 9] then begin
            TransferHeader.Reset();
            TransferHeader.SetRange("Subcontr. Purch. Order No.", SuccessorPurchase."No.");
            TransferHeader.SetRange("Subc. Return Order", false);
            TransferHeader.FindSet();
            repeat
                Line.Reset();
                Line.SetRange("Document No.", TransferHeader."No.");
                if not Line.IsEmpty() then begin
                    Line.SetRange("Transfer WIP Item", true);
                    if (Variant = 5) and not Line.IsEmpty() then
                        PostVendorRoutingDirect(TransferHeader, true)
                    else
                        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
                end;
            until TransferHeader.Next() = 0;
        end;
        if Variant = 8 then begin
            BeforeState := VendorRoutingArtifactState();
            ExpectVendorRoutingNoCreation(SuccessorPurchase, '40', Source20, '');
            Assert.AreEqual(BeforeState, VendorRoutingArtifactState(), 'Two unknown expanded histories must not be allocated heuristically.');
        end else begin
            CreateVendorRoutingForward(SuccessorPurchase);
            case Variant of
                2:
                    begin
                        VerifyVendorRoutingTuple(SuccessorPurchase, '20', Source20, 16);
                        VerifyVendorRoutingTuple(SuccessorPurchase, '30', Source30, 12);
                    end;
                3, 4, 6:
                    begin
                        VerifyVendorRoutingTuple(SuccessorPurchase, '20', Source20, 12);
                        VerifyVendorRoutingTuple(SuccessorPurchase, '30', Source30, 12);
                    end;
                5, 7:
                    begin
                        VerifyVendorRoutingTuple(SuccessorPurchase, '20', Source20, 8);
                        VerifyVendorRoutingTuple(SuccessorPurchase, '30', Source30, 0);
                        VerifyVendorRoutingWIP(VRRouting[4], SuccessorPurchase."Subc. Location Code", false, 16);
                        if Company20 then
                            VerifyVendorRoutingWIP(VRRouting[1], VRMain.Code, false, 0);
                    end;
                9:
                    VerifyVendorRoutingTuple(SuccessorPurchase, '20', VRMain.Code, 8);
            end;
        end;
        FinishVendorRoutingFixture();
    end;

    [ConfirmHandler]
    procedure VendorRoutingConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(ExpectedQuestion, Question, 'Reject every unexpected or partially matched confirmation.');
        Reply := LibraryVariableStorage.DequeueBoolean();
        if StrPos(Question, 'Do you want to update the subcontractor on operation ') = 1 then
            VRVendorQuestionCount += 1;
    end;

    [PageHandler]
    procedure VendorRoutingCardHandler(var VendorCard: TestPage "Vendor Card")
    begin
        VendorCard."No.".AssertEquals(LibraryVariableStorage.DequeueText());
        VendorCard.Close();
    end;

    [MessageHandler]
    procedure VendorRoutingUpdateMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual('Successfully updated.', Message, 'Only the native work-center component-update message is expected.');
    end;

    [RequestPageHandler]
    procedure VendorRoutingCalculateHandler(var Calculate: TestRequestPage "Subc. Calculate Subcontracts")
    begin
        VRCalculateCallbackCount += 1;
        Calculate."Prod. Order Routing Line".SetFilter("Prod. Order No.", VROrder."No.");
        Calculate."Work Center".SetFilter("No.", VRWorkCenter[1]."No.");
        Calculate."Only Operations Ready to Start".SetValue(false);
        Calculate.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure VendorRoutingCarryOutHandler(var CarryOut: TestRequestPage "Carry Out Action Msg. - Req.")
    begin
        VRCarryOutCallbackCount += 1;
        CarryOut.PrintOrders.SetValue(false);
        CarryOut.OK().Invoke();
    end;

    [PageHandler]
    procedure VendorRoutingTransferHandler(var TransferOrder: TestPage "Transfer Order")
    var
        Header: Record "Transfer Header";
    begin
        Header.Get(TransferOrder."No.".Value);
        Assert.AreEqual(VRDisplayedPurchase, Header."Subcontr. Purch. Order No.", 'Only the selected purchase transfer may open.');
        Assert.AreEqual(VRDisplayedReturn, Header."Subc. Return Order", 'Displayed transfer direction must be exact.');
        TransferOrder.Close();
    end;

    [PageHandler]
    procedure VendorRoutingTransfersHandler(var Transfers: TestPage "Transfer Orders")
    var
        Header: Record "Transfer Header";
    begin
        Assert.IsTrue(Transfers.First(), 'The native filtered transfer list must not be empty.');
        repeat
            Header.Get(Transfers."No.".Value);
            Assert.AreEqual(VRDisplayedPurchase, Header."Subcontr. Purch. Order No.", 'Transfer list must exclude other purchases.');
            Assert.AreEqual(VRDisplayedReturn, Header."Subc. Return Order", 'Transfer list must preserve direction.');
        until not Transfers.Next();
        Transfers.Close();
    end;

    [Test]
    [HandlerFunctions('SummaryReadTransferCreatedHandler,SummaryTransferLinesHandler')]
    procedure SummaryOriginalTransferLinesDrilldown()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OtherWorkCenter: Record "Work Center";
        Items: array[2] of Record Item;
        PurchaseHeader: Record "Purchase Header";
        OtherPurchaseHeader: Record "Purchase Header";
        OtherPurchaseLine: Record "Purchase Line";
        ForwardHeader: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
        OtherTransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Original-line counts and detail exclude native derived lines and disappear after actual completion.
        InitializeSummaryPurchasing();

        // [GIVEN] Two real family WIP lines share one native forward header; another order has an unrelated transfer.
        SubcWarehouseLibrary.CreateSummaryFamily(10, 10, ProductionOrder, WorkCenter, Items);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, ForwardHeader);
        SubcWarehouseLibrary.CreateSummaryOrder(5, OtherOrder, OtherWorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, OtherWorkCenter, OtherPurchaseHeader, OtherPurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(OtherOrder, OtherWorkCenter, OtherPurchaseHeader, OtherTransferHeader);
        TransferLine.SetRange("Document No.", ForwardHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        Assert.AreEqual(2, TransferLine.Count(), 'Family forward must contain two originals, not two headers.');
        TransferLine.FindSet();
        repeat
            TransferLine.Validate("Qty. to Ship", 4);
            TransferLine.Modify(true);
        until TransferLine.Next() = 0;

        // [WHEN] Native partial shipment creates derived lines, then receipt makes real WIP available for native return creation.
        LibraryWarehouse.PostTransferOrder(ForwardHeader, true, false);
        TransferLine.SetFilter("Derived From Line No.", '<>0');
        Assert.RecordIsNotEmpty(TransferLine);
        LibraryWarehouse.PostTransferOrder(ForwardHeader, false, true);
        SubcWarehouseLibrary.CreateSummaryReturn(PurchaseHeader, ReturnHeader);

        // [THEN] Each field counts two originals on one header and drills to its own exact source population.
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.TransferCount.AssertEquals(2);
        ReleasedOrder.SubcontractingSummary.ReturnTransferCount.AssertEquals(2);
        ReleasedOrder.Close();
        VerifySummaryTransferDetails(ProductionOrder, false);
        VerifySummaryTransferDetails(ProductionOrder, true);

        // [WHEN] All remaining forward quantities and then the available return quantities are actually completed.
        LibraryWarehouse.PostTransferOrder(ForwardHeader, true, true);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, true, true);

        // [THEN] Completed source rows and both detail populations are empty, without a cached header count.
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.TransferCount.AssertEquals(0);
        ReleasedOrder.SubcontractingSummary.ReturnTransferCount.AssertEquals(0);
        ReleasedOrder.Close();
        VerifySummaryTransferDetails(ProductionOrder, false);
        VerifySummaryTransferDetails(ProductionOrder, true);
        Assert.IsTrue(OtherTransferHeader.Get(OtherTransferHeader."No."), 'Unrelated original transfer must remain untouched.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryReadTransferCreatedHandler,SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler,SummaryTransferLinesHandler,SummaryConformanceWIPHandler,SummaryConformanceRoutingHandler')]
    procedure SummaryFeatureWideConformance()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ForwardHeader: Record "Transfer Header";
        ReturnHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] The actual Released card consumes the complete approved worked purchasing and forward/return WIP request.
        InitializeSummaryPurchasing();

        // [GIVEN] A real order of ten, another order sharing routing, and a native purchase order still available for transfer creation.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            OtherOrder, OtherOrder.Status::Released, OtherOrder."Source Type"::Item, ProductionOrder."Source No.", 4, ProductionOrder."Location Code");
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, ForwardHeader);

        // [WHEN] Ten are shipped and received in two native stages, then three are returned before invoicing deletes the PO.
        LibraryWarehouse.PostTransferOrder(ForwardHeader, true, false);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 0, 10);
        TransferLine.SetRange("Document No.", ForwardHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.FindFirst();
        TransferLine.Validate("Qty. to Receive", 4);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(ForwardHeader, false, true);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 4, 6);
        LibraryWarehouse.PostTransferOrder(ForwardHeader, false, true);
        SubcWarehouseLibrary.CreateSummaryReturn(PurchaseHeader, ReturnHeader);
        TransferLine.Reset();
        TransferLine.SetRange("Document No.", ReturnHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.FindFirst();
        TransferLine.Validate(Quantity, 3);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, true, false);
        SubcWarehouseLibrary.VerifySummaryWIP(ProductionOrder, 7, 3);
        LibraryWarehouse.PostTransferOrder(ReturnHeader, false, true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 4);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 6);

        // [THEN] All nine final card values, source details and the untouched other order agree.
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 10, 10, true, 7, 0, 0, 0);
        SubcWarehouseLibrary.VerifySummaryCard(OtherOrder, 1, 0, 0, 0, true, 0, 0, 0, 0);
        VerifySummaryPurchaseDetails(ProductionOrder);
        VerifySummaryTransferDetails(ProductionOrder, false);
        VerifySummaryTransferDetails(ProductionOrder, true);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.DrillDown();
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'Exactly the current subcontract operation must be returned.');
        Assert.AreEqual(ProductionOrder."No.", LibraryVariableStorage.DequeueText(), 'Routing detail must retain the current order.');
        Assert.AreEqual('10', LibraryVariableStorage.DequeueText(), 'Routing detail must retain the operation key.');
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.DrillDown();
        VerifySummaryConformanceWIPRows(ProductionOrder, false);
        ReleasedOrder.SubcontractingSummary.WIPInTransit.DrillDown();
        VerifySummaryConformanceWIPRows(ProductionOrder, true);
        ReleasedOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryPurchasingLifecycle()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Actual purchase persistence and all three card drilldowns agree at each lifecycle boundary.
        InitializeSummaryPurchasing();

        // [GIVEN] A real subcontract order and its native purchase order.
        // [WHEN] Receipt and two invoices are posted.
        // [THEN] The genuine card and details follow all four persisted states.
        RunSummaryPurchaseLifecycle();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryFullyInvoicedLifecycle()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Exact receipt equality alone is insufficient until the linked quantity is invoiced.
        InitializeSummaryPurchasing();

        // [GIVEN] A real ten-unit open purchase line, initially with equal empty history.
        // [WHEN] Native posting receives ten and invoices four then six.
        // [THEN] The card is No, No, No, then Yes after native purchase-order deletion.
        RunSummaryPurchaseLifecycle();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryFamilyRawQuantities()
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Every real family contributor posts in its document unit; raw totals are not base totals.
        InitializeSummaryPurchasing();

        // [GIVEN] Two family outputs with factor-six and base document units.
        // [WHEN] Both contributors are received and invoiced through native purchasing.
        // [THEN] Card and detail show .16 and .30, not converted .46 and .80.
        RunSummaryFamilyPurchasing(0.06, 0.10);
        RunSummaryFamilyPurchasing(0.10, 0.20);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryMultipleOperationsAndIsolation()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        SecondWorkCenter: Record "Work Center";
        PurchaseHeader: array[2] of Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
        OtherHeader: Record "Purchase Header";
        OtherLine: Record "Purchase Line";
        OrdinaryLine: Record "Purchase Line";
        OrdinaryItem: Record Item;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Multiple purchased operations aggregate once per source row and exclude other orders and ancillary links.
        InitializeSummaryPurchasing();

        // [GIVEN] "A" and "B" share two real subcontract operations.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        AddSummarySecondOperation(ProductionOrder, SecondWorkCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            OtherOrder, OtherOrder.Status::Released, OtherOrder."Source Type"::Item, ProductionOrder."Source No.", 7, ProductionOrder."Location Code");
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader[1], PurchaseLine[1]);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, SecondWorkCenter, PurchaseHeader[2], PurchaseLine[2]);
        LibraryInventory.CreateItem(OrdinaryItem);
        LibraryPurchase.CreatePurchaseLine(OrdinaryLine, PurchaseHeader[1], OrdinaryLine.Type::Item, OrdinaryItem."No.", 3);
        OrdinaryLine.Validate("Qty. to Receive", 0);
        OrdinaryLine.Validate("Qty. to Invoice", 0);
        OrdinaryLine.Modify(true);

        // [WHEN] Both operations of both orders are received, but only "A"'s first is invoiced.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[1], true, false);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader[2], true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader[1], PurchaseLine[1], 10);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, WorkCenter, OtherHeader, OtherLine);
        LibraryPurchase.PostPurchaseDocument(OtherHeader, true, false);
        Clear(OtherLine);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, SecondWorkCenter, OtherHeader, OtherLine);
        LibraryPurchase.PostPurchaseDocument(OtherHeader, true, false);
        CreateSummaryAncillaryLine(ProductionOrder);

        // [THEN] Raw operation totals are 20, not unique output 10; other and ancillary lines do not leak.
        VerifySummaryPurchaseCard(ProductionOrder, 20, 20, 10, false);
        VerifySummaryPurchaseCard(OtherOrder, 14, 14, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        VerifySummaryPurchaseDetails(OtherOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SummaryRetainedLineUsesQuantityPredicate()
    var
        ProductionOrder: Record "Production Order";
        PartialOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OrdinaryLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Retained fully invoiced lines do not count as open; editable quantities and header status do not decide.
        InitializeSummaryPurchasing();

        // [GIVEN] A mixed purchase order retains the fully posted subcontract line.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(OrdinaryLine, PurchaseHeader, OrdinaryLine.Type::Item, Item."No.", 3);
        OrdinaryLine.Validate("Qty. to Receive", 0);
        OrdinaryLine.Validate("Qty. to Invoice", 0);
        OrdinaryLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Only the subcontract line is fully invoiced.
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 10);

        // [THEN] The retained linked line is not open, irrespective of header status.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(10, PurchaseLine."Quantity Invoiced", 'The retained linked quantity must be posted, not assigned.');
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 10, true);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 10, true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 10, true);

        // [GIVEN] Another order is only partially invoiced, with editable Qty. to Invoice zero.
        Clear(PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryOrder(10, PartialOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(PartialOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 4);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine.Validate("Qty. to Invoice", 0);
        PurchaseLine.Modify(true);

        // [THEN] Posted inequality still makes the card No.
        VerifySummaryPurchaseCard(PartialOrder, 10, 10, 4, false);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        VerifySummaryPurchaseCard(PartialOrder, 10, 10, 4, false);
    end;

    [Test]
#pragma warning disable AA0210 // Bounded receipt and correction fixtures.
    [HandlerFunctions('SummaryConfirmHandler,SummaryReceiptLinesHandler')]
    procedure SummaryReceiptUndoSigned()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Native receipt undo appends signed history, while its reopened purchase line prevents Yes.
        InitializeSummaryPurchasing();

        // [GIVEN] An uninvoiced, unapplied real subcontract receipt of ten.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ReceiptLine.FindFirst();

        // [WHEN] Native undo is performed before any application or invoice.
        LibraryPurchase.UndoPurchaseReceiptLine(ReceiptLine);

        // [THEN] Both correction rows appear and net to zero, but the original quantity remains open.
        ReceiptLine.Reset();
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(2, ReceiptLine.Count(), 'Undo must retain original and negative correction.');
        ReceiptLine.CalcSums(Quantity);
        Assert.AreEqual(0, ReceiptLine.Quantity, 'Signed receipt history must net to zero.');
        ReceiptLine.SetFilter(Quantity, '>0');
        ReceiptLine.CalcSums(Quantity);
        Assert.AreEqual(10, ReceiptLine.Quantity, 'The original positive receipt must remain.');
        ReceiptLine.SetFilter(Quantity, '<0');
        ReceiptLine.CalcSums(Quantity);
        Assert.AreEqual(-10, ReceiptLine.Quantity, 'Native undo must append the negative correction.');
        VerifySummaryPurchaseCard(ProductionOrder, 10, 0, 0, false);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        VerifySummaryReceiptDetailRows(ProductionOrder);
        ReleasedOrder.Close();
        LibraryVariableStorage.AssertEmpty();
    end;
#pragma warning restore AA0210

    [Test]
    procedure SummaryEmptyQuantityProxy()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Empty real eligible orders have equal empty history and no open linked purchase lines.
        InitializeSummaryPurchasing();

        // [GIVEN] Real routing exists, but no purchase creator has run.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);

        // [WHEN] The real Released card is read.
        // [THEN] The complete empty summary has Fully Invoiced Yes.
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 0, 0, true, 0, 0, 0, 0);
    end;

    [Test]
    [HandlerFunctions('SummaryPurchaseLinesHandler,SummaryReceiptLinesHandler,SummaryInvoiceLinesHandler')]
    procedure SummaryNamedSourcesAndCorrections()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseLine: Record "Purchase Line";
        CreditLine: Record "Purch. Cr. Memo Line";
        ReturnLine: Record "Return Shipment Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] The actual card and drilldowns retain signed named sources and exclude credit and return populations.
        InitializeSummaryPurchasing();

        // [GIVEN] Named signed receipt/invoice rows net to four; excluded sources have unmatched quantities.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.InsertSummaryReceipt(ProductionOrder."No.", 5);
        SubcWarehouseLibrary.InsertSummaryReceipt(ProductionOrder."No.", -1);
        SubcWarehouseLibrary.InsertSummaryInvoice(ProductionOrder."No.", 5);
        SubcWarehouseLibrary.InsertSummaryInvoice(ProductionOrder."No.", -1);
        SubcWarehouseLibrary.InsertSummaryPurchase(ProductionOrder."No.", PurchaseLine."Document Type"::"Return Order", 100, 0, PurchaseLine);
        SubcWarehouseLibrary.InsertSummaryPurchase(ProductionOrder."No.", PurchaseLine."Document Type"::"Credit Memo", 200, 0, PurchaseLine);
        CreditLine."Document No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(CreditLine."Document No."));
        CreditLine."Line No." := 10000;
        CreditLine."Prod. Order No." := ProductionOrder."No.";
        CreditLine.Quantity := 300;
        CreditLine.Insert();
        ReturnLine."Document No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ReturnLine."Document No."));
        ReturnLine."Line No." := 10000;
        ReturnLine."Prod. Order No." := ProductionOrder."No.";
        ReturnLine.Quantity := 400;
        ReturnLine.Insert();
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 4, 4, true, 0, 0, 0, 0);
        VerifySummaryPurchaseDetails(ProductionOrder);

        // [WHEN] A further correction is added to the named invoice source.
        SubcWarehouseLibrary.InsertSummaryInvoice(ProductionOrder."No.", -0.5);

        // [THEN] Its sign is retained and exact equality is lost.
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 0, 4, 3.5, false, 0, 0, 0, 0);
        VerifySummaryPurchaseDetails(ProductionOrder);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifySummaryTransferDetails(ProductionOrder: Record "Production Order"; ReturnOrder: Boolean)
    var
        TransferLine: Record "Transfer Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        if ReturnOrder then
            ReleasedOrder.SubcontractingSummary.ReturnTransferCount.DrillDown()
        else
            ReleasedOrder.SubcontractingSummary.TransferCount.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetRange("Subc. Return Order", ReturnOrder);
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(TransferLine.Count());
        Assert.AreEqual(TransferLine.Count(), LibraryVariableStorage.DequeueInteger(), 'Transfer detail must count original lines, not headers.');
        if TransferLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(TransferLine.RecordId());
                Assert.AreEqual(TransferLine."Document No.", LibraryVariableStorage.DequeueText(), 'Transfer document must match the filtered original.');
                Assert.AreEqual(TransferLine."Item No.", LibraryVariableStorage.DequeueText(), 'Every original family item must appear.');
                Assert.AreEqual(TransferLine."Outstanding Quantity", LibraryVariableStorage.DequeueDecimal(), 'Transfer detail quantity must match.');
            until TransferLine.Next() = 0;
        ReleasedOrder.Close();
    end;

    local procedure VerifySummaryConformanceWIPRows(ProductionOrder: Record "Production Order"; InTransit: Boolean)
    var
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
    begin
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntry.SetRange("In Transit", InTransit);
        Assert.AreEqual(WIPEntry.Count(), LibraryVariableStorage.DequeueInteger(), 'Worked request WIP detail count must agree.');
        if WIPEntry.FindSet() then
            repeat
                Assert.AreEqual(WIPEntry."Entry No.", LibraryVariableStorage.DequeueInteger(), 'Worked request must return every exact ledger key.');
                Assert.AreEqual(WIPEntry."Quantity (Base)", LibraryVariableStorage.DequeueDecimal(), 'Worked request detail must preserve signed movements.');
            until WIPEntry.Next() = 0;
    end;

    [PageHandler]
    procedure SummaryTransferLinesHandler(var Lines: TestPage "Transfer Lines")
    var
        Documents: List of [Text];
        Items: List of [Text];
        Quantities: List of [Decimal];
        RowIndex: Integer;
        Quantity: Decimal;
    begin
        if Lines.First() then
            repeat
                Documents.Add(Lines."Document No.".Value());
                Items.Add(Lines."Item No.".Value());
                Evaluate(Quantity, Lines."Outstanding Quantity".Value());
                Quantities.Add(Quantity);
            until not Lines.Next();
        LibraryVariableStorage.Enqueue(Documents.Count());
        for RowIndex := 1 to Documents.Count() do begin
            LibraryVariableStorage.Enqueue(Documents.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Items.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryConformanceWIPHandler(var Entries: TestPage "Subc. WIP Ledger Entries")
    var
        EntryNumbers: List of [Integer];
        Quantities: List of [Decimal];
        EntryNo: Integer;
        Quantity: Decimal;
        RowIndex: Integer;
    begin
        if Entries.First() then
            repeat
                Evaluate(EntryNo, Entries."Entry No.".Value());
                EntryNumbers.Add(EntryNo);
                Evaluate(Quantity, Entries."Quantity (Base)".Value());
                Quantities.Add(Quantity);
            until not Entries.Next();
        LibraryVariableStorage.Enqueue(EntryNumbers.Count());
        for RowIndex := 1 to EntryNumbers.Count() do begin
            LibraryVariableStorage.Enqueue(EntryNumbers.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Entries.Close();
    end;

    [PageHandler]
    procedure SummaryConformanceRoutingHandler(var Routing: TestPage "Prod. Order Routing")
    var
        Orders: List of [Text];
        Operations: List of [Text];
        RowIndex: Integer;
    begin
        if Routing.First() then
            repeat
                Orders.Add(Routing."Prod. Order No.".Value());
                Operations.Add(Routing."Operation No.".Value());
            until not Routing.Next();
        LibraryVariableStorage.Enqueue(Orders.Count());
        for RowIndex := 1 to Orders.Count() do begin
            LibraryVariableStorage.Enqueue(Orders.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Operations.Get(RowIndex));
        end;
        Routing.Close();
    end;

    local procedure RunSummaryPurchaseLifecycle()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 0, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 4);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(4, PurchaseLine."Quantity Invoiced", 'Partial quantity must be persisted by posting.');
        VerifySummaryPurchaseCard(ProductionOrder, 10, 10, 4, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        SubcWarehouseLibrary.PostSummaryInvoice(PurchaseHeader, PurchaseLine, 6);
        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No."), 'Native final posting must delete the simple order.');
        VerifySummaryPurchaseCard(ProductionOrder, 0, 10, 10, true);
        VerifySummaryPurchaseDetails(ProductionOrder);
    end;

    local procedure RunSummaryFamilyPurchasing(FirstQuantity: Decimal; SecondQuantity: Decimal)
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        Items: array[2] of Record Item;
        ItemUOM: Record "Item Unit of Measure";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        InvoiceLine: Record "Purch. Inv. Line";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SubcWarehouseLibrary.CreateSummaryFamily(FirstQuantity * 6, SecondQuantity, ProductionOrder, WorkCenter, Items);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUOM, Items[1]."No.", 6);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("No.", Items[1]."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Unit of Measure Code", ItemUOM.Code);
        PurchaseLine.Validate(Quantity, FirstQuantity);
        PurchaseLine.Modify(true);
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        ItemUOM.Get(PurchaseLine."No.", PurchaseLine."Unit of Measure Code");
        Assert.AreEqual(6, ItemUOM."Qty. per Unit of Measure", 'First contributor must use the factor-six item UOM conversion.');
        PurchaseLine.SetRange("No.", Items[2]."No.");
        PurchaseLine.FindFirst();
        Assert.AreEqual(SecondQuantity, PurchaseLine.Quantity, 'Second contributor must exist with its raw quantity.');
        SubSetupLibrary.EnsureGeneralPostingSetupIsValid(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifySummaryPurchaseCard(ProductionOrder, FirstQuantity + SecondQuantity, 0, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        VerifySummaryPurchaseCard(ProductionOrder, FirstQuantity + SecondQuantity, FirstQuantity + SecondQuantity, 0, false);
        VerifySummaryPurchaseDetails(ProductionOrder);
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Invoice No.", CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(PurchaseHeader."Vendor Invoice No.")));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        VerifySummaryPurchaseCard(ProductionOrder, 0, FirstQuantity + SecondQuantity, FirstQuantity + SecondQuantity, true);
        VerifySummaryPurchaseDetails(ProductionOrder);
#pragma warning disable AA0210 // Filters inspect only the documents created by this family fixture.
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ReceiptLine.SetRange("No.", Items[1]."No.");
        ReceiptLine.FindFirst();
        Assert.AreEqual(FirstQuantity, ReceiptLine.Quantity, 'First family receipt must retain document quantity.');
        Assert.AreEqual(ItemUOM.Code, ReceiptLine."Unit of Measure Code", 'First family receipt must retain document UOM.');
        ReceiptLine.SetRange("No.", Items[2]."No.");
        ReceiptLine.FindFirst();
        Assert.AreEqual(SecondQuantity, ReceiptLine.Quantity, 'Second family receipt must be posted.');
        InvoiceLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        InvoiceLine.SetRange("No.", Items[1]."No.");
        InvoiceLine.FindFirst();
        Assert.AreEqual(FirstQuantity, InvoiceLine.Quantity, 'First family invoice must be posted.');
        Assert.AreEqual(ItemUOM.Code, InvoiceLine."Unit of Measure Code", 'First family invoice must retain document UOM.');
        InvoiceLine.SetRange("No.", Items[2]."No.");
#pragma warning restore AA0210
        InvoiceLine.FindFirst();
        Assert.AreEqual(SecondQuantity, InvoiceLine.Quantity, 'Second family invoice must be posted.');
    end;

    local procedure VerifySummaryPurchaseCard(ProductionOrder: Record "Production Order"; PurchaseQuantity: Decimal; ReceiptQuantity: Decimal; InvoiceQuantity: Decimal; FullyInvoiced: Boolean)
    var
        ReleasedOrder: TestPage "Released Production Order";
    begin
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.AssertEquals(PurchaseQuantity);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.AssertEquals(ReceiptQuantity);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.AssertEquals(InvoiceQuantity);
        ReleasedOrder.SubcontractingSummary.FullyInvoiced.AssertEquals(Format(FullyInvoiced));
        ReleasedOrder.Close();
    end;

    local procedure VerifySummaryPurchaseDetails(ProductionOrder: Record "Production Order")
    var
        PurchaseLine: Record "Purchase Line";
        InvoiceLine: Record "Purch. Inv. Line";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(PurchaseLine.Count());
        Assert.AreEqual(PurchaseLine.Count(), LibraryVariableStorage.DequeueInteger(), 'Purchase detail row count must match.');
        if PurchaseLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(PurchaseLine.RecordId());
                Assert.AreEqual(PurchaseLine."Document No.", LibraryVariableStorage.DequeueText(), 'Purchase document key must match.');
                Assert.AreEqual(PurchaseLine.Quantity, LibraryVariableStorage.DequeueDecimal(), 'Raw purchase detail quantity must match.');
            until PurchaseLine.Next() = 0;
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        VerifySummaryReceiptDetailRows(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        InvoiceLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(InvoiceLine.Count());
        Assert.AreEqual(InvoiceLine.Count(), LibraryVariableStorage.DequeueInteger(), 'Invoice detail row count must match.');
        if InvoiceLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(InvoiceLine.RecordId());
                Assert.AreEqual(InvoiceLine."Document No.", LibraryVariableStorage.DequeueText(), 'Invoice document must match.');
                Assert.AreEqual(InvoiceLine."No.", LibraryVariableStorage.DequeueText(), 'Invoice item must match.');
                Assert.AreEqual(InvoiceLine.Quantity, LibraryVariableStorage.DequeueDecimal(), 'Raw signed invoice quantity must match.');
            until InvoiceLine.Next() = 0;
        ReleasedOrder.Close();
    end;

    local procedure VerifySummaryReceiptDetailRows(ProductionOrder: Record "Production Order")
    var
        ReceiptLine: Record "Purch. Rcpt. Line";
    begin
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(ReceiptLine.Count());
        if ReceiptLine.FindSet() then
            repeat
                SubcWarehouseLibrary.VerifySummaryDetailRecord(ReceiptLine.RecordId());
            until ReceiptLine.Next() = 0;
    end;

    local procedure CreateSummaryAncillaryLine(ProductionOrder: Record "Production Order")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 99);
        PurchaseLine."Subc. Prod. Order No." := ProductionOrder."No.";
        PurchaseLine.Modify(true);
    end;

    local procedure AddSummarySecondOperation(var ProductionOrder: Record "Production Order"; var WorkCenter: Record "Work Center")
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        Location: Record Location;
        Vendor: Record Vendor;
    begin
        Item.Get(ProductionOrder."Source No.");
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(WorkCenter);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Get(WorkCenter."Subcontractor No.");
        Vendor.Validate("Subc. Location Code", Location.Code);
        Vendor.Modify(true);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    [ConfirmHandler]
    procedure SummaryConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [PageHandler]
    procedure SummaryPurchaseLinesHandler(var Lines: TestPage "Purchase Lines")
    var
        Documents: List of [Text];
        Quantities: List of [Decimal];
        RowIndex: Integer;
        Quantity: Decimal;
    begin
        if Lines.First() then
            repeat
                Documents.Add(Lines."Document No.".Value());
                Evaluate(Quantity, Lines.Quantity.Value());
                Quantities.Add(Quantity);
            until not Lines.Next();
        LibraryVariableStorage.Enqueue(Documents.Count());
        for RowIndex := 1 to Documents.Count() do begin
            LibraryVariableStorage.Enqueue(Documents.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReceiptLinesHandler(var Lines: TestPage "Purch. Receipt Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryInvoiceLinesHandler(var Lines: TestPage "Subc. Summary Invoice Lines")
    var
        Documents: List of [Text];
        Items: List of [Text];
        Quantities: List of [Decimal];
        RowIndex: Integer;
        Quantity: Decimal;
    begin
        if Lines.First() then
            repeat
                Documents.Add(Lines."Document No.".Value());
                Items.Add(Lines."No.".Value());
                Evaluate(Quantity, Lines.Quantity.Value());
                Quantities.Add(Quantity);
            until not Lines.Next();
        LibraryVariableStorage.Enqueue(Documents.Count());
        for RowIndex := 1 to Documents.Count() do begin
            LibraryVariableStorage.Enqueue(Documents.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Items.Get(RowIndex));
            LibraryVariableStorage.Enqueue(Quantities.Get(RowIndex));
        end;
        Lines.Close();
    end;

    local procedure InitializeSummaryPurchasing()
    begin
        Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
    end;

    [Test]
    [HandlerFunctions('SummaryRoutingHandler')]
    procedure SummaryCardRoutingAndEligibility()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ReleasedOrders: TestPage "Released Production Orders";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] The genuine card aggregates current subcontract operations, not internal or other-order lines.
        Initialize();

        // [GIVEN] Order "A" has two subcontract operations and one internal operation; "B" shares its routing.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        AddSummaryRoutingOperations(ProductionOrder, true);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            OtherOrder, OtherOrder.Status::Released, OtherOrder."Source Type"::Item, ProductionOrder."Source No.", 7, ProductionOrder."Location Code");

        // [WHEN] The real Released list opens its card and the routing detail is invoked.
        ReleasedOrders.OpenView();
        ReleasedOrders.GoToRecord(ProductionOrder);
        ReleasedOrder.Trap();
        ReleasedOrders.Edit().Invoke();
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.RoutingCount.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);

        // [THEN] Only "A"'s subcontract operation keys are returned.
        VerifySummaryRoutingDetails(ProductionOrder);
        ReleasedOrder.Close();
        ReleasedOrders.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure SummaryCardNavigationAndBlankGuard()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        OtherWorkCenter: Record "Work Center";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Navigation clears hidden and blank records instead of retaining another order's values.
        Initialize();

        // [GIVEN] Eligible "A" and internal-only "B".
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        AddSummaryRoutingOperations(ProductionOrder, true);
        SubcWarehouseLibrary.CreateSummaryOrder(7, OtherOrder, OtherWorkCenter);
        OtherWorkCenter.Validate("Subcontractor No.", '');
        OtherWorkCenter.Modify(true);

        // [WHEN] The actual card navigates "A" -> "B" -> "A".
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        ReleasedOrder.GoToRecord(OtherOrder);

        // [THEN] "B" is ineligible and does not inherit "A"; "A" is recomputed on return.
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.Visible(), 'Internal-only order must hide the summary.');
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        ReleasedOrder.Close();
        ReleasedOrder.OpenNew();
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.Visible(), 'Blank card must hide the summary.');
        ReleasedOrder.Close();
    end;

    [Test]
    [HandlerFunctions('SummaryRefreshProductionOrderHandler')]
    procedure SummaryRefreshActionUpdatesWithoutReselection()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Refresh Production Order updates the open summary without reselecting the order.
        Initialize();

        // [GIVEN] The open card has one operation, while its certified master routing now has two subcontract operations.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(1);
        AddSummaryRoutingOperations(ProductionOrder, false);
        Commit();

        // [WHEN] The real parent action recalculates the order from its changed master routing.
        ReleasedOrder.RefreshProductionOrder.Invoke();

        // [THEN] The same card immediately shows both subcontract operations without GoToRecord or reopening.
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(2);
        ReleasedOrder.Close();
    end;

    [RequestPageHandler]
    procedure SummaryRefreshProductionOrderHandler(var RefreshOrder: TestRequestPage "Refresh Production Order")
    begin
        RefreshOrder.CalcLines.SetValue(true);
        RefreshOrder.CalcRoutings.SetValue(true);
        RefreshOrder.CalcComponents.SetValue(true);
        RefreshOrder.CreateInbRqst.SetValue(false);
        RefreshOrder.OK().Invoke();
    end;

    [Test]
    procedure SummaryOrdinaryRefreshAndMembership()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReleasedOrder: TestPage "Released Production Order";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Persisted work-center membership is recalculated by the parent even while the part is hidden.
        Initialize();

        // [GIVEN] Eligible "A" has one current subcontract operation.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        VendorNo := WorkCenter."Subcontractor No.";
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(1);

        // [WHEN] The work center's subcontractor is cleared and the current record is reread.
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify(true);
        ReleasedOrder.GoToRecord(ProductionOrder);

        // [THEN] The parent hides the part, then restores it after the persisted vendor is restored.
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.Visible(), 'Cleared membership must hide the summary.');
        WorkCenter.Validate("Subcontractor No.", VendorNo);
        WorkCenter.Modify(true);
        ReleasedOrder.GoToRecord(ProductionOrder);
        Assert.IsTrue(ReleasedOrder.SubcontractingSummary.Visible(), 'Hidden part must become eligible again.');
        ReleasedOrder.SubcontractingSummary.RoutingCount.AssertEquals(1);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ReleasedOrder.GoToRecord(ProductionOrder);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.AssertEquals(10);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.AssertEquals(10);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.AssertEquals(0);
        ReleasedOrder.SubcontractingSummary.FullyInvoiced.AssertEquals(Format(false));
        ReleasedOrder.Close();
    end;

    [Test]
    procedure SummaryVisibilityAndPersonalizationContract()
    var
        ProductionOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        ReleasedOrder: TestPage "Released Production Order";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Eligible cards expose all nine read-only summary values by default; client personalization needs a client trace.
        Initialize();

        // [GIVEN] An eligible order without purchasing history.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);

        // [WHEN] Its actual card is opened for editing.
        ReleasedOrder.OpenEdit();
        ReleasedOrder.GoToRecord(ProductionOrder);

        // [THEN] The summary is visible, but none of its nine fields is editable.
        Assert.IsTrue(ReleasedOrder.SubcontractingSummary.Visible(), 'Eligible summary must be visible by default.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.RoutingCount.Editable(), 'Routing count is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.PurchaseQuantity.Editable(), 'Purchase quantity is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.ReceiptQuantity.Editable(), 'Receipt quantity is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.InvoiceQuantity.Editable(), 'Invoice quantity is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.FullyInvoiced.Editable(), 'Indicator is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.Editable(), 'WIP balance is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.WIPInTransit.Editable(), 'Transit balance is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.TransferCount.Editable(), 'Forward count is read-only.');
        Assert.IsFalse(ReleasedOrder.SubcontractingSummary.ReturnTransferCount.Editable(), 'Return count is read-only.');
        ReleasedOrder.SubcontractingSummary.FullyInvoiced.AssertEquals(Format(true));
        ReleasedOrder.Close();
    end;

    [Test]
    [HandlerFunctions('SummaryReadTransferCreatedHandler,SummaryReadPurchaseHandler,SummaryReadReceiptHandler,SummaryReadInvoiceHandler,SummaryReadWIPHandler,SummaryReadTransferHandler,SummaryRoutingHandler')]
    procedure SummaryReadPermissionsContract()
    var
        ProductionOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        WorkCenter: Record "Work Center";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        OtherPurchaseHeader: Record "Purchase Header";
        OtherPurchaseLine: Record "Purchase Line";
        ReceiptLine: Record "Purch. Rcpt. Line";
        InvoiceLine: Record "Purch. Inv. Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        RoutingLine: Record "Prod. Order Routing Line";
        WIPEntry: Record "Subcontractor WIP Ledger Entry";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        DirectPost: Codeunit "TransferOrder-Post Transfer";
        ReleasedOrder: TestPage "Released Production Order";
        OrderSystemModifiedAt: DateTime;
        WIPEntryCount: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 636866] Record actual card read permission use without treating this Disabled suite as an effective-user permission test.
        Initialize();

        // [GIVEN] A real production order is prepared before the read-only permission recording phase.
        SubcWarehouseLibrary.CreateSummaryOrder(10, ProductionOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(ProductionOrder, WorkCenter, PurchaseHeader, PurchaseLine);
        SubcWarehouseLibrary.CreateSummaryForward(ProductionOrder, WorkCenter, PurchaseHeader, TransferHeader);
        TransferHeader.Validate("Direct Transfer", true);
        TransferHeader.Validate("Direct Transfer Posting", TransferHeader."Direct Transfer Posting"::"Direct Transfer");
        TransferHeader.Modify(true);
        DirectPost.SetHideValidationDialog(true);
        DirectPost.Run(TransferHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        OrderSystemModifiedAt := ProductionOrder.SystemModifiedAt;
        WIPEntry.SetProductionOrderFilter(ProductionOrder, true);
        WIPEntryCount := WIPEntry.Count();

        // [GIVEN] A different order has a real posted invoice, while the current order has none.
        SubcWarehouseLibrary.CreateSummaryOrder(3, OtherOrder, WorkCenter);
        SubcWarehouseLibrary.CreateSummaryPurchase(OtherOrder, WorkCenter, OtherPurchaseHeader, OtherPurchaseLine);
        LibraryPurchase.PostPurchaseDocument(OtherPurchaseHeader, true, false);
        SubcWarehouseLibrary.PostSummaryInvoice(OtherPurchaseHeader, OtherPurchaseLine, 3);
#pragma warning disable AA0210 // Bounded foreign-order invoice fixture.
        InvoiceLine.SetRange("Prod. Order No.", OtherOrder."No.");
#pragma warning restore AA0210
        Assert.RecordIsNotEmpty(InvoiceLine);

        // [WHEN] The real consumer reads with Base Application read permissions and the owning extension role.
        LibraryLowerPermissions.StartLoggingNAVPermissions('Subcontract. - Read');
        LibraryLowerPermissions.AddeRead();
        SubcWarehouseLibrary.VerifySummaryCard(ProductionOrder, 1, 10, 10, 0, false, 10, 0, 0, 0);
        ReleasedOrder.OpenView();
        ReleasedOrder.GoToRecord(ProductionOrder);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.PurchaseQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(PurchaseLine.RecordId());
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.ReceiptQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
#pragma warning disable AA0210 // Bounded receipt fixture.
        ReceiptLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning restore AA0210
        ReceiptLine.FindFirst();
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(ReceiptLine.RecordId());
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.InvoiceQuantity.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(0);
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.WIPAtSubcontractor.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        WIPEntry.FindFirst();
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(WIPEntry.RecordId());
        ReleasedOrder.SubcontractingSummary.WIPInTransit.DrillDown();
        ReleasedOrder.SubcontractingSummary.TransferCount.DrillDown();
        ReleasedOrder.SubcontractingSummary.ReturnTransferCount.DrillDown();
        SubcWarehouseLibrary.StartSummaryDetailCapture();
        BindSubscription(SubcWarehouseLibrary);
        ReleasedOrder.SubcontractingSummary.RoutingCount.DrillDown();
        UnbindSubscription(SubcWarehouseLibrary);
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RoutingLine.FindFirst();
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(1);
        SubcWarehouseLibrary.VerifySummaryDetailRecord(RoutingLine.RecordId());
        Assert.AreEqual(1, LibraryVariableStorage.DequeueInteger(), 'Read-role routing detail must contain one operation.');
        Assert.AreEqual(ProductionOrder."No.", LibraryVariableStorage.DequeueText(), 'Read-role routing detail must retain current order.');
        Assert.AreEqual('10', LibraryVariableStorage.DequeueText(), 'Read-role routing detail must retain operation.');
        ReleasedOrder.Close();

        // [THEN] Reading has not modified the header. Actual non-SUPER access remains a separate client obligation.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.AreEqual(OrderSystemModifiedAt, ProductionOrder.SystemModifiedAt, 'Summary reads must not write the production order.');
        Assert.AreEqual(WIPEntryCount, WIPEntry.Count(), 'Summary details must not write WIP history.');
        TransferLine.SetRange("Subc. Prod. Order No.", ProductionOrder."No.");
        Assert.RecordIsEmpty(TransferLine);
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure AddSummaryRoutingOperations(var ProductionOrder: Record "Production Order"; RefreshOrder: Boolean)
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SecondWorkCenter: Record "Work Center";
        InternalWorkCenter: Record "Work Center";
    begin
        Item.Get(ProductionOrder."Source No.");
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::New);
        RoutingHeader.Modify(true);
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(SecondWorkCenter);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", SecondWorkCenter."No.");
        LibraryMfgManagement.CreateSubcontractingWorkCenterWithCalendar(InternalWorkCenter);
        InternalWorkCenter.Validate("Subcontractor No.", '');
        InternalWorkCenter.Modify(true);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '30', RoutingLine.Type::"Work Center", InternalWorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        if RefreshOrder then
            LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure VerifySummaryRoutingDetails(ProductionOrder: Record "Production Order")
    var
        RoutingLine: Record "Prod. Order Routing Line";
    begin
        RoutingLine.SetRange(Status, ProductionOrder.Status);
        RoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210 // Subcontracting is a FlowField; routing is already scoped to one order.
        RoutingLine.SetRange(Subcontracting, true);
#pragma warning restore AA0210
        SubcWarehouseLibrary.VerifySummaryDetailRecordCount(RoutingLine.Count());
        Assert.AreEqual(2, LibraryVariableStorage.DequeueInteger(), 'Exactly two qualifying operations must be shown.');
        RoutingLine.FindSet();
        repeat
            SubcWarehouseLibrary.VerifySummaryDetailRecord(RoutingLine.RecordId());
            Assert.AreEqual(ProductionOrder."No.", LibraryVariableStorage.DequeueText(), 'Detail must be scoped to current order.');
            Assert.AreEqual(RoutingLine."Operation No.", LibraryVariableStorage.DequeueText(), 'Detail operation must match the filtered routing.');
        until RoutingLine.Next() = 0;
    end;

    [PageHandler]
    procedure SummaryRoutingHandler(var Routing: TestPage "Prod. Order Routing")
    var
        OrderNumbers: List of [Text];
        OperationNumbers: List of [Text];
        RowIndex: Integer;
    begin
        if Routing.First() then
            repeat
                OrderNumbers.Add(Routing."Prod. Order No.".Value());
                OperationNumbers.Add(Routing."Operation No.".Value());
            until not Routing.Next();
        LibraryVariableStorage.Enqueue(OrderNumbers.Count());
        for RowIndex := 1 to OrderNumbers.Count() do begin
            LibraryVariableStorage.Enqueue(OrderNumbers.Get(RowIndex));
            LibraryVariableStorage.Enqueue(OperationNumbers.Get(RowIndex));
        end;
        Routing.Close();
    end;

    [PageHandler]
    procedure SummaryReadTransferCreatedHandler(var TransferOrder: TestPage "Transfer Order")
    begin
        TransferOrder.Close();
    end;

    [PageHandler]
    procedure SummaryReadPurchaseHandler(var Lines: TestPage "Purchase Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReadReceiptHandler(var Lines: TestPage "Purch. Receipt Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReadInvoiceHandler(var Lines: TestPage "Subc. Summary Invoice Lines")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Lines.First();
        while HasRecord do
            HasRecord := Lines.Next();
        Lines.Close();
    end;

    [PageHandler]
    procedure SummaryReadWIPHandler(var Entries: TestPage "Subc. WIP Ledger Entries")
    var
        HasRecord: Boolean;
    begin
        HasRecord := Entries.First();
        while HasRecord do
            HasRecord := Entries.Next();
        Entries.Close();
    end;

    [PageHandler]
    procedure SummaryReadTransferHandler(var Lines: TestPage "Transfer Lines")
    begin
        Lines.Close();
    end;

    local procedure Initialize()
    begin
        Clear(SubcWarehouseLibrary);
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Subcontracting UI Test");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Subcontracting UI Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Subcontracting UI Test");
    end;

    [Test]
    procedure SubcontractingAssistedSetupIsRegistered()
    var
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
    begin
        // [SCENARIO 642233] The Subcontracting assisted setup is registered with Guided Experience.
        Initialize();

        // [GIVEN] The Subcontracting assisted setup registration does not exist
        AssistedSetupTestLibrary.Delete(Page::"Subcontracting Setup Wizard");

        // [WHEN] Assisted setups are registered
        AssistedSetupTestLibrary.CallOnRegister();

        // [THEN] The Subcontracting setup wizard is registered
        Assert.IsTrue(AssistedSetupTestLibrary.Exists(Page::"Subcontracting Setup Wizard"), 'The Subcontracting assisted setup should be registered.');
    end;

    [Test]
    [HandlerFunctions('SetupNotCompletedConfirmHandler')]
    procedure SubcontractingSetupWizardShowsCompanyDefaultsAndConfigurationLinks()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcCompTransferLeadTime: DateFormula;
        SubcontractingSetupWizard: TestPage "Subcontracting Setup Wizard";
        SubcontractingBatchName: Code[10];
        SubcontractingTemplateName: Code[10];
        ComponentDirectUnitCost: Option Standard,"Prod. Order Component";
        CreateProdOrderInfoLine: Boolean;
        SubcDefaultCompLocation: Enum "Components at Location";
    begin
        // [SCENARIO 642233] The setup wizard displays the installed company defaults and the next configuration links.
        Initialize();

        // [GIVEN] The company has Subcontracting defaults
        ManufacturingSetup.Get();
        SubcontractingTemplateName := ManufacturingSetup."Subcontracting Template Name";
        SubcontractingBatchName := ManufacturingSetup."Subcontracting Batch Name";
        CreateProdOrderInfoLine := ManufacturingSetup."Create Prod. Order Info Line";
        ComponentDirectUnitCost := ManufacturingSetup."Component Direct Unit Cost";
        SubcCompTransferLeadTime := ManufacturingSetup."Subc. Comp. Transfer Lead Time";
        SubcDefaultCompLocation := ManufacturingSetup."Subc. Default Comp. Location";

        // [WHEN] The setup wizard is opened
        SubcontractingSetupWizard.OpenEdit();

        // [THEN] The welcome step is shown
        Assert.IsFalse(SubcontractingSetupWizard.ActionBack.Enabled(), 'Back should be disabled on the welcome step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be enabled on the welcome step.');
        Assert.IsFalse(SubcontractingSetupWizard.ActionFinish.Enabled(), 'Finish should be disabled on the welcome step.');

        // [WHEN] The user continues to company defaults
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [THEN] The defaults created during installation are displayed
        SubcontractingSetupWizard."Subcontracting Template Name".AssertEquals(SubcontractingTemplateName);
        SubcontractingSetupWizard."Subcontracting Batch Name".AssertEquals(SubcontractingBatchName);
        SubcontractingSetupWizard."Create Prod. Order Info Line".AssertEquals(CreateProdOrderInfoLine);
        SubcontractingSetupWizard."Component Direct Unit Cost".AssertEquals(ComponentDirectUnitCost);
        SubcontractingSetupWizard."Subc. Comp. Transfer Lead Time".AssertEquals(SubcCompTransferLeadTime);
        SubcontractingSetupWizard."Subc. Default Comp. Location".AssertEquals(SubcDefaultCompLocation);
        Assert.IsTrue(SubcontractingSetupWizard.ActionBack.Enabled(), 'Back should be enabled on the company defaults step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be enabled on the company defaults step.');

        // [WHEN] The user continues to the final step
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [THEN] Links to the remaining Subcontracting configuration are displayed
        Assert.IsTrue(SubcontractingSetupWizard.WorkCentersLink.Visible(), 'The work centers link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.VendorsLink.Visible(), 'The vendors link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.LocationsLink.Visible(), 'The locations link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.SubcontractorPricesLink.Visible(), 'The subcontractor prices link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.ComponentSupplyMethodsLink.Visible(), 'The component supply methods link should be visible.');
        Assert.IsTrue(SubcontractingSetupWizard.DocumentationLink.Visible(), 'The documentation link should be visible.');
        Assert.IsFalse(SubcontractingSetupWizard.ActionNext.Enabled(), 'Next should be disabled on the final step.');
        Assert.IsTrue(SubcontractingSetupWizard.ActionFinish.Enabled(), 'Finish should be enabled on the final step.');

        // [WHEN] The user closes the guide without finishing the setup
        LibraryVariableStorage.Enqueue(SetupNotCompletedQst);
        LibraryVariableStorage.Enqueue(true);
        SubcontractingSetupWizard.Close();

        // [THEN] The expected confirmation was handled
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Opening and navigating the guide did not replace the installed defaults
        ManufacturingSetup.Get();
        Assert.AreEqual(SubcontractingTemplateName, ManufacturingSetup."Subcontracting Template Name", 'The Subcontracting template default should be preserved.');
        Assert.AreEqual(SubcontractingBatchName, ManufacturingSetup."Subcontracting Batch Name", 'The Subcontracting batch default should be preserved.');
        Assert.AreEqual(CreateProdOrderInfoLine, ManufacturingSetup."Create Prod. Order Info Line", 'The production order information line default should be preserved.');
        Assert.AreEqual(ComponentDirectUnitCost, ManufacturingSetup."Component Direct Unit Cost", 'The component direct unit cost default should be preserved.');
        Assert.AreEqual(SubcCompTransferLeadTime, ManufacturingSetup."Subc. Comp. Transfer Lead Time", 'The component transfer lead time default should be preserved.');
        Assert.AreEqual(SubcDefaultCompLocation, ManufacturingSetup."Subc. Default Comp. Location", 'The default component location source should be preserved.');
    end;

    [Test]
    procedure FinishingSubcontractingSetupWizardSavesDefaultsAndCompletesAssistedSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        AssistedSetupTestLibrary: Codeunit "Assisted Setup Test Library";
        GuidedExperience: Codeunit "Guided Experience";
        CreateProdOrderInfoLine: Boolean;
        OriginalCreateProdOrderInfoLine: Boolean;
        SubcontractingSetupWizard: TestPage "Subcontracting Setup Wizard";
    begin
        // [SCENARIO 642233] Finishing the setup guide saves changes and marks the assisted setup as completed.
        Initialize();

        // [GIVEN] The Subcontracting assisted setup is registered and incomplete
        AssistedSetupTestLibrary.Delete(Page::"Subcontracting Setup Wizard");
        AssistedSetupTestLibrary.CallOnRegister();
        AssistedSetupTestLibrary.SetStatusToNotCompleted(Page::"Subcontracting Setup Wizard");
        Assert.IsFalse(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Subcontracting Setup Wizard"), 'The assisted setup should initially be incomplete.');

        // [GIVEN] A changed company default in the setup wizard
        ManufacturingSetup.Get();
        OriginalCreateProdOrderInfoLine := ManufacturingSetup."Create Prod. Order Info Line";
        CreateProdOrderInfoLine := not OriginalCreateProdOrderInfoLine;
        SubcontractingSetupWizard.OpenEdit();
        SubcontractingSetupWizard.ActionNext.Invoke();
        SubcontractingSetupWizard."Create Prod. Order Info Line".SetValue(CreateProdOrderInfoLine);
        SubcontractingSetupWizard.ActionNext.Invoke();

        // [WHEN] The user finishes the setup wizard
        SubcontractingSetupWizard.ActionFinish.Invoke();

        // [THEN] The company default is saved and the assisted setup is completed
        ManufacturingSetup.Get();
        Assert.AreEqual(CreateProdOrderInfoLine, ManufacturingSetup."Create Prod. Order Info Line", 'The changed company default should be saved.');
        Assert.IsTrue(GuidedExperience.IsAssistedSetupComplete(ObjectType::Page, Page::"Subcontracting Setup Wizard"), 'The assisted setup should be completed.');

        ManufacturingSetup."Create Prod. Order Info Line" := OriginalCreateProdOrderInfoLine;
        ManufacturingSetup.Modify();
    end;

    [Test]
    procedure ManufacturingSetupContainsDefaultComponentLocationSource()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        PageControl: Record "Page Control Field";
    begin
        // [SCENARIO 642233] Manufacturing Setup remains available for maintaining all Subcontracting company defaults.
        Initialize();

        // [WHEN] Controls on Manufacturing Setup are inspected
        PageControl.SetRange(TableNo, Database::"Manufacturing Setup");
        PageControl.SetRange(PageNo, Page::"Manufacturing Setup");
        PageControl.SetRange(FieldNo, ManufacturingSetup.FieldNo("Subc. Default Comp. Location"));

        // [THEN] Default Component Location Source is available for later maintenance
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ManufacturingSetup.FieldCaption("Subc. Default Comp. Location")));
    end;

    [Test]
    procedure ProdOrderCompLinesExposeTransferQuantities()
    var
        PageControl: Record "Page Control Field";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // [SCENARIO 650391] Prod. Order Comp. Lines exposes subcontracting transfer quantities.
        Initialize();

        // [WHEN] Controls on Prod. Order Comp. Lines are inspected
        // [THEN] Transfer quantities are available with the requested default visibility
        AssertPageControlExists(
            Database::"Prod. Order Component", Page::"Prod. Order Comp. Line List",
            ProdOrderComponent.FieldNo("Subc. Qty.on TransOrder (Base)"), 'Subc. Qty.on TransOrder (Base)');
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Prod. Order Component", Page::"Prod. Order Comp. Line List",
            ProdOrderComponent.FieldNo("Subc. Qty. in Transit (Base)"), 'Qty. in Transit (Base)');
        AssertPageControlExists(
            Database::"Prod. Order Component", Page::"Prod. Order Comp. Line List",
            ProdOrderComponent.FieldNo("Subc. Qty. transf. to Subcontr"), 'Subc. Qty. transf. to Subcontractor');
    end;

    [Test]
    procedure CommentPagesExposeOperationKeysAndFields()
    var
        PageAction: Record "Page Action";
        PageControl: Record "Page Control Field";
        SubcProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
    begin
        // [SCENARIO TP-001] Dedicated subcontracting comment pages expose their source operation keys and editable fields.
        Initialize();

        // [WHEN] Source pages expose navigation to dedicated subcontracting comments
        AssertPageActionRunsPage(PageAction, Page::"Standard Tasks", 'Subc. Subcontracting Comments', Page::"Subc. Standard Task Comments");
        AssertPageActionRunsPage(PageAction, Page::"Routing Lines", 'Subc. Subcontracting Comments', Page::"Subc. Routing Comments");
        AssertPageActionRunsPage(PageAction, Page::"Routing Version Lines", 'Subc. Subcontracting Comments', Page::"Subc. Routing Comments");
        AssertPageActionRunsPage(PageAction, Page::"Prod. Order Routing", 'Subc. Subcontracting Comments', Page::"Subc. Prod. Rtng. Comments");

        // [WHEN] Controls on each dedicated comment page are inspected
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Standard Task Code"), 'Standard Task Code');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Description 2"), 'Description 2');

        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Routing No."), 'Routing No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Version Code"), 'Version Code');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Operation No."), 'Operation No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Description 2"), 'Description 2');

        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo(Status), 'Status');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Prod. Order No."), 'Prod. Order No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Routing Reference No."), 'Routing Reference No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Routing No."), 'Routing No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Operation No."), 'Operation No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Line No."), 'Line No.');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo(Description), 'Description');
        AssertPageControlExists(
            Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Description 2"), 'Description 2');

        // [THEN] Ordinary routing comments are not a source for the dedicated page surface
        PageControl.SetRange(TableNo, Database::"Routing Comment Line");
        PageControl.SetRange(PageNo, Page::"Subc. Routing Comments");
        Assert.IsTrue(PageControl.IsEmpty(), 'The dedicated subcontracting routing comment page must not use ordinary routing comments.');
    end;

    [Test]
    procedure SubcontractingCommentDescription2IsHiddenInitially()
    var
        SubcProdOrderRoutingComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        PageControl: Record "Page Control Field";
    begin
        // [SCENARIO TP-031] Description 2 is initially hidden on each dedicated subcontracting comment page.
        Initialize();

        // [WHEN] The Description 2 control metadata is inspected on each dedicated comment page
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Standard Task Comment", Page::"Subc. Standard Task Comments",
            SubcStandardTaskComment.FieldNo("Description 2"), SubcStandardTaskComment.FieldCaption("Description 2"));
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Routing Comment Line", Page::"Subc. Routing Comments",
            SubcRoutingCommentLine.FieldNo("Description 2"), SubcRoutingCommentLine.FieldCaption("Description 2"));
        AssertPageControlIsInitiallyHidden(
            PageControl, Database::"Subc. Prod. Rtng. Comment", Page::"Subc. Prod. Rtng. Comments",
            SubcProdOrderRoutingComment.FieldNo("Description 2"), SubcProdOrderRoutingComment.FieldCaption("Description 2"));
    end;

    [Test]
    procedure SubcontractingCommentsEnabledOnlyForSubcontractingLines()
    var
        Item: Record Item;
        MachineCenter: array[2] of Record "Machine Center";
        NonSubcontractingProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NonSubcontractingRoutingLine: Record "Routing Line";
        NonSubcontractingRoutingVersionLine: Record "Routing Line";
        ProductionOrder: Record "Production Order";
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        SubcontractingProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcontractingRoutingLine: Record "Routing Line";
        SubcontractingRoutingVersionLine: Record "Routing Line";
        WorkCenter: array[2] of Record "Work Center";
        RoutingPage: TestPage Routing;
        RoutingVersionPage: TestPage "Routing Version";
        ProdOrderRouting: TestPage "Prod. Order Routing";
    begin
        // [SCENARIO TP-029] Dedicated subcontracting comments are enabled only for subcontracting operations.
        Initialize();

        // [GIVEN] A regular work center and a subcontracting work center
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, false);
        WorkCenter[2].Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter[2].Modify(true);

        // [GIVEN] A routing and routing version containing both work center types
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, NonSubcontractingRoutingLine, '', '10', NonSubcontractingRoutingLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, SubcontractingRoutingLine, '', '20', SubcontractingRoutingLine.Type::"Work Center", WorkCenter[2]."No.");
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingHeader."No.", 'V1');
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, NonSubcontractingRoutingVersionLine, RoutingVersion."Version Code", '10', NonSubcontractingRoutingVersionLine.Type::"Work Center", WorkCenter[1]."No.");
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, SubcontractingRoutingVersionLine, RoutingVersion."Version Code", '20', SubcontractingRoutingVersionLine.Type::"Work Center", WorkCenter[2]."No.");
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // [WHEN] Routing Lines is inspected for each operation type
        RoutingPage.OpenEdit();
        RoutingPage.GotoRecord(RoutingHeader);
        RoutingPage.RoutingLine.GotoRecord(NonSubcontractingRoutingLine);

        // [THEN] Subcontracting comments are disabled for a regular routing line
        Assert.IsFalse(RoutingPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular routing line.');

        RoutingPage.RoutingLine.GotoRecord(SubcontractingRoutingLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting routing line
        Assert.IsTrue(RoutingPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting routing line.');
        RoutingPage.Close();

        // [WHEN] Routing Version Lines is inspected for each operation type
        RoutingVersionPage.OpenEdit();
        RoutingVersionPage.GotoRecord(RoutingVersion);
        RoutingVersionPage.RoutingLine.GotoRecord(NonSubcontractingRoutingVersionLine);

        // [THEN] Subcontracting comments are disabled for a regular routing version line
        Assert.IsFalse(RoutingVersionPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular routing version line.');

        RoutingVersionPage.RoutingLine.GotoRecord(SubcontractingRoutingVersionLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting routing version line
        Assert.IsTrue(RoutingVersionPage.RoutingLine."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting routing version line.');
        RoutingVersionPage.Close();

        // [GIVEN] A released production order with regular and subcontracting operations
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 1);
        NonSubcontractingProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        NonSubcontractingProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        NonSubcontractingProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        NonSubcontractingProdOrderRoutingLine.FindFirst();
        SubcontractingProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        SubcontractingProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        SubcontractingProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        SubcontractingProdOrderRoutingLine.FindFirst();

        // [WHEN] Prod. Order Routing is inspected for each operation type
        ProdOrderRouting.OpenView();
        ProdOrderRouting.GotoRecord(NonSubcontractingProdOrderRoutingLine);

        // [THEN] Subcontracting comments are disabled for a regular production operation
        Assert.IsFalse(ProdOrderRouting."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be disabled for a regular production operation.');

        ProdOrderRouting.GotoRecord(SubcontractingProdOrderRoutingLine);

        // [THEN] Subcontracting comments are enabled for a subcontracting production operation
        Assert.IsTrue(ProdOrderRouting."Subc. Subcontracting Comments".Enabled(), 'Subcontracting comments should be enabled for a subcontracting production operation.');
        ProdOrderRouting.Close();
    end;


    [Test]
    procedure V1DoesNotExposeUnsupportedCommentOrAttachmentSetup()
    var
        PageControl: Record "Page Control Field";
        TableField: Record Field;
    begin
        // [SCENARIO TP-025] V1 comment and attachment surfaces do not expose unsupported metadata.
        Initialize();

        // [WHEN] Dedicated comment tables are inspected for unsupported translation and date metadata
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Standard Task Comment", 'Ending Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Routing Comment Line", 'Ending Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Vendor No.');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Language Code');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Starting Date');
        AssertTableFieldMissing(TableField, Database::"Subc. Prod. Rtng. Comment", 'Ending Date');

        // [THEN] Routing Lines do not expose operation-specific attachment selection
        AssertTableFieldMissing(TableField, Database::"Routing Line", 'Document Flow Production');
        AssertTableFieldMissing(TableField, Database::"Routing Line", 'Document Flow Purchase');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Lines", 'Document Flow Production');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Lines", 'Document Flow Purchase');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Version Lines", 'Document Flow Production');
        AssertPageControlMissing(PageControl, Database::"Routing Line", Page::"Routing Version Lines", 'Document Flow Purchase');
    end;

    [Test]
    procedure CheckCustCtrl_PagePurchaseOrderSubContractingLocationCode()
    var
        PageControl: Record "Page Control Field";
        PurchHeader: Record "Purchase Header";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Purchase Header"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Purchase Header");
        PageControl.SetRange(PageNo, Page::"Purchase Order");
        PageControl.SetRange(FieldNo, PurchHeader.FieldNo("Subc. Location Code"));
        ControlExist := not PageControl.IsEmpty();
        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PurchHeader.FieldCaption("Subc. Location Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PagePurchaseOrderSubContractingOrder()
    var
        PageControl: Record "Page Control Field";
        PurchHeader: Record "Purchase Header";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Purchase Header"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Purchase Header");
        PageControl.SetRange(PageNo, Page::"Purchase Order");
        PageControl.SetRange(FieldNo, PurchHeader.FieldNo("Subc. Order"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PurchHeader.FieldCaption("Subc. Order")));
    end;

    [Test]
    procedure CheckCustCtrl_PageVendorCardSubContractingLocationCode()
    var
        PageControl: Record "Page Control Field";
        Vendor: Record Vendor;
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Vendor Card"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::Vendor);
        PageControl.SetRange(PageNo, Page::"Vendor Card");
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Subc. Location Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Subc. Location Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PageVendorCardLinkedToWorkCenter()
    var
        PageControl: Record "Page Control Field";
        Vendor: Record Vendor;
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Vendor Card"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::Vendor);
        PageControl.SetRange(PageNo, Page::"Vendor Card");
        PageControl.SetRange(FieldNo, Vendor.FieldNo("Subc. Linked to Work Center"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, Vendor.FieldCaption("Subc. Linked to Work Center")));
    end;

    [Test]
    procedure CheckCustCtrl_PageSubcontractingWorksheetStandardTaskCode()
    var
        PageControl: Record "Page Control Field";
        ReqLine: Record "Requisition Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Subcontracting Worksheet"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Requisition Line");
        PageControl.SetRange(PageNo, Page::"Subc. Subcontracting Worksheet");
        PageControl.SetRange(FieldNo, ReqLine.FieldNo("Subc. Standard Task Code"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ReqLine.FieldCaption("Subc. Standard Task Code")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMLinesComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        ProdBOMLine: Record "Production BOM Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Production BOM Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Production BOM Line");
        PageControl.SetRange(PageNo, Page::"Production BOM Lines");
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure CheckCustCtrl_PageProductionBOMVersionLinesComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        ProdBOMLine: Record "Production BOM Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Production BOM Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Production BOM Line");
        PageControl.SetRange(PageNo, Page::"Production BOM Version Lines");
        PageControl.SetRange(FieldNo, ProdBOMLine.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();
        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, ProdBOMLine.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure CheckCustCtrl_PagePlanningComponentComponentSupplyMethod()
    var
        PageControl: Record "Page Control Field";
        PlanComp: Record "Planning Component";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO] Check if Controls exist on Page "Planning Components"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Planning Component");
        PageControl.SetRange(PageNo, Page::"Planning Components");
        PageControl.SetRange(FieldNo, PlanComp.FieldNo("Component Supply Method"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, PlanComp.FieldCaption("Component Supply Method")));
    end;

    [Test]
    procedure WorkCenterCardSubcontractingActionsHiddenWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontracting action group is not visible on Work Center Card when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is not enabled
        Assert.IsFalse(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsVisibleErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardSubcontractingActionsVisibleWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontracting action group is visible on Work Center Card when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is enabled
        Assert.IsTrue(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsNotVisibleErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardDispatchListDisabledWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontractor - Dispatch List action is disabled on Work Center Card when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor - Dispatch List action is not enabled
        Assert.IsFalse(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterCard.Close();
    end;

    [Test]
    procedure WorkCenterCardDispatchListEnabledWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 633206] Subcontractor - Dispatch List action is enabled on Work Center Card when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center Card page is opened for the Work Center
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GotoRecord(WorkCenter);

        // [THEN] Subcontractor - Dispatch List action is enabled
        Assert.IsTrue(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterCard.Close();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardPersistsPendingChangesWhenSubcontractorIsValidated()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 651344] Pending Work Center changes are persisted when Subcontractor No. is validated.
        Initialize();

        // [GIVEN] Work Center "WC" with time-based unit costs and configured subcontractor "V"
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Time);
        WorkCenter.Modify(true);
        CreateVendorWithSubcontractingLocation(Vendor);

        // [WHEN] Unit Cost Calculation is changed to Units and "V" is selected on the Work Center Card
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Unit Cost Calculation".SetValue(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");
        VerifySubcontractorLocationNotification('');

        // [THEN] Both changes remain on the page and are persisted
        WorkCenterCard."Unit Cost Calculation".AssertEquals(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard."Subcontractor No.".AssertEquals(Vendor."No.");
        WorkCenterCard.Close();
        WorkCenter.Get(WorkCenter."No.");
        Assert.AreEqual(WorkCenter."Unit Cost Calculation"::Units, WorkCenter."Unit Cost Calculation", 'Unit Cost Calculation should be persisted.');
        Assert.AreEqual(Vendor."No.", WorkCenter."Subcontractor No.", 'Subcontractor No. should be persisted.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardEnablesSubcontractingActionsAfterSettingSubcontractor()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637771] Subcontracting actions are enabled immediately after setting Subcontractor No.
        Initialize();

        // [GIVEN] Work Center "WC" without a subcontractor and configured subcontractor "V"
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        CreateVendorWithSubcontractingLocation(Vendor);
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);

        // [WHEN] "V" is selected as the subcontractor
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");
        VerifySubcontractorLocationNotification('');

        // [THEN] Subcontracting actions are enabled without reopening the card
        Assert.IsTrue(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsNotEnabledErr);
        Assert.IsTrue(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardDisablesSubcontractingActionsAfterClearingSubcontractor()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 637771] Subcontracting actions are disabled immediately after clearing Subcontractor No.
        Initialize();

        // [GIVEN] Work Center "WC" with configured subcontractor "V" and time-based unit costs
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        CreateVendorWithSubcontractingLocation(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Time);
        WorkCenter.Modify(true);
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);

        // [WHEN] Unit Cost Calculation is changed to Units and the subcontractor is cleared
        WorkCenterCard."Unit Cost Calculation".SetValue(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard."Subcontractor No.".SetValue('');
        VerifySubcontractorLocationNotification('');

        // [THEN] Subcontracting actions are disabled and the pending unit-cost change is persisted
        Assert.IsFalse(WorkCenterCard."Subcontractor Prices".Enabled(), SubcontractingActionsEnabledErr);
        Assert.IsFalse(WorkCenterCard."Subcontractor Dispatch List".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterCard."Unit Cost Calculation".AssertEquals(WorkCenter."Unit Cost Calculation"::Units);
        WorkCenterCard.Close();
        WorkCenter.Get(WorkCenter."No.");
        Assert.AreEqual(WorkCenter."Unit Cost Calculation"::Units, WorkCenter."Unit Cost Calculation", 'Unit Cost Calculation should be persisted.');
        Assert.AreEqual('', WorkCenter."Subcontractor No.", 'Subcontractor No. should be cleared.');
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardNotifiesWhenSubcontractorHasNoLocation()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] A notification identifies a subcontractor vendor that has no subcontracting location.
        Initialize();

        // [GIVEN] A Work Center and a vendor without a Subcontracting Location Code
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));

        // [WHEN] The vendor is selected as the subcontractor on the Work Center Card
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] Any previous notification is recalled before one notification is sent for that vendor
        VerifySubcontractorLocationNotification(Vendor."No.");
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardDoesNotStackSubcontractorLocationNotifications()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] Revalidating an unconfigured subcontractor replaces the existing notification.
        Initialize();

        // [GIVEN] A Work Center Card showing a notification for a vendor without a subcontracting location
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");
        VerifySubcontractorLocationNotification(Vendor."No.");

        // [WHEN] The same vendor is validated again
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] The previous notification is recalled before its replacement is sent with the same notification ID
        VerifySubcontractorLocationNotification(Vendor."No.");
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationHandler,SubcontractorLocationRecallHandler')]
    procedure WorkCenterCardRecallsSubcontractorLocationNotificationWhenNoLongerNeeded()
    var
        Location: Record Location;
        ConfiguredVendor: Record Vendor;
        UnconfiguredVendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] A previous notification is removed when the subcontractor is configured or cleared.
        Initialize();

        // [GIVEN] An unconfigured vendor, a configured vendor, and a Work Center Card showing the notification
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        UnconfiguredVendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        ConfiguredVendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        ConfiguredVendor.Validate("Subc. Location Code", Location.Code);
        ConfiguredVendor.Modify(true);
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(UnconfiguredVendor."No.");
        VerifySubcontractorLocationNotification(UnconfiguredVendor."No.");

        // [WHEN] The configured vendor is selected
        WorkCenterCard."Subcontractor No.".SetValue(ConfiguredVendor."No.");

        // [THEN] The previous notification is recalled and no notification is sent for the configured vendor
        VerifySubcontractorLocationNotification('');

        // [WHEN] The unconfigured vendor is selected again
        WorkCenterCard."Subcontractor No.".SetValue(UnconfiguredVendor."No.");

        // [THEN] The previous notification is recalled before a new notification is sent
        VerifySubcontractorLocationNotification(UnconfiguredVendor."No.");

        // [WHEN] The subcontractor is cleared
        WorkCenterCard."Subcontractor No.".SetValue('');

        // [THEN] The notification is recalled without sending another one
        VerifySubcontractorLocationNotification('');
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SubcontractorLocationNotificationActionHandler,SubcontractorLocationRecallHandler,VendorCardHandler')]
    procedure WorkCenterCardSubcontractorLocationNotificationActionOpensVendorCard()
    var
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        WorkCenterCard: TestPage "Work Center Card";
    begin
        // [SCENARIO 642229] The notification action opens the selected subcontractor vendor.
        Initialize();

        // [GIVEN] A Work Center and a vendor without a Subcontracting Location Code
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));

        // [WHEN] The vendor is selected as the subcontractor and the notification action is invoked
        WorkCenterCard.OpenEdit();
        WorkCenterCard.GoToRecord(WorkCenter);
        WorkCenterCard."Subcontractor No.".SetValue(Vendor."No.");

        // [THEN] The notification is sent for the vendor and the Vendor Card opens for that vendor
        VerifySubcontractorLocationNotification(Vendor."No.");
        Assert.AreEqual(Vendor."No.", LibraryVariableStorage.DequeueText(), VendorCardNoErr);
        WorkCenterCard.Close();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure WorkCenterListSubcontractingActionsDisabledWhenNotSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: TestPage "Work Center List";
    begin
        // [SCENARIO 633206] Subcontractor Prices action is disabled on Work Center List when Work Center has no Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center without a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);

        // [WHEN] The Work Center List page is opened and navigated to the Work Center
        WorkCenterList.OpenEdit();
        WorkCenterList.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is not enabled
        Assert.IsFalse(WorkCenterList."Subcontractor Prices".Enabled(), SubcontractingActionsEnabledErr);
        WorkCenterList.Close();
    end;

    [Test]
    procedure WorkCenterListSubcontractingActionsEnabledWhenSubcontracting()
    var
        WorkCenter: Record "Work Center";
        WorkCenterList: TestPage "Work Center List";
    begin
        // [SCENARIO 633206] Subcontractor Prices action is enabled on Work Center List when Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [WHEN] The Work Center List page is opened and navigated to the Work Center
        WorkCenterList.OpenEdit();
        WorkCenterList.GotoRecord(WorkCenter);

        // [THEN] Subcontractor Prices action is enabled
        Assert.IsTrue(WorkCenterList."Subcontractor Prices".Enabled(), SubcontractingActionsNotEnabledErr);
        WorkCenterList.Close();
    end;

    [Test]
    [HandlerFunctions('HandlePostedPurchaseReceiptPage')]
    procedure CapLedgerEntriesShowDocumentOpensPostedReceipt()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Posted Purchase Receipt when Document No. matches a receipt
        Initialize();

        // [GIVEN] A Posted Purchase Receipt
        PurchRcptHeader.Init();
        PurchRcptHeader."No." := 'TEST-RCPT-001';
        if not PurchRcptHeader.Insert() then
            PurchRcptHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Document No. pointing to the receipt
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := PurchRcptHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Posted Purchase Receipt page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();
    end;

    [Test]
    [HandlerFunctions('HandlePostedPurchaseInvoicePage')]
    procedure CapLedgerEntriesShowDocumentOpensPostedInvoice()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchInvHeader: Record "Purch. Inv. Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Posted Purchase Invoice when Document No. matches an invoice
        Initialize();

        // [GIVEN] A Posted Purchase Invoice (no matching receipt)
        PurchInvHeader.Init();
        PurchInvHeader."No." := 'TEST-INV-001';
        if not PurchInvHeader.Insert() then
            PurchInvHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Document No. pointing to the invoice
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := PurchInvHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Posted Purchase Invoice page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();

        // Cleanup
        CapacityLedgerEntry.Delete();
        PurchInvHeader.Delete();
    end;

    [Test]
    [HandlerFunctions('HandlePurchaseOrderPage')]
    procedure CapLedgerEntriesShowDocumentOpensPurchaseOrder()
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 620656] Show Document action opens Purchase Order when no posted document exists
        Initialize();

        // [GIVEN] A Purchase Order
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := 'TEST-PO-001';
        if not PurchaseHeader.Insert() then
            PurchaseHeader.Modify();

        // [GIVEN] A Capacity Ledger Entry with Subc. Purch. Order No. but no matching posted document
        CapacityLedgerEntry.Init();
        CapacityLedgerEntry."Entry No." := GetNextCapLedgerEntryNo();
        CapacityLedgerEntry."Document No." := '';
        CapacityLedgerEntry."Subc. Purch. Order No." := PurchaseHeader."No.";
        CapacityLedgerEntry.Insert();

        // [WHEN] The Show Document action is invoked
        CapacityLedgerEntries.OpenView();
        CapacityLedgerEntries.GoToRecord(CapacityLedgerEntry);
        CapacityLedgerEntries.ShowDocument.Invoke();

        // [THEN] The Purchase Order page is opened (verified by PageHandler)
        CapacityLedgerEntries.Close();

        // Cleanup
        CapacityLedgerEntry.Delete();
        PurchaseHeader.Delete();
    end;

    [Test]
    procedure CheckCustCtrl_PageRoutingVersionLinesTransferWIPItem()
    var
        PageControl: Record "Page Control Field";
        RoutingLine: Record "Routing Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO 638530] Check if Transfer WIP Item control exists on Page "Routing Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Routing Line");
        PageControl.SetRange(PageNo, Page::"Routing Version Lines");
        PageControl.SetRange(FieldNo, RoutingLine.FieldNo("Transfer WIP Item"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, RoutingLine.FieldCaption("Transfer WIP Item")));
    end;

    [Test]
    procedure CheckCustCtrl_PageRoutingVersionLinesTransferDescription()
    var
        PageControl: Record "Page Control Field";
        RoutingLine: Record "Routing Line";
        ControlExist: Boolean;
    begin
        // [FEATURE] Subcontracting Management
        // [SCENARIO 638530] Check if Transfer Description control exists on Page "Routing Version Lines"

        // [GIVEN]
        Initialize();

        // [WHEN] Find Control on Page
        PageControl.SetRange(TableNo, Database::"Routing Line");
        PageControl.SetRange(PageNo, Page::"Routing Version Lines");
        PageControl.SetRange(FieldNo, RoutingLine.FieldNo("Transfer Description"));
        ControlExist := not PageControl.IsEmpty();

        // [THEN]
        Assert.AreEqual(true, ControlExist, StrSubstNo(ControlNotExistMsg, RoutingLine.FieldCaption("Transfer Description")));
    end;

    local procedure AssertPageControlExists(ControlTableNo: Integer; ControlPageNo: Integer; ControlFieldNo: Integer; ControlNameValue: Text)
    var
        PageControl: Record "Page Control Field";
    begin
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(FieldNo, ControlFieldNo);
        PageControl.SetRange(ControlName, ControlNameValue);
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ControlNameValue));
    end;

    local procedure AssertPageControlIsInitiallyHidden(var PageControl: Record "Page Control Field"; ControlTableNo: Integer; ControlPageNo: Integer; ControlFieldNo: Integer; ControlFieldCaption: Text)
    begin
        PageControl.Reset();
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(FieldNo, ControlFieldNo);
        Assert.IsFalse(PageControl.IsEmpty(), StrSubstNo(ControlNotExistMsg, ControlFieldCaption));
        PageControl.FindFirst();
        Assert.AreEqual('false', LowerCase(PageControl.Visible), StrSubstNo(ControlShouldBeHiddenErr, ControlFieldCaption, ControlPageNo));
    end;

    local procedure AssertPageActionRunsPage(var PageAction: Record "Page Action"; SourcePageNo: Integer; ActionName: Text; TargetPageNo: Integer)
    begin
        PageAction.Reset();
        PageAction.SetRange("Page ID", SourcePageNo);
        PageAction.SetRange(Name, ActionName);
        Assert.IsFalse(PageAction.IsEmpty(), StrSubstNo(ActionNotExistMsg, ActionName, SourcePageNo));
        PageAction.FindFirst();
        Assert.AreEqual(TargetPageNo, PageAction.RunObjectID, StrSubstNo(ActionTargetUnexpectedMsg, ActionName, TargetPageNo));
    end;

    local procedure AssertPageControlMissing(var PageControl: Record "Page Control Field"; ControlTableNo: Integer; ControlPageNo: Integer; ControlNameValue: Text)
    begin
        PageControl.Reset();
        PageControl.SetRange(TableNo, ControlTableNo);
        PageControl.SetRange(PageNo, ControlPageNo);
        PageControl.SetRange(ControlName, ControlNameValue);
        Assert.IsTrue(PageControl.IsEmpty(), StrSubstNo(UnsupportedControlExistsMsg, ControlNameValue, ControlPageNo));
    end;

    local procedure AssertTableFieldMissing(var TableField: Record Field; TableNumber: Integer; FieldNameValue: Text)
    begin
        TableField.Reset();
        TableField.SetRange(TableNo, TableNumber);
        TableField.SetRange(FieldName, FieldNameValue);
        Assert.IsTrue(TableField.IsEmpty(), StrSubstNo(UnsupportedFieldExistsMsg, FieldNameValue, TableNumber));
    end;

    local procedure GetNextCapLedgerEntryNo(): Integer
    var
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
    begin
        if CapacityLedgerEntry.FindLast() then
            exit(CapacityLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    local procedure VerifySubcontractorLocationNotification(VendorNo: Code[20])
    begin
        Assert.AreEqual(RecallNotificationTok, LibraryVariableStorage.DequeueText(), NotificationOrderErr);
        Assert.AreEqual(Format(GetMissingSubcontractingLocationNotificationId()), LibraryVariableStorage.DequeueText(), NotificationIdErr);
        if VendorNo <> '' then begin
            Assert.AreEqual(SendNotificationTok, LibraryVariableStorage.DequeueText(), NotificationOrderErr);
            Assert.AreEqual(Format(GetMissingSubcontractingLocationNotificationId()), LibraryVariableStorage.DequeueText(), NotificationIdErr);
            Assert.AreEqual(StrSubstNo(MissingSubcontractingLocationMsg, VendorNo), LibraryVariableStorage.DequeueText(), NotificationMessageErr);
            Assert.AreEqual(VendorNo, LibraryVariableStorage.DequeueText(), NotificationVendorErr);
        end;
    end;

    local procedure GetMissingSubcontractingLocationNotificationId(): Guid
    begin
        exit('{8A4B9A58-21EC-49DD-A3A5-C7E81F745B6D}');
    end;

    [SendNotificationHandler]
    procedure SubcontractorLocationNotificationHandler(var SubcontractorLocationNotification: Notification): Boolean
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        CaptureSubcontractorLocationNotification(SubcontractorLocationNotification);
        exit(true);
    end;

    [SendNotificationHandler]
    procedure SubcontractorLocationNotificationActionHandler(var SubcontractorLocationNotification: Notification): Boolean
    var
        SubcNotificationMgmt: Codeunit "Subc. Notification Mgmt.";
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        CaptureSubcontractorLocationNotification(SubcontractorLocationNotification);
        // Simulate choosing the Open Vendor Card notification action.
        SubcNotificationMgmt.OpenVendorCard(SubcontractorLocationNotification);
        exit(true);
    end;

    local procedure CaptureSubcontractorLocationNotification(SubcontractorLocationNotification: Notification)
    begin
        LibraryVariableStorage.Enqueue(SendNotificationTok);
        LibraryVariableStorage.Enqueue(Format(SubcontractorLocationNotification.Id));
        LibraryVariableStorage.Enqueue(SubcontractorLocationNotification.Message);
        LibraryVariableStorage.Enqueue(SubcontractorLocationNotification.GetData(VendorNoTok));
    end;

    [RecallNotificationHandler]
    procedure SubcontractorLocationRecallHandler(var SubcontractorLocationNotification: Notification): Boolean
    begin
        if SubcontractorLocationNotification.Id <> GetMissingSubcontractingLocationNotificationId() then
            exit(false);

        LibraryVariableStorage.Enqueue(RecallNotificationTok);
        LibraryVariableStorage.Enqueue(Format(SubcontractorLocationNotification.Id));
        exit(true);
    end;

    [PageHandler]
    procedure VendorCardHandler(var VendorCard: TestPage "Vendor Card")
    begin
        LibraryVariableStorage.Enqueue(VendorCard."No.".Value());
        VendorCard.Close();
    end;

    [PageHandler]
    procedure HandlePostedPurchaseReceiptPage(var PostedPurchaseReceipt: TestPage "Posted Purchase Receipt")
    begin
        PostedPurchaseReceipt.Close();
    end;

    [PageHandler]
    procedure HandlePostedPurchaseInvoicePage(var PostedPurchaseInvoice: TestPage "Posted Purchase Invoice")
    begin
        PostedPurchaseInvoice.Close();
    end;

    [PageHandler]
    procedure HandlePurchaseOrderPage(var PurchaseOrder: TestPage "Purchase Order")
    begin
        PurchaseOrder.Close();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcActionsDisabledWhenNotSubcontracting()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 638458] Subcontracting actions on Item Ledger Entries are disabled when the entry has no subcontracting production order or purchase order.
        Initialize();

        // [GIVEN] An Item Ledger Entry that is NOT related to subcontracting (no production order or Subc. Purch. Order No.)
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry."Order No." := '';
        ItemLedgerEntry."Subc. Purch. Order No." := '';
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Production Order Routing action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Production Order Components action is disabled
        Assert.IsFalse(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsEnabledErr);
        // [THEN] The Purchase Order action is disabled
        Assert.IsFalse(ItemLedgerEntries."Purchase Order".Enabled(), ILEPurchActionsEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcActionsEnabledWhenSubcontracting()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 638458] Subcontracting actions on Item Ledger Entries are enabled when the entry is related to a subcontracting production order and purchase order.
        Initialize();

        // [GIVEN] An Item Ledger Entry that IS related to subcontracting
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Purchase;
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Production;
        ItemLedgerEntry."Order No." := 'PO-SUBC-001';
        ItemLedgerEntry."Order Line No." := 10000;
        ItemLedgerEntry."Subc. Purch. Order No." := 'PURCH-SUBC-001';
        ItemLedgerEntry."Subc. Purch. Order Line No." := 10000;
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Routing action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Components action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Purchase Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Purchase Order".Enabled(), ILEPurchActionsNotEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure ItemLedgerEntriesSubcProdActionsEnabledForTransferViaSubcProdOrder()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 641405] Subcontracting production actions on Item Ledger Entries are enabled for a Transfer-type entry
        // [SCENARIO 641405] whose production order is referenced only through the Subc. Prod. Order fields (the base Order No. holds the transfer order).
        Initialize();

        // [GIVEN] A Transfer-type Item Ledger Entry whose base Order fields point at a transfer order,
        //         while the production order is only referenced through the Subc. Prod. Order fields
        ItemLedgerEntry.Init();
        ItemLedgerEntry."Entry No." := GetNextItemLedgerEntryNo();
        ItemLedgerEntry."Item No." := 'TEST-ITEM';
        ItemLedgerEntry."Entry Type" := ItemLedgerEntry."Entry Type"::Transfer;
        ItemLedgerEntry."Order Type" := ItemLedgerEntry."Order Type"::Transfer;
        ItemLedgerEntry."Order No." := 'TRANSFER-001';
        ItemLedgerEntry."Order Line No." := 10000;
        ItemLedgerEntry."Subc. Prod. Order No." := 'PO-SUBC-001';
        ItemLedgerEntry."Subc. Prod. Order Line No." := 10000;
        ItemLedgerEntry.Insert();

        // [WHEN] The Item Ledger Entries page is opened for that entry
        ItemLedgerEntries.OpenView();
        ItemLedgerEntries.GoToRecord(ItemLedgerEntry);

        // [THEN] The Production Order action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Routing action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Routing".Enabled(), ILEProdActionsNotEnabledErr);
        // [THEN] The Production Order Components action is enabled
        Assert.IsTrue(ItemLedgerEntries."Production Order Components".Enabled(), ILEProdActionsNotEnabledErr);

        ItemLedgerEntries.Close();

        // Cleanup
        ItemLedgerEntry.Delete();
    end;

    [Test]
    procedure RoutingLinesTransferWIPItemDisabledForMachineCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLines: TestPage "Routing Lines";
        MachineCenterNo: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is disabled on Routing Lines page for a Machine Center routing line,
        // even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLineForMachineCenter(RoutingLine, RoutingHeader, MachineCenterNo);

        // [WHEN] The Routing Lines page is opened for that line
        RoutingLines.OpenEdit();
        RoutingLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is not enabled (Machine Center type is not eligible for Transfer WIP Item)
        Assert.IsFalse(RoutingLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPEnabledErr);
        RoutingLines.Close();
    end;

    [Test]
    procedure RoutingLinesTransferWIPItemEnabledForSubcontractingWorkCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLines: TestPage "Routing Lines";
    begin
        // [SCENARIO] Transfer WIP Item field is enabled on Routing Lines page for a Work Center routing line
        // when the Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Routing with a Work Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");

        // [WHEN] The Routing Lines page is opened for that line
        RoutingLines.OpenEdit();
        RoutingLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is enabled (subcontracting Work Center type)
        Assert.IsTrue(RoutingLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPNotEnabledErr);
        RoutingLines.Close();
    end;

    [Test]
    procedure RoutingVersionLinesTransferWIPItemDisabledForMachineCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersionLines: TestPage "Routing Version Lines";
        MachineCenterNo: Code[20];
        VersionCode: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is disabled on Routing Version Lines page for a Machine Center
        // routing line, even when the parent Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing Version with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        VersionCode := '1';
        CreateRoutingVersionAndMachineCenterLine(RoutingHeader."No.", VersionCode, MachineCenterNo, RoutingLine);

        // [WHEN] The Routing Version Lines page is opened for that line
        RoutingVersionLines.OpenEdit();
        RoutingVersionLines.Filter.SetFilter("Routing No.", RoutingHeader."No.");
        RoutingVersionLines.Filter.SetFilter("Version Code", VersionCode);
        RoutingVersionLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is not enabled (Machine Center type is not eligible for Transfer WIP Item)
        Assert.IsFalse(RoutingVersionLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPEnabledErr);
        RoutingVersionLines.Close();
    end;

    [Test]
    procedure RoutingVersionLinesTransferWIPItemEnabledForSubcontractingWorkCenterLine()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersionLines: TestPage "Routing Version Lines";
        VersionCode: Code[20];
    begin
        // [SCENARIO] Transfer WIP Item field is enabled on Routing Version Lines page for a Work Center routing line
        // when the Work Center has a Subcontractor No.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Routing Version with a Work Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        VersionCode := '1';
        CreateRoutingVersionAndWorkCenterLine(RoutingHeader."No.", VersionCode, WorkCenter."No.", RoutingLine);

        // [WHEN] The Routing Version Lines page is opened for that line
        RoutingVersionLines.OpenEdit();
        RoutingVersionLines.Filter.SetFilter("Routing No.", RoutingHeader."No.");
        RoutingVersionLines.Filter.SetFilter("Version Code", VersionCode);
        RoutingVersionLines.GoToRecord(RoutingLine);

        // [THEN] Transfer WIP Item is enabled (subcontracting Work Center type)
        Assert.IsTrue(RoutingVersionLines."Transfer WIP Item".Enabled(), RoutingLineTransferWIPNotEnabledErr);
        RoutingVersionLines.Close();
    end;

    [Test]
    procedure RoutingLineTransferWIPItemValidationFailsForMachineCenterType()
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        MachineCenterNo: Code[20];
    begin
        // [SCENARIO] Validating Transfer WIP Item = true on a Machine Center routing line fails
        // with an error because the Type must be Work Center.
        Initialize();

        // [GIVEN] A Work Center with a Subcontractor No.
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        WorkCenter.Modify(true);

        // [GIVEN] A Machine Center belonging to that Work Center
        LibraryMfgManagement.CreateMachineCenter(MachineCenterNo, WorkCenter."No.", 0);

        // [GIVEN] A Routing with a Machine Center routing line
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryMfgManagement.CreateRoutingLineForMachineCenter(RoutingLine, RoutingHeader, MachineCenterNo);

        // [WHEN] Transfer WIP Item is set to true on the Machine Center routing line
        // [THEN] An error is raised because the line type must be Work Center
        asserterror RoutingLine.Validate("Transfer WIP Item", true);
        Assert.ExpectedTestFieldError(RoutingLine.FieldCaption(Type), Format(RoutingLine.Type::"Work Center"));
    end;

    local procedure CreateRoutingVersionAndWorkCenterLine(RoutingNo: Code[20]; VersionCode: Code[20]; WorkCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingVersion: Record "Routing Version";
        CapacityUoM: Record "Capacity Unit of Measure";
    begin
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingNo);
        RoutingVersion."Version Code" := VersionCode;
        RoutingVersion.Insert(true);

#pragma warning disable AA0210
        CapacityUoM.SetRange(Type, CapacityUoM.Type::Minutes);
#pragma warning restore AA0210
        CapacityUoM.FindFirst();

        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", RoutingNo);
        RoutingLine.Validate("Version Code", VersionCode);
        RoutingLine.Validate("Operation No.", '10');
        RoutingLine.Validate(Type, RoutingLine.Type::"Work Center");
        RoutingLine.Validate("No.", WorkCenterNo);
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Insert(true);
    end;

    local procedure CreateRoutingVersionAndMachineCenterLine(RoutingNo: Code[20]; VersionCode: Code[20]; MachineCenterNo: Code[20]; var RoutingLine: Record "Routing Line")
    var
        RoutingVersion: Record "Routing Version";
        CapacityUoM: Record "Capacity Unit of Measure";
    begin
        RoutingVersion.Init();
        RoutingVersion.Validate("Routing No.", RoutingNo);
        RoutingVersion."Version Code" := VersionCode;
        RoutingVersion.Insert(true);

#pragma warning disable AA0210
        CapacityUoM.SetRange(Type, CapacityUoM.Type::Minutes);
#pragma warning restore AA0210
        CapacityUoM.FindFirst();

        RoutingLine.Init();
        RoutingLine.Validate("Routing No.", RoutingNo);
        RoutingLine.Validate("Version Code", VersionCode);
        RoutingLine.Validate("Operation No.", '10');
        RoutingLine.Validate(Type, RoutingLine.Type::"Machine Center");
        RoutingLine.Validate("No.", MachineCenterNo);
        RoutingLine.Validate("Setup Time", 1);
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUoM.Code);
        RoutingLine.Insert(true);
    end;

    local procedure CreateVendorWithSubcontractingLocation(var Vendor: Record Vendor)
    var
        Location: Record Location;
    begin
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Vendor.Validate("Subc. Location Code", Location.Code);
        Vendor.Modify(true);
    end;

    local procedure GetNextItemLedgerEntryNo(): Integer
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgerEntry.FindLast() then
            exit(ItemLedgerEntry."Entry No." + 1);
        exit(1);
    end;

    [ConfirmHandler]
    procedure SetupNotCompletedConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    var
        Assert: Codeunit Assert;
        VROrder: Record "Production Order";
        VROtherOrder: Record "Production Order";
        VRItem: Record Item;
        VRComponentItem: array[2] of Record Item;
        VRVendor: array[5] of Record Vendor;
        VRWorkCenter: array[4] of Record "Work Center";
        VRRouting: array[4] of Record "Prod. Order Routing Line";
        VRReq: Record "Requisition Line";
        VRBatch: Record "Requisition Wksh. Name";
        VRMain: Record Location;
        VREast: Record Location;
        VRWest: Record Location;
        VRLink: Record "Routing Link";
        VRTask: Record "Standard Task";
        VRSavedWorkDate: Date;
        VRBusinessBefore: Text;
        VRMastersBefore: Text;
        VRDisplayedPurchase: Code[20];
        VRDisplayedReturn: Boolean;
        VRVendorQuestionCount: Integer;
        VRCalculateCallbackCount: Integer;
        VRCarryOutCallbackCount: Integer;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        IsInitialized: Boolean;
        ActionNotExistMsg: Label 'Action %1 does not exist on page %2.', Comment = '%1 = action name, %2 = page number';
        ActionTargetUnexpectedMsg: Label 'Action %1 does not run page %2.', Comment = '%1 = action name, %2 = target page number';
        ControlNotExistMsg: Label 'Control %1 does not exist.', Comment = '%1 = field caption';
        ControlShouldBeHiddenErr: Label 'The %1 control on page %2 should be initially hidden.', Comment = '%1 = field caption, %2 = page number';
        UnsupportedControlExistsMsg: Label 'Unsupported control %1 exists on page %2.', Comment = '%1 = control name, %2 = page number';
        UnsupportedFieldExistsMsg: Label 'Unsupported field %1 exists on table %2.', Comment = '%1 = field name, %2 = table number';
        SubcontractingActionsVisibleErr: Label 'Subcontractor Prices action should not be visible for a non-subcontracting Work Center.';
        SubcontractingActionsEnabledErr: Label 'Subcontractor Prices action should not be enabled for a non-subcontracting Work Center.';
        SubcontractingActionsNotVisibleErr: Label 'Subcontractor Prices action should be visible for a subcontracting Work Center.';
        SubcontractingActionsNotEnabledErr: Label 'Subcontractor Prices action should be enabled for a subcontracting Work Center.';
        ILEProdActionsEnabledErr: Label 'Production actions should not be enabled for a non-subcontracting Item Ledger Entry.';
        ILEProdActionsNotEnabledErr: Label 'Production actions should be enabled for a subcontracting Item Ledger Entry.';
        ILEPurchActionsEnabledErr: Label 'Purchase Order action should not be enabled for a non-subcontracting Item Ledger Entry.';
        ILEPurchActionsNotEnabledErr: Label 'Purchase Order action should be enabled for a subcontracting Item Ledger Entry.';
        RoutingLineTransferWIPEnabledErr: Label 'Transfer WIP Item should not be enabled for a Machine Center routing line.';
        RoutingLineTransferWIPNotEnabledErr: Label 'Transfer WIP Item should be enabled for a subcontracting Work Center routing line.';
        SetupNotCompletedQst: Label 'The Subcontracting setup is not complete. Are you sure you want to exit?';
        MissingSubcontractingLocationMsg: Label 'Vendor %1 has no subcontracting location. This location is used to track components and work-in-process (WIP) items at the subcontractor. Choose a Subcontracting Location Code on the vendor before using this work center for subcontracting.', Comment = '%1 = Vendor No.';
        NotificationIdErr: Label 'The subcontractor location notification ID is unexpected.';
        NotificationMessageErr: Label 'The subcontractor location notification message is unexpected.';
        NotificationOrderErr: Label 'The subcontractor location notification interactions occurred in an unexpected order.';
        NotificationVendorErr: Label 'The vendor in the subcontractor location notification is unexpected.';
        RecallNotificationTok: Label 'Recall', Locked = true;
        SendNotificationTok: Label 'Send', Locked = true;
        VendorCardNoErr: Label 'The Vendor Card opened for an unexpected vendor.';
        VendorNoTok: Label 'VendorNo', Locked = true;
}