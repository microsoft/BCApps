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
using Microsoft.QualityManagement.Configuration.Template.Field;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Integration.Utilities;
using Microsoft.QualityManagement.Setup.Setup;
using Microsoft.Test.QualityManagement.TestLibraries;
using Microsoft.Utilities;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139970 "Qlty. Codeunit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    var
        LibraryAssert: Codeunit "Library Assert";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        QltyTestsUtility: Codeunit "Qlty. Tests - Utility";
        FileName: Text;
        OutStreamLbl: Label 'test';
        FileNameTok: Label 'test.txt';
        FirstFileNameTxt: Label 'First';
        SecondFileNameTxt: Label 'Second';
        FileNameTxt: Label 'filename';
        AttachFileLbl: Label 'Attach a file';
        IsInitialized: Boolean;

    [Test]
    procedure HandleOnBeforeInsertAttachment_Test()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
    begin
        // [SCENARIO] Attach a document to a Quality Inspection Test Header and verify attachment details
        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A new Quality Inspection Test Header record is created
        QltyInspectionTestHeader.Init();
        QltyInspectionTestHeader.Insert(true);

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the test header record
        RecordRef.GetTable(QltyInspectionTestHeader);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the test header with proper table ID and identifiers
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Test Header", DocumentAttachment."Table ID", 'Should be test.');
        LibraryAssert.AreEqual(QltyInspectionTestHeader."No.", DocumentAttachment."No.", 'Should be correct test.');
        LibraryAssert.AreEqual(QltyInspectionTestHeader."Retest No.", DocumentAttachment."Line No.", 'Should be correct test.');
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
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Template is created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

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
    procedure HandleOnBeforeInsertAttachment_Field()
    var
        ToLoadQltyField: Record "Qlty. Field";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
        FieldCode: Text;
    begin
        // [SCENARIO] Attach a document to a Quality Field and verify attachment details

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A Quality Field with a randomly generated code is created
        ToLoadQltyField.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Insert();

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the field record
        RecordRef.GetTable(ToLoadQltyField);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the field with proper table ID and field code
        LibraryAssert.AreEqual(Database::"Qlty. Field", DocumentAttachment."Table ID", 'Should be field.');
        LibraryAssert.AreEqual(ToLoadQltyField.Code, DocumentAttachment."No.", 'Should be correct field.');
    end;

    [Test]
    procedure HandleOnBeforeInsertAttachment_TestLine()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
    begin
        // [SCENARIO] Attach a document to a Quality Inspection Test Line and verify attachment details

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Test Header is created
        QltyInspectionTestHeader.Init();
        QltyInspectionTestHeader.Insert(true);

        // [GIVEN] A Quality Inspection Test Line is created for the test header
        QltyInspectionTestLine.Init();
        QltyInspectionTestLine."Test No." := QltyInspectionTestHeader."No.";
        QltyInspectionTestLine."Retest No." := QltyInspectionTestHeader."Retest No.";
        QltyInspectionTestLine.Insert(true);

        // [GIVEN] A file content is prepared in a temporary blob
        TempBlob.CreateOutStream(OutStreamToTest);
        OutStreamToTest.WriteText(OutStreamLbl);

        // [WHEN] The attachment is saved to the test line record
        RecordRef.GetTable(QltyInspectionTestLine);
        DocumentAttachment.SaveAttachment(RecordRef, FileNameTok, TempBlob);

        // [THEN] The document attachment is correctly linked to the test line with proper table ID and identifiers
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Test Line", DocumentAttachment."Table ID", 'Should be test line.');
        LibraryAssert.AreEqual(QltyInspectionTestLine."Test No.", DocumentAttachment."No.", 'Should be correct test line.');
        LibraryAssert.AreEqual(QltyInspectionTestLine."Line No.", DocumentAttachment."Line No.", 'Should be correct test line.');
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
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Template with one line is created
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);

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
    procedure HandleOnAfterOpenForRecRef_Test()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        SecondQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        FirstDocumentAttachment: Record "Document Attachment";
        SecondDocumentAttachment: Record "Document Attachment";
        QltyInspectionTest: TestPage "Qlty. Inspection Test";
    begin
        // [SCENARIO] Open attachments page for a test record and verify correct attachment filtering

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Two Quality Inspection Test Headers are created
        QltyInspectionTestHeader.Init();
        QltyInspectionTestHeader.Insert(true);

        SecondQltyInspectionTestHeader.Init();
        SecondQltyInspectionTestHeader.Insert(true);

        // [GIVEN] A document attachment is created for the first test
        FirstDocumentAttachment.Init();
        FirstDocumentAttachment."Table ID" := Database::"Qlty. Inspection Test Header";
        FirstDocumentAttachment."No." := QltyInspectionTestHeader."No.";
        FirstDocumentAttachment."Line No." := QltyInspectionTestHeader."Retest No.";
        FirstDocumentAttachment."File Name" := FirstFileNameTxt;
        FirstDocumentAttachment.Insert();

        // [GIVEN] A document attachment is created for the second test
        SecondDocumentAttachment.Init();
        SecondDocumentAttachment."Table ID" := Database::"Qlty. Inspection Test Header";
        SecondDocumentAttachment."No." := SecondQltyInspectionTestHeader."No.";
        SecondDocumentAttachment."Line No." := SecondQltyInspectionTestHeader."Retest No.";
        SecondDocumentAttachment."File Name" := SecondFileNameTxt;
        SecondDocumentAttachment.Insert();

        // [WHEN] The attachments page is opened for the first test
        QltyInspectionTest.OpenView();
        QltyInspectionTest.GotoRecord(QltyInspectionTestHeader);
        FileName := FirstFileNameTxt;
        QltyInspectionTest.Attachments.Invoke();
        QltyInspectionTest."Attached Documents".OpenInDetail.Invoke();

        // [THEN] Only the attachment for the first test is displayed (verified in modal page handler)
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
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(QltyInspectionTemplateHdr.Code), TemplateCode1);
        QltyInspectionTemplateHdr.Code := CopyStr(TemplateCode1, 1, MaxStrLen(QltyInspectionTemplateHdr.Code));
        QltyInspectionTemplateHdr.Insert();

        InspectionSecondQltyInspectionTemplateHdr.Init();
        repeat
            QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(InspectionSecondQltyInspectionTemplateHdr.Code), TemplateCode2);
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
    procedure HandleOnAfterOpenForRecRef_Field()
    var
        QltyField: Record "Qlty. Field";
        SecondQltyField: Record "Qlty. Field";
        DocumentAttachment: Record "Document Attachment";
        SecondDocumentAttachment: Record "Document Attachment";
        DocumentAttachmentDetails: Page "Document Attachment Details";
        RecordRef: RecordRef;
        FieldCode: Text;
        SecondFieldCode: Text;
    begin
        // [SCENARIO] Opening document attachment details for a Quality Field record through RecordRef shows only attachments for that specific field

        Initialize();

        QltyTestsUtility.EnsureSetup();

        // [GIVEN] Two Quality Field records with different codes are created
        QltyField.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Insert();

        SecondQltyField.Init();
        repeat
            QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(SecondQltyField.Code), SecondFieldCode);
        until SecondFieldCode <> FieldCode;
        SecondQltyField.Code := CopyStr(SecondFieldCode, 1, MaxStrLen(SecondQltyField.Code));
        SecondQltyField.Insert();

        // [GIVEN] Document attachments are created for both field records
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Field";
        DocumentAttachment."No." := QltyField.Code;
        DocumentAttachment."File Name" := FirstFileNameTxt;
        DocumentAttachment.Insert();

        SecondDocumentAttachment.Init();
        SecondDocumentAttachment."Table ID" := Database::"Qlty. Field";
        SecondDocumentAttachment."No." := SecondQltyField.Code;
        SecondDocumentAttachment."File Name" := SecondFileNameTxt;
        SecondDocumentAttachment.Insert();

        // [WHEN] The document attachment details page is opened for the first field via RecordRef
        RecordRef.GetTable(QltyField);
        FileName := FirstFileNameTxt;
        DocumentAttachmentDetails.OpenForRecRef(RecordRef);
        DocumentAttachmentDetails.RunModal();

        // [THEN] Only the attachment for the first field is displayed (verified in modal page handler)
    end;

    [Test]
    procedure FilterDocumentAttachment_Field()
    var
        ToLoadQltyField: Record "Qlty. Field";
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecordRef: RecordRef;
        FieldCode: Text;
    begin
        // [SCENARIO] Filter document attachments for a Quality Field record and verify correct filter is applied

        Initialize();

        // [GIVEN] A Quality Field with a randomly generated code is created
        ToLoadQltyField.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
        ToLoadQltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(ToLoadQltyField.Code));
        ToLoadQltyField.Insert();

        // [GIVEN] A document attachment is created for the field
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Field";
        DocumentAttachment."No." := ToLoadQltyField.Code;
        DocumentAttachment."File Name" := FileNameTxt;
        DocumentAttachment.Insert();

        // [WHEN] Document attachment filters are set for the field record
        RecordRef.GetTable(ToLoadQltyField);
        DocumentAttachmentMgmt.SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecordRef);

        // [THEN] The document attachment is filtered to the correct field code
        LibraryAssert.AreEqual(ToLoadQltyField.Code, DocumentAttachment.GetFilter("No."), 'Should be filtered to field code.');
    end;

    [Test]
    procedure FilterDocumentAttachment_TestLine()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTestLine: Record "Qlty. Inspection Test Line";
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Filter document attachments for a Quality Inspection Test Line and verify correct filters are applied

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Test Header is created
        QltyInspectionTestHeader.Init();
        QltyInspectionTestHeader.Insert(true);

        // [GIVEN] A Quality Inspection Test Line is created for the test header
        QltyInspectionTestLine.Init();
        QltyInspectionTestLine."Test No." := QltyInspectionTestHeader."No.";
        QltyInspectionTestLine."Retest No." := QltyInspectionTestHeader."Retest No.";
        QltyInspectionTestLine."Line No." := 10000;
        QltyInspectionTestLine.Insert();

        // [GIVEN] A document attachment is created for the test line
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := Database::"Qlty. Inspection Test Line";
        DocumentAttachment."File Name" := FileNameTxt;
        DocumentAttachment."No." := QltyInspectionTestLine."Test No.";
        DocumentAttachment."Line No." := QltyInspectionTestLine."Line No.";
        DocumentAttachment.Insert();

        // [WHEN] Document attachment filters are set for the test line record
        RecordRef.GetTable(QltyInspectionTestLine);
        DocumentAttachmentMgmt.SetDocumentAttachmentFiltersForRecRef(DocumentAttachment, RecordRef);

        // [THEN] The document attachment is filtered to the correct test number and line number
        LibraryAssert.AreEqual(QltyInspectionTestLine."Test No.", DocumentAttachment.GetFilter("No."), 'Should be filtered to test no.');
        LibraryAssert.AreEqual(Format(QltyInspectionTestLine."Line No."), DocumentAttachment.GetFilter("Line No."), 'Should be filtered to line no.');
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
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Template with a randomly generated code is created
        QltyInspectionTemplateHdr.Init();
        QltyTestsUtility.GenerateRandomCharacters(MaxStrLen(QltyInspectionTemplateHdr.Code), TemplateCode);
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
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTest: TestPage "Qlty. Inspection Test";
        QltyInspectionTestSecond: TestPage "Qlty. Inspection Test";
        Navigate: TestPage Navigate;
    begin
        // [SCENARIO] Navigate to a Quality Inspection Test record from the Navigate page and verify correct test is opened

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, QltyInspectionTemplateHdr);

        // [WHEN] The Navigate page is opened from the test and the test record is selected and shown
        QltyInspectionTest.OpenView();
        QltyInspectionTest.GotoRecord(QltyInspectionTestHeader);
        Navigate.Trap();
        QltyInspectionTest.FindEntries.Invoke();
        Navigate.First();
        repeat
            if Navigate."Table Name".Value() = QltyInspectionTestHeader.TableCaption() then begin
                QltyInspectionTestSecond.Trap();
                Navigate.Show.Invoke();
                break;
            end;
        until Navigate.Next() = false;

        // [THEN] The correct test is opened with the correct test number and no retest number
        LibraryAssert.AreEqual(QltyInspectionTestHeader."No.", QltyInspectionTestSecond."No.".Value(), 'Should be correct test.');
        LibraryAssert.AreEqual('', QltyInspectionTestSecond."Retest No.".Value(), 'Should be correct test.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure HandleOnAfterShowRecords_MultipleTests()
    var
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        ReQltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInspectionTest: TestPage "Qlty. Inspection Test";
        QltyInspectionTestList: TestPage "Qlty. Inspection Test List";
        Navigate: TestPage Navigate;
        Count: Integer;
    begin
        // [SCENARIO] Navigate to multiple Quality Inspection Test records (original and retest) from the Navigate page and verify both tests are shown

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, QltyInspectionTemplateHdr);

        // [GIVEN] A retest is created for the original test
        QltyInspectionTestHeader.CreateReTest();
        ReQltyInspectionTestHeader.Get(QltyInspectionTestHeader."No.", 1);

        // [WHEN] The Navigate page is opened from the test and the test records are shown
        QltyInspectionTest.OpenView();
        QltyInspectionTest.GotoRecord(QltyInspectionTestHeader);
        Navigate.Trap();
        QltyInspectionTest.FindEntries.Invoke();
        Navigate.First();
        repeat
            if Navigate."Table Name".Value() = QltyInspectionTestHeader.TableCaption() then begin
                QltyInspectionTestList.Trap();
                Navigate.Show.Invoke();
                break;
            end;
        until Navigate.Next() = false;

        // [THEN] Both the original test and retest are shown with the same test number
        QltyInspectionTestList.First();
        repeat
            LibraryAssert.AreEqual(QltyInspectionTestHeader."No.", QltyInspectionTestList."No.".Value(), 'Should be correct test.');
            Count += 1;
        until QltyInspectionTestList.Next() = false;
        LibraryAssert.AreEqual(2, Count, 'Should be two tests.');
    end;

    [Test]
    procedure HandleOnAfterFindTrackingRecords()
    var
        Location: Record Location;
        Item: Record Item;
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ReservationEntry: Record "Reservation Entry";
        LotNoInformation: Record "Lot No. Information";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        QltyPurOrderGenerator: Codeunit "Qlty. Pur. Order Generator";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        Navigate: TestPage Navigate;
        LotNoInformationCard: TestPage "Lot No. Information Card";
    begin
        // [SCENARIO] Navigate from a lot number to find associated Quality Inspection Test records and verify tracking records are found

        Initialize();

        // [GIVEN] Quality Management setup is initialized and a full WMS location is created
        QltyTestsUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] A lot-tracked item with a purchase order and reservation entry are created
        QltyTestsUtility.CreateLotTrackedItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] A quality inspection template and rule are created for purchase lines
        QltyTestsUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);
        QltyTestsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInTestGenerationRule);

        // [GIVEN] A quality inspection test is created with the purchase line and lot tracking
        QltyTestsUtility.CreateTestWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionTestHeader);

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

        // [THEN] The Quality Inspection Test record is found with one matching record
        Navigate.First();
        repeat
            if Navigate."Table Name".Value() = QltyInspectionTestHeader.TableCaption() then begin
                LibraryAssert.IsTrue(Navigate."No. of Records".Value() = '1', 'Should be one record.');
                break;
            end;
        until Navigate.Next() = false;

        QltyInspectionTemplateHdr.Delete();
        QltyInTestGenerationRule.Delete();
    end;

    [Test]
    procedure GetConditionalCardPageID()
    var
        PageManagement: Codeunit "Page Management";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Get the conditional card page ID for a Quality Inspection Test Header record and verify correct page is returned

        Initialize();

        // [GIVEN] A record reference is opened for the Quality Inspection Test Header table
        RecordRef.Open(Database::"Qlty. Inspection Test Header");

        // [WHEN] GetConditionalCardPageID is called for the record reference
        // [THEN] The Quality Inspection Test card page ID is returned
        LibraryAssert.AreEqual(Page::"Qlty. Inspection Test", PageManagement.GetConditionalCardPageID(RecordRef), 'Should be test card page.');
    end;

    [Test]
    procedure GetConditionalListPageID_Test()
    var
        PageManagement: Codeunit "Page Management";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Get the conditional list page ID for a Quality Inspection Test Header record and verify correct page is returned

        Initialize();

        // [GIVEN] A record reference is opened for the Quality Inspection Test Header table
        RecordRef.Open(Database::"Qlty. Inspection Test Header");

        // [WHEN] GetConditionalListPageID is called for the record reference
        // [THEN] The Quality Inspection Test List page ID is returned
        LibraryAssert.AreEqual(Page::"Qlty. Inspection Test List", PageManagement.GetConditionalListPageID(RecordRef), 'Should be tests list page.');
    end;

    [Test]
    procedure HandleOnAfterGetPageSummary()
    var
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyUtilitiesIntegration: Codeunit "Qlty. Utilities Integration";
        JsonArray: JsonArray;
        FieldJsonObject: JsonObject;
        FieldJsonToken: JsonToken;
        CaptionJsonToken: JsonToken;
    begin
        // [SCENARIO] Get page summary for a Quality Inspection Test and verify brick headers are correctly populated from setup

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyTestsUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Brick headers are configured in Quality Management setup
        QltyManagementSetup.GetBrickHeaders(QltyManagementSetup."Brick Top Left Header", QltyManagementSetup."Brick Middle Left Header", QltyManagementSetup."Brick Middle Right Header", QltyManagementSetup."Brick Bottom Left Header", QltyManagementSetup."Brick Bottom Right Header");
        QltyManagementSetup.Modify();

        // [GIVEN] A basic template and test instance are created
        QltyTestsUtility.CreateABasicTemplateAndInstanceOfATest(QltyInspectionTestHeader, QltyInspectionTemplateHdr);

        // [GIVEN] A JSON array is prepared with brick field captions
        FieldJsonObject.Add('caption', QltyInspectionTestHeader.FieldCaption("Brick Bottom Left"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionTestHeader.FieldCaption("Brick Bottom Right"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionTestHeader.FieldCaption("Brick Middle Left"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionTestHeader.FieldCaption("Brick Middle Right"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionTestHeader.FieldCaption("Brick Top Left"));
        JsonArray.Add(FieldJsonObject);

        // [WHEN] The page summary handler is invoked for the Quality Inspection Test
        QltyUtilitiesIntegration.InternalHandleOnAfterGetPageSummary(Page::"Qlty. Inspection Test", QltyInspectionTestHeader.RecordId(), JsonArray);

        // [THEN] All brick field captions are replaced with the configured brick headers from setup
        foreach FieldJsonToken in JsonArray do begin
            FieldJsonObject := FieldJsonToken.AsObject();
            FieldJsonObject.Get('caption', CaptionJsonToken);
            LibraryAssert.IsTrue(CaptionJsonToken.AsValue().AsText() in [QltyManagementSetup."Brick Bottom Left Header", QltyManagementSetup."Brick Bottom Right Header", QltyManagementSetup."Brick Middle Left Header", QltyManagementSetup."Brick Middle Right Header", QltyManagementSetup."Brick Top Left Header"], 'Should be correct header.');
        end;
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
