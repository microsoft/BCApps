// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.QualityManagement;

using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Purchases.Document;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Configuration.Template;
using Microsoft.QualityManagement.Configuration.Template.Test;
using Microsoft.QualityManagement.Document;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139970 "Qlty. Tests - Insepctions"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyInspectionUtility: Codeunit "Qlty. Inspection Utility";
        FileName: Text;
        OutStreamLbl: Label 'test';
        FileNameTok: Label 'test.txt';
        FirstFileNameTxt: Label 'First';
        SecondFileNameTxt: Label 'Second';
        FileNameTxt: Label 'filename';
        AttachFileLbl: Label 'Attach a file';
        IsInitialized: Boolean;

    [Test]
    procedure HandleOnBeforeInsertAttachment_Inspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
    begin
        // [SCENARIO] Attach a document to a Quality Inspection Header and verify attachment details
        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A new Quality Inspection Header record is created
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Insert(true);

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the inspection header record
        RecordRef.GetTable(QltyInspectionHeader);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the inspection header with proper table ID and identifiers
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Header", DocumentAttachment."Table ID", 'Should be inspection.');
        LibraryAssert.AreEqual(QltyInspectionHeader."No.", DocumentAttachment."No.", 'Should be correct inspection.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Re-inspection No.", DocumentAttachment."Line No.", 'Should be correct inspection.');
    end;

    [Test]
    procedure HandleOnBeforeInsertAttachment_Template()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
    begin
        // [SCENARIO] Attach a document to a Quality Inspection Template and verify attachment details

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A Quality Inspection Template is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the template record
        RecordRef.GetTable(QltyInspectionTemplateHdr);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the template with proper table ID and code
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Template Hdr.", DocumentAttachment."Table ID", 'Should be template.');
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, DocumentAttachment."No.", 'Should be correct template.');
    end;

    [Test]
    procedure HandleOnBeforeInsertAttachment_Test()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
        TestCode: Text;
    begin
        // [SCENARIO] Attach a document to a Quality Test and verify attachment details

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A Quality Test with a randomly generated code is created
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Insert();

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the test record
        RecordRef.GetTable(ToLoadQltyTest);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the test with proper table ID and test code
        LibraryAssert.AreEqual(Database::"Qlty. Test", DocumentAttachment."Table ID", 'Should be test.');
        LibraryAssert.AreEqual(ToLoadQltyTest.Code, DocumentAttachment."No.", 'Should be correct test.');
    end;

    [Test]
    procedure HandleOnBeforeInsertAttachment_InspectionLine()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
    begin
        // [SCENARIO] Attach a document to a Quality Inspection Line and verify attachment details

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A Quality Inspection Header is created
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Insert(true);

        // [GIVEN] A Quality Inspection Line is created for the inspection header
        QltyInspectionLine.Init();
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        QltyInspectionLine.Insert(true);

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the inspection line record
        RecordRef.GetTable(QltyInspectionLine);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the inspection line with proper table ID and identifiers
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Line", DocumentAttachment."Table ID", 'Should be inspection line.');
        LibraryAssert.AreEqual(QltyInspectionLine."Inspection No.", DocumentAttachment."No.", 'Should be correct inspection line.');
        LibraryAssert.AreEqual(QltyInspectionLine."Line No.", DocumentAttachment."Line No.", 'Should be correct inspection line.');
    end;

    [Test]
    procedure HandleOnBeforeInsertAttachment_TemplateLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
    begin
        // [SCENARIO] Attach a document to a Quality Inspection Template Line and verify attachment details

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A Quality Inspection Template with one line is created
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);

        // [GIVEN] A Quality Inspection Template Line is created for the template
        QltyInspectionTemplateLine.Init();
        QltyInspectionTemplateLine."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateLine.Insert(true);

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the template line record
        RecordRef.GetTable(QltyInspectionTemplateLine);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the template line with proper table ID and identifiers
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Template Line", DocumentAttachment."Table ID", 'Should be template line.');
        LibraryAssert.AreEqual(QltyInspectionTemplateLine."Template Code", DocumentAttachment."No.", 'Should be correct template line.');
        LibraryAssert.AreEqual(QltyInspectionTemplateLine."Line No.", DocumentAttachment."Line No.", 'Should be correct template line.');
    end;

    [Test]
    [HandlerFunctions('DocumentAttachmentDetailsModalPageHandler')]
    procedure HandleOnAfterOpenForRecRef_Inspection()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        SecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        FirstDocumentAttachment: Record "Document Attachment";
        SecondDocumentAttachment: Record "Document Attachment";
        QltyInspection: TestPage "Qlty. Inspection";
    begin
        // [SCENARIO] Open attachments page for an inspection record and verify correct attachment filtering

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Two Quality Inspection Headers are created
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Insert(true);

        SecondQltyInspectionHeader.Init();
        SecondQltyInspectionHeader.Insert(true);

        // [GIVEN] A document attachment is created for the first Inspection
        FirstDocumentAttachment.Init();
        FirstDocumentAttachment."Table ID" := Database::"Qlty. Inspection Header";
        FirstDocumentAttachment."No." := QltyInspectionHeader."No.";
        FirstDocumentAttachment."Line No." := QltyInspectionHeader."Re-inspection No.";
        FirstDocumentAttachment."File Name" := FirstFileNameTxt;
        FirstDocumentAttachment.Insert();

        // [GIVEN] A document attachment is created for the second Inspection
        SecondDocumentAttachment.Init();
        SecondDocumentAttachment."Table ID" := Database::"Qlty. Inspection Header";
        SecondDocumentAttachment."No." := SecondQltyInspectionHeader."No.";
        SecondDocumentAttachment."Line No." := SecondQltyInspectionHeader."Re-inspection No.";
        SecondDocumentAttachment."File Name" := SecondFileNameTxt;
        SecondDocumentAttachment.Insert();

        // [WHEN] The attachments page is opened for the first Inspection
        QltyInspection.OpenView();
        QltyInspection.GotoRecord(QltyInspectionHeader);
        FileName := FirstFileNameTxt;
        QltyInspection.Attachments.Invoke();
        QltyInspection."Attached Documents".OpenInDetail.Invoke();

        // [THEN] Only the attachment for the first inspection is displayed (verified in modal page handler)
    end;

    [Test]
    [HandlerFunctions('DocumentAttachmentDetailsModalPageHandler')]
    procedure HandleOnAfterOpenForRecRef_Template()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        InspectionSecondQltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        DocumentAttachment: Record "Document Attachment";
        SecondDocumentAttachment: Record "Document Attachment";
        QltyInspectionTemplate: TestPage "Qlty. Inspection Template";
        TemplateCode1: Text;
        TemplateCode2: Text;
    begin
        // [SCENARIO] Open attachments page for a template record and verify correct attachment filtering

        Initialize();

        // [GIVEN] Two Quality Inspection Templates with unique codes are created
        QltyInspectionTemplateHdr.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyInspectionTemplateHdr.Code), TemplateCode1);
        QltyInspectionTemplateHdr.Code := CopyStr(TemplateCode1, 1, MaxStrLen(QltyInspectionTemplateHdr.Code));
        QltyInspectionTemplateHdr.Insert();

        InspectionSecondQltyInspectionTemplateHdr.Init();
        repeat
            QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(InspectionSecondQltyInspectionTemplateHdr.Code), TemplateCode2);
        until TemplateCode2 <> TemplateCode1;
        InspectionSecondQltyInspectionTemplateHdr.Code := CopyStr(TemplateCode2, 1, MaxStrLen(InspectionSecondQltyInspectionTemplateHdr.Code));
        InspectionSecondQltyInspectionTemplateHdr.Insert();

        // [GIVEN] A document attachment is created for the first template
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Inspection Template Hdr.";
        DocumentAttachment."No." := QltyInspectionTemplateHdr.Code;
        DocumentAttachment."File Name" := FirstFileNameTxt;
        DocumentAttachment.Insert();

        // [GIVEN] A document attachment is created for the second template
        SecondDocumentAttachment.Init();
        SecondDocumentAttachment."Table ID" := Database::"Qlty. Inspection Template Hdr.";
        SecondDocumentAttachment."No." := InspectionSecondQltyInspectionTemplateHdr.Code;
        SecondDocumentAttachment."File Name" := SecondFileNameTxt;
        SecondDocumentAttachment.Insert();

        // [WHEN] The attachments page is opened for the first template
        QltyInspectionTemplate.OpenView();
        QltyInspectionTemplate.GotoRecord(QltyInspectionTemplateHdr);
        FileName := FirstFileNameTxt;
        QltyInspectionTemplate."Attached Documents".OpenInDetail.Invoke();

        // [THEN] Only the attachment for the first template is displayed (verified in modal page handler)
    end;

    [Test]
    [HandlerFunctions('DocumentAttachmentDetailsModalPageHandler')]
    procedure HandleOnAfterOpenForRecRef_Test()
    var
        QltyTest: Record "Qlty. Test";
        SecondQltyTest: Record "Qlty. Test";
        DocumentAttachment: Record "Document Attachment";
        SecondDocumentAttachment: Record "Document Attachment";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecordRef: RecordRef;
        TestCode: Text;
        SecondTestCode: Text;
    begin
        // [SCENARIO] Opening document attachment details for a Quality Test record through RecordRef shows only attachments for that specific test

        Initialize();

        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] Two Quality Test records with different codes are created
        QltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyTest.Code), TestCode);
        QltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(QltyTest.Code));
        QltyTest.Insert();

        SecondQltyTest.Init();
        repeat
            QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(SecondQltyTest.Code), SecondTestCode);
        until SecondTestCode <> TestCode;
        SecondQltyTest.Code := CopyStr(SecondTestCode, 1, MaxStrLen(SecondQltyTest.Code));
        SecondQltyTest.Insert();

        // [GIVEN] Document attachments are created for both test records
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Test";
        DocumentAttachment."No." := QltyTest.Code;
        DocumentAttachment."File Name" := FirstFileNameTxt;
        DocumentAttachment.Insert();

        SecondDocumentAttachment.Init();
        SecondDocumentAttachment."Table ID" := Database::"Qlty. Test";
        SecondDocumentAttachment."No." := SecondQltyTest.Code;
        SecondDocumentAttachment."File Name" := SecondFileNameTxt;
        SecondDocumentAttachment.Insert();

        // [WHEN] The document attachment details page is opened for the first test via RecordRef
        RecordRef.GetTable(QltyTest);
        FileName := FirstFileNameTxt;
        DocumentAttachmentDetails.OpenForRecRef(RecordRef);
        DocumentAttachmentDetails.RunModal();

        // [THEN] Only the attachment for the first test is displayed (verified in modal page handler)
    end;

    [Test]
    procedure FilterDocumentAttachment_Test()
    var
        ToLoadQltyTest: Record "Qlty. Test";
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecordRef: RecordRef;
        TestCode: Text;
    begin
        // [SCENARIO] Filter document attachments for a Quality Test record and verify correct filter is applied

        Initialize();

        // [GIVEN] A Quality Test with a randomly generated code is created
        ToLoadQltyTest.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyTest.Code), TestCode);
        ToLoadQltyTest.Code := CopyStr(TestCode, 1, MaxStrLen(ToLoadQltyTest.Code));
        ToLoadQltyTest.Insert();

        // [GIVEN] A document attachment is created for the test
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Test";
        DocumentAttachment."No." := ToLoadQltyTest.Code;
        DocumentAttachment."File Name" := FileNameTxt;
        DocumentAttachment.Insert();

        // [WHEN] Document attachment filters are set for the test record
        RecordRef.GetTable(ToLoadQltyTest);
        DocumentAttachmentMgmt.SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecordRef);

        // [THEN] The document attachment is filtered to the correct test code
        LibraryAssert.AreEqual(ToLoadQltyTest.Code, DocumentAttachment.GetFilter("No."), 'Should be filtered to test code.');
    end;

    [Test]
    procedure FilterDocumentAttachment_InspectionLine()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Filter document attachments for a Quality Inspection Line and verify correct filters are applied

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A Quality Inspection Header is created
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Insert(true);

        // [GIVEN] A Quality Inspection Line is created for the inspection header
        QltyInspectionLine.Init();
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Re-inspection No." := QltyInspectionHeader."Re-inspection No.";
        QltyInspectionLine."Line No." := 10000;
        QltyInspectionLine.Insert();

        // [GIVEN] A document attachment is created for the inspection line
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Inspection Line";
        DocumentAttachment."File Name" := FileNameTxt;
        DocumentAttachment."No." := QltyInspectionLine."Inspection No.";
        DocumentAttachment."Line No." := QltyInspectionLine."Line No.";
        DocumentAttachment.Insert();

        // [WHEN] Document attachment filters are set for the inspection line record
        RecordRef.GetTable(QltyInspectionLine);
        DocumentAttachmentMgmt.SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecordRef);

        // [THEN] The document attachment is filtered to the correct inspection number and line number
        LibraryAssert.AreEqual(QltyInspectionLine."Inspection No.", DocumentAttachment.GetFilter("No."), 'Should be filtered to inspection no.');
        LibraryAssert.AreEqual(Format(QltyInspectionLine."Line No."), DocumentAttachment.GetFilter("Line No."), 'Should be filtered to line no.');
    end;

    [Test]
    procedure FilterDocumentAttachment_TemplateLine()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTemplateLine: Record "Qlty. Inspection Template Line";
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecordRef: RecordRef;
        TemplateCode: Text;
    begin
        // [SCENARIO] Filter document attachments for a Quality Inspection Template Line and verify correct filters are applied

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A Quality Inspection Template with a randomly generated code is created
        QltyInspectionTemplateHdr.Init();
        QltyInspectionUtility.GenerateRandomCharacters(MaxStrLen(QltyInspectionTemplateHdr.Code), TemplateCode);
        QltyInspectionTemplateHdr.Code := CopyStr(TemplateCode, 1, MaxStrLen(QltyInspectionTemplateHdr.Code));
        QltyInspectionTemplateHdr.Insert(true);

        // [GIVEN] A Quality Inspection Template Line is created for the template
        QltyInspectionTemplateLine.Init();
        QltyInspectionTemplateLine."Template Code" := QltyInspectionTemplateHdr.Code;
        QltyInspectionTemplateLine.Insert(true);

        // [GIVEN] A document attachment is created for the template line
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Inspection Template Line";
        DocumentAttachment."No." := QltyInspectionTemplateHdr.Code;
        DocumentAttachment."Line No." := QltyInspectionTemplateLine."Line No.";
        DocumentAttachment."File Name" := FileNameTxt;
        DocumentAttachment.Insert();

        // [WHEN] Document attachment filters are set for the template line record
        RecordRef.GetTable(QltyInspectionTemplateLine);
        DocumentAttachmentMgmt.SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecordRef);

        // [THEN] The document attachment is filtered to the correct template code and line number
        LibraryAssert.AreEqual(QltyInspectionTemplateHdr.Code, DocumentAttachment.GetFilter("No."), 'Should be filtered to template code.');
        LibraryAssert.AreEqual(Format(QltyInspectionTemplateLine."Line No."), DocumentAttachment.GetFilter("Line No."), 'Should be filtered to templateline no.');
    end;

    [Test]
    procedure HandleOnAfterShowRecords()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspection: TestPage "Qlty. Inspection";
        QltyInspectionSecond: TestPage "Qlty. Inspection";
        Navigate: TestPage Navigate;
    begin
        // [SCENARIO] Navigate to a Quality Inspection record from the Navigate page and verify correct inspection is opened

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);

        // [WHEN] The Navigate page is opened from the inspection and the inspection record is selected and shown
        QltyInspection.OpenView();
        QltyInspection.GotoRecord(QltyInspectionHeader);
        Navigate.Trap();
        QltyInspection.FindEntries.Invoke();
        Navigate.First();
        repeat
            if Navigate."Table Name".Value() = QltyInspectionHeader.TableCaption() then begin
                QltyInspectionSecond.Trap();
                Navigate.Show.Invoke();
                break;
            end;
        until Navigate.Next() = false;

        // [THEN] The correct inspection is opened with the correct inspection number and no re-inspection number
        LibraryAssert.AreEqual(QltyInspectionHeader."No.", QltyInspectionSecond."No.".Value(), 'Should be correct inspection.');
        LibraryAssert.AreEqual('', QltyInspectionSecond."Re-inspection No.".Value(), 'Should be correct inspection.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure HandleOnAfterShowRecords_MultipleInspections()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspection: TestPage "Qlty. Inspection";
        QltyInspectionList: TestPage "Qlty. Inspection List";
        Navigate: TestPage Navigate;
        Count: Integer;
    begin
        // [SCENARIO] Navigate to multiple Quality Inspection records (original and re-inspection) from the Navigate page and verify both inspections are shown

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionUtility.EnsureSetupExists();

        // [GIVEN] A basic template and inspection instance are created
        QltyInspectionUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);

        // [GIVEN] A re-inspection is created for the original inspection 
        QltyInspectionHeader.CreateReinspection();
        ReQltyInspectionHeader.Get(QltyInspectionHeader."No.", 1);

        // [WHEN] The Navigate page is opened from the inspection and the inspection records are shown
        QltyInspection.OpenView();
        QltyInspection.GotoRecord(QltyInspectionHeader);
        Navigate.Trap();
        QltyInspection.FindEntries.Invoke();
        Navigate.First();
        repeat
            if Navigate."Table Name".Value() = QltyInspectionHeader.TableCaption() then begin
                QltyInspectionList.Trap();
                Navigate.Show.Invoke();
                break;
            end;
        until Navigate.Next() = false;

        // [THEN] Both the original inspection and re-inspection are shown with the same inspection number
        QltyInspectionList.First();
        repeat
            LibraryAssert.AreEqual(QltyInspectionHeader."No.", QltyInspectionList."No.".Value(), 'Should be correct inspection.');
            Count += 1;
        until QltyInspectionList.Next() = false;
        LibraryAssert.AreEqual(2, Count, 'Should be two inspections.');
    end;

    [Test]
    procedure HandleOnAfterFindTrackingRecords()
    var
        Location: Record Location;
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNoInformation: Record "Lot No. Information";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Navigate: TestPage Navigate;
        LotNoInformationCard: TestPage "Lot No. Information Card";
    begin
        // [SCENARIO] Navigate from a lot number to find associated Quality Inspection records and verify tracking records are found

        Initialize();

        // [GIVEN] Quality Management setup is initialized and a full WMS location is created
        QltyInspectionUtility.EnsureSetupExists();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] A lot-tracked item with a purchase order and reservation entry are created
        QltyInspectionUtility.CreateLotTrackedItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] A quality inspection template and rule are created for purchase lines
        QltyInspectionUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);
        QltyInspectionUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A quality inspection is created with the purchase line and lot tracking
        QltyInspectionUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

        // [GIVEN] Lot number information is created for the tracked lot
        LotNoInformation.Init();
        LotNoInformation."Item No." := Item."No.";
        LotNoInformation."Lot No." := ReservationEntry."Lot No.";
        LotNoInformation.Insert();

        // [WHEN] Navigate is opened from the lot number information card
        LotNoInformationCard.OpenView();
        LotNoInformationCard.GotoRecord(LotNoInformation);
        Navigate.Trap();
        LotNoInformationCard.Navigate.Invoke();

        // [THEN] The Quality Inspection record is found with one matching record
        Navigate.First();
        repeat
            if Navigate."Table Name".Value() = QltyInspectionHeader.TableCaption() then begin
                LibraryAssert.IsTrue(Navigate."No. of Records".Value() = '1', 'Should be one record.');
                break;
            end;
        until Navigate.Next() = false;

        QltyInspectionTemplateHdr.Delete();
        QltyInspectionGenRule.Delete();
    end;

    [Test]
    procedure GetConditionalCardPageID()
    var
        PageManagement: Codeunit "Page Management";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Get the conditional card page ID for a Quality Inspection Header record and verify correct page is returned

        Initialize();

        // [GIVEN] A record reference is opened for the Quality Inspection Header table
        RecordRef.Open(Database::"Qlty. Inspection Header");

        // [WHEN] GetConditionalCardPageID is called for the record reference
        // [THEN] The Quality Inspection card page ID is returned
        LibraryAssert.AreEqual(Page::"Qlty. Inspection", PageManagement.GetConditionalCardPageID(RecordRef), 'Should be inspection card page.');
    end;

    [Test]
    procedure GetConditionalListPageID_Inspection()
    var
        PageManagement: Codeunit "Page Management";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Get the conditional list page ID for a Quality Inspection Header record and verify correct page is returned

        Initialize();

        // [GIVEN] A record reference is opened for the Quality Inspection Header table
        RecordRef.Open(Database::"Qlty. Inspection Header");

        // [WHEN] GetConditionalListPageID is called for the record reference
        // [THEN] The Quality Inspection List page ID is returned
        LibraryAssert.AreEqual(Page::"Qlty. Inspection List", PageManagement.GetConditionalListPageID(RecordRef), 'Should be inspections list page.');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        LibraryERMCountryData.CreateVATData();
        IsInitialized := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure DocumentAttachmentDetailsModalPageHandler(var DocumentAttachmentDetails: TestPage "Document Attachment Details")
    begin
        DocumentAttachmentDetails.First();

        LibraryAssert.AreEqual(DocumentAttachmentDetails.Name.Value(), FileName, 'Should be correct file.');

        DocumentAttachmentDetails.Next();

        LibraryAssert.IsTrue(DocumentAttachmentDetails.Name.Value() = AttachFileLbl, 'Next record should be new (empty).');
        LibraryAssert.IsTrue(DocumentAttachmentDetails."File Extension".Value() = '', 'Next record should be empty.');
        LibraryAssert.IsTrue(DocumentAttachmentDetails."Attached Date".Value() = '', 'Next record should be empty.');
    end;
}
