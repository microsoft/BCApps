// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;
using System.Environment;
using System.Upgrade;

codeunit 139994 "Subc. ReqWkshTemplUpgrade Test"
{
    // [FEATURE] Subcontracting Req. Wksh. Template Type Upgrade
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;
    RequiredTestIsolation = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        CopySourceNo: Code[20];
        FailCutoverOrderNo: Code[20];

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CutoverSerializesHeaderCreation()
    var
        Workers: Codeunit "Subc WIP Concurrent Worker";
    begin
        Workers.ExerciseHeaderRace();
    end;

    [Test]
    procedure ImmutableWIPIdentityErrorHidesInternalDiagnostics()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        ProductionOrder.Status := ProductionOrder.Status::Planned;
        ProductionOrder."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ProductionOrder."No."));
        ProductionOrder.Insert(false);
        ProductionOrder."Subc. WIP Version" += 1;

        asserterror ProductionOrder.Modify(false);
        Assert.ExpectedErrorCode('Dialog');
        Assert.IsFalse(GetLastErrorText(true).Contains('The subcontracting WIP identity'), 'Internal bookkeeping diagnostics must not be exposed as an actionable client error.');
    end;

    [Test]
    procedure CutoverRetryAndCompanyIsolation()
    var
        ExistingOrder: Record "Production Order";
        OtherOrder: Record "Production Order";
        Activation: Record "Subc. WIP Activation";
        OtherActivation: Record "Subc. WIP Activation";
        Alias: Record "Subc. WIP Order Alias";
        Company: Record Company;
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        UpgradeFixture: Codeunit "Subc. WIP Upgrade Fixture";
        FailureSubscriber: Codeunit "Subc. ReqWkshTemplUpgrade Test";
        LineageID: Guid;
        ActivationID: Guid;
        ActivationCreatedAt: DateTime;
        AliasCount: Integer;
    begin
        Initialize();
        ExistingOrder.Status := ExistingOrder.Status::Planned;
        ExistingOrder."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ExistingOrder."No."));
        ExistingOrder.Insert(false);
        UpgradeFixture.RestorePreactivationColumns();
        FailureSubscriber.FailWhenEnrolling(ExistingOrder."No.");
        BindSubscription(FailureSubscriber);
        asserterror CohortMgt.InitializeCompany();
        Assert.ExpectedError('Injected failure before completed cutover marker.');
        UnbindSubscription(FailureSubscriber);
        Assert.RecordIsEmpty(Activation);
        ExistingOrder.Get(ExistingOrder.Status, ExistingOrder."No.");
        Assert.AreEqual(ExistingOrder."Subc. WIP Cohort"::Unassigned, ExistingOrder."Subc. WIP Cohort", 'Rollback must not leave partial enrollment.');
        Assert.IsTrue(IsNullGuid(ExistingOrder."Subc. WIP Lineage ID"), 'Rollback must undo the identity as well as the marker.');
        Assert.RecordIsEmpty(Alias);
        CohortMgt.InitializeCompany();
        ExistingOrder.Get(ExistingOrder.Status, ExistingOrder."No.");
        LineageID := ExistingOrder."Subc. WIP Lineage ID";
        Assert.AreEqual(ExistingOrder."Subc. WIP Cohort"::Legacy, ExistingOrder."Subc. WIP Cohort", 'Retry must classify the old persistent root as legacy.');
        Activation.Get('');
        ActivationID := Activation.SystemId;
        ActivationCreatedAt := Activation.SystemCreatedAt;
        AliasCount := Alias.Count();
        CohortMgt.InitializeCompany();
        Activation.Get('');
        ExistingOrder.Get(ExistingOrder.Status, ExistingOrder."No.");
        Assert.AreEqual(ActivationID, Activation.SystemId, 'Idempotent initialization must retain the exact marker.');
        Assert.AreEqual(ActivationCreatedAt, Activation.SystemCreatedAt, 'Repeated initialization cannot change the activation epoch.');
        Assert.AreEqual(LineageID, ExistingOrder."Subc. WIP Lineage ID", 'Repeated initialization cannot generate another identity.');
        Assert.AreEqual(AliasCount, Alias.Count(), 'Repeated initialization cannot duplicate aliases.');

        Company.Name := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Company.Name));
        Company.Insert(true);
        OtherOrder.ChangeCompany(Company.Name);
        OtherOrder.Status := OtherOrder.Status::Planned;
        OtherOrder."No." := ExistingOrder."No.";
        OtherOrder.Insert(false);
        OtherActivation.ChangeCompany(Company.Name);
        OtherActivation.Get('');
        OtherOrder.Get(OtherOrder.Status, OtherOrder."No.");
        Assert.AreEqual(1, OtherActivation.Version, 'An empty second company initializes independently on its first persistent insert.');
        Assert.AreNotEqual(ActivationID, OtherActivation.SystemId, 'Companies cannot share activation marker identity.');
        Assert.AreEqual(OtherOrder."Subc. WIP Cohort"::StateV1, OtherOrder."Subc. WIP Cohort", 'The new root in the empty company is postactivation.');
        Assert.AreNotEqual(LineageID, OtherOrder."Subc. WIP Lineage ID", 'Identical native order numbers in different companies cannot share identity.');
        Activation.Get('');
        Assert.AreEqual(ActivationID, Activation.SystemId, 'Initializing another company must not replace the first marker.');
        Assert.AreEqual(AliasCount, Alias.Count(), 'Another company must not add aliases to this one.');
        Company.Delete(true);
    end;

    internal procedure FailWhenEnrolling(OrderNo: Code[20])
    begin
        FailCutoverOrderNo := OrderNo;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Production Order", OnAfterModifyEvent, '', false, false)]
    local procedure FailIncompleteCutover(var Rec: Record "Production Order"; var xRec: Record "Production Order"; RunTrigger: Boolean)
    begin
        if (FailCutoverOrderNo <> '') and (Rec."No." = FailCutoverOrderNo) and
           (Rec."Subc. WIP Cohort" = Rec."Subc. WIP Cohort"::Legacy)
        then
            Error('Injected failure before completed cutover marker.');
    end;

    [Test]
    [HandlerFunctions('CutoverRequest,CutoverProposal,CutoverMessage,CutoverConfirm,CutoverTransferOrder')]
    procedure CutoverKeepsAllExistingOrdersLegacy()
    var
        ProductionOrder: Record "Production Order";
        Header: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Entry: Record "Subcontractor WIP Ledger Entry";
        Activation: Record "Subc. WIP Activation";
        WarehouseLibrary: Codeunit "Subc. Warehouse Library";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        UpgradeFixture: Codeunit "Subc. WIP Upgrade Fixture";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        Seen: Dictionary of [Guid, Boolean];
        I: Integer;
    begin
        Initialize();
        WarehouseLibrary.CreateLegacyWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 14);
        WarehouseLibrary.CreateStateWIPSupply(PurchaseHeader, TransferHeader, TransferLine);
        TransferLine.Validate("Qty. to Ship", 10);
        TransferLine.Modify(true);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        for I := 0 to 4 do begin
            Header.Init();
            Header.Status := Enum::"Production Order Status".FromInteger(I);
            Header."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(Header."No."));
            Header.Insert(false);
        end;
        UpgradeFixture.RestorePreactivationColumns();
        CohortMgt.InitializeCompany();
        Activation.Get('');
        Assert.AreEqual(1, Activation.Version, 'The completed activation marker must be persisted.');
        Header.FindSet();
        repeat
            Assert.AreEqual(Header."Subc. WIP Cohort"::Legacy, Header."Subc. WIP Cohort", 'Every preactivation status remains legacy.');
            Assert.IsFalse(IsNullGuid(Header."Subc. WIP Lineage ID"), 'Every existing persistent order requires identity.');
            Assert.IsFalse(Seen.ContainsKey(Header."Subc. WIP Lineage ID"), 'Independent orders cannot share a lineage.');
            Seen.Add(Header."Subc. WIP Lineage ID", true);
        until Header.Next() = 0;
        Entry.SetRange("Prod. Order No.", ProductionOrder."No.");
        Entry.SetRange("In Transit", false);
        Entry.CalcSums("Quantity (Base)");
        Assert.AreEqual(10, Entry."Quantity (Base)", 'Cutover must not rewrite legacy physical custody.');
        Entry.SetRange("State Tracked", true);
        Assert.RecordIsEmpty(Entry);
        TransferLine.Get(TransferLine."Document No.", TransferLine."Line No.");
        Assert.AreEqual(4, TransferLine.Quantity - TransferLine."Quantity Shipped", 'Cutover preserves the native open transfer.');
        Assert.IsFalse(TransferLine."Subc. State Tracked", 'The preactivation open transfer stays legacy.');
    end;

    [RequestPageHandler]
    procedure CutoverRequest(var Request: TestRequestPage "Subc. Create Transf. Order")
    begin
        Request.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CutoverProposal(var Proposal: TestPage "Subc. Transfer Proposal")
    begin
        Proposal.OK().Invoke();
    end;

    [MessageHandler]
    procedure CutoverMessage(Message: Text[1024])
    begin
        Assert.AreEqual('1 transfer order(s) with 1 line(s) were created.', Message, 'Unexpected cutover fixture creation.');
    end;

    [ConfirmHandler]
    procedure CutoverConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    procedure CutoverTransferOrder(var TransferOrder: TestPage "Transfer Order")
    begin
        TransferOrder.Close();
    end;

    [Test]
    procedure ReplanChildGetsNewBusinessLineage()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        BOM: Record "Production BOM Header";
        BOMLine: Record "Production BOM Line";
        ParentOrder: Record "Production Order";
        ChildOrder: Record "Production Order";
        UpgradeFixture: Codeunit "Subc. WIP Upgrade Fixture";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        Replan: Report "Replan Production Order";
        Direction: Option Forward,Backward;
        Calculate: Option "No Levels","One level","All levels";
        ParentLineage: Guid;
        ChildLineage: Guid;
    begin
        Initialize();
        LibraryInventory.CreateItem(ChildItem);
        ChildItem.Validate("Replenishment System", ChildItem."Replenishment System"::"Prod. Order");
        ChildItem.Validate("Manufacturing Policy", ChildItem."Manufacturing Policy"::"Make-to-Order");
        ChildItem.Modify(true);
        LibraryInventory.CreateItem(ParentItem);
        LibraryManufacturing.CreateProductionBOMHeader(BOM, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(BOM, BOMLine, '', BOMLine.Type::Item, ChildItem."No.", 1);
        BOM.Validate(Status, BOM.Status::Certified);
        BOM.Modify(true);
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
        ParentItem.Validate("Production BOM No.", BOM."No.");
        ParentItem.Modify(true);
        LibraryManufacturing.CreateProductionOrder(ParentOrder, ParentOrder.Status::Released, ParentOrder."Source Type"::Item, ParentItem."No.", 10);
        LibraryManufacturing.RefreshProdOrder(ParentOrder, false, true, true, true, false);
        UpgradeFixture.RestorePreactivationColumns();
        CohortMgt.InitializeCompany();
        ParentOrder.Get(ParentOrder.Status, ParentOrder."No.");
        ParentLineage := ParentOrder."Subc. WIP Lineage ID";
        ParentOrder.SetRecFilter();
        Replan.InitializeRequest(Direction::Backward, Calculate::"All levels");
        Replan.SetTableView(ParentOrder);
        Replan.UseRequestPage(false);
        Replan.RunModal();
        ChildOrder.SetRange("Source Type", ChildOrder."Source Type"::Item);
        ChildOrder.SetRange("Source No.", ChildItem."No.");
        Assert.RecordCount(ChildOrder, 1);
        ChildOrder.FindFirst();
        ChildLineage := ChildOrder."Subc. WIP Lineage ID";
        AssertStateIdentity(ChildOrder, ChildLineage);
        Assert.AreNotEqual(ParentLineage, ChildLineage, 'A shortage-generated child is a new business root, not continuation of its legacy parent.');
        LibraryManufacturing.RefreshProdOrder(ChildOrder, false, true, true, true, false);
        ChildOrder.Get(ChildOrder.Status, ChildOrder."No.");
        AssertStateIdentity(ChildOrder, ChildLineage);
        ParentOrder.Get(ParentOrder.Status, ParentOrder."No.");
        Assert.AreEqual(ParentOrder."Subc. WIP Cohort"::Legacy, ParentOrder."Subc. WIP Cohort", 'Replanning cannot promote the original parent.');
        Assert.AreEqual(ParentLineage, ParentOrder."Subc. WIP Lineage ID", 'Replanning must preserve parent identity.');
    end;

    [Test]
    procedure NewHeaderPathsEnrollExactlyOnce()
    var
        ProductionOrder: Record "Production Order";
        ImportedOrder: Record "Production Order";
        TemporaryOrder: Record "Production Order" temporary;
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        OriginalLineage: Guid;
        OriginalWorkDate: Date;
    begin
        Initialize();
        CohortMgt.InitializeCompany();
        OriginalWorkDate := WorkDate();
        WorkDate(CalcDate('<-1Y>', OriginalWorkDate));
        ProductionOrder.Init();
        ProductionOrder.Status := ProductionOrder.Status::Planned;
        ProductionOrder."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ProductionOrder."No."));
        ProductionOrder.Insert(true);
        WorkDate(OriginalWorkDate);
        OriginalLineage := ProductionOrder."Subc. WIP Lineage ID";
        AssertStateIdentity(ProductionOrder, OriginalLineage);

        ImportedOrder := ProductionOrder;
        ImportedOrder."No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(ImportedOrder."No."));
        ImportedOrder.Insert(false);
        Assert.AreNotEqual(OriginalLineage, ImportedOrder."Subc. WIP Lineage ID", 'A new imported header must not clone foreign identity.');
        AssertStateIdentity(ImportedOrder, ImportedOrder."Subc. WIP Lineage ID");
        ImportedOrder.Description := 'Imported after activation';
        ImportedOrder.Modify(false);
        CohortMgt.InitializeCompany();
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        AssertStateIdentity(ProductionOrder, OriginalLineage);

        TemporaryOrder.Init();
        TemporaryOrder.Status := TemporaryOrder.Status::Planned;
        TemporaryOrder."No." := ProductionOrder."No.";
        TemporaryOrder.Insert(false);
        Assert.IsTrue(IsNullGuid(TemporaryOrder."Subc. WIP Lineage ID"), 'Temporary planning headers must not enroll.');
        Assert.AreEqual(TemporaryOrder."Subc. WIP Cohort"::Unassigned, TemporaryOrder."Subc. WIP Cohort", 'Temporary headers must remain unclassified.');
        ImportedOrder."Subc. WIP Lineage ID" := OriginalLineage;
        asserterror ImportedOrder.Modify(false);
        Assert.ExpectedError('is inconsistent');
    end;

    [Test]
    procedure StatusReplacementRetainsCohort()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        OriginalLineage: Guid;
        OriginalNo: Code[20];
        ReleasedNo: Code[20];
    begin
        Initialize();
        CohortMgt.InitializeCompany();
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, Item."No.", 10);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        OriginalLineage := ProductionOrder."Subc. WIP Lineage ID";
        OriginalNo := ProductionOrder."No.";
        ReleasedNo := LibraryManufacturing.ChangeStatusFirmPlanToReleased(OriginalNo);
        ProductionOrder.Get(ProductionOrder.Status::Released, ReleasedNo);
        AssertStateIdentity(ProductionOrder, OriginalLineage);
        Assert.AreEqual(OriginalLineage, CohortMgt.GetLineage(ProductionOrder.Status::"Firm Planned", OriginalNo), 'The deleted native source must retain its lineage alias.');
        Assert.IsTrue(CohortMgt.IsTracked(ProductionOrder.Status::"Firm Planned", OriginalNo), 'Historical aliases retain cohort classification.');
    end;

    [Test]
    [HandlerFunctions('CopyStateOrderRequest')]
    procedure RefreshAndCopyKeepTargetCohort()
    var
        Item: Record Item;
        SourceOrder: Record "Production Order";
        TargetOrder: Record "Production Order";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        CopyProductionOrder: Report "Copy Production Order Document";
        TargetLineage: Guid;
    begin
        Initialize();
        CohortMgt.InitializeCompany();
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionOrder(SourceOrder, SourceOrder.Status::Planned, SourceOrder."Source Type"::Item, Item."No.", 10);
        LibraryManufacturing.RefreshProdOrder(SourceOrder, false, true, true, true, false);
        LibraryManufacturing.CreateProductionOrder(TargetOrder, TargetOrder.Status::Planned, TargetOrder."Source Type"::Item, Item."No.", 1);
        TargetLineage := TargetOrder."Subc. WIP Lineage ID";
        LibraryManufacturing.RefreshProdOrder(TargetOrder, false, true, true, true, false);
        TargetOrder.Get(TargetOrder.Status, TargetOrder."No.");
        AssertStateIdentity(TargetOrder, TargetLineage);
        Assert.AreNotEqual(SourceOrder."Subc. WIP Lineage ID", TargetLineage, 'Distinct business orders require distinct lineages.');
        CopySourceNo := SourceOrder."No.";
        CopyProductionOrder.SetProdOrder(TargetOrder);
        CopyProductionOrder.RunModal();
        TargetOrder.Get(TargetOrder.Status, TargetOrder."No.");
        Assert.AreEqual(10, TargetOrder.Quantity, 'The native copy must actually copy source content.');
        AssertStateIdentity(TargetOrder, TargetLineage);
    end;

    [Test]
    [HandlerFunctions('ReopenStateOrderConfirm')]
    procedure NativeReopenKeepsOriginalLineage()
    var
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        WarehouseLibrary: Codeunit "Subc. Warehouse Library";
        ManagementLibrary: Codeunit "Subc. Management Library";
        StatusManagement: Codeunit "Prod. Order Status Management";
        OriginalLineage: Guid;
        FinishedNo: Code[20];
    begin
        Initialize();
        ManagementLibrary.Initialize();
        WarehouseLibrary.CreateStateWIPPurchaseOrder(ProductionOrder, PurchaseHeader, PurchaseLine, 10, 1, false);
        OriginalLineage := ProductionOrder."Subc. WIP Lineage ID";
        WarehouseLibrary.CompleteStateWIPProduction(ProductionOrder);
        ItemLedgerEntry.SetRange("Item No.", ProductionOrder."Source No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Output);
        ItemLedgerEntry.CalcSums(Quantity);
        Assert.AreEqual(10, ItemLedgerEntry.Quantity, 'Reopen requires real nonzero native output, not a bypassed guard.');
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, ProductionOrder.Status::Finished, WorkDate(), false);
        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Finished);
        ProductionOrder.SetRange("Subc. WIP Lineage ID", OriginalLineage);
        ProductionOrder.FindFirst();
        FinishedNo := ProductionOrder."No.";
        StatusManagement.ReopenFinishedProdOrder(ProductionOrder);
        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, ProductionOrder.Status::Released);
        ProductionOrder.SetRange("Subc. WIP Lineage ID", OriginalLineage);
        ProductionOrder.FindFirst();
        AssertStateIdentity(ProductionOrder, OriginalLineage);
        Assert.AreEqual(OriginalLineage, CohortMgt.GetLineage(ProductionOrder.Status::Finished, FinishedNo), 'The native finished source alias survives its deletion.');
    end;

    [ConfirmHandler]
    procedure ReopenStateOrderConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := not Question.ToLower().Contains('view') and not Question.ToLower().Contains('open the');
    end;

    local procedure AssertStateIdentity(ProductionOrder: Record "Production Order"; LineageID: Guid)
    var
        CohortMgt: Codeunit "Subc. WIP Cohort Mgt.";
    begin
        Assert.IsFalse(IsNullGuid(LineageID), 'A persistent StateV1 order requires a lineage.');
        Assert.AreEqual(ProductionOrder."Subc. WIP Cohort"::StateV1, ProductionOrder."Subc. WIP Cohort", 'The persistent order must enroll after activation.');
        Assert.AreEqual(1, ProductionOrder."Subc. WIP Version", 'The enrolled version must remain stable.');
        Assert.AreEqual(LineageID, ProductionOrder."Subc. WIP Lineage ID", 'A native content/status change must retain its business identity.');
        Assert.AreEqual(LineageID, CohortMgt.GetLineage(ProductionOrder.Status, ProductionOrder."No."), 'The native key must resolve the same durable identity.');
    end;

    [RequestPageHandler]
    procedure CopyStateOrderRequest(var Request: TestRequestPage "Copy Production Order Document")
    begin
        Request.Status.SetValue('Planned');
        Request.DocumentNo.SetValue(CopySourceNo);
        Request.IncludeHeader.SetValue(true);
        Request.OK().Invoke();
    end;

    [Test]
    procedure MigrationConvertsLegacyRawTypeValueToCurrentSubcontractingValue()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Migrating "Req. Wksh. Template".Type converts the pre-renumbering raw value (99001500) to the current Subcontracting value (20500)
        Initialize();

        // [GIVEN] A Req. Wksh. Template whose Type field holds the legacy raw value 99001500, seeded through RecordRef/FieldRef
        CreateReqWkshTemplateWithRawTypeValue(ReqWkshTemplate, LegacySubcontractingTypeValue());

        // [WHEN] The Req. Wksh. Template Type migration runs
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The template's Type is the current, typed Subcontracting value
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Type should be converted to the current Subcontracting value.');

        ReqWkshTemplate.Delete();
    end;

    [Test]
    procedure MigrationDoesNotAffectUnrelatedTemplateTypes()
    var
        PlanningReqWkshTemplate: Record "Req. Wksh. Template";
        LegacyReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Migrating "Req. Wksh. Template".Type does not touch templates that already have a valid, unrelated Type value
        Initialize();

        // [GIVEN] A Req. Wksh. Template with Type = Planning, set through the normal typed Validate
        CreateReqWkshTemplateWithTypedType(PlanningReqWkshTemplate, PlanningReqWkshTemplate.Type::Planning);

        // [GIVEN] A second Req. Wksh. Template holding the legacy raw value, so the migration has matching data to act on
        CreateReqWkshTemplateWithRawTypeValue(LegacyReqWkshTemplate, LegacySubcontractingTypeValue());

        // [WHEN] The Req. Wksh. Template Type migration runs
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The unrelated Planning template is unchanged
        PlanningReqWkshTemplate.Get(PlanningReqWkshTemplate.Name);
        Assert.AreEqual(PlanningReqWkshTemplate.Type::Planning, PlanningReqWkshTemplate.Type, 'Unrelated Planning template Type must remain unchanged.');

        PlanningReqWkshTemplate.Delete();
        LegacyReqWkshTemplate.Delete();
    end;

    [Test]
    procedure MigrationRunningTwiceIsHarmless()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
