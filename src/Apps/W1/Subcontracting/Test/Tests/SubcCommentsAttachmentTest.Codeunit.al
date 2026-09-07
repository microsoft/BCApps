// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using System.Email;
using System.TestLibraries.Email;
using System.Utilities;

codeunit 139995 "Subc. Comments Attachment Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure StandardTaskSubcontractingCommentsCanBeMaintained()
    var
        StandardTask: Record "Standard Task";
        StandardTaskDescription: Record "Standard Task Description";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        DescriptionText: Text[100];
        Description2Text: Text[50];
    begin
        // [SCENARIO TP-002] A Standard Task stores a subcontracting comment at both maximum field lengths.
        Initialize();

        // [GIVEN] A Standard Task and maximum-length dedicated subcontracting comment values
        LibraryManufacturing.CreateStandardTask(StandardTask);
        DescriptionText := PadStr('D', MaxStrLen(DescriptionText), 'D');
        Description2Text := PadStr('E', MaxStrLen(Description2Text), 'E');

        // [WHEN] A dedicated subcontracting comment is inserted for the Standard Task
        SubcStandardTaskComment.Validate("Standard Task Code", StandardTask.Code);
        SubcStandardTaskComment."Line No." := 10000;
        SubcStandardTaskComment.Validate(Description, DescriptionText);
        SubcStandardTaskComment.Validate("Description 2", Description2Text);
        SubcStandardTaskComment.Insert();

        // [THEN] Exactly one dedicated comment is linked to the Standard Task and both values round-trip unchanged
        SubcStandardTaskComment.SetRange("Standard Task Code", StandardTask.Code);
        Assert.AreEqual(1, SubcStandardTaskComment.Count(), 'Exactly one subcontracting comment should be stored for the Standard Task.');
        SubcStandardTaskComment.Get(StandardTask.Code, 10000);
        Assert.AreEqual(DescriptionText, SubcStandardTaskComment.Description, 'The maximum-length Description should be stored unchanged.');
        Assert.AreEqual(Description2Text, SubcStandardTaskComment."Description 2", 'The maximum-length Description 2 should be stored unchanged.');

        // [THEN] The dedicated comment is not stored as an ordinary Standard Task description
        StandardTaskDescription.SetRange("Standard Task Code", StandardTask.Code);
        Assert.AreEqual(0, StandardTaskDescription.Count(), 'The dedicated comment must not create an ordinary Standard Task description.');
    end;

    [Test]
    [Scope('OnPrem')]
    [TestPermissions(TestPermissions::Restrictive)]
    procedure SubcontractingCommentPagesHonorReadAndEditPermissionSets()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        StandardTask: Record "Standard Task";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        WorkCenter: Record "Work Center";
        ProdRtngComments: TestPage "Subc. Prod. Rtng. Comments";
        RoutingComments: TestPage "Subc. Routing Comments";
        StandardTaskComments: TestPage "Subc. Standard Task Comments";
    begin
        Initialize();
        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Standard task comment', 'Standard task detail');
        SubcStandardTaskComment.Get(StandardTask.Code, 10000);

        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", '010', 1, 1);
        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 10000, 'Routing comment', 'Routing detail');
        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 10000);

        SubcProdRtngComment.Status := "Production Order Status"::Released;
        SubcProdRtngComment."Prod. Order No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SubcProdRtngComment."Prod. Order No."));
        SubcProdRtngComment."Routing Reference No." := 10000;
        SubcProdRtngComment."Routing No." := CopyStr(LibraryUtility.GenerateGUID(), 1, MaxStrLen(SubcProdRtngComment."Routing No."));
        SubcProdRtngComment."Operation No." := '010';
        SubcProdRtngComment."Line No." := 10000;
        SubcProdRtngComment.Validate(Description, 'Production routing comment');
        SubcProdRtngComment.Validate("Description 2", 'Production routing detail');
        SubcProdRtngComment.Insert();

        LibraryLowerPermissions.StartLoggingNAVPermissions();
        LibraryLowerPermissions.SetExactPermissionSet('Subcontract. - Read');

        StandardTaskComments.OpenView();
        StandardTaskComments.GoToRecord(SubcStandardTaskComment);
        StandardTaskComments.Close();
        RoutingComments.OpenView();
        RoutingComments.GoToRecord(SubcRoutingCommentLine);
        RoutingComments.Close();
        ProdRtngComments.OpenView();
        ProdRtngComments.GoToRecord(SubcProdRtngComment);
        ProdRtngComments.Close();

        LibraryLowerPermissions.SetExactPermissionSet('Subcontract. - Edit');

        StandardTaskComments.OpenEdit();
        StandardTaskComments.GoToRecord(SubcStandardTaskComment);
        StandardTaskComments.Description.SetValue('Edited standard task comment');
        StandardTaskComments.Close();
        RoutingComments.OpenEdit();
        RoutingComments.GoToRecord(SubcRoutingCommentLine);
        RoutingComments.Description.SetValue('Edited routing comment');
        RoutingComments.Close();
        ProdRtngComments.OpenEdit();
        ProdRtngComments.GoToRecord(SubcProdRtngComment);
        ProdRtngComments.Description.SetValue('Edited production routing comment');
        ProdRtngComments.Close();

        LibraryLowerPermissions.StopLoggingNAVPermissions();

        SubcStandardTaskComment.Get(StandardTask.Code, 10000);
        Assert.AreEqual('Edited standard task comment', SubcStandardTaskComment.Description, 'The Standard Task comment page should allow edits with the edit permission set.');
        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 10000);
        Assert.AreEqual('Edited routing comment', SubcRoutingCommentLine.Description, 'The Routing comment page should allow edits with the edit permission set.');
        SubcProdRtngComment.Get(
            SubcProdRtngComment.Status, SubcProdRtngComment."Prod. Order No.",
            SubcProdRtngComment."Routing Reference No.", SubcProdRtngComment."Routing No.", SubcProdRtngComment."Operation No.", SubcProdRtngComment."Line No.");
        Assert.AreEqual('Edited production routing comment', SubcProdRtngComment.Description, 'The production routing comment page should allow edits with the edit permission set.');
    end;

    [Test]
    procedure SubcontractingCommentLengthBoundariesAreEnforced()
    var
        StandardTask: Record "Standard Task";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        OverLimitDescription: Text;
        OverLimitDescription2: Text;
        OverLimitValue: Variant;
    begin
        // [SCENARIO TP-003] Over-limit subcontracting comment values are rejected while blank values remain valid.
        Initialize();

        // [GIVEN] A Standard Task and over-limit dedicated subcontracting comment values
        LibraryManufacturing.CreateStandardTask(StandardTask);
        Commit();
        OverLimitDescription := PadStr('D', 101, 'D');
        OverLimitDescription2 := PadStr('E', 51, 'E');

        // [WHEN] A 101-character Description is validated
        SubcStandardTaskComment.Validate("Standard Task Code", StandardTask.Code);
        SubcStandardTaskComment."Line No." := 10000;
        OverLimitValue := OverLimitDescription;
        asserterror SubcStandardTaskComment.Validate(Description, OverLimitValue);
        Assert.ExpectedError('The length of the string is 101');

        // [THEN] The invalid Description is not stored
        SubcStandardTaskComment.SetRange("Standard Task Code", StandardTask.Code);
        Assert.AreEqual(0, SubcStandardTaskComment.Count(), 'The invalid Description must not create a comment row.');

        // [WHEN] A 51-character Description 2 is validated
        Clear(SubcStandardTaskComment);
        SubcStandardTaskComment.Validate("Standard Task Code", StandardTask.Code);
        SubcStandardTaskComment."Line No." := 20000;
        SubcStandardTaskComment.Validate(Description, 'Valid description');
        OverLimitValue := OverLimitDescription2;
        asserterror SubcStandardTaskComment.Validate("Description 2", OverLimitValue);
        Assert.ExpectedError('The length of the string is 51');

        // [THEN] The invalid Description 2 does not leave a partial comment row
        SubcStandardTaskComment.SetRange("Standard Task Code", StandardTask.Code);
        Assert.AreEqual(0, SubcStandardTaskComment.Count(), 'The invalid Description 2 must not leave a partial comment row.');

        // [WHEN] A blank-description comment is inserted
        Clear(SubcStandardTaskComment);
        SubcStandardTaskComment.Validate("Standard Task Code", StandardTask.Code);
        SubcStandardTaskComment."Line No." := 30000;
        SubcStandardTaskComment.Insert();

        // [THEN] Blank descriptions remain within their declared fields and are persisted normally
        SubcStandardTaskComment.SetRange("Standard Task Code", StandardTask.Code);
        Assert.AreEqual(1, SubcStandardTaskComment.Count(), 'The blank subcontracting comment should be stored.');
        SubcStandardTaskComment.Get(StandardTask.Code, 30000);
        Assert.AreEqual('', SubcStandardTaskComment.Description, 'Blank Description should remain blank.');
        Assert.AreEqual('', SubcStandardTaskComment."Description 2", 'Blank Description 2 should remain blank.');
    end;

    [Test]
    procedure StandardTaskCommentsTransferToRoutingLineOnValidation()
    var
        OtherRoutingLine: Record "Routing Line";
        RoutingCommentLine: Record "Routing Comment Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        StandardTask: Record "Standard Task";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        CurrentSetupComment1Lbl: Label 'Current setup comment 1';
        CurrentSetupComment2Lbl: Label 'Current setup comment 2';
        CurrentSetupDetail1Lbl: Label 'Current setup detail 1';
        CurrentSetupDetail2Lbl: Label 'Current setup detail 2';
    begin
        // [SCENARIO TP-004] Validating a Standard Task Code replaces Routing Line setup comments.
        Initialize();

        // [GIVEN] A Standard Task with two dedicated comments and a routing with a stale dedicated comment
        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryPurchase.CreateVendor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", '010', 1, 1);
        LibraryManufacturing.CreateRoutingLineSetup(OtherRoutingLine, RoutingHeader, WorkCenter."No.", '020', 1, 1);
        SubcStandardTaskComment.Validate("Standard Task Code", StandardTask.Code);
        SubcStandardTaskComment."Line No." := 10000;
        SubcStandardTaskComment.Validate(Description, CurrentSetupComment1Lbl);
        SubcStandardTaskComment.Validate("Description 2", CurrentSetupDetail1Lbl);
        SubcStandardTaskComment.Insert();

        Clear(SubcStandardTaskComment);
        SubcStandardTaskComment.Validate("Standard Task Code", StandardTask.Code);
        SubcStandardTaskComment."Line No." := 20000;
        SubcStandardTaskComment.Validate(Description, CurrentSetupComment2Lbl);
        SubcStandardTaskComment.Validate("Description 2", CurrentSetupDetail2Lbl);
        SubcStandardTaskComment.Insert();

        SubcRoutingCommentLine."Routing No." := RoutingLine."Routing No.";
        SubcRoutingCommentLine."Version Code" := RoutingLine."Version Code";
        SubcRoutingCommentLine."Operation No." := RoutingLine."Operation No.";
        SubcRoutingCommentLine."Line No." := 10000;
        SubcRoutingCommentLine.Validate(Description, 'Stale setup comment');
        SubcRoutingCommentLine.Validate("Description 2", 'Stale setup detail');
        SubcRoutingCommentLine.Insert();

        // [GIVEN] An ordinary routing comment on a different operation
        RoutingCommentLine."Routing No." := OtherRoutingLine."Routing No.";
        RoutingCommentLine."Version Code" := OtherRoutingLine."Version Code";
        RoutingCommentLine."Operation No." := OtherRoutingLine."Operation No.";
        RoutingCommentLine."Line No." := 10000;
        RoutingCommentLine.Validate(Comment, 'Ordinary routing comment');
        RoutingCommentLine.Insert();

        // [WHEN] The Standard Task Code is validated on the Routing Line
        RoutingLine.Validate("Standard Task Code", StandardTask.Code);

        // [THEN] The dedicated Routing Line comments exactly match the Standard Task comments
        SubcRoutingCommentLine.SetRange("Routing No.", RoutingLine."Routing No.");
        SubcRoutingCommentLine.SetRange("Version Code", RoutingLine."Version Code");
        SubcRoutingCommentLine.SetRange("Operation No.", RoutingLine."Operation No.");
        Assert.AreEqual(2, SubcRoutingCommentLine.Count(), 'The Routing Line should contain exactly the two current Standard Task comments.');

        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 10000);
        Assert.AreEqual(CurrentSetupComment1Lbl, SubcRoutingCommentLine.Description, 'The first Standard Task comment should replace the stale comment.');
        Assert.AreEqual(CurrentSetupDetail1Lbl, SubcRoutingCommentLine."Description 2", 'The first Standard Task comment detail should be transferred.');

        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 20000);
        Assert.AreEqual(CurrentSetupComment2Lbl, SubcRoutingCommentLine.Description, 'The second Standard Task comment should be transferred.');
        Assert.AreEqual(CurrentSetupDetail2Lbl, SubcRoutingCommentLine."Description 2", 'The second Standard Task comment detail should be transferred.');

        // [THEN] Ordinary routing comments on other operations remain separate and unchanged
        RoutingCommentLine.Get(OtherRoutingLine."Routing No.", OtherRoutingLine."Version Code", OtherRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Ordinary routing comment', RoutingCommentLine.Comment, 'An ordinary routing comment on another operation must remain unchanged.');
    end;

    [Test]
    procedure StandardTaskCommentsTransferToSubcontractingRoutingLine()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        StandardTask: Record "Standard Task";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO TP-032] Validating a Standard Task Code copies dedicated comments to a subcontracting Routing Line.
        Initialize();

        // [GIVEN] A subcontracting Work Center and a Standard Task with two dedicated comments
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);
        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Subcontracting comment 1', 'Subcontracting detail 1');
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 20000, 'Subcontracting comment 2', 'Subcontracting detail 2');

        // [GIVEN] A Routing Line that uses the subcontracting Work Center
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", '010', 1, 1);
        RoutingLine.CalcFields(Subcontracting);
        Assert.IsTrue(RoutingLine.Subcontracting, 'The Routing Line should evaluate as subcontracting.');

        // [WHEN] The Standard Task Code is validated on the Routing Line
        RoutingLine.Validate("Standard Task Code", StandardTask.Code);

        // [THEN] The dedicated Routing Line comments exactly match the Standard Task comments
        SubcRoutingCommentLine.SetRange("Routing No.", RoutingLine."Routing No.");
        SubcRoutingCommentLine.SetRange("Version Code", RoutingLine."Version Code");
        SubcRoutingCommentLine.SetRange("Operation No.", RoutingLine."Operation No.");
        Assert.AreEqual(2, SubcRoutingCommentLine.Count(), 'The subcontracting Routing Line should contain both Standard Task comments.');

        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 10000);
        Assert.AreEqual('Subcontracting comment 1', SubcRoutingCommentLine.Description, 'The first Standard Task comment should be transferred.');
        Assert.AreEqual('Subcontracting detail 1', SubcRoutingCommentLine."Description 2", 'The first Standard Task detail should be transferred.');

        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 20000);
        Assert.AreEqual('Subcontracting comment 2', SubcRoutingCommentLine.Description, 'The second Standard Task comment should be transferred.');
        Assert.AreEqual('Subcontracting detail 2', SubcRoutingCommentLine."Description 2", 'The second Standard Task detail should be transferred.');
    end;

    [Test]
    procedure StandardTaskCommentsAreNotTransferredToNonSubcontractingRoutingLine()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        StandardTask: Record "Standard Task";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO TP-034] Validating a Standard Task Code does not copy dedicated comments to a non-subcontracting Routing Line.
        Initialize();

        // [GIVEN] A regular Work Center and a Standard Task with two dedicated comments
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Regular operation comment 1', 'Regular operation detail 1');
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 20000, 'Regular operation comment 2', 'Regular operation detail 2');

        // [GIVEN] A Routing Line that uses the regular Work Center
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", '010', 1, 1);
        RoutingLine.CalcFields(Subcontracting);
        Assert.IsFalse(RoutingLine.Subcontracting, 'The Routing Line should evaluate as non-subcontracting.');

        // [WHEN] The Standard Task Code is validated on the Routing Line
        RoutingLine.Validate("Standard Task Code", StandardTask.Code);

        // [THEN] No dedicated Routing Line comments are inserted
        SubcRoutingCommentLine.SetRange("Routing No.", RoutingLine."Routing No.");
        SubcRoutingCommentLine.SetRange("Version Code", RoutingLine."Version Code");
        SubcRoutingCommentLine.SetRange("Operation No.", RoutingLine."Operation No.");
        Assert.AreEqual(0, SubcRoutingCommentLine.Count(), 'A non-subcontracting Routing Line must not receive Standard Task comments.');

        // [THEN] The Standard Task source comments remain unchanged
        SubcStandardTaskComment.SetRange("Standard Task Code", StandardTask.Code);
        Assert.AreEqual(2, SubcStandardTaskComment.Count(), 'The Standard Task comments must remain available as the source set.');
    end;

    [Test]
    procedure StandardTaskCommentsTransferToSubcontractingProdOrderRoutingLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        StandardTask: Record "Standard Task";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-033] Validating a Standard Task Code copies dedicated comments to a subcontracting production operation.
        Initialize();

        // [GIVEN] A released production order with a subcontracting operation
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Production subcontracting comment 1', 'Production subcontracting detail 1');
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 20000, 'Production subcontracting comment 2', 'Production subcontracting detail 2');

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.CalcFields(Subcontracting);
        Assert.IsTrue(ProdOrderRoutingLine.Subcontracting, 'The production operation should evaluate as subcontracting.');

        // [WHEN] The Standard Task Code is validated on the production operation
        ProdOrderRoutingLine.Validate("Standard Task Code", StandardTask.Code);

        // [THEN] The dedicated production comments exactly match the Standard Task comments
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The subcontracting production operation should contain both Standard Task comments.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.",
            ProdOrderRoutingLine."Routing Reference No.", ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Production subcontracting comment 1', SubcProdRtngComment.Description, 'The first Standard Task comment should be transferred.');
        Assert.AreEqual('Production subcontracting detail 1', SubcProdRtngComment."Description 2", 'The first Standard Task detail should be transferred.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.",
            ProdOrderRoutingLine."Routing Reference No.", ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000);
        Assert.AreEqual('Production subcontracting comment 2', SubcProdRtngComment.Description, 'The second Standard Task comment should be transferred.');
        Assert.AreEqual('Production subcontracting detail 2', SubcProdRtngComment."Description 2", 'The second Standard Task detail should be transferred.');
    end;

    [Test]
    procedure StandardTaskCommentsAreNotTransferredToNonSubcontractingProdOrderRoutingLine()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        StandardTask: Record "Standard Task";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        SubcStandardTaskComment: Record "Subc. Standard Task Comment";
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-035] Validating a Standard Task Code does not copy dedicated comments to a non-subcontracting production operation.
        Initialize();

        // [GIVEN] A released production order with a regular operation
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, false);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Regular production comment 1', 'Regular production detail 1');
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 20000, 'Regular production comment 2', 'Regular production detail 2');

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.CalcFields(Subcontracting);
        Assert.IsFalse(ProdOrderRoutingLine.Subcontracting, 'The production operation should evaluate as non-subcontracting.');

        // [WHEN] The Standard Task Code is validated on the production operation
        ProdOrderRoutingLine.Validate("Standard Task Code", StandardTask.Code);

        // [THEN] No dedicated production comments are inserted
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(0, SubcProdRtngComment.Count(), 'A non-subcontracting production operation must not receive Standard Task comments.');

        // [THEN] The Standard Task source comments remain unchanged
        SubcStandardTaskComment.SetRange("Standard Task Code", StandardTask.Code);
        Assert.AreEqual(2, SubcStandardTaskComment.Count(), 'The Standard Task comments must remain available as the source set.');
    end;

    [Test]
    procedure RemovingSubcontractorPreservesRoutingLineComments()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
    begin
        // [SCENARIO TP-036] Removing a subcontractor preserves existing Routing Line comments without an error.
        Initialize();

        // [GIVEN] A subcontracting Work Center, Routing Line, and dedicated comment
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenter."No.", '010', 1, 1);
        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 10000, 'Preserved routing comment', 'Preserved routing detail');

        // [WHEN] The subcontractor is cleared through the normal Work Center record trigger path
        WorkCenter.Validate("Subcontractor No.", '');
        WorkCenter.Modify(true);

        // [THEN] The Work Center is no longer subcontracting and the existing comment remains
        WorkCenter.Get(WorkCenter."No.");
        RoutingLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.");
        RoutingLine.CalcFields(Subcontracting);
        Assert.IsFalse(RoutingLine.Subcontracting, 'The Routing Line should evaluate as non-subcontracting after removal.');

        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 10000);
        Assert.AreEqual('Preserved routing comment', SubcRoutingCommentLine.Description, 'The existing Routing Line comment should be preserved.');
        Assert.AreEqual('Preserved routing detail', SubcRoutingCommentLine."Description 2", 'The existing Routing Line detail should be preserved.');
    end;

    [Test]
    procedure RemovingSubcontractorPreservesProdOrderRoutingLineComments()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-037] Removing a subcontractor preserves existing production comments without an error.
        Initialize();

        // [GIVEN] A released production operation with a subcontractor and a dedicated comment
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(
            ProdOrderRoutingLine, 10000, 'Preserved production comment', 'Preserved production detail');

        // [WHEN] The subcontractor is cleared through the normal Work Center record trigger path
        WorkCenter[2].Get(WorkCenter[2]."No.");
        WorkCenter[2].Validate("Subcontractor No.", '');
        WorkCenter[2].Modify(true);

        // [THEN] The production operation is no longer subcontracting and its existing comment remains
        WorkCenter[2].Get(WorkCenter[2]."No.");
        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.CalcFields(Subcontracting);
        Assert.IsFalse(ProdOrderRoutingLine.Subcontracting, 'The production operation should evaluate as non-subcontracting after removal.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.",
            ProdOrderRoutingLine."Routing Reference No.", ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Preserved production comment', SubcProdRtngComment.Description, 'The existing production comment should be preserved.');
        Assert.AreEqual('Preserved production detail', SubcProdRtngComment."Description 2", 'The existing production detail should be preserved.');
    end;

    [Test]
    procedure RemovedSubcontractorDoesNotTransferCommentsToPurchaseLine()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        SubcPurchaseOrderCreator: Codeunit "Subc. Purchase Order Creator";
        NextLineNo: Integer;
    begin
        // [SCENARIO TP-038] Preserved production comments are not transferred to Purchase Lines after subcontractor removal.
        Initialize();

        // [GIVEN] A released subcontracting production operation with a dedicated comment
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(
            ProdOrderRoutingLine, 10000, 'Preserved purchase source comment', 'Preserved purchase source detail');

        // [GIVEN] The Work Center is no longer subcontracting while the source comment remains
        WorkCenter[2].Get(WorkCenter[2]."No.");
        WorkCenter[2].Validate("Subcontractor No.", '');
        WorkCenter[2].Modify(true);

        // [GIVEN] A parent item Purchase Line and Requisition Line reference the production operation
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine."Prod. Order No." := ProductionOrder."No.";
        PurchaseLine."Prod. Order Line No." := ProdOrderRoutingLine."Routing Reference No.";
        PurchaseLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        PurchaseLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        PurchaseLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        PurchaseLine.Modify();

        RequisitionLine."Prod. Order No." := ProductionOrder."No.";
        RequisitionLine."Prod. Order Line No." := ProdOrderRoutingLine."Routing Reference No.";
        RequisitionLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
        RequisitionLine."Routing No." := ProdOrderRoutingLine."Routing No.";
        RequisitionLine."Operation No." := ProdOrderRoutingLine."Operation No.";
        NextLineNo := PurchaseLine."Line No.";

        // [WHEN] The production comments are transferred through the public purchase-order creator path
        SubcPurchaseOrderCreator.InsertSubcontractingProdOrderComments(PurchaseLine, RequisitionLine, NextLineNo);

        // [THEN] No attached blank Purchase Line is created for the preserved comment
        AttachedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchaseLine.SetRange(Type, AttachedPurchaseLine.Type::" ");
        AttachedPurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, AttachedPurchaseLine.Count(), 'A removed subcontractor must not transfer a preserved comment to a Purchase Line.');

        // [THEN] The original production comment remains unchanged
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(1, SubcProdRtngComment.Count(), 'The preserved production comment should remain as the source row.');
        SubcProdRtngComment.FindFirst();
        Assert.AreEqual('Preserved purchase source comment', SubcProdRtngComment.Description, 'The source production comment should remain unchanged.');
        Assert.AreEqual('Preserved purchase source detail', SubcProdRtngComment."Description 2", 'The source production detail should remain unchanged.');
    end;

    [Test]
    procedure StandardTaskCommentsTransferToProdOrderRoutingLineOnValidation()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        OtherProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRoutingLineBlankXRec: Record "Prod. Order Routing Line";
        ProdOrderRoutingLineNonblankXRec: Record "Prod. Order Routing Line";
        ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";
        ProductionOrder: Record "Production Order";
        PreviousStandardTask: Record "Standard Task";
        StandardTask: Record "Standard Task";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        OrdinaryCommentText: Text[80];
    begin
        // [SCENARIO TP-005] Validating a Standard Task Code replaces production-order routing comments for blank and nonblank xRec values.
        Initialize();

        // [GIVEN] A released production order with two subcontracting operations
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryManufacturing.CreateStandardTask(PreviousStandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Current production comment 1', 'Current production detail 1');
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 20000, 'Current production comment 2', 'Current production detail 2');

        // [GIVEN] A stale dedicated comment on an operation with a blank prior Standard Task Code
        ProdOrderRoutingLineBlankXRec.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLineBlankXRec.SetRange("Work Center No.", WorkCenter[1]."No.");
        ProdOrderRoutingLineBlankXRec.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLineBlankXRec, 10000, 'Stale production comment 1', 'Stale production detail 1');

        // [GIVEN] A stale dedicated comment on an operation with a nonblank prior Standard Task Code
        ProdOrderRoutingLineNonblankXRec.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLineNonblankXRec.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLineNonblankXRec.FindFirst();
        ProdOrderRoutingLineNonblankXRec.Validate("Standard Task Code", PreviousStandardTask.Code);
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLineNonblankXRec, 10000, 'Stale production comment 2', 'Stale production detail 2');

        // [GIVEN] An ordinary production-order routing comment on another operation
        OtherProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        OtherProdOrderRoutingLine.SetFilter(
            "Operation No.", '<>%1&<>%2', ProdOrderRoutingLineBlankXRec."Operation No.", ProdOrderRoutingLineNonblankXRec."Operation No.");
        OtherProdOrderRoutingLine.SetRange(Type, OtherProdOrderRoutingLine.Type::"Machine Center");
        OtherProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderRtngCommentLine(
            OtherProdOrderRoutingLine.Status, OtherProdOrderRoutingLine."Prod. Order No.",
            OtherProdOrderRoutingLine."Routing Reference No.", OtherProdOrderRoutingLine."Routing No.",
            OtherProdOrderRoutingLine."Operation No.");
        ProdOrderRtngCommentLine.SetRange(Status, OtherProdOrderRoutingLine.Status);
        ProdOrderRtngCommentLine.SetRange("Prod. Order No.", OtherProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRtngCommentLine.SetRange("Routing Reference No.", OtherProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRtngCommentLine.SetRange("Routing No.", OtherProdOrderRoutingLine."Routing No.");
        ProdOrderRtngCommentLine.SetRange("Operation No.", OtherProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(1, ProdOrderRtngCommentLine.Count(), 'Exactly one ordinary production-order routing comment should exist on the other operation.');
        ProdOrderRtngCommentLine.FindFirst();
        OrdinaryCommentText := ProdOrderRtngCommentLine.Comment;

        // [WHEN] Standard Task Code is validated with a blank xRec and then with a nonblank xRec
        ProdOrderRoutingLineBlankXRec.Validate("Standard Task Code", StandardTask.Code);
        ProdOrderRoutingLineNonblankXRec.Validate("Standard Task Code", StandardTask.Code);

        // [THEN] Both xRec partitions contain exactly the selected Standard Task comments
        AssertProdOrderCommentsMatchStandardTask(ProdOrderRoutingLineBlankXRec);
        AssertProdOrderCommentsMatchStandardTask(ProdOrderRoutingLineNonblankXRec);

        // [THEN] The ordinary production-order routing comment remains separate and unchanged
        ProdOrderRtngCommentLine.Reset();
        ProdOrderRtngCommentLine.SetRange(Status, OtherProdOrderRoutingLine.Status);
        ProdOrderRtngCommentLine.SetRange("Prod. Order No.", OtherProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRtngCommentLine.SetRange("Routing Reference No.", OtherProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRtngCommentLine.SetRange("Routing No.", OtherProdOrderRoutingLine."Routing No.");
        ProdOrderRtngCommentLine.SetRange("Operation No.", OtherProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(1, ProdOrderRtngCommentLine.Count(), 'The ordinary production-order routing comment must remain unchanged.');
        ProdOrderRtngCommentLine.FindFirst();
        Assert.AreEqual(OrdinaryCommentText, ProdOrderRtngCommentLine.Comment, 'The ordinary production-order routing comment text must remain unchanged.');
    end;

    [Test]
    procedure ProductionOrderCreationCopiesRoutingSubcontractingComments()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";
        ProductionOrder: Record "Production Order";
        RoutingCommentLine: Record "Routing Comment Line";
        RoutingLine: Record "Routing Line";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-006] Production-order creation copies dedicated Routing Line comments to the production operation.
        Initialize();

        // [GIVEN] A certified item routing with a subcontracting operation and dedicated setup comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        RoutingLine.FindFirst();

        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 10000, 'Routing setup comment 1', 'Routing setup detail 1');
        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 20000, 'Routing setup comment 2', 'Routing setup detail 2');

        // [GIVEN] An ordinary routing comment on the same operation
        RoutingCommentLine."Routing No." := RoutingLine."Routing No.";
        RoutingCommentLine."Version Code" := RoutingLine."Version Code";
        RoutingCommentLine."Operation No." := RoutingLine."Operation No.";
        RoutingCommentLine."Line No." := 10000;
        RoutingCommentLine.Validate(Comment, 'Ordinary routing setup comment');
        RoutingCommentLine.Insert();

        // [WHEN] The production order is created and refreshed
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        // [THEN] Dedicated production-order comments exactly match the dedicated Routing Line setup
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", RoutingLine."Operation No.");
        ProdOrderRoutingLine.FindFirst();

        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The production-order operation should contain exactly the two dedicated routing setup comments.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Routing setup comment 1', SubcProdRtngComment.Description, 'The first dedicated routing comment should be copied to the production order.');
        Assert.AreEqual('Routing setup detail 1', SubcProdRtngComment."Description 2", 'The first dedicated routing detail should be copied to the production order.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000);
        Assert.AreEqual('Routing setup comment 2', SubcProdRtngComment.Description, 'The second dedicated routing comment should be copied to the production order.');
        Assert.AreEqual('Routing setup detail 2', SubcProdRtngComment."Description 2", 'The second dedicated routing detail should be copied to the production order.');

        // [THEN] The ordinary routing comment remains an ordinary production-order routing comment
        ProdOrderRtngCommentLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderRtngCommentLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRtngCommentLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRtngCommentLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderRtngCommentLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(1, ProdOrderRtngCommentLine.Count(), 'The ordinary routing comment should remain separate from dedicated subcontracting comments.');
        ProdOrderRtngCommentLine.FindFirst();
        Assert.AreEqual('Ordinary routing setup comment', ProdOrderRtngCommentLine.Comment, 'The ordinary routing comment should be copied unchanged by standard behavior.');

        // [THEN] The source dedicated routing comments remain available
        SubcRoutingCommentLine.SetRange("Routing No.", RoutingLine."Routing No.");
        SubcRoutingCommentLine.SetRange("Version Code", RoutingLine."Version Code");
        SubcRoutingCommentLine.SetRange("Operation No.", RoutingLine."Operation No.");
        Assert.AreEqual(2, SubcRoutingCommentLine.Count(), 'The source routing setup comments should remain unchanged after production-order creation.');
    end;

    [Test]
    procedure FirmPlannedProductionOrderStatusChangeTransfersSubcontractingComments()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        FirmPlannedProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        ReleasedProdOrderRoutingLine: Record "Prod. Order Routing Line";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        FirmPlannedProdOrderNo: Code[20];
    begin
        // [SCENARIO TP-028] Changing a Firm Planned production order to Released transfers dedicated subcontracting comments.
        Initialize();

        // [GIVEN] A Firm Planned production order with a subcontracting operation and two dedicated comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::"Firm Planned",
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        FirmPlannedProdOrderRoutingLine.SetRange(Status, "Production Order Status"::"Firm Planned");
        FirmPlannedProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        FirmPlannedProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        FirmPlannedProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(
            FirmPlannedProdOrderRoutingLine, 10000, 'Status change comment 1', 'Status change detail 1');
        LibraryMfgManagement.CreateProdOrderSubcComment(
            FirmPlannedProdOrderRoutingLine, 20000, 'Status change comment 2', 'Status change detail 2');
        FirmPlannedProdOrderNo := ProductionOrder."No.";

        // [WHEN] The production order status is changed to Released
        LibraryManufacturing.ChangeProdOrderStatus(ProductionOrder, "Production Order Status"::Released, WorkDate(), false);

        // [THEN] The dedicated comments are transferred to the Released production-order operation
        ProductionOrder.Reset();
        ProductionOrder.SetRange(Status, "Production Order Status"::Released);
        ProductionOrder.SetRange("Source No.", Item."No.");
        ProductionOrder.FindFirst();
        ReleasedProdOrderRoutingLine.SetRange(Status, "Production Order Status"::Released);
        ReleasedProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ReleasedProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ReleasedProdOrderRoutingLine.FindFirst();

        SubcProdRtngComment.SetRange(Status, ReleasedProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ReleasedProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ReleasedProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ReleasedProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ReleasedProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The Released operation should contain both transferred subcontracting comments.');

        SubcProdRtngComment.Get(
            ReleasedProdOrderRoutingLine.Status, ReleasedProdOrderRoutingLine."Prod. Order No.", ReleasedProdOrderRoutingLine."Routing Reference No.",
            ReleasedProdOrderRoutingLine."Routing No.", ReleasedProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Status change comment 1', SubcProdRtngComment.Description, 'The first subcontracting comment should be transferred to Released.');
        Assert.AreEqual('Status change detail 1', SubcProdRtngComment."Description 2", 'The first subcontracting comment detail should be transferred to Released.');

        SubcProdRtngComment.Get(
            ReleasedProdOrderRoutingLine.Status, ReleasedProdOrderRoutingLine."Prod. Order No.", ReleasedProdOrderRoutingLine."Routing Reference No.",
            ReleasedProdOrderRoutingLine."Routing No.", ReleasedProdOrderRoutingLine."Operation No.", 20000);
        Assert.AreEqual('Status change comment 2', SubcProdRtngComment.Description, 'The second subcontracting comment should be transferred to Released.');
        Assert.AreEqual('Status change detail 2', SubcProdRtngComment."Description 2", 'The second subcontracting comment detail should be transferred to Released.');

        // [THEN] The Firm Planned source comments are removed after the status change
        SubcProdRtngComment.Reset();
        SubcProdRtngComment.SetRange(Status, "Production Order Status"::"Firm Planned");
        SubcProdRtngComment.SetRange("Prod. Order No.", FirmPlannedProdOrderNo);
        Assert.AreEqual(0, SubcProdRtngComment.Count(), 'The Firm Planned subcontracting comments should not remain after the status change.');
    end;

    [Test]
    procedure RoutingRefreshReplacesProductionSubcontractingComments()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        SubcRoutingCommentLine: Record "Subc. Routing Comment Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-007] Routing refresh replaces setup-derived production subcontracting comments.
        Initialize();

        // [GIVEN] A production order with the original routing setup comment set
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        RoutingLine.FindFirst();
        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 10000, 'Original routing comment', 'Original routing detail');
        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 20000, 'Removed routing comment', 'Removed routing detail');

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", RoutingLine."Operation No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 30000, 'Order-specific pre-refresh comment', 'Order-specific pre-refresh detail');

        // [GIVEN] The routing setup is changed before the production order is refreshed
        SubcRoutingCommentLine.Get(RoutingLine."Routing No.", RoutingLine."Version Code", RoutingLine."Operation No.", 20000);
        SubcRoutingCommentLine.Delete();
        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 30000, 'New routing comment', 'New routing detail');

        // [WHEN] The production order routing is refreshed
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [THEN] Only the newly transferred setup rows remain; the old and order-specific rows are replaced
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'Routing refresh should leave exactly the current setup comment set.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Original routing comment', SubcProdRtngComment.Description, 'The unchanged setup comment should remain after refresh.');
        Assert.AreEqual('Original routing detail', SubcProdRtngComment."Description 2", 'The unchanged setup detail should remain after refresh.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 30000);
        Assert.AreEqual('New routing comment', SubcProdRtngComment.Description, 'The new setup comment should replace the removed and order-specific rows.');
        Assert.AreEqual('New routing detail', SubcProdRtngComment."Description 2", 'The new setup detail should be transferred during refresh.');
    end;

    [Test]
    procedure ProdOrderRoutingStandardTaskRevalidationReplacesComments()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        StandardTask: Record "Standard Task";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-008] Revalidating a nonblank Standard Task Code replaces prior production comments.
        Initialize();

        // [GIVEN] A released production order and a Standard Task with two dedicated comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Revalidated comment 1', 'Revalidated detail 1');
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 20000, 'Revalidated comment 2', 'Revalidated detail 2');

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] The Standard Task Code is assigned and an order-specific row is added
        ProdOrderRoutingLine.Validate("Standard Task Code", StandardTask.Code);
        ProdOrderRoutingLine.Modify(true);
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 30000, 'Order-specific comment', 'Order-specific detail');

        // [WHEN] The same nonblank Standard Task Code is validated again
        ProdOrderRoutingLine.Validate("Standard Task Code", StandardTask.Code);

        // [THEN] Only the current Standard Task comment set remains
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'Revalidation should leave exactly the current Standard Task comments.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Revalidated comment 1', SubcProdRtngComment.Description, 'The first Standard Task comment should remain after revalidation.');
        Assert.AreEqual('Revalidated detail 1', SubcProdRtngComment."Description 2", 'The first Standard Task detail should remain after revalidation.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000);
        Assert.AreEqual('Revalidated comment 2', SubcProdRtngComment.Description, 'The second Standard Task comment should remain after revalidation.');
        Assert.AreEqual('Revalidated detail 2', SubcProdRtngComment."Description 2", 'The second Standard Task detail should remain after revalidation.');
    end;

    [Test]
    procedure ProductionOrderCommentCanBeAddedBeforePurchaseCreation()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        RoutingLine: Record "Routing Line";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-009] A user can add an order-specific production comment after setup transfer.
        Initialize();

        // [GIVEN] A production order operation with a setup-derived comment
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        RoutingLine.FindFirst();
        LibraryMfgManagement.CreateRoutingSubcComment(RoutingLine, 10000, 'Setup comment', 'Setup detail');

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", RoutingLine."Operation No.");
        ProdOrderRoutingLine.FindFirst();

        // [WHEN] The user inserts an additional production-order comment
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 20000, 'Order-specific comment', 'Order-specific detail');

        // [THEN] The new comment is stored under the exact operation key and setup comments remain unchanged
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The operation should contain the setup and order-specific comments.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000);
        Assert.AreEqual('Order-specific comment', SubcProdRtngComment.Description, 'The order-specific Description should be stored unchanged.');
        Assert.AreEqual('Order-specific detail', SubcProdRtngComment."Description 2", 'The order-specific Description 2 should be stored unchanged.');
    end;

    [Test]
    procedure ProductionOrderCommentCanBeEditedBeforePurchaseCreation()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-010] A user can edit both description fields on a production-order subcontracting comment.
        Initialize();

        // [GIVEN] A production-order operation with one dedicated comment
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[1]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 10000, 'Initial comment', 'Initial detail');

        // [WHEN] The user edits both description fields on the existing comment
        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        SubcProdRtngComment.Validate(Description, 'Edited comment');
        SubcProdRtngComment.Validate("Description 2", 'Edited detail');
        SubcProdRtngComment.Modify();

        // [THEN] The same line key retains both edited values without creating a duplicate
        SubcProdRtngComment.Reset();
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(1, SubcProdRtngComment.Count(), 'Editing a comment should not create a duplicate line.');
        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Edited comment', SubcProdRtngComment.Description, 'The edited Description should be persisted on the same line.');
        Assert.AreEqual('Edited detail', SubcProdRtngComment."Description 2", 'The edited Description 2 should be persisted on the same line.');
    end;

    [Test]
    procedure ProductionOrderCommentCanBeExcludedBeforePurchaseCreation()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-011] A user can exclude one production-order comment before purchase creation.
        Initialize();

        // [GIVEN] A production-order operation with two dedicated comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 10000, 'Keep this comment', 'Keep this detail');
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 20000, 'Exclude this comment', 'Exclude this detail');

        // [WHEN] The user deletes the comment that should not be sent to the vendor
        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000);
        SubcProdRtngComment.Delete(true);

        // [THEN] Only the remaining comment stays linked to the same operation
        Assert.IsFalse(
            SubcProdRtngComment.Get(
                ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
                ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000),
            'The excluded production-order comment should no longer exist.');

        SubcProdRtngComment.Reset();
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(1, SubcProdRtngComment.Count(), 'Exactly one production-order comment should remain for the operation.');
        SubcProdRtngComment.FindFirst();
        Assert.AreEqual('Keep this comment', SubcProdRtngComment.Description, 'The remaining comment should stay eligible for purchase transfer.');
        Assert.AreEqual('Keep this detail', SubcProdRtngComment."Description 2", 'The remaining comment detail should be unchanged.');
    end;

    [Test]
    procedure DirectSubcontractingPurchaseCreationTransfersProductionComments()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        FirstCommentCount: Integer;
        SecondCommentCount: Integer;
    begin
        // [SCENARIO TP-012] Direct purchase creation transfers production comments to attached blank Purchase Lines.
        Initialize();

        // [GIVEN] A released production order with two subcontracting comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 10000, 'Purchase comment 1', 'Purchase detail 1');
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 20000, 'Purchase comment 2', 'Purchase detail 2');
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] The user creates the subcontracting purchase order directly from the routing line
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [THEN] Each production comment becomes an attached blank Purchase Line for the parent item line
        Assert.AreEqual(PurchaseLine.Type::Item, PurchaseLine.Type, 'The direct flow should return the parent item Purchase Line.');
        AttachedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchaseLine.SetRange(Type, AttachedPurchaseLine.Type::" ");
        AttachedPurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(2, AttachedPurchaseLine.Count(), 'Each production comment should create one attached blank Purchase Line.');

        if AttachedPurchaseLine.FindSet() then
            repeat
                if (AttachedPurchaseLine.Description = 'Purchase comment 1') and
                   (AttachedPurchaseLine."Description 2" = 'Purchase detail 1')
                then begin
                    FirstCommentCount += 1;
                    Assert.AreEqual(0, AttachedPurchaseLine.Quantity, 'An attached comment Purchase Line should have zero quantity.');
                end;
                if (AttachedPurchaseLine.Description = 'Purchase comment 2') and
                   (AttachedPurchaseLine."Description 2" = 'Purchase detail 2')
                then begin
                    SecondCommentCount += 1;
                    Assert.AreEqual(0, AttachedPurchaseLine.Quantity, 'An attached comment Purchase Line should have zero quantity.');
                end;
            until AttachedPurchaseLine.Next() = 0;
        Assert.AreEqual(1, FirstCommentCount, 'The first production comment should be copied to an attached Purchase Line.');
        Assert.AreEqual(1, SecondCommentCount, 'The second production comment should be copied to an attached Purchase Line.');

        // [THEN] The dedicated production comments remain the source rows for the transfer
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The two production comments should remain available after direct purchase creation.');
    end;

    [Test]
    procedure RepeatedSubcontractingPurchaseCreationDoesNotDuplicateComments()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        PurchaseDocumentNo: Code[20];
        PurchaseLineNo: Integer;
    begin
        // [SCENARIO TP-014] Repeated purchase creation does not duplicate attached comment lines.
        Initialize();

        // [GIVEN] A released production order with two subcontracting comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 10000, 'Repeated comment 1', 'Repeated detail 1');
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 20000, 'Repeated comment 2', 'Repeated detail 2');
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] The same direct purchase creation action is invoked twice
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseDocumentNo := PurchaseLine."Document No.";
        PurchaseLineNo := PurchaseLine."Line No.";
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [THEN] The existing parent purchase line is reused and each source comment has one attached line
        Assert.AreEqual(PurchaseDocumentNo, PurchaseLine."Document No.", 'Repeated creation should reuse the existing purchase document.');
        Assert.AreEqual(PurchaseLineNo, PurchaseLine."Line No.", 'Repeated creation should reuse the existing parent purchase line.');
        AttachedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchaseLine.SetRange(Type, AttachedPurchaseLine.Type::" ");
        AttachedPurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(2, AttachedPurchaseLine.Count(), 'Repeated creation must not duplicate attached comment Purchase Lines.');
    end;

    [Test]
    procedure DeletingSubcontractingParentLineDeletesAttachedCommentLines()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        UnrelatedAttachedPurchaseLine: Record "Purchase Line";
        UnrelatedPurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-015] Deleting a subcontracting parent removes its attached comment lines only.
        Initialize();

        // [GIVEN] A released production order with two subcontracting comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 10000, 'Delete comment 1', 'Delete detail 1');
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 20000, 'Delete comment 2', 'Delete detail 2');
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [GIVEN] A subcontracting purchase parent and an unrelated parent with its own attached line
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        LibraryPurchase.CreatePurchaseLine(UnrelatedPurchaseLine, PurchaseHeader, UnrelatedPurchaseLine.Type::Item, Item."No.", 1);

        UnrelatedAttachedPurchaseLine.Init();
        UnrelatedAttachedPurchaseLine."Document Type" := PurchaseHeader."Document Type";
        UnrelatedAttachedPurchaseLine."Document No." := PurchaseHeader."No.";
        UnrelatedAttachedPurchaseLine."Line No." := UnrelatedPurchaseLine."Line No." + 10000;
        UnrelatedAttachedPurchaseLine.Type := UnrelatedAttachedPurchaseLine.Type::" ";
        UnrelatedAttachedPurchaseLine."Attached to Line No." := UnrelatedPurchaseLine."Line No.";
        UnrelatedAttachedPurchaseLine.Description := 'Unrelated comment';
        UnrelatedAttachedPurchaseLine."Description 2" := 'Unrelated detail';
        UnrelatedAttachedPurchaseLine.Insert();

        // [WHEN] The subcontracting parent Purchase Line is deleted through the normal trigger path
        PurchaseLine.Delete(true);

        // [THEN] Both attached comment lines for the deleted parent are removed
        AttachedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchaseLine.SetRange(Type, AttachedPurchaseLine.Type::" ");
        AttachedPurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, AttachedPurchaseLine.Count(), 'Deleting the subcontracting parent must remove all attached comment lines.');

        // [THEN] The unrelated parent and its attached line remain
        Assert.IsTrue(
            UnrelatedPurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", UnrelatedPurchaseLine."Line No."),
            'Deleting one parent must retain the unrelated parent Purchase Line.');
        Assert.IsTrue(
            UnrelatedAttachedPurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", UnrelatedAttachedPurchaseLine."Line No."),
            'Deleting one parent must retain the unrelated attached Purchase Line.');
    end;

    [Test]
    procedure WorksheetSubcontractingPurchaseCreationTransfersProductionComments()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        FirstCommentCount: Integer;
        SecondCommentCount: Integer;
    begin
        // [SCENARIO TP-013] Worksheet purchase creation transfers production comments with direct-path parity.
        Initialize();

        // [GIVEN] A released production order with two subcontracting comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 10000, 'Worksheet comment 1', 'Worksheet detail 1');
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 20000, 'Worksheet comment 2', 'Worksheet detail 2');
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] The user creates the subcontracting purchase order through the worksheet
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);

        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
