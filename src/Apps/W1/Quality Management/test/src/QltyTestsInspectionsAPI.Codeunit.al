// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.QualityManagement.API;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using System.TestLibraries.Utilities;

codeunit 139972 "Qlty. Tests - Inspections API"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = Uncategorized;

    trigger OnRun()
    begin
        // [FEATURE] [Quality Management] [API]
    end;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        IsInitialized: Boolean;
        InspectionsServiceNameTxt: Label 'qualityInspections', Locked = true;
        CreateInspectionsServiceNameTxt: Label 'createQualityInspections', Locked = true;
        ActionFinishInspectionTxt: Label 'Microsoft.NAV.FinishInspection', Locked = true;
        ActionReopenInspectionTxt: Label 'Microsoft.NAV.ReopenInspection', Locked = true;
        ActionCreateReinspectionTxt: Label 'Microsoft.NAV.CreateReinspection', Locked = true;
        ActionSetTestValueTxt: Label 'Microsoft.NAV.SetTestValue', Locked = true;
        ActionAssignToTxt: Label 'Microsoft.NAV.AssignTo', Locked = true;
        ActionCreateFromRecordIDTxt: Label 'Microsoft.NAV.CreateInspectionFromRecordID', Locked = true;
        ActionCreateFromTableFilterTxt: Label 'Microsoft.NAV.CreateInspectionFromTableIDAndFilter', Locked = true;
        EmptyResponseErr: Label 'Response should not be empty.';

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    // region Qlty. Inspections API (page 20414) - GET Tests

    [Test]
    procedure GetInspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Retrieve a single quality inspection via GET request
        Initialize();

        // [GIVEN] A quality inspection exists
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();

        // [WHEN] A GET request is made for the specific inspection
        TargetURL := LibraryGraphMgt.CreateTargetURL(QltyInspectionHeader.SystemId, Page::"Qlty. Inspections API", InspectionsServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response contains the inspection information
        LibraryAssert.AreNotEqual('', ResponseText, EmptyResponseErr);
        LibraryGraphMgt.VerifyIDInJson(ResponseText);
    end;

    [Test]
    procedure GetInspectionVerifiesKeyFields()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Verify key fields (No., Template Code) are returned correctly via GET
        Initialize();

        // [GIVEN] A quality inspection exists with a known template code
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();

        // [WHEN] A GET request is made for the inspection
        TargetURL := LibraryGraphMgt.CreateTargetURL(QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response contains the correct No. and template code
        LibraryAssert.AreNotEqual('', ResponseText, EmptyResponseErr);
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseText, 'qltyTestNo', QltyInspectionHeader."No.");
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseText, 'qltyTemplate', QltyInspectionHeader."Template Code");
    end;

    [Test]
    procedure GetInspectionVerifiesSourceFields()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Verify source fields are returned correctly via GET
        Initialize();

        // [GIVEN] A quality inspection exists with source information
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();

        // [WHEN] A GET request is made for the inspection
        TargetURL := LibraryGraphMgt.CreateTargetURL(QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response contains source information fields
        LibraryAssert.AreNotEqual('', ResponseText, EmptyResponseErr);
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseText, 'qltySourceDocumentNo', QltyInspectionHeader."Source Document No.");
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseText, 'qltySourceItemNo', QltyInspectionHeader."Source Item No.");
    end;

    [Test]
    procedure GetInspectionVerifiesStatusField()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Verify the inspection status field is returned correctly via GET
        Initialize();

        // [GIVEN] A new quality inspection exists with Open status
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();

        // [WHEN] A GET request is made for the inspection
        TargetURL := LibraryGraphMgt.CreateTargetURL(QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response contains the status field showing Open
        LibraryAssert.AreNotEqual('', ResponseText, EmptyResponseErr);
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseText, 'qltyInspectionStatus', Format(QltyInspectionHeader.Status::Open));
    end;

    [Test]
    procedure GetMultipleInspections()
    var
        QltyInspectionHeader1: Record "Qlty. Inspection Header";
        QltyInspectionHeader2: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr1: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateHdr2: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Retrieve multiple quality inspections via GET collection request
        Initialize();

        // [GIVEN] Two quality inspections exist
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader1, QltyInspectionTemplateHdr1);
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader2, QltyInspectionTemplateHdr2);
        Commit();

        // [WHEN] A GET request is made for the inspections collection
        TargetURL := LibraryGraphMgt.CreateTargetURL('', PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response contains inspection data
        LibraryAssert.AreNotEqual('', ResponseText, EmptyResponseErr);
    end;

    // endregion

    // region Qlty. Inspections API (page 20414) - Action Tests

    [Test]
    procedure FinishInspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Finish a quality inspection via the FinishInspection API action
        Initialize();

        // [GIVEN] An open quality inspection exists
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();

        // [WHEN] The FinishInspection action is called
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionFinishInspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [THEN] The inspection status is updated to Finished
        QltyInspectionHeader.Get(QltyInspectionHeader."No.");
        LibraryAssert.AreEqual(
            QltyInspectionHeader.Status::Finished, QltyInspectionHeader.Status,
            'Inspection should be finished.');
    end;

    [Test]
    procedure FinishInspectionSetsFinishedDate()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Finishing an inspection sets the Finished Date
        Initialize();

        // [GIVEN] An open quality inspection exists with no finished date
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        LibraryAssert.AreEqual(0D, QltyInspectionHeader."Finished Date", 'Finished date should initially be blank.');
        Commit();

        // [WHEN] The FinishInspection action is called
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionFinishInspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [THEN] The finished date is set to today
        QltyInspectionHeader.Get(QltyInspectionHeader."No.");
        LibraryAssert.AreEqual(Today(), QltyInspectionHeader."Finished Date", 'Finished date should be set to today.');
    end;

    [Test]
    procedure ReopenFinishedInspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Reopen a finished quality inspection via the ReopenInspection API action
        Initialize();

        // [GIVEN] A finished quality inspection exists
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionFinishInspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [WHEN] The ReopenInspection action is called
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionReopenInspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [THEN] The inspection status is updated back to Open
        QltyInspectionHeader.Get(QltyInspectionHeader."No.");
        LibraryAssert.AreEqual(
            QltyInspectionHeader.Status::Open, QltyInspectionHeader.Status,
            'Inspection should be reopened.');
    end;

    [Test]
    procedure CreateReinspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        AllInspections: Record "Qlty. Inspection Header";
        ResponseText: Text;
        TargetURL: Text;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a reinspection from a finished inspection via CreateReinspection API action
        Initialize();

        // [GIVEN] A finished quality inspection exists
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionFinishInspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        AllInspections.Reset();
        BeforeCount := AllInspections.Count();

        // [WHEN] The CreateReinspection action is called
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionCreateReinspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [THEN] A new inspection record is created
        AllInspections.Reset();
        AfterCount := AllInspections.Count();
        LibraryAssert.AreEqual(BeforeCount + 1, AfterCount, 'A reinspection should have been created.');
    end;

    [Test]
    procedure SetTestValue()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ActionBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        TestCodeToSet: Code[20];
        TestValueToSet: Text[250];
    begin
        // [SCENARIO] Set a test value on an inspection line via the SetTestValue API action
        Initialize();

        // [GIVEN] An open quality inspection exists with test lines
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);

        // [GIVEN] A test code from the first inspection line
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        QltyInspectionLine.FindFirst();
        TestCodeToSet := QltyInspectionLine."Test Code";
        TestValueToSet := 'API_TEST_VALUE';
        Commit();

        // [WHEN] The SetTestValue action is called with the test code and a value
        ActionBody := LibraryGraphMgt.AddPropertytoJSON('', 'testCode', TestCodeToSet);
        ActionBody := LibraryGraphMgt.AddPropertytoJSON(ActionBody, 'testValue', TestValueToSet);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionSetTestValueTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, ActionBody, ResponseText, 204);

        // [THEN] The inspection line test value is updated
        QltyInspectionLine.Get(QltyInspectionLine."Inspection No.", QltyInspectionLine."Re-inspection No.", QltyInspectionLine."Line No.");
        LibraryAssert.AreEqual(TestValueToSet, QltyInspectionLine."Test Value", 'Test value should be updated.');
    end;

    [Test]
    procedure AssignToUser()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ActionBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        AssignedUser: Text;
    begin
        // [SCENARIO] Assign a quality inspection to a user via the AssignTo API action
        Initialize();

        // [GIVEN] An open quality inspection exists
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        AssignedUser := CopyStr(UserId(), 1, 50);
        Commit();

        // [WHEN] The AssignTo action is called with a user ID
        ActionBody := LibraryGraphMgt.AddPropertytoJSON('', 'assignToUser', AssignedUser);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionAssignToTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, ActionBody, ResponseText, 204);

        // [THEN] The inspection is assigned to the specified user
        QltyInspectionHeader.Get(QltyInspectionHeader."No.");
        LibraryAssert.AreEqual(
            CopyStr(AssignedUser, 1, MaxStrLen(QltyInspectionHeader."Assigned User ID")),
            QltyInspectionHeader."Assigned User ID",
            'Inspection should be assigned to the specified user.');
    end;

    [Test]
    procedure SetTestValueAndFinishInspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        ActionBody: Text;
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Set test values on all lines and then finish the inspection via API
        Initialize();

        // [GIVEN] An open quality inspection exists with test lines
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();

        // [GIVEN] All test values are set via the API
        QltyInspectionLine.SetRange("Inspection No.", QltyInspectionHeader."No.");
        if QltyInspectionLine.FindSet() then
            repeat
                ActionBody := LibraryGraphMgt.AddPropertytoJSON('', 'testCode', QltyInspectionLine."Test Code");
                ActionBody := LibraryGraphMgt.AddPropertytoJSON(ActionBody, 'testValue', 'PASS_VALUE');
                TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
                    QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionSetTestValueTxt);
                LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, ActionBody, ResponseText, 204);
            until QltyInspectionLine.Next() = 0;

        // [WHEN] The FinishInspection action is called
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionFinishInspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [THEN] The inspection is finished
        QltyInspectionHeader.Get(QltyInspectionHeader."No.");
        LibraryAssert.AreEqual(
            QltyInspectionHeader.Status::Finished, QltyInspectionHeader.Status,
            'Inspection should be finished after setting all test values.');
    end;

    [Test]
    procedure GetInspectionAfterFinish()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ResponseText: Text;
        TargetURL: Text;
    begin
        // [SCENARIO] Verify finished inspection fields are correct when retrieved via GET
        Initialize();

        // [GIVEN] A finished quality inspection exists
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
        Commit();
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt, ActionFinishInspectionTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, '', ResponseText, 204);

        // [WHEN] A GET request is made for the finished inspection
        TargetURL := LibraryGraphMgt.CreateTargetURL(QltyInspectionHeader.SystemId, PAGE::"Qlty. Inspections API", InspectionsServiceNameTxt);
        LibraryGraphMgt.GetFromWebService(ResponseText, TargetURL);

        // [THEN] The response shows the Finished status
        LibraryAssert.AreNotEqual('', ResponseText, EmptyResponseErr);
        LibraryGraphMgt.VerifyPropertyInJSON(ResponseText, 'qltyInspectionStatus', Format(QltyInspectionHeader.Status::Finished));
    end;

    // endregion

    // region Qlty. Create Inspection API (page 20415) - Action Tests

    [Test]
    procedure CreateInspectionFromRecordIDWithTableNumber()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ActionBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from a record ID using the table number as tableName
        Initialize();

        // [GIVEN] A production order routing line exists with a matching generation rule
        SetupProductionOrderForCreateInspection(QltyInspectionTemplateHdr, ProdOrderRoutingLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        Commit();

        // [WHEN] The CreateInspectionFromRecordID action is called with the table number
        ActionBody := LibraryGraphMgt.AddPropertytoJSON('', 'tableName', Format(Database::"Prod. Order Routing Line"));
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            ProdOrderRoutingLine.SystemId, PAGE::"Qlty. Create Inspection API", CreateInspectionsServiceNameTxt, ActionCreateFromRecordIDTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, ActionBody, ResponseText, 201);

        // [THEN] A new quality inspection is created
        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();
        LibraryAssert.AreEqual(BeforeCount + 1, AfterCount, 'A quality inspection should have been created.');

        // [THEN] The created inspection uses the correct template
        QltyInspectionHeader.SetRange("Template Code", QltyInspectionTemplateHdr.Code);
        LibraryAssert.RecordIsNotEmpty(QltyInspectionHeader);
    end;

    [Test]
    procedure CreateInspectionFromRecordIDWithTableName()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ActionBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from a record ID using the table name as tableName
        Initialize();

        // [GIVEN] A production order routing line exists with a matching generation rule
        SetupProductionOrderForCreateInspection(QltyInspectionTemplateHdr, ProdOrderRoutingLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();
        Commit();

        // [WHEN] The CreateInspectionFromRecordID action is called with the table name
        ActionBody := LibraryGraphMgt.AddPropertytoJSON('', 'tableName', 'Prod. Order Routing Line');
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            ProdOrderRoutingLine.SystemId, PAGE::"Qlty. Create Inspection API", CreateInspectionsServiceNameTxt, ActionCreateFromRecordIDTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, ActionBody, ResponseText, 201);

        // [THEN] A new quality inspection is created
        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();
        LibraryAssert.AreEqual(BeforeCount + 1, AfterCount, 'A quality inspection should have been created.');
    end;

    [Test]
    procedure CreateInspectionFromTableIDAndFilter()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ActionBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        TableFilter: Text;
        BeforeCount: Integer;
        AfterCount: Integer;
    begin
        // [SCENARIO] Create a quality inspection from a table ID and filter
        Initialize();

        // [GIVEN] A production order routing line exists with a matching generation rule
        SetupProductionOrderForCreateInspection(QltyInspectionTemplateHdr, ProdOrderRoutingLine);

        QltyInspectionHeader.Reset();
        BeforeCount := QltyInspectionHeader.Count();

        // [GIVEN] A table filter that uniquely identifies the routing line
        TableFilter := StrSubstNo('WHERE(Prod. Order No.=FILTER(%1),Routing Reference No.=FILTER(%2),Routing No.=FILTER(%3),Operation No.=FILTER(%4))',
            ProdOrderRoutingLine."Prod. Order No.",
            ProdOrderRoutingLine."Routing Reference No.",
            ProdOrderRoutingLine."Routing No.",
            ProdOrderRoutingLine."Operation No.");
        Commit();

        // [WHEN] The CreateInspectionFromTableIDAndFilter action is called
        ActionBody := LibraryGraphMgt.AddPropertytoJSON('', 'tableName', Format(Database::"Prod. Order Routing Line"));
        ActionBody := LibraryGraphMgt.AddPropertytoJSON(ActionBody, 'tableNameFilter', TableFilter);
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            ProdOrderRoutingLine.SystemId, PAGE::"Qlty. Create Inspection API", CreateInspectionsServiceNameTxt, ActionCreateFromTableFilterTxt);
        LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, ActionBody, ResponseText, 201);

        // [THEN] A new quality inspection is created
        QltyInspectionHeader.Reset();
        AfterCount := QltyInspectionHeader.Count();
        LibraryAssert.AreEqual(BeforeCount + 1, AfterCount, 'A quality inspection should have been created from the table filter.');
    end;

    [Test]
    procedure CreateInspectionFromRecordIDWithInvalidSystemIdFails()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ActionBody: Text;
        ResponseText: Text;
        TargetURL: Text;
        InvalidSystemId: Guid;
    begin
        // [SCENARIO] Attempting to create an inspection with an invalid SystemId should fail
        Initialize();

        // [GIVEN] A generation rule exists but the SystemId does not match any record
        SetupProductionOrderForCreateInspection(QltyInspectionTemplateHdr, ProdOrderRoutingLine);
        InvalidSystemId := CreateGuid();
        Commit();

        // [WHEN] The CreateInspectionFromRecordID action is called with an invalid SystemId
        ActionBody := LibraryGraphMgt.AddPropertytoJSON('', 'tableName', Format(Database::"Prod. Order Routing Line"));
        TargetURL := LibraryGraphMgt.CreateTargetURLWithSubpage(
            InvalidSystemId, PAGE::"Qlty. Create Inspection API", CreateInspectionsServiceNameTxt, ActionCreateFromRecordIDTxt);

        // [THEN] An error occurs because the record cannot be found
        asserterror LibraryGraphMgt.PostToWebServiceAndCheckResponseCode(TargetURL, ActionBody, ResponseText, 201);
    end;

    // endregion

    // region Helper procedures

    local procedure SetupProductionOrderForCreateInspection(var QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr."; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        Item: Record Item;
        ProdProductionOrder: Record "Production Order";
        QltyProdOrderGenerator: Codeunit "Qlty. Prod. Order Generator";
    begin
        QltyInspectionUtility.EnsureSetupExists();
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 3);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Prod. Order Routing Line", QltyInspectionGenRule);
        QltyProdOrderGenerator.CreateItemAndProductionOrder(Item, ProdProductionOrder, ProdOrderRoutingLine);
    end;

    // endregion
}