#pragma warning restore AL0432
    begin
        // [SCENARIO 644283] Running the Req. Wksh. Template Type migration a second time is a harmless no-op (idempotent)
        Initialize();

        // [GIVEN] A Req. Wksh. Template holding the legacy raw value, already migrated once
        CreateReqWkshTemplateWithRawTypeValue(ReqWkshTemplate, LegacySubcontractingTypeValue());
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Type should be converted to the current Subcontracting value after the first run.');

        // [WHEN] The migration runs a second time
#pragma warning disable AL0432
        SubcReqWkshTemplUpgrade.MigrateReqWkshTemplateTypeFromLegacyValue();
#pragma warning restore AL0432

        // [THEN] The Type value remains the current, typed Subcontracting value and no error occurs
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'Re-running the migration must be harmless and keep the Subcontracting value.');

        ReqWkshTemplate.Delete();
    end;

    [Test]
    procedure InitializeReusesSurvivingDefaultWorksheet()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Cleared extension setup is initialized when the default worksheet survives reinstallation.
        Initialize();

        // [GIVEN] Blank Subcontracting setup and surviving template and batch "S".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'SUBCONTR');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'SUBCONTR');

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Existing records are selected and the scalar defaults are persisted.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeReusesCustomWorksheetWithoutChanges()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Existing custom worksheet records are reused unchanged, including on repeated initialization.
        Initialize();

        // [GIVEN] Blank setup and custom template "C" with batch "B".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        ReqWkshTemplate.Recurring := true;
        ReqWkshTemplate."Increment Batch Name" := true;
        ReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Custom records are selected without duplicates or metadata changes.
        VerifyDefaultSetup(ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeCreatesMissingBatchForExistingTemplate()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] An existing template without a batch receives a default batch and company defaults.
        Initialize();

        // [GIVEN] Blank setup and custom template "C" without batches.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] A default batch is created beneath the surviving template.
        VerifyDefaultSetup(ReqWkshTemplate.Name, 'SUBCONTR');
        RequisitionWkshName.Get(ReqWkshTemplate.Name, 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure FreshInitializationIsIdempotent()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Fresh initialization creates defaults and a second call leaves those records unchanged.
        Initialize();

        // [GIVEN] Blank setup and no Subcontracting worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Default selections and scalar settings are persisted.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        ReqWkshTemplate.Get('SUBCONTR');
        RequisitionWkshName.Get('SUBCONTR', 'SUBCONTR');
        VerifyCreatedWorksheet(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Company defaults are initialized again.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Setup and worksheet identities remain unchanged.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeCreatesAbsentManufacturingSetup()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A company without Manufacturing Setup receives the complete Subcontracting defaults.
        Initialize();

        // [GIVEN] Neither Manufacturing Setup nor Subcontracting worksheets exist.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup.Delete();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Manufacturing Setup is created with valid worksheet selections and defaults.
        VerifyDefaultSetup('SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure InitializePreservesNonFirstSelectedWorksheetAndSettings()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        FirstRequisitionWkshName: Record "Requisition Wksh. Name";
        SelectedRequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Valid non-first selections and deliberately false or blank settings survive repeated initialization.
        Initialize();

        // [GIVEN] Template "Z" and its second batch are selected instead of the first available records.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(FirstReqWkshTemplate, 'AFIRST');
        CreateSubcontractingBatch(FirstRequisitionWkshName, FirstReqWkshTemplate.Name, 'AFIRST');
        CreateSubcontractingTemplate(SelectedReqWkshTemplate, 'ZSELECTED');
        CreateSubcontractingBatch(FirstRequisitionWkshName, SelectedReqWkshTemplate.Name, 'AFIRST');
        CreateSubcontractingBatch(SelectedRequisitionWkshName, SelectedReqWkshTemplate.Name, 'ZSELECTED');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", SelectedRequisitionWkshName.Name);
        ManufacturingSetup."Component Direct Unit Cost" := ManufacturingSetup."Component Direct Unit Cost"::"Prod. Order Component";
        ManufacturingSetup.Validate("Subc. Default Comp. Location", ManufacturingSetup."Subc. Default Comp. Location"::Purchase);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Every configured field and the selected worksheet records remain unchanged.
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, SelectedRequisitionWkshName.Name);
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, SelectedRequisitionWkshName, 2, 2);
    end;

    [Test]
    procedure InitializeRepairsSelectedTemplateWithoutResettingScalars()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A selected template alone proves prior configuration when its missing batch is repaired.
        Initialize();

        // [GIVEN] Template "Z" is selected without a batch and scalar fields are deliberately false or blank.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(FirstReqWkshTemplate, 'AFIRST');
        CreateSubcontractingTemplate(SelectedReqWkshTemplate, 'ZSELECTED');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The missing batch is created for the selected template without resetting scalar fields.
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, 'SUBCONTR');
        RequisitionWkshName.Get(SelectedReqWkshTemplate.Name, 'SUBCONTR');
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, RequisitionWkshName, 2, 1);
    end;

    [Test]
    procedure InitializePreservesCustomLeadTimeWithBlankSelections()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A custom transfer lead time prevents scalar defaulting while blank worksheet selections are repaired.
        Initialize();

        // [GIVEN] Custom lead time with false information lines and blank selections, plus surviving worksheet "C".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
        Evaluate(ManufacturingSetup."Subc. Comp. Transfer Lead Time", '<3D>');
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized twice.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Selections are repaired and the custom lead time and false information lines are retained.
        VerifyConfiguredSetup(ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializePreservesComponentCostOnlyConfiguration()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A component cost choice alone prevents scalar defaulting when worksheets must be created.
        Initialize();

        // [GIVEN] Only component cost is configured and there are no worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup."Component Direct Unit Cost" := ManufacturingSetup."Component Direct Unit Cost"::"Prod. Order Component";
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Worksheets are created without changing any configured scalar field.
        VerifyConfiguredSetup(ManufacturingSetup, 'SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure InitializePreservesComponentLocationOnlyConfiguration()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A component location choice alone prevents scalar defaulting when worksheets must be created.
        Initialize();

        // [GIVEN] Only component location is configured and there are no worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup.Validate("Subc. Default Comp. Location", ManufacturingSetup."Subc. Default Comp. Location"::Purchase);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Worksheets are created without changing any configured scalar field.
        VerifyConfiguredSetup(ManufacturingSetup, 'SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure InitializePreservesBlankLeadTimeWithInformationLines()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Enabled information lines alone prove configuration and preserve a deliberately blank lead time.
        Initialize();

        // [GIVEN] Only information lines are enabled and there are no worksheets.
        PrepareUninitializedSetup(ManufacturingSetup);
        ManufacturingSetup."Create Prod. Order Info Line" := true;
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Worksheet creation does not replace the blank lead time.
        VerifyConfiguredSetup(ManufacturingSetup, 'SUBCONTR', 'SUBCONTR');
        VerifyWorksheetCounts('SUBCONTR', 1, 1);
    end;

    [Test]
    procedure SetupHelperSucceedsWithExistingTemplate()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        SetupAvailable: Boolean;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] The public setup helper reports availability rather than creation for an existing worksheet.
        Initialize();

        // [GIVEN] Blank setup and surviving custom worksheet "C".
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] The setup helper is called directly.
        SetupAvailable := SubcontractingCompInit.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup(ManufacturingSetup);

        // [THEN] The helper succeeds and fills the caller's selections without mutating worksheet records.
        VerifySetupHelperResult(SetupAvailable, ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure InitializeCreatesAlternativeTemplateOnNameCollision()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Initialization creates an alternative template without changing a conflicting Planning worksheet.
        Initialize();

        // [GIVEN] Blank setup and a Planning template named SUBCONTR with a custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Defaults use the alternative template and the conflicting worksheet is unchanged.
        VerifyDefaultSetup('SUBCONTR1', 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyAlternativeWorksheet('SUBCONTR1');
    end;

    [Test]
    procedure ReinitializeReusesAlternativeTemplateAfterNameCollision()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reinitialization reuses an alternative template without changing the conflicting worksheet.
        Initialize();

        // [GIVEN] Planning worksheet "P" occupies SUBCONTR and initialization has created an alternative.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [WHEN] Company defaults are initialized again.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The same alternative is selected without duplicate templates or changes to "P".
        VerifyDefaultSetup('SUBCONTR1', 'SUBCONTR');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyAlternativeWorksheet('SUBCONTR1');
    end;

    [Test]
    procedure CreateReqWkshTemplateCreatesAlternativeOnNameCollision()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Direct template creation returns a new alternative without changing the conflicting worksheet or setup.
        Initialize();

        // [GIVEN] Blank setup and a Planning template named SUBCONTR with a custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ExpectedReqWkshTemplate, RequisitionWkshName);

        // [WHEN] The default template is created using an unfiltered record.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] An alternative template is created while the conflicting worksheet and setup remain unchanged.
        Assert.IsTrue(TemplateCreated, 'An available alternative name must allow template creation.');
        Assert.AreEqual('SUBCONTR1', ReqWkshTemplate.Name, 'The first available alternative name must be used.');
        ReqWkshTemplate.Get(ReqWkshTemplate.Name);
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'The alternative must have the Subcontracting type.');
        Assert.AreEqual(Page::"Subc. Subcontracting Worksheet", ReqWkshTemplate."Page ID", 'The alternative must use the Subcontracting worksheet page.');
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyConfiguredSetup(ManufacturingSetup, '', '');
    end;

    [Test]
    procedure SetupHelperSelectsAlternativeOnTemplateNameCollision()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        SetupAvailable: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] The setup helper replaces incompatible selections with an alternative Subcontracting worksheet.
        Initialize();

        // [GIVEN] Setup selects Planning template "P" named SUBCONTR and its custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);
        ManufacturingSetup."Subcontracting Template Name" := ReqWkshTemplate.Name;
        ManufacturingSetup."Subcontracting Batch Name" := RequisitionWkshName.Name;
        ManufacturingSetup.Modify();

        // [WHEN] The setup helper is called directly.
        SetupAvailable := SubcontractingCompInit.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup(ManufacturingSetup);

        // [THEN] The caller receives valid selections while persisted setup and the Planning worksheet remain unchanged.
        VerifySetupHelperResult(SetupAvailable, ManufacturingSetup, 'SUBCONTR1', 'SUBCONTR');
        VerifyConfiguredSetup(ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyAlternativeWorksheet('SUBCONTR1');
    end;

    [Test]
    procedure InitializeReusesValidTemplateWithConflictingDefaultName()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ConflictingReqWkshTemplate: Record "Req. Wksh. Template";
        ConflictingRequisitionWkshName: Record "Requisition Wksh. Name";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] A valid Subcontracting template is reused even when the default name belongs to a Planning template.
        Initialize();

        // [GIVEN] Planning template "P" occupies SUBCONTR and Subcontracting template "S" has a custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ConflictingReqWkshTemplate, ConflictingRequisitionWkshName);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Setup uses the valid template while both worksheets remain unchanged.
        VerifyDefaultSetup(ReqWkshTemplate.Name, RequisitionWkshName.Name);
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyWorksheetUnchanged(ConflictingReqWkshTemplate, ConflictingRequisitionWkshName, 1, 1);
    end;

    [Test]
    procedure CreateReqWkshTemplateReturnsExistingTemplateWithoutCreation()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] A false creation result still returns an existing valid template for callers to reuse.
        Initialize();

        // [GIVEN] Subcontracting template "S" and its custom batch already exist.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ExpectedReqWkshTemplate, 'CUSTOM');
        CreateSubcontractingBatch(RequisitionWkshName, ExpectedReqWkshTemplate.Name, 'CUSTOMBAT');
        ExpectedReqWkshTemplate.Get(ExpectedReqWkshTemplate.Name);

        // [WHEN] Default template creation is requested.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] No template is created and the existing valid template is returned unchanged.
        Assert.IsFalse(TemplateCreated, 'Reusing a template must not report successful creation.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Name, ReqWkshTemplate.Name, 'The existing valid template must be returned.');
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        Assert.IsTrue(ExpectedReqWkshTemplate.SystemModifiedAt = ReqWkshTemplate.SystemModifiedAt, 'A template with the correct page must not be modified.');
    end;

    [Test]
    procedure InitializeSkipsOccupiedAlternativeTemplateNames()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        OccupiedReqWkshTemplate: Record "Req. Wksh. Template";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Alternative naming skips occupied names and stays within the template name length.
        Initialize();

        // [GIVEN] Planning templates occupy the default name and alternatives through suffix 99.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);
        CreateOccupiedAlternativeTemplateNames();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The first available length-safe name is used and occupied templates are not changed.
        VerifyDefaultSetup('SUBCONT100', 'SUBCONTR');
        VerifyAlternativeWorksheet('SUBCONT100');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        OccupiedReqWkshTemplate.Get('SUBCONTR99');
        Assert.AreEqual(OccupiedReqWkshTemplate.Type::Planning, OccupiedReqWkshTemplate.Type, 'Occupied alternative names must retain their type.');
    end;

    [Test]
    procedure ReinitializeReusesLengthSafeAlternativeTemplate()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        OccupiedReqWkshTemplate: Record "Req. Wksh. Template";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reinitialization reuses the length-safe alternative when shorter names are occupied.
        Initialize();

        // [GIVEN] Planning templates occupy SUBCONTR through SUBCONTR99 and initialization has created an alternative.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateConflictingWorksheet(ReqWkshTemplate, RequisitionWkshName);
        CreateOccupiedAlternativeTemplateNames();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [WHEN] Company defaults are initialized again.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The same length-safe alternative is selected and occupied worksheets remain unchanged.
        VerifyDefaultSetup('SUBCONT100', 'SUBCONTR');
        VerifyAlternativeWorksheet('SUBCONT100');
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        OccupiedReqWkshTemplate.Get('SUBCONTR99');
        Assert.AreEqual(OccupiedReqWkshTemplate.Type::Planning, OccupiedReqWkshTemplate.Type, 'Occupied alternative names must retain their type.');
    end;

    [Test]
    procedure CreateReqWkshTemplateRepairsExistingTemplatePageOnly()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Reusing a Subcontracting template migrates only its legacy Subcontracting worksheet page.
        Initialize();

        // [GIVEN] Subcontracting template "S" has the legacy Subcontracting page and custom metadata and batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ExpectedReqWkshTemplate, 'CUSTOM');
        ExpectedReqWkshTemplate."Page ID" := 99000886;
        ExpectedReqWkshTemplate.Recurring := true;
        ExpectedReqWkshTemplate."Increment Batch Name" := true;
        ExpectedReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ExpectedReqWkshTemplate.Name, 'CUSTOMBAT');

        // [WHEN] Default template creation is requested.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] The existing template is returned with only its page corrected.
        Assert.IsFalse(TemplateCreated, 'Correcting a page must not report template creation.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Name, ReqWkshTemplate.Name, 'The existing template must be reused.');
        ExpectedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyConfiguredSetup(ManufacturingSetup, '', '');
    end;

    [Test]
    procedure InitializeRepairsSelectedTemplatePageOnly()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Initialization migrates the selected legacy Subcontracting page without switching templates or resetting settings.
        Initialize();

        // [GIVEN] Non-first Subcontracting template "S" is selected with the legacy Subcontracting page.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(FirstReqWkshTemplate, 'AFIRST');
        CreateSubcontractingTemplate(SelectedReqWkshTemplate, 'ZSELECTED');
        SelectedReqWkshTemplate."Page ID" := 99000886;
        SelectedReqWkshTemplate.Recurring := true;
        SelectedReqWkshTemplate."Increment Batch Name" := true;
        SelectedReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, SelectedReqWkshTemplate.Name, 'CUSTOMBAT');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", RequisitionWkshName.Name);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] Only the selected template page changes.
        SelectedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, RequisitionWkshName, 2, 1);
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, RequisitionWkshName.Name);
    end;

    [Test]
    procedure ReinitializePreservesRepairedSelectedTemplate()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        FirstReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reinitialization preserves the repaired selected worksheet and customer settings.
        Initialize();

        // [GIVEN] Initialization has repaired non-first selected template "S" and preserved its custom batch.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(FirstReqWkshTemplate, 'AFIRST');
        CreateSubcontractingTemplate(SelectedReqWkshTemplate, 'ZSELECTED');
        SelectedReqWkshTemplate."Page ID" := 99000886;
        SelectedReqWkshTemplate.Recurring := true;
        SelectedReqWkshTemplate."Increment Batch Name" := true;
        SelectedReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, SelectedReqWkshTemplate.Name, 'CUSTOMBAT');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", RequisitionWkshName.Name);
        ManufacturingSetup.Modify();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();
        SelectedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";

        // [WHEN] Company defaults are initialized again.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The repaired worksheet is reused without switching templates or resetting settings.
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, RequisitionWkshName, 2, 1);
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, RequisitionWkshName.Name);
    end;

    [Test]
    procedure CreateReqWkshTemplatePreservesUnrelatedPage()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedReqWkshTemplate: Record "Req. Wksh. Template";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
        TemplateCreated: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Reusing a Subcontracting template preserves a page other than the legacy Subcontracting worksheet.
        Initialize();

        // [GIVEN] Subcontracting template "S" has a Planning page selected by the customer.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ExpectedReqWkshTemplate, 'CUSTOM');
        ExpectedReqWkshTemplate."Page ID" := Page::"Planning Worksheet";
        ExpectedReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ExpectedReqWkshTemplate.Name, 'CUSTOMBAT');
        ExpectedReqWkshTemplate.Get(ExpectedReqWkshTemplate.Name);

        // [WHEN] Default template creation is requested.
        TemplateCreated := SubcontractingCompInit.CreateReqWkshTemplate(ReqWkshTemplate, false);

        // [THEN] The existing template and its unrelated page are unchanged.
        Assert.IsFalse(TemplateCreated, 'Reusing a template must not report creation.');
        VerifyWorksheetUnchanged(ExpectedReqWkshTemplate, RequisitionWkshName, 1, 1);
        Assert.IsTrue(ExpectedReqWkshTemplate.SystemModifiedAt = ReqWkshTemplate.SystemModifiedAt, 'An unrelated page must not cause template modification.');
    end;

    [Test]
    procedure InitializePreservesSelectedTemplateUnrelatedPage()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 647022] Initialization preserves an unrelated page on the selected Subcontracting template.
        Initialize();

        // [GIVEN] Subcontracting template "S" is selected with a Planning page.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        ReqWkshTemplate."Page ID" := Page::"Planning Worksheet";
        ReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
        ManufacturingSetup.Validate("Subcontracting Template Name", ReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", RequisitionWkshName.Name);
        ManufacturingSetup.Modify();

        // [WHEN] Company defaults are initialized.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The selected worksheet and all configured settings remain unchanged.
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyConfiguredSetup(ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
    end;

    [Test]
    procedure ReinitializePreservesSelectedTemplateUnrelatedPage()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        SubcontractingCompInit: Codeunit "Subcontracting Comp. Init.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Reinitialization preserves a customer-selected page and configured settings.
        Initialize();

        // [GIVEN] Subcontracting worksheet "S" has a customer-selected Planning page and setup is already initialized.
        PrepareUninitializedSetup(ManufacturingSetup);
        CreateSubcontractingTemplate(ReqWkshTemplate, 'CUSTOM');
        ReqWkshTemplate."Page ID" := Page::"Planning Worksheet";
        ReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
        ManufacturingSetup.Validate("Subcontracting Template Name", ReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", RequisitionWkshName.Name);
        ManufacturingSetup.Modify();
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [WHEN] Company defaults are initialized again.
        SubcontractingCompInit.CreateBasicSubcontractingMgtSetup();

        // [THEN] The selected worksheet and configured settings remain unchanged.
        VerifyWorksheetUnchanged(ReqWkshTemplate, RequisitionWkshName, 1, 1);
        VerifyConfiguredSetup(ManufacturingSetup, ReqWkshTemplate.Name, RequisitionWkshName.Name);
    end;

    [Test]
    procedure PageUpgradeMigratesAllLegacyTemplatesAfterTypeUpgrade()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        SelectedReqWkshTemplate: Record "Req. Wksh. Template";
        UnselectedReqWkshTemplate: Record "Req. Wksh. Template";
        SelectedRequisitionWkshName: Record "Requisition Wksh. Name";
        UnselectedRequisitionWkshName: Record "Requisition Wksh. Name";
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
        SubcUpgradeTagDefExt: Codeunit "Subc. Upgrade Tag Def. Ext.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Page migration repairs selected and unselected legacy worksheets after the type migration completed.
        Initialize();

        // [GIVEN] The type upgrade tag exists but the independent page upgrade tag does not.
        PrepareUninitializedSetup(ManufacturingSetup);
        RemoveUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplateTypeUpgradeTag());
        RemoveUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplatePageUpgradeTag());
        UpgradeTag.SetUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplateTypeUpgradeTag());

        // [GIVEN] Selected worksheet "S" and unselected worksheet "U" use the legacy page and have custom settings and batches.
        CreateLegacySubcontractingWorksheet(SelectedReqWkshTemplate, SelectedRequisitionWkshName, 'SELECTED');
        CreateLegacySubcontractingWorksheet(UnselectedReqWkshTemplate, UnselectedRequisitionWkshName, 'UNSELECTED');
        ManufacturingSetup.Validate("Subcontracting Template Name", SelectedReqWkshTemplate.Name);
        ManufacturingSetup.Validate("Subcontracting Batch Name", SelectedRequisitionWkshName.Name);
        ManufacturingSetup.Modify();

        // [WHEN] The per-company page upgrade step runs.
        SubcReqWkshTemplUpgrade.UpgradeReqWkshTemplatePage();

        // [THEN] Both pages are repaired without changing worksheet metadata, batches or setup.
        SelectedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        UnselectedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        VerifyWorksheetUnchanged(SelectedReqWkshTemplate, SelectedRequisitionWkshName, 2, 1);
        VerifyWorksheetUnchanged(UnselectedReqWkshTemplate, UnselectedRequisitionWkshName, 2, 1);
        VerifyConfiguredSetup(ManufacturingSetup, SelectedReqWkshTemplate.Name, SelectedRequisitionWkshName.Name);
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplatePageUpgradeTag()), 'The independent page upgrade tag must be set.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplateTypeUpgradeTag()), 'The completed type upgrade tag must be preserved.');
    end;

    [Test]
    procedure PageUpgradePreservesUnrelatedTypesAndPages()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        LegacyReqWkshTemplate: Record "Req. Wksh. Template";
        CustomReqWkshTemplate: Record "Req. Wksh. Template";
        PlanningReqWkshTemplate: Record "Req. Wksh. Template";
        LegacyRequisitionWkshName: Record "Requisition Wksh. Name";
        CustomRequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningRequisitionWkshName: Record "Requisition Wksh. Name";
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
        SubcUpgradeTagDefExt: Codeunit "Subc. Upgrade Tag Def. Ext.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] Page migration matches both the Subcontracting type and the exact legacy page.
        Initialize();

        // [GIVEN] Worksheet "L" needs migration and the page upgrade tag does not exist.
        PrepareUninitializedSetup(ManufacturingSetup);
        RemoveUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplatePageUpgradeTag());
        CreateLegacySubcontractingWorksheet(LegacyReqWkshTemplate, LegacyRequisitionWkshName, 'LEGACY');

        // [GIVEN] Subcontracting worksheet "C" has a custom page and Planning worksheet "P" has the legacy page.
        CreateSubcontractingTemplate(CustomReqWkshTemplate, 'CUSTOM');
        CustomReqWkshTemplate."Page ID" := Page::"Planning Worksheet";
        CustomReqWkshTemplate.Modify();
        CreateSubcontractingBatch(CustomRequisitionWkshName, CustomReqWkshTemplate.Name, 'CUSTOMBAT');
        CreateConflictingWorksheet(PlanningReqWkshTemplate, PlanningRequisitionWkshName);
        PlanningReqWkshTemplate."Page ID" := 99000886;
        PlanningReqWkshTemplate.Modify();

        // [WHEN] The per-company page upgrade step runs.
        SubcReqWkshTemplUpgrade.UpgradeReqWkshTemplatePage();

        // [THEN] Only "L" is repaired; the unrelated type, custom page, batches and setup remain unchanged.
        LegacyReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        VerifyWorksheetUnchanged(LegacyReqWkshTemplate, LegacyRequisitionWkshName, 2, 1);
        VerifyWorksheetUnchanged(CustomReqWkshTemplate, CustomRequisitionWkshName, 2, 1);
        VerifyWorksheetUnchanged(PlanningReqWkshTemplate, PlanningRequisitionWkshName, 2, 1);
        VerifyConfiguredSetup(ManufacturingSetup, '', '');
    end;

    [Test]
    procedure PageUpgradeDoesNotRunAgainAfterTagIsSet()
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        MigratedReqWkshTemplate: Record "Req. Wksh. Template";
        NewLegacyReqWkshTemplate: Record "Req. Wksh. Template";
        MigratedRequisitionWkshName: Record "Requisition Wksh. Name";
        NewLegacyRequisitionWkshName: Record "Requisition Wksh. Name";
        SubcReqWkshTemplUpgrade: Codeunit "Subc. Req Wksh Templ Upgrade";
        SubcUpgradeTagDefExt: Codeunit "Subc. Upgrade Tag Def. Ext.";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] A completed page upgrade is a no-op, even when another legacy worksheet appears later.
        Initialize();

        // [GIVEN] Worksheet "M" has been migrated and another legacy worksheet "N" was created afterwards.
        PrepareUninitializedSetup(ManufacturingSetup);
        RemoveUpgradeTag(SubcUpgradeTagDefExt.GetReqWkshTemplatePageUpgradeTag());
        CreateLegacySubcontractingWorksheet(MigratedReqWkshTemplate, MigratedRequisitionWkshName, 'MIGRATED');
        SubcReqWkshTemplUpgrade.UpgradeReqWkshTemplatePage();
        MigratedReqWkshTemplate."Page ID" := Page::"Subc. Subcontracting Worksheet";
        CreateLegacySubcontractingWorksheet(NewLegacyReqWkshTemplate, NewLegacyRequisitionWkshName, 'NEWLEGACY');

        // [WHEN] The per-company page upgrade step is called again.
        SubcReqWkshTemplUpgrade.UpgradeReqWkshTemplatePage();

        // [THEN] Both worksheets remain unchanged because the completed upgrade tag prevents another migration.
        VerifyWorksheetUnchanged(MigratedReqWkshTemplate, MigratedRequisitionWkshName, 2, 1);
        VerifyWorksheetUnchanged(NewLegacyReqWkshTemplate, NewLegacyRequisitionWkshName, 2, 1);
        VerifyConfiguredSetup(ManufacturingSetup, '', '');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. ReqWkshTemplUpgrade Test");
        LibrarySetupStorage.Restore();
    end;

    local procedure PrepareUninitializedSetup(var ManufacturingSetup: Record "Manufacturing Setup")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        if not ManufacturingSetup.Get() then begin
            ManufacturingSetup.Init();
            ManufacturingSetup.Insert(true);
        end;
        Clear(LibrarySetupStorage);
        LibrarySetupStorage.Save(Database::"Manufacturing Setup");
        ManufacturingSetup."Subcontracting Template Name" := '';
        ManufacturingSetup."Subcontracting Batch Name" := '';
        ManufacturingSetup."Create Prod. Order Info Line" := false;
        Clear(ManufacturingSetup."Subc. Comp. Transfer Lead Time");
        ManufacturingSetup."Component Direct Unit Cost" := ManufacturingSetup."Component Direct Unit Cost"::Standard;
        ManufacturingSetup."Subc. Default Comp. Location" := ManufacturingSetup."Subc. Default Comp. Location"::Empty;
        ManufacturingSetup.Modify();

        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        if ReqWkshTemplate.FindSet() then
            repeat
                RequisitionWkshName.SetRange("Worksheet Template Name", ReqWkshTemplate.Name);
                RequisitionWkshName.DeleteAll();
            until ReqWkshTemplate.Next() = 0;
        ReqWkshTemplate.DeleteAll();
    end;

    local procedure CreateConflictingWorksheet(var ReqWkshTemplate: Record "Req. Wksh. Template"; var RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        RequisitionWkshName.SetRange("Worksheet Template Name", 'SUBCONTR');
        RequisitionWkshName.DeleteAll();
        RequisitionWkshName.Reset();
        ReqWkshTemplate.SetRange(Name, 'SUBCONTR');
        ReqWkshTemplate.DeleteAll();
        ReqWkshTemplate.Reset();

        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, 'SUBCONTR');
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Planning);
        ReqWkshTemplate.Description := 'Customer planning template';
        ReqWkshTemplate.Insert(true);
        ReqWkshTemplate.Recurring := true;
        ReqWkshTemplate."Increment Batch Name" := true;
        ReqWkshTemplate.Modify();
        Assert.AreEqual(Page::"Planning Worksheet", ReqWkshTemplate."Page ID", 'The conflicting template must retain its Planning page.');
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
    end;

    local procedure CreateLegacySubcontractingWorksheet(var ReqWkshTemplate: Record "Req. Wksh. Template"; var RequisitionWkshName: Record "Requisition Wksh. Name"; TemplateName: Code[10])
    begin
        CreateSubcontractingTemplate(ReqWkshTemplate, TemplateName);
        ReqWkshTemplate."Page ID" := 99000886;
        ReqWkshTemplate.Recurring := true;
        ReqWkshTemplate."Increment Batch Name" := true;
        ReqWkshTemplate.Modify();
        CreateSubcontractingBatch(RequisitionWkshName, ReqWkshTemplate.Name, 'CUSTOMBAT');
    end;

    local procedure CreateOccupiedAlternativeTemplateNames()
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        TemplateName: Code[10];
        Suffix: Integer;
    begin
        for Suffix := 1 to 99 do begin
            TemplateName := CopyStr('SUBCONTR' + Format(Suffix, 0, 9), 1, MaxStrLen(ReqWkshTemplate.Name));
            ReqWkshTemplate.SetRange(Name, TemplateName);
            ReqWkshTemplate.DeleteAll(true);
            ReqWkshTemplate.Reset();
            ReqWkshTemplate.Init();
            ReqWkshTemplate.Name := TemplateName;
            ReqWkshTemplate.Type := ReqWkshTemplate.Type::Planning;
            ReqWkshTemplate.Insert(true);
        end;
    end;

    local procedure CreateSubcontractingTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; TemplateName: Code[10])
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, TemplateName);
        ReqWkshTemplate.Validate(Type, ReqWkshTemplate.Type::Subcontracting);
        ReqWkshTemplate.Validate("Page ID", Page::"Subc. Subcontracting Worksheet");
        ReqWkshTemplate.Description := 'Custom template description';
        ReqWkshTemplate.Insert(true);
    end;

    local procedure CreateSubcontractingBatch(var RequisitionWkshName: Record "Requisition Wksh. Name"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        RequisitionWkshName.Init();
        RequisitionWkshName.Validate("Worksheet Template Name", TemplateName);
        RequisitionWkshName.Validate(Name, BatchName);
        RequisitionWkshName.Description := 'Custom batch description';
        RequisitionWkshName.Insert(true);
    end;

    local procedure VerifyDefaultSetup(TemplateName: Code[10]; BatchName: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        ExpectedLeadTime: DateFormula;
    begin
        ManufacturingSetup.Get();
        Evaluate(ExpectedLeadTime, '<1D>');
        VerifySetupSelections(ManufacturingSetup, TemplateName, BatchName);
        Assert.IsTrue(ManufacturingSetup."Create Prod. Order Info Line", 'Uninitialized setup must enable production order information lines.');
        Assert.AreEqual(ExpectedLeadTime, ManufacturingSetup."Subc. Comp. Transfer Lead Time", 'Uninitialized setup must receive the one-day transfer lead time.');
        Assert.AreEqual(ManufacturingSetup."Component Direct Unit Cost"::Standard, ManufacturingSetup."Component Direct Unit Cost", 'Initialization must retain the standard component cost choice.');
        Assert.AreEqual(ManufacturingSetup."Subc. Default Comp. Location"::Empty, ManufacturingSetup."Subc. Default Comp. Location", 'Initialization must retain the empty component location choice.');
    end;

    local procedure VerifyConfiguredSetup(ExpectedManufacturingSetup: Record "Manufacturing Setup"; TemplateName: Code[10]; BatchName: Code[10])
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        ManufacturingSetup.Get();
        VerifySetupSelections(ManufacturingSetup, TemplateName, BatchName);
        Assert.AreEqual(ExpectedManufacturingSetup."Create Prod. Order Info Line", ManufacturingSetup."Create Prod. Order Info Line", 'Initialization must preserve the configured information-line choice.');
        Assert.AreEqual(ExpectedManufacturingSetup."Subc. Comp. Transfer Lead Time", ManufacturingSetup."Subc. Comp. Transfer Lead Time", 'Initialization must preserve the configured transfer lead time, including blank.');
        Assert.AreEqual(ExpectedManufacturingSetup."Component Direct Unit Cost", ManufacturingSetup."Component Direct Unit Cost", 'Initialization must preserve the component cost choice.');
        Assert.AreEqual(ExpectedManufacturingSetup."Subc. Default Comp. Location", ManufacturingSetup."Subc. Default Comp. Location", 'Initialization must preserve the component location choice.');
    end;

    local procedure VerifySetupSelections(ManufacturingSetup: Record "Manufacturing Setup"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        Assert.AreEqual(TemplateName, ManufacturingSetup."Subcontracting Template Name", 'Initialization must select the available Subcontracting template.');
        Assert.AreEqual(BatchName, ManufacturingSetup."Subcontracting Batch Name", 'Initialization must select the available batch under the resolved template.');
    end;

    local procedure VerifySetupHelperResult(SetupAvailable: Boolean; ManufacturingSetup: Record "Manufacturing Setup"; TemplateName: Code[10]; BatchName: Code[10])
    begin
        Assert.IsTrue(SetupAvailable, 'An existing Subcontracting worksheet must make the setup helper succeed.');
        VerifySetupSelections(ManufacturingSetup, TemplateName, BatchName);
    end;

    local procedure VerifyCreatedWorksheet(ReqWkshTemplate: Record "Req. Wksh. Template"; RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        Assert.AreEqual(ReqWkshTemplate.Type::Subcontracting, ReqWkshTemplate.Type, 'The created template must have the Subcontracting type.');
        Assert.AreEqual(Page::"Subc. Subcontracting Worksheet", ReqWkshTemplate."Page ID", 'The created template must use the Subcontracting worksheet page.');
        Assert.IsFalse(ReqWkshTemplate.Recurring, 'The default template must not be recurring.');
        Assert.AreEqual(ReqWkshTemplate.Name, RequisitionWkshName."Worksheet Template Name", 'The created batch must belong to the created template.');
    end;

    local procedure VerifyAlternativeWorksheet(TemplateName: Code[10])
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.Get(TemplateName);
        RequisitionWkshName.Get(TemplateName, 'SUBCONTR');
        VerifyCreatedWorksheet(ReqWkshTemplate, RequisitionWkshName);
        VerifyWorksheetCounts(TemplateName, 1, 1);
    end;

    local procedure VerifyWorksheetUnchanged(ExpectedReqWkshTemplate: Record "Req. Wksh. Template"; ExpectedRequisitionWkshName: Record "Requisition Wksh. Name"; TemplateCount: Integer; BatchCount: Integer)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.Get(ExpectedReqWkshTemplate.Name);
        RequisitionWkshName.Get(ExpectedRequisitionWkshName."Worksheet Template Name", ExpectedRequisitionWkshName.Name);
        Assert.AreEqual(ExpectedReqWkshTemplate.SystemId, ReqWkshTemplate.SystemId, 'Initialization must reuse the template identity.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Description, ReqWkshTemplate.Description, 'Initialization must preserve the template description.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Type, ReqWkshTemplate.Type, 'Initialization must preserve the template type.');
        Assert.AreEqual(ExpectedReqWkshTemplate."Page ID", ReqWkshTemplate."Page ID", 'Initialization must preserve the template page.');
        Assert.AreEqual(ExpectedReqWkshTemplate.Recurring, ReqWkshTemplate.Recurring, 'Initialization must preserve the recurring choice.');
        Assert.AreEqual(ExpectedReqWkshTemplate."Increment Batch Name", ReqWkshTemplate."Increment Batch Name", 'Initialization must preserve the increment batch choice.');
        Assert.AreEqual(ExpectedRequisitionWkshName.SystemId, RequisitionWkshName.SystemId, 'Initialization must reuse the batch identity.');
        Assert.AreEqual(ExpectedRequisitionWkshName.Description, RequisitionWkshName.Description, 'Initialization must preserve the batch description.');
        VerifyWorksheetCounts(ReqWkshTemplate.Name, TemplateCount, BatchCount);
    end;

    local procedure VerifyWorksheetCounts(TemplateName: Code[10]; TemplateCount: Integer; BatchCount: Integer)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::Subcontracting);
        RequisitionWkshName.SetRange("Worksheet Template Name", TemplateName);
        Assert.AreEqual(TemplateCount, ReqWkshTemplate.Count(), 'Initialization must not create duplicate Subcontracting templates.');
        Assert.AreEqual(BatchCount, RequisitionWkshName.Count(), 'Initialization must not create duplicate batches under the resolved template.');
    end;

    local procedure CreateReqWkshTemplateWithRawTypeValue(var ReqWkshTemplate: Record "Req. Wksh. Template"; RawTypeValue: Integer)
    var
        ReqWkshTemplateRecordRef: RecordRef;
        TypeFieldRef: FieldRef;
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Name := CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"), 1, MaxStrLen(ReqWkshTemplate.Name));
        ReqWkshTemplate.Insert();

        ReqWkshTemplateRecordRef.GetTable(ReqWkshTemplate);
        TypeFieldRef := ReqWkshTemplateRecordRef.Field(ReqWkshTemplate.FieldNo(Type));
        TypeFieldRef.Value := RawTypeValue;
        ReqWkshTemplateRecordRef.Modify();
    end;

    local procedure CreateReqWkshTemplateWithTypedType(var ReqWkshTemplate: Record "Req. Wksh. Template"; TypeValue: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.Init();
        ReqWkshTemplate.Validate(Name, CopyStr(LibraryUtility.GenerateRandomCode(ReqWkshTemplate.FieldNo(Name), Database::"Req. Wksh. Template"), 1, MaxStrLen(ReqWkshTemplate.Name)));
        ReqWkshTemplate.Validate(Type, TypeValue);
        ReqWkshTemplate.Insert(true);
    end;

    local procedure LegacySubcontractingTypeValue(): Integer
    begin
        // Raw value the Subcontracting enum extension value used before the object renumbering (Bug 644283).
        exit(99001500);
    end;

    local procedure RemoveUpgradeTag(UpgradeTagCode: Code[250])
    var
        UpgradeTagsRecordRef: RecordRef;
        UpgradeTagsFieldRef: FieldRef;
    begin
        // Upgrade Tags is internal to System Application; scope fixture cleanup to this tag and company.
        UpgradeTagsRecordRef.Open(9999);
        UpgradeTagsFieldRef := UpgradeTagsRecordRef.Field(1); // Tag
        UpgradeTagsFieldRef.SetRange(UpgradeTagCode);
        UpgradeTagsFieldRef := UpgradeTagsRecordRef.Field(3); // Company
        UpgradeTagsFieldRef.SetRange(CompanyName());
        UpgradeTagsRecordRef.DeleteAll();
        UpgradeTagsRecordRef.Close();
    end;
}