#pragma warning restore AA0210
        PurchaseLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        PurchaseLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
#pragma warning disable AA0210
        PurchaseLine.SetRange("Work Center No.", ProdOrderRoutingLine."Work Center No.");
#pragma warning restore AA0210
        PurchaseLine.FindFirst();

        // [THEN] The worksheet path creates the same attached blank comment lines as the direct path
        AttachedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchaseLine.SetRange(Type, AttachedPurchaseLine.Type::" ");
        AttachedPurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(2, AttachedPurchaseLine.Count(), 'The worksheet path should create one attached blank Purchase Line per production comment.');

        if AttachedPurchaseLine.FindSet() then
            repeat
                if (AttachedPurchaseLine.Description = 'Worksheet comment 1') and
                   (AttachedPurchaseLine."Description 2" = 'Worksheet detail 1')
                then begin
                    FirstCommentCount += 1;
                    Assert.AreEqual(0, AttachedPurchaseLine.Quantity, 'An attached worksheet comment Purchase Line should have zero quantity.');
                end;
                if (AttachedPurchaseLine.Description = 'Worksheet comment 2') and
                   (AttachedPurchaseLine."Description 2" = 'Worksheet detail 2')
                then begin
                    SecondCommentCount += 1;
                    Assert.AreEqual(0, AttachedPurchaseLine.Quantity, 'An attached worksheet comment Purchase Line should have zero quantity.');
                end;
            until AttachedPurchaseLine.Next() = 0;
        Assert.AreEqual(1, FirstCommentCount, 'The first production comment should be copied by the worksheet path.');
        Assert.AreEqual(1, SecondCommentCount, 'The second production comment should be copied by the worksheet path.');
    end;

    [Test]
    procedure FamilySubcontractingPurchaseCreationTransfersCommentsAndAttachments()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        DocumentAttachment: Record "Document Attachment";
        Family: Record Family;
        FamilyLine: array[2] of Record "Family Line";
        GeneralPurchaseLine: Record "Purchase Line";
        Item: array[2] of Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ManufacturingSetup: Record "Manufacturing Setup";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ProdOrderLineFilter: Record "Prod. Order Line";
        ProdOrderRoutingLine: array[2] of Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        AttachmentBaseNames: array[2] of Text[250];
        CommentDescriptions: array[2] of Text[100];
        CommentDetails: array[2] of Text[50];
        ItemIndex: Integer;
        OriginalCreateProdOrderInfoLine: Boolean;
    begin
        // [SCENARIO TP-030] Family subcontracting purchase creation keeps shared operation comments and output attachments on each related Purchase Line.
        Initialize();

        ManufacturingSetup.Get();
        OriginalCreateProdOrderInfoLine := ManufacturingSetup."Create Prod. Order Info Line";

        // [GIVEN] A Family with two output items and one shared subcontracting routing operation
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        LibraryManufacturing.CreateFamily(Family);
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[1], Family."No.", Item[1]."No.", 1);
        LibraryManufacturing.CreateFamilyLine(FamilyLine[2], Family."No.", Item[2]."No.", 1);
        CreateFamilyRoutingWithSubcontractingWorkCenter(Family, WorkCenter[2]."No.");
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        // [GIVEN] A released Family production order with one production-order line per output item
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Family, Family."No.", 1, Location.Code);

        AttachmentBaseNames[1] := 'TP-030-family-output-1';
        AttachmentBaseNames[2] := 'TP-030-family-output-2';
        CommentDescriptions[1] := 'Family output 1 operation comment';
        CommentDescriptions[2] := 'Family output 2 operation comment';
        CommentDetails[1] := 'Family output 1 operation detail';
        CommentDetails[2] := 'Family output 2 operation detail';

        ProdOrderLineFilter.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLineFilter.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(2, ProdOrderLineFilter.Count(), 'The Family production order should contain exactly two output lines.');

        for ItemIndex := 1 to 2 do begin
            ProdOrderLine[ItemIndex].SetRange(Status, "Production Order Status"::Released);
            ProdOrderLine[ItemIndex].SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderLine[ItemIndex].SetRange("Item No.", Item[ItemIndex]."No.");
            ProdOrderLine[ItemIndex].FindFirst();

            ProdOrderRoutingLine[ItemIndex].SetRange(Status, "Production Order Status"::Released);
            ProdOrderRoutingLine[ItemIndex].SetRange("Prod. Order No.", ProductionOrder."No.");
            ProdOrderRoutingLine[ItemIndex].SetRange("Work Center No.", WorkCenter[2]."No.");
            Assert.AreEqual(1, ProdOrderRoutingLine[ItemIndex].Count(), 'The Family production order should contain one shared subcontracting operation.');
            ProdOrderRoutingLine[ItemIndex].FindFirst();

            LibraryMfgManagement.CreateProdOrderSubcComment(
                ProdOrderRoutingLine[ItemIndex], 10000 * ItemIndex,
                CommentDescriptions[ItemIndex], CommentDetails[ItemIndex]);
            CreateEligibleProdOrderLineAttachment(ProdOrderLine[ItemIndex], AttachmentBaseNames[ItemIndex]);
        end;

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        ManufacturingSetup.Get();
        ManufacturingSetup."Create Prod. Order Info Line" := true;
        ManufacturingSetup.Modify(true);

        // [WHEN] The subcontracting requisition worksheet is calculated and carried out
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);

        // [THEN] Each Family output creates exactly one related item Purchase Line
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(2, PurchaseLine.Count(), 'The Family purchase order should contain exactly one item line per output.');

        for ItemIndex := 1 to 2 do begin
            PurchaseLine.Reset();
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
            PurchaseLine.SetRange("No.", Item[ItemIndex]."No.");
            Assert.AreEqual(1, PurchaseLine.Count(), 'Each Family output should have exactly one related item Purchase Line.');
            PurchaseLine.FindFirst();
            Assert.AreEqual(
                ProdOrderLine[ItemIndex]."Line No.", PurchaseLine."Prod. Order Line No.",
                'The Purchase Line must retain its Family output production-order-line scope.');

            GeneralPurchaseLine.Reset();
            GeneralPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
            GeneralPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
            GeneralPurchaseLine.SetRange(Type, GeneralPurchaseLine.Type::" ");
            GeneralPurchaseLine.SetRange("Attached to Line No.", 0);
            GeneralPurchaseLine.SetFilter("Line No.", '<%1', PurchaseLine."Line No.");
            Assert.IsTrue(
                GeneralPurchaseLine.FindLast(),
                'Each Family output item line should have a standalone production-description line before it.');
            Assert.AreEqual(
                ProdOrderLine[ItemIndex].Description, GeneralPurchaseLine.Description,
                'The Family output description should be copied to the standalone line before its item line.');
            Assert.AreEqual(
                ProdOrderLine[ItemIndex]."Description 2", GeneralPurchaseLine."Description 2",
                'The Family output secondary description should be copied to the standalone line before its item line.');

            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
            DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
            DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
            Assert.AreEqual(1, DocumentAttachment.Count(), 'Each Family output Purchase Line should have exactly one attachment.');
            DocumentAttachment.SetRange("File Name", AttachmentBaseNames[ItemIndex]);
            Assert.AreEqual(1, DocumentAttachment.Count(), 'Each Purchase Line should receive its own output attachment.');
            DocumentAttachment.SetRange("File Name", AttachmentBaseNames[3 - ItemIndex]);
            Assert.AreEqual(0, DocumentAttachment.Count(), 'A Purchase Line must not receive the other Family output attachment.');

            AttachedPurchaseLine.Reset();
            AttachedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
            AttachedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
            AttachedPurchaseLine.SetRange(Type, AttachedPurchaseLine.Type::" ");
            AttachedPurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
            Assert.AreEqual(2, AttachedPurchaseLine.Count(), 'Each Family output should receive both shared operation comments.');
            AttachedPurchaseLine.SetRange(Description, CommentDescriptions[1]);
            AttachedPurchaseLine.SetRange("Description 2", CommentDetails[1]);
            Assert.AreEqual(1, AttachedPurchaseLine.Count(), 'The first shared operation comment should be copied to each related Purchase Line.');
            AttachedPurchaseLine.SetRange(Description, CommentDescriptions[2]);
            AttachedPurchaseLine.SetRange("Description 2", CommentDetails[2]);
            Assert.AreEqual(1, AttachedPurchaseLine.Count(), 'The second shared operation comment should be copied to each related Purchase Line.');

            // [THEN] The source comment and attachment remain on the Family output scope
            SubcProdRtngComment.Reset();
            SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine[ItemIndex].Status);
            SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine[ItemIndex]."Prod. Order No.");
            SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine[ItemIndex]."Routing Reference No.");
            SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine[ItemIndex]."Routing No.");
            SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine[ItemIndex]."Operation No.");
            Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The shared source operation should retain both dedicated comments.');
            SubcProdRtngComment.SetRange("Line No.", 10000);
            Assert.AreEqual(1, SubcProdRtngComment.Count(), 'The first shared source operation comment should remain unchanged.');
            SubcProdRtngComment.FindFirst();
            Assert.AreEqual(CommentDescriptions[1], SubcProdRtngComment.Description, 'The first shared source operation comment should remain unchanged.');
            Assert.AreEqual(CommentDetails[1], SubcProdRtngComment."Description 2", 'The first shared source operation comment detail should remain unchanged.');
            SubcProdRtngComment.SetRange("Line No.", 20000);
            Assert.AreEqual(1, SubcProdRtngComment.Count(), 'The second shared source operation comment should remain unchanged.');
            SubcProdRtngComment.FindFirst();
            Assert.AreEqual(CommentDescriptions[2], SubcProdRtngComment.Description, 'The second shared source operation comment should remain unchanged.');
            Assert.AreEqual(CommentDetails[2], SubcProdRtngComment."Description 2", 'The second shared source operation comment detail should remain unchanged.');

            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
            DocumentAttachment.SetRange("No.", ProductionOrder."No.");
            DocumentAttachment.SetRange("Line No.", ProdOrderLine[ItemIndex]."Line No.");
            DocumentAttachment.SetRange("File Name", AttachmentBaseNames[ItemIndex]);
            Assert.AreEqual(1, DocumentAttachment.Count(), 'The source output attachment should remain on its production-order line.');
        end;

        ManufacturingSetup.Get();
        ManufacturingSetup."Create Prod. Order Info Line" := OriginalCreateProdOrderInfoLine;
        ManufacturingSetup.Modify(true);
    end;

    [Test]
    [HandlerFunctions('RoutingHeaderAttachmentDetailsPageHandler')]
    procedure RoutingHeaderAttachmentPurchaseTrxIsAvailable()
    var
        DocumentAttachment: Record "Document Attachment";
        RoutingHeader: Record "Routing Header";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RoutingHeaderRecRef: RecordRef;
    begin
        // [SCENARIO TP-016] Routing Header attachments expose an editable Purchase Trx flag.
        Initialize();

        // [GIVEN] A Routing Header with a deterministic document attachment selected for Production Trx
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        RoutingHeaderRecRef.GetTable(RoutingHeader);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-016-routing-header.txt', true, false);
        DocumentAttachment.SetRange("Table ID", Database::"Routing Header");
        DocumentAttachment.SetRange("No.", RoutingHeader."No.");
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The Routing Header should have exactly one deterministic attachment.');
        DocumentAttachment.FindFirst();

        // [WHEN] The attachment details page is opened for the Routing Header and Purchase Trx is selected
        DocumentAttachmentDetails.OpenForRecRef(RoutingHeaderRecRef);
        DocumentAttachmentDetails.RunModal();

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Routing Header");
        DocumentAttachment.SetRange("No.", RoutingHeader."No.");
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The attachment should remain associated with the Routing Header.');
        DocumentAttachment.FindFirst();
        Assert.IsTrue(DocumentAttachment."Document Flow Production", 'The Production Trx selection should remain enabled.');
        Assert.IsTrue(DocumentAttachment."Document Flow Purchase", 'The Purchase Trx selection should be persisted.');
    end;

    [Test]
    procedure RoutingAttachmentFlowRequiresProductionAndPurchaseFlags()
    var
        DocumentAttachment: Record "Document Attachment";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeaderRecRef: RecordRef;
    begin
        // [SCENARIO TP-017] Routing attachments require both Production Trx and Purchase Trx flags to reach a Purchase Line.
        Initialize();

        // [GIVEN] A routing and subcontracting production setup with four flagged Routing Header attachments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeaderRecRef.GetTable(RoutingHeader);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-017-both.txt', true, true);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-017-production-only.txt', true, false);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-017-purchase-only.txt', false, true);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-017-neither.txt', false, false);

        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);
        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] The subcontracting purchase order is created from the production-order routing
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [THEN] Both flags reach the production-order line, while Production Trx only is retained there
        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
        Assert.AreEqual(2, DocumentAttachment.Count(), 'Only attachments selected for Production Trx should reach the production-order line.');
        DocumentAttachment.SetRange("File Name", 'TP-017-both');
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The attachment selected for both flows should reach the production-order line.');
        DocumentAttachment.SetRange("File Name", 'TP-017-production-only');
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The Production Trx-only attachment should reach the production-order line.');
        DocumentAttachment.SetRange("File Name", 'TP-017-purchase-only');
        Assert.AreEqual(0, DocumentAttachment.Count(), 'The Purchase Trx-only attachment must not reach the production-order line.');
        DocumentAttachment.SetRange("File Name", 'TP-017-neither');
        Assert.AreEqual(0, DocumentAttachment.Count(), 'The unselected attachment must not reach the production-order line.');

        // [THEN] Only the attachment selected for both flows reaches the Purchase Line, never the Purchase Header
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(1, DocumentAttachment.Count(), 'Only the attachment selected for both flows should reach the Purchase Line.');
        DocumentAttachment.SetRange("File Name", 'TP-017-both');
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The both-flags attachment should be copied to the Purchase Line.');
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
        DocumentAttachment.SetRange("Line No.", 0);
        Assert.AreEqual(0, DocumentAttachment.Count(), 'Routing attachments must not be copied to the Purchase Header.');
    end;

    [Test]
    procedure CombinedSubcontractingPurchaseOrderKeepsAttachmentsOnRelatedLines()
    var
        DocumentAttachment: Record "Document Attachment";
        Item: array[2] of Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: array[2] of Record "Prod. Order Line";
        ProductionOrder: array[2] of Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: array[2] of Record "Routing Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeaderRecRef: RecordRef;
        ExpectedAttachmentName: Text[250];
        PurchaseLineCount: Integer;
        AttachmentIndex: Integer;
    begin
        // [SCENARIO TP-018] A combined subcontracting purchase order keeps routing attachments on related lines.
        Initialize();

        // [GIVEN] Two items with separate routing attachments and the same subcontractor
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item[1], WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item[2], WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item[1], WorkCenter[2]."No.");
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLink(Item[2], WorkCenter[2]."No.");

        RoutingHeader[1].Get(Item[1]."Routing No.");
        RoutingHeaderRecRef.GetTable(RoutingHeader[1]);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-018-order-1.txt', true, true);
        RoutingHeader[2].Get(Item[2]."Routing No.");
        RoutingHeaderRecRef.GetTable(RoutingHeader[2]);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-018-order-2.txt', true, true);

        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder[1], "Production Order Status"::Released,
            ProductionOrder[1]."Source Type"::Item, Item[1]."No.", 10, Location.Code);
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder[2], "Production Order Status"::Released,
            ProductionOrder[2]."Source Type"::Item, Item[2]."No.", 10, Location.Code);

        for AttachmentIndex := 1 to 2 do begin
            ProdOrderLine[AttachmentIndex].SetRange(Status, "Production Order Status"::Released);
            ProdOrderLine[AttachmentIndex].SetRange("Prod. Order No.", ProductionOrder[AttachmentIndex]."No.");
            ProdOrderLine[AttachmentIndex].FindFirst();

            DocumentAttachment.Reset();
            DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
            DocumentAttachment.SetRange("No.", ProductionOrder[AttachmentIndex]."No.");
            DocumentAttachment.SetRange("Line No.", ProdOrderLine[AttachmentIndex]."Line No.");
            Assert.AreEqual(1, DocumentAttachment.Count(), 'Each production-order line should receive its routing attachment.');
        end;

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] The worksheet creates one purchase order for both production orders
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder[1]."No.", PurchaseHeader);

        // [THEN] Each related parent Purchase Line has only its own attachment
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        Assert.AreEqual(2, PurchaseLine.Count(), 'The combined purchase order should contain one parent line per production order.');

        if PurchaseLine.FindSet() then
            repeat
                if PurchaseLine."Prod. Order No." = ProductionOrder[1]."No." then
                    ExpectedAttachmentName := 'TP-018-order-1'
                else begin
                    Assert.AreEqual(ProductionOrder[2]."No.", PurchaseLine."Prod. Order No.", 'The combined order should contain only the two expected production orders.');
                    ExpectedAttachmentName := 'TP-018-order-2';
                end;

                DocumentAttachment.Reset();
                DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
                DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
                DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
                Assert.AreEqual(1, DocumentAttachment.Count(), 'Each related Purchase Line should receive exactly one attachment.');
                DocumentAttachment.FindFirst();
                Assert.AreEqual(ExpectedAttachmentName, DocumentAttachment."File Name", 'The Purchase Line should receive the attachment from its own production order.');
                PurchaseLineCount += 1;
            until PurchaseLine.Next() = 0;
        Assert.AreEqual(2, PurchaseLineCount, 'Both production orders should be represented by an attached Purchase Line.');

        // [THEN] No attachment is stored on the combined Purchase Header
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
        DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
        DocumentAttachment.SetRange("Line No.", 0);
        Assert.AreEqual(0, DocumentAttachment.Count(), 'Combined routing attachments must remain on Purchase Lines, not the Purchase Header.');
    end;

    [Test]
    procedure SameAttachmentCanFlowToMultipleSubcontractingPurchaseLines()
    var
        DocumentAttachment: Record "Document Attachment";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeaderRecRef: RecordRef;
        FirstPurchaseLineNo: Integer;
        PurchaseLineCount: Integer;
    begin
        // [SCENARIO TP-019] One source attachment is copied independently to multiple subcontracting lines.
        Initialize();

        // [GIVEN] One item with two subcontracting operations for the same vendor
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenterSameVendor(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.UpdateProdBomAndRoutingWithRoutingLinkForBothOperations(Item, WorkCenter);

        RoutingHeader.Get(Item."Routing No.");
        RoutingHeaderRecRef.GetTable(RoutingHeader);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-019-shared.txt', true, true);

        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);
        Vendor.Get(WorkCenter[1]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The production-order line should contain the one shared source attachment.');

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();

        // [WHEN] The worksheet creates subcontracting purchase lines for both operations
        SubcWarehouseLibrary.CreateSubcontractingOrdersViaWorksheet(ProductionOrder."No.", PurchaseHeader);

        // [THEN] Each operation receives its own copy with the same file identity
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        Assert.AreEqual(2, PurchaseLine.Count(), 'Both subcontracting operations should create a parent Purchase Line.');

        PurchaseLineCount := 0;
        if PurchaseLine.FindSet() then
            repeat
                if PurchaseLineCount = 0 then
                    FirstPurchaseLineNo := PurchaseLine."Line No."
                else
                    Assert.IsTrue(FirstPurchaseLineNo <> PurchaseLine."Line No.", 'Each operation must have a distinct Purchase Line scope.');

                DocumentAttachment.Reset();
                DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
                DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
                DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
                Assert.AreEqual(1, DocumentAttachment.Count(), 'Each subcontracting Purchase Line should receive one independent attachment copy.');
                DocumentAttachment.FindFirst();
                Assert.AreEqual('TP-019-shared', DocumentAttachment."File Name", 'Each target line should receive the shared source attachment.');
                PurchaseLineCount += 1;
            until PurchaseLine.Next() = 0;
        Assert.AreEqual(2, PurchaseLineCount, 'Two independently scoped Purchase Line copies should exist.');

        // [THEN] The shared attachment is not collapsed onto the Purchase Header
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
        DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
        DocumentAttachment.SetRange("Line No.", 0);
        Assert.AreEqual(0, DocumentAttachment.Count(), 'The shared attachment must not be deduplicated onto the Purchase Header.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderLineAttachmentDetailsPageHandler')]
    procedure ManuallyAddedProdOrderLineAttachmentDoesNotFlowToPurchaseLine()
    var
        DocumentAttachment: Record "Document Attachment";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        TempBlob: Codeunit "Temp Blob";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        ProdOrderLineRecRef: RecordRef;
        AttachmentOutStream: OutStream;
    begin
        // [SCENARIO TP-020] A manually added production-order-line attachment cannot be selected for Purchase Trx and does not flow to a Purchase Line.
        Initialize();

        // [GIVEN] A released subcontracting production order with a manually added attachment
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLineRecRef.GetTable(ProdOrderLine);
        TempBlob.CreateOutStream(AttachmentOutStream);
        AttachmentOutStream.WriteText('TP-020 manually added production line attachment');
        DocumentAttachment.SaveAttachment(ProdOrderLineRecRef, 'TP-020-manual.txt', TempBlob);

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The manually added attachment should remain on the production-order line.');

        // [WHEN] The attachment details page is opened and the related subcontracting purchase order is created
        DocumentAttachmentDetails.OpenForRecRef(ProdOrderLineRecRef);
        DocumentAttachmentDetails.RunModal();
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
#pragma warning disable AA0210
        DocumentAttachment.SetRange("File Name", 'TP-020-manual');
#pragma warning restore AA0210
        DocumentAttachment.FindFirst();
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Purchase Trx should remain disabled for a production-order-line attachment.');

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [THEN] The source remains and the manually added attachment does not flow to the Purchase Line
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
        DocumentAttachment.SetRange("File Name", 'TP-020-manual');
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The manual source attachment should remain available on the production-order line.');

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
        DocumentAttachment.SetRange("File Name", 'TP-020-manual');
        Assert.AreEqual(0, DocumentAttachment.Count(), 'A manually added production-order-line attachment must not flow to the Purchase Line.');
    end;

    [Test]
    [HandlerFunctions('ProdOrderLineExistingAttachmentDetailsPageHandler')]
    procedure ManuallyAddedProdOrderLineAttachmentDoesNotFlowToExistingPurchaseLine()
    var
        DocumentAttachment: Record "Document Attachment";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        TempBlob: Codeunit "Temp Blob";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        ProdOrderLineRecRef: RecordRef;
        AttachmentOutStream: OutStream;
        InitialPurchaseDocumentNo: Code[20];
        InitialPurchaseLineNo: Integer;
    begin
        // [SCENARIO TP-025] A manually added production-order-line attachment does not flow to an existing Purchase Line.
        Initialize();

        // [GIVEN] A released subcontracting production order with an existing purchase line
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        InitialPurchaseDocumentNo := PurchaseLine."Document No.";
        InitialPurchaseLineNo := PurchaseLine."Line No.";

        // [GIVEN] An attachment is added to the existing production-order line
        ProdOrderLineRecRef.GetTable(ProdOrderLine);
        TempBlob.CreateOutStream(AttachmentOutStream);
        AttachmentOutStream.WriteText('TP-025 attachment added after purchase creation');
        DocumentAttachment.SaveAttachment(ProdOrderLineRecRef, 'TP-025-existing.txt', TempBlob);

        DocumentAttachmentDetails.OpenForRecRef(ProdOrderLineRecRef);
        DocumentAttachmentDetails.RunModal();

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
#pragma warning disable AA0210
        DocumentAttachment.SetRange("File Name", 'TP-025-existing');
#pragma warning restore AA0210
        DocumentAttachment.FindFirst();
        Assert.IsFalse(DocumentAttachment."Document Flow Purchase", 'Purchase Trx should remain disabled for a production-order-line attachment.');

        // [WHEN] Subcontracting purchase creation updates the existing purchase line
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        // [THEN] The existing Purchase Line does not receive the attachment
        Assert.AreEqual(InitialPurchaseDocumentNo, PurchaseLine."Document No.", 'The existing purchase document should be reused.');
        Assert.AreEqual(InitialPurchaseLineNo, PurchaseLine."Line No.", 'The existing purchase line should be reused.');
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
#pragma warning disable AA0210
        DocumentAttachment.SetRange("File Name", 'TP-025-existing');
#pragma warning restore AA0210
        Assert.AreEqual(0, DocumentAttachment.Count(), 'A manually added production-order-line attachment must not flow to the existing Purchase Line.');
    end;

    [Test]
    [HandlerFunctions('PurchaseLineAttachmentDetailsPageHandler')]
    procedure CopiedPurchaseLineAttachmentCanBeRemovedBeforeSending()
    var
        DocumentAttachment: Record "Document Attachment";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        UnrelatedPurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RoutingHeaderRecRef: RecordRef;
        PurchaseLineRecRef: RecordRef;
    begin
        // [SCENARIO TP-021] A copied Purchase Line attachment can be removed without changing its source.
        Initialize();

        // [GIVEN] A subcontracting Purchase Line with one routing attachment copied from its production order
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeaderRecRef.GetTable(RoutingHeader);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-021-removable.txt', true, true);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] An unrelated Purchase Line on the same open document
        LibraryPurchase.CreatePurchaseLine(UnrelatedPurchaseLine, PurchaseHeader, UnrelatedPurchaseLine.Type::Item, Item."No.", 1);

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The copied attachment should exist before the user removes it.');
        PurchaseLineRecRef.GetTable(PurchaseLine);

        // [WHEN] The user deletes the copied attachment from the Purchase Line details page
        DocumentAttachmentDetails.OpenForRecRef(PurchaseLineRecRef);
        DocumentAttachmentDetails.RunModal();

        // [THEN] The target copy is removed while the source and unrelated scopes remain unchanged
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(0, DocumentAttachment.Count(), 'The copied Purchase Line attachment should be removable before sending.');

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
        Assert.AreEqual(1, DocumentAttachment.Count(), 'Removing the Purchase Line copy must not remove the production source attachment.');

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
        DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
        DocumentAttachment.SetRange("Line No.", 0);
        Assert.AreEqual(0, DocumentAttachment.Count(), 'Removing a line attachment must not create a Purchase Header attachment.');

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", UnrelatedPurchaseLine."Document No.");
        DocumentAttachment.SetRange("Line No.", UnrelatedPurchaseLine."Line No.");
        Assert.AreEqual(0, DocumentAttachment.Count(), 'The unrelated Purchase Line must remain unchanged.');
    end;

    [Test]
    procedure SubcontractingPurchasePostingWithLineAttachmentSucceeds()
    var
        DocumentAttachment: Record "Document Attachment";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        RoutingHeaderRecRef: RecordRef;
        PurchaseDocumentNo: Code[20];
        TotalAmount: Decimal;
        TotalQuantity: Decimal;
    begin
        // [SCENARIO TP-022] A line-scoped subcontracting attachment does not break standard purchase posting.
        Initialize();

        // [GIVEN] A subcontracting purchase order with a selected line attachment
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        RoutingHeader.Get(Item."Routing No.");
        Item.Validate("Flushing Method", Item."Flushing Method"::"Pick + Manual");
        Item.Modify(true);
        RoutingHeaderRecRef.GetTable(RoutingHeader);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-022-posting.txt', true, true);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderLine.SetRange(Status, "Production Order Status"::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();

        DocumentAttachment.SetRange("Table ID", Database::"Prod. Order Line");
        DocumentAttachment.SetRange("No.", ProductionOrder."No.");
        DocumentAttachment.SetRange("Line No.", ProdOrderLine."Line No.");
        DocumentAttachment.SetRange("File Name", 'TP-022-posting');
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The selected attachment should be copied to the production-order line before purchase creation.');

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        PurchaseDocumentNo := PurchaseHeader."No.";

        PurchaseLine.Reset();
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseLine.FindSet() then
            repeat
                if PurchaseLine.Quantity = 0 then
                    PurchaseLine.Validate(Quantity, 1);
                if PurchaseLine."Direct Unit Cost" = 0 then
                    PurchaseLine.Validate("Direct Unit Cost", 1);
                PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity);
                PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity);
                PurchaseLine.Modify(true);
                EnsureGeneralPostingSetupIsValid(
                    GeneralPostingSetup, PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
                TotalQuantity += PurchaseLine.Quantity;
                TotalAmount += PurchaseLine."Line Amount";
            until PurchaseLine.Next() = 0;
        Assert.IsTrue(TotalQuantity > 0, 'The posting fixture should contain a positive item quantity.');
        Assert.IsTrue(TotalAmount > 0, 'The posting fixture should contain a positive item amount.');

        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseHeader."No.");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
        DocumentAttachment.SetRange("File Name", 'TP-022-posting');
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The selected attachment should be stored on the subcontracting Purchase Line before posting.');

        // [WHEN] The purchase order is received and invoiced by the standard posting library
        PurchaseHeader.Validate("Vendor Invoice No.", 'TP-022-INV');
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Posting succeeds without moving the line attachment to the original Purchase Header
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"Purchase Header");
        DocumentAttachment.SetRange("No.", PurchaseDocumentNo);
        DocumentAttachment.SetRange("Line No.", 0);
        Assert.AreEqual(0, DocumentAttachment.Count(), 'Posting must not create a subcontracting attachment on the Purchase Header.');
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderReportRequestPageHandler')]
    procedure StandardPurchaseOrderOutputIncludesDescriptionForAttachedCommentLine()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        XmlParameters: Text;
    begin
        // [SCENARIO TP-023] Standard purchase output includes Description for an attached blank line.
        Initialize();

        // [GIVEN] A purchase order with an attached blank Purchase Line containing both descriptions
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        AttachedPurchaseLine.Init();
        AttachedPurchaseLine."Document Type" := PurchaseHeader."Document Type";
        AttachedPurchaseLine."Document No." := PurchaseHeader."No.";
        AttachedPurchaseLine."Line No." := PurchaseLine."Line No." + 10000;
        AttachedPurchaseLine.Type := AttachedPurchaseLine.Type::" ";
        AttachedPurchaseLine."Attached to Line No." := PurchaseLine."Line No.";
        AttachedPurchaseLine.Description := 'TP-023 report Description';
        AttachedPurchaseLine."Description 2" := 'TP-023 report Description 2';
        AttachedPurchaseLine.Insert();

        // [WHEN] The standard Purchase Order report dataset is generated
        PurchaseHeader.SetRecFilter();
        Commit();
        XmlParameters := Report.RunRequestPage(Report::"Standard Purchase - Order");
        LibraryReportDataset.RunReportAndLoad(Report::"Standard Purchase - Order", PurchaseHeader, XmlParameters);

        // [THEN] Description is present in the standard dataset; Description 2 remains outside this boundary
        LibraryReportDataset.AssertElementWithValueExists('Desc_PurchLine', AttachedPurchaseLine.Description);
    end;

    [Test]
    procedure ExistingRoutingCommentsAreNotConvertedToSubcontractingComments()
    var
        AttachedPurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";
        ProductionOrder: Record "Production Order";
        PurchaseLine: Record "Purchase Line";
        RoutingCommentLine: Record "Routing Comment Line";
        RoutingLine: Record "Routing Line";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-024] Existing ordinary routing comments remain separate from dedicated subcontracting comments.
        Initialize();

        // [GIVEN] A certified routing with an ordinary comment on a subcontracting operation
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();

        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        RoutingLine.FindFirst();
        RoutingCommentLine."Routing No." := RoutingLine."Routing No.";
        RoutingCommentLine."Version Code" := RoutingLine."Version Code";
        RoutingCommentLine."Operation No." := RoutingLine."Operation No.";
        RoutingCommentLine."Line No." := 10000;
        RoutingCommentLine.Validate(Comment, 'Ordinary routing comment');
        RoutingCommentLine.Insert();

        // [WHEN] The production order and its subcontracting purchase order are created
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Operation No.", RoutingLine."Operation No.");
        ProdOrderRoutingLine.FindFirst();
        LibraryMfgManagement.CreateProdOrderSubcComment(ProdOrderRoutingLine, 20000, 'Dedicated purchase comment', 'Dedicated purchase detail');

        // [THEN] The ordinary comment remains standard data and is not converted into the new flow
        ProdOrderRtngCommentLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderRtngCommentLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRtngCommentLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRtngCommentLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderRtngCommentLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(1, ProdOrderRtngCommentLine.Count(), 'The ordinary routing comment should remain an ordinary production-order routing comment.');

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);

        AttachedPurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        AttachedPurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        AttachedPurchaseLine.SetRange(Type, AttachedPurchaseLine.Type::" ");
        AttachedPurchaseLine.SetRange("Attached to Line No.", PurchaseLine."Line No.");
        Assert.AreEqual(1, AttachedPurchaseLine.Count(), 'Only the explicitly added dedicated comment should create an attached Purchase Line.');
        AttachedPurchaseLine.FindFirst();
        Assert.AreEqual('Dedicated purchase comment', AttachedPurchaseLine.Description, 'An ordinary routing comment must not be converted into a purchase comment line.');
        Assert.AreEqual('Dedicated purchase detail', AttachedPurchaseLine."Description 2", 'The dedicated purchase comment detail should remain available.');
    end;

    [Test]
    [HandlerFunctions('SelectSendingOptionsOKModalPageHandler,EmailEditorCheckAndDiscardModalPageHandler,ConfirmHandlerFalse,KeepDraftOrDiscardStrMenuHandler')]
    procedure PurchaseLineAttachmentIsNotAutomaticallyAddedToVendorEmail()
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentSendingProfile: Record "Document Sending Profile";
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RoutingHeader: Record "Routing Header";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
        ConnectorMock: Codeunit "Connector Mock";
        DocumentMailingTests: Codeunit "Subc. Comments Attachment Test";
        LibraryEmail: Codeunit "Library - Email";
        RoutingHeaderRecRef: RecordRef;
    begin
        // [SCENARIO TP-026] A copied Purchase Line attachment is not automatically included in vendor email.
        Initialize();

        // [GIVEN] A subcontracting Purchase Line with a copied line-scoped attachment
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        RoutingHeader.Get(Item."Routing No.");
        RoutingHeaderRecRef.GetTable(RoutingHeader);
        CreateRoutingHeaderAttachment(RoutingHeaderRecRef, 'TP-026-line.txt', true, true);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor."E-Mail" := 'tp026@example.com';
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        SubcWarehouseLibrary.UpdateSubMgmtSetupWithReqWkshTemplate();
        SubcWarehouseLibrary.CreateSubcontractingOrderFromProdOrderRouting(Item."Routing No.", WorkCenter[2]."No.", PurchaseLine);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        DocumentAttachment.SetRange("Table ID", Database::"Purchase Line");
        DocumentAttachment.SetRange("No.", PurchaseLine."Document No.");
        DocumentAttachment.SetRange("Line No.", PurchaseLine."Line No.");
        DocumentAttachment.SetRange("File Name", 'TP-026-line');
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The copied line attachment should exist before the vendor send action.');

        // [GIVEN] Standard email sending is configured with a failing connector so no message is sent
        CreateEmailSendingProfile(DocumentSendingProfile);
        Vendor.Validate("Document Sending Profile", DocumentSendingProfile.Code);
        Vendor.Modify(true);
        LibraryEmail.SetUpEmailAccount();
        ConnectorMock.FailOnSend(true);

        // [WHEN] The standard Purchase Order send action is invoked
        DocumentMailingTests.ResetEmailSendObservation();
        BindSubscription(DocumentMailingTests);
        PurchaseHeader.SetRecFilter();
        PurchaseHeader.SendRecords();
        UnbindSubscription(DocumentMailingTests);

        // [THEN] The standard email payload was inspected and did not include the copied line attachment
        Assert.IsTrue(DocumentMailingTests.IsEmailSendObserved(), 'The standard Purchase Order send should create an email payload for inspection.');
    end;

    [Test]
    procedure ClearingProdOrderStandardTaskCodeLeavesRelationsAsStandard()
    var
        Item: Record Item;
        Location: Record Location;
        MachineCenter: array[2] of Record "Machine Center";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProductionOrder: Record "Production Order";
        StandardTask: Record "Standard Task";
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
        Vendor: Record Vendor;
        WorkCenter: array[2] of Record "Work Center";
    begin
        // [SCENARIO TP-027] Clearing Standard Task Code leaves existing production subcontracting comments unchanged.
        Initialize();

        // [GIVEN] A released production-order operation with copied Standard Task comments
        SubcWarehouseLibrary.CreateAndCalculateNeededWorkAndMachineCenter(WorkCenter, MachineCenter, true);
        SubcWarehouseLibrary.CreateItemForProductionIncludeRoutingAndProdBOM(Item, WorkCenter, MachineCenter);
        SubcWarehouseLibrary.CreateLocationWithWarehouseHandling(Location);

        Vendor.Get(WorkCenter[2]."Subcontractor No.");
        Vendor."Subc. Location Code" := Location.Code;
        Vendor."Location Code" := Location.Code;
        Vendor.Modify();
        SubcWarehouseLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released,
            ProductionOrder."Source Type"::Item, Item."No.", 10, Location.Code);

        LibraryManufacturing.CreateStandardTask(StandardTask);
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 10000, 'Cleared code comment 1', 'Cleared code detail 1');
        LibraryMfgManagement.CreateStandardTaskComment(StandardTask.Code, 20000, 'Cleared code comment 2', 'Cleared code detail 2');

        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", WorkCenter[2]."No.");
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.Validate("Standard Task Code", StandardTask.Code);
        ProdOrderRoutingLine.Modify(true);

        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The operation should contain the copied Standard Task comments before clearing the code.');

        // [WHEN] Standard Task Code is cleared on the existing production-order operation
        ProdOrderRoutingLine.Validate("Standard Task Code", '');
        ProdOrderRoutingLine.Modify(true);

        // [THEN] The code is blank but the existing dedicated relation rows remain unchanged
        Assert.AreEqual('', ProdOrderRoutingLine."Standard Task Code", 'The Standard Task Code should be cleared.');
        SubcProdRtngComment.Reset();
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'Clearing Standard Task Code must not rebuild or remove existing subcontracting comments.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Cleared code comment 1', SubcProdRtngComment.Description, 'The first existing comment should remain after clearing the code.');
        Assert.AreEqual('Cleared code detail 1', SubcProdRtngComment."Description 2", 'The first existing comment detail should remain after clearing the code.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000);
        Assert.AreEqual('Cleared code comment 2', SubcProdRtngComment.Description, 'The second existing comment should remain after clearing the code.');
        Assert.AreEqual('Cleared code detail 2', SubcProdRtngComment."Description 2", 'The second existing comment detail should remain after clearing the code.');
    end;

    [ModalPageHandler]
    procedure SelectSendingOptionsOKModalPageHandler(var SelectSendingOptions: TestPage "Select Sending Options")
    begin
        SelectSendingOptions.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure EmailEditorCheckAndDiscardModalPageHandler(var EmailEditor: TestPage "Email Editor")
    begin
        EmailEditor.Discard.Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerFalse(Question: Text; var Reply: Boolean)
    var
        GoAheadLbl: Label 'Go ahead and discard?';
    begin
        if Question = GoAheadLbl then
            Reply := false;
    end;

    [StrMenuHandler]
    procedure KeepDraftOrDiscardStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    var
        DiscardLbl: Label 'Discard email';
    begin
        if StrPos(Options, DiscardLbl) <> 0 then
            Choice := 2;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Document-Mailing", 'OnBeforeSendEmail', '', false, false)]
    local procedure OnBeforeSendEmail(var TempEmailItem: Record "Email Item" temporary; IsFromPostedDoc: Boolean; PostedDocNo: Code[20]; HideDialog: Boolean; ReportUsage: Integer)
    var
        Attachments: Codeunit "Temp Blob List";
        AttachmentNames: List of [Text];
        AttachmentIndex: Integer;
    begin
        TempEmailItem.GetAttachments(Attachments, AttachmentNames);
        for AttachmentIndex := 1 to AttachmentNames.Count() do
            Assert.IsTrue(
                StrPos(AttachmentNames.Get(AttachmentIndex), 'TP-026-line') = 0,
                'A Purchase Line document attachment must not be added to the vendor email payload.');
        EmailSendObserved := true;
    end;

    procedure ResetEmailSendObservation()
    begin
        EmailSendObserved := false;
    end;

    procedure IsEmailSendObserved(): Boolean
    begin
        exit(EmailSendObserved);
    end;

    [RequestPageHandler]
    procedure StandardPurchaseOrderReportRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
    end;

    [ModalPageHandler]
    procedure RoutingHeaderAttachmentDetailsPageHandler(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        // [THEN] Purchase Trx is visible and editable for the Routing Header attachment
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Routing Header attachments should show the Purchase Trx control.');
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Editable(), 'Routing Header Purchase Trx should be editable.');
        DocumentAttachmentDetails."Document Flow Purchase".SetValue(true);
        DocumentAttachmentDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ProdOrderLineAttachmentDetailsPageHandler(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        // [THEN] Purchase Trx is visible but read-only for a manually added production-order-line attachment
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Production-order-line attachments should show the Purchase Trx control.');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Editable(), 'Production-order-line Purchase Trx should be read-only.');
        Assert.AreEqual('TP-020-manual', DocumentAttachmentDetails.Name.Value(), 'The attachment details page should show the TP-020 attachment.');
        DocumentAttachmentDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ProdOrderLineExistingAttachmentDetailsPageHandler(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        // [THEN] Purchase Trx is visible but read-only for an attachment added after purchase creation
        Assert.IsTrue(DocumentAttachmentDetails."Document Flow Purchase".Visible(), 'Production-order-line attachments should show the Purchase Trx control.');
        Assert.IsFalse(DocumentAttachmentDetails."Document Flow Purchase".Editable(), 'Production-order-line Purchase Trx should be read-only.');
        Assert.AreEqual('TP-025-existing', DocumentAttachmentDetails.Name.Value(), 'The attachment details page should show the TP-025 attachment.');
        DocumentAttachmentDetails.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PurchaseLineAttachmentDetailsPageHandler(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        Assert.AreEqual('TP-021-removable', DocumentAttachmentDetails.Name.Value(), 'The Purchase Line details page should show the copied attachment.');
        DocumentAttachmentDetails.DeleteAttachmentForTest.Invoke();
        DocumentAttachmentDetails.OK().Invoke();
    end;

    local procedure CreateRoutingHeaderAttachment(RoutingHeaderRecRef: RecordRef; FileName: Text[250]; FlowProduction: Boolean; FlowPurchase: Boolean)
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        AttachmentOutStream: OutStream;
    begin
        TempBlob.CreateOutStream(AttachmentOutStream);
        AttachmentOutStream.WriteText(FileName);
        DocumentAttachment.SaveAttachment(RoutingHeaderRecRef, FileName, TempBlob);
        DocumentAttachment.Validate("Document Flow Production", FlowProduction);
        DocumentAttachment.Validate("Document Flow Purchase", FlowPurchase);
        DocumentAttachment.Modify(true);
    end;

    local procedure CreateEligibleProdOrderLineAttachment(ProdOrderLine: Record "Prod. Order Line"; FileName: Text[250])
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        ProdOrderLineRecRef: RecordRef;
        AttachmentOutStream: OutStream;
    begin
        ProdOrderLineRecRef.GetTable(ProdOrderLine);
        TempBlob.CreateOutStream(AttachmentOutStream);
        AttachmentOutStream.WriteText(FileName);
        DocumentAttachment.SaveAttachment(ProdOrderLineRecRef, FileName + '.txt', TempBlob);
        DocumentAttachment.Validate("Document Flow Production", true);
        DocumentAttachment.Validate("Document Flow Purchase", true);
        DocumentAttachment.Modify(true);
    end;

    local procedure CreateFamilyRoutingWithSubcontractingWorkCenter(var Family: Record Family; WorkCenterNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        Family.Validate("Routing No.", RoutingHeader."No.");
        Family.Modify(true);
    end;

    local procedure EnsureGeneralPostingSetupIsValid(var GeneralPostingSetup: Record "General Posting Setup"; GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20])
    begin
        if GeneralPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup) then begin
            if GeneralPostingSetup.Blocked then begin
                GeneralPostingSetup.Blocked := false;
                GeneralPostingSetup.Modify();
            end;
            EnsureGeneralPostingSetupAccounts(GeneralPostingSetup);
            exit;
        end;

        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusPostingGroup, GenProdPostingGroup);
        EnsureGeneralPostingSetupAccounts(GeneralPostingSetup);
    end;

    local procedure EnsureGeneralPostingSetupAccounts(var GeneralPostingSetup: Record "General Posting Setup")
    begin
        if GeneralPostingSetup."Purch. Account" = '' then
            GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Purch. Credit Memo Account" = '' then
            GeneralPostingSetup.Validate("Purch. Credit Memo Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Sales Account" = '' then
            GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Sales Credit Memo Account" = '' then
            GeneralPostingSetup.Validate("Sales Credit Memo Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."COGS Account" = '' then
            GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Inventory Adjmt. Account" = '' then
            GeneralPostingSetup.Validate("Inventory Adjmt. Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Direct Cost Applied Account" = '' then
            GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Overhead Applied Account" = '' then
            GeneralPostingSetup.Validate("Overhead Applied Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Purchase Variance Account" = '' then
            GeneralPostingSetup.Validate("Purchase Variance Account", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."COGS Account (Interim)" = '' then
            GeneralPostingSetup.Validate("COGS Account (Interim)", LibraryERM.CreateGLAccountNo());
        if GeneralPostingSetup."Invt. Accrual Acc. (Interim)" = '' then
            GeneralPostingSetup.Validate("Invt. Accrual Acc. (Interim)", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateEmailSendingProfile(var DocumentSendingProfile: Record "Document Sending Profile")
    begin
        DocumentSendingProfile.Init();
        DocumentSendingProfile.Code := LibraryUtility.GenerateGUID();
        DocumentSendingProfile.Description := 'TP-026 email profile';
        DocumentSendingProfile."E-Mail" := DocumentSendingProfile."E-Mail"::"Yes (Prompt for Settings)";
        DocumentSendingProfile."E-Mail Attachment" := DocumentSendingProfile."E-Mail Attachment"::PDF;
        DocumentSendingProfile.Printer := DocumentSendingProfile.Printer::No;
        DocumentSendingProfile.Disk := DocumentSendingProfile.Disk::No;
        DocumentSendingProfile."Electronic Document" := DocumentSendingProfile."Electronic Document"::No;
        DocumentSendingProfile.Insert();
    end;

    local procedure AssertProdOrderCommentsMatchStandardTask(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        SubcProdRtngComment: Record "Subc. Prod. Rtng. Comment";
    begin
        SubcProdRtngComment.SetRange(Status, ProdOrderRoutingLine.Status);
        SubcProdRtngComment.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        SubcProdRtngComment.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        SubcProdRtngComment.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        SubcProdRtngComment.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        Assert.AreEqual(2, SubcProdRtngComment.Count(), 'The production-order routing operation should contain exactly two selected Standard Task comments.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 10000);
        Assert.AreEqual('Current production comment 1', SubcProdRtngComment.Description, 'The first Standard Task comment should replace the stale production comment.');
        Assert.AreEqual('Current production detail 1', SubcProdRtngComment."Description 2", 'The first Standard Task detail should be transferred to the production order.');

        SubcProdRtngComment.Get(
            ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.", ProdOrderRoutingLine."Operation No.", 20000);
        Assert.AreEqual('Current production comment 2', SubcProdRtngComment.Description, 'The second Standard Task comment should be transferred to the production order.');
        Assert.AreEqual('Current production detail 2', SubcProdRtngComment."Description 2", 'The second Standard Task detail should be transferred to the production order.');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Comments Attachment Test");
        LibrarySetupStorage.Restore();
        LibraryPurchase.SetOrderNoSeriesInSetup();

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Comments Attachment Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Comments Attachment Test");
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SubcWarehouseLibrary: Codeunit "Subc. Warehouse Library";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        EmailSendObserved: Boolean;
}