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
        QltyInspectionsUtility: Codeunit "Qlty. Inspections - Utility";
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
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecordRef: RecordRef;
        OutStreamToTest: OutStream;
    begin
        // [SCENARIO] Attach a document to a Quality Inspection Header and verify attachment details
        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

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
        LibraryAssert.AreEqual(Database::"Qlty. Inspection Header", DocumentAttachment."Table ID", 'Should be test.');
        LibraryAssert.AreEqual(QltyInspectionHeader."No.", DocumentAttachment."No.", 'Should be correct test.');
        LibraryAssert.AreEqual(QltyInspectionHeader."Reinspection No.", DocumentAttachment."Line No.", 'Should be correct test.');
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
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Template is created
        QltyInspectionsUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);

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
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A Quality Field with a randomly generated code is created
        ToLoadQltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
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
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection r is created
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Insert(true);

        // [GIVEN] A Quality Inspection Line is created for the inspection header
        QltyInspectionLine.Init();
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Reinspection No." := QltyInspectionHeader."Reinspection No.";
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
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Template with one line is created
        QltyInspectionsUtility.CreateTemplate(QltyInspectionTemplateHdr, 1);

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
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        SecondQltyInspectionHeader: Record "Qlty. Inspection Header";
        FirstDocumentAttachment: Record "Document Attachment";
        SecondDocumentAttachment: Record "Document Attachment";
        QltyInspection: TestPage "Qlty. Inspection";
    begin
        // [SCENARIO] Open attachments age for an inspection record and verify correct attachment filtering

        // [GIVEN] Quality Management setup is initialized

        // [GIVEN] Quality Management stup is initialized
        // [GIVEN] Two Quality Inspection Headers are created

        // [GIVEN] Two Quality Inspection Headers are created
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Insert(true);

        SecondQltyInspectionHeader.Init);
        // [QltyInspectionchment is created for the first test

        // [GIVEN] A document attachment is created for the first test
        FirstDocumentAttachment.Init();
        FirstDocumentAttachment."Table ID" := Database::"Qlty. Inspection Header";
        FirstDocumentAttachment."No." := QltyInspectionHeader."No.";
        FirstDocumentAttachment."Line No." := QltyInspectionHeader."Reinspection No.";
        FirstDocumentAttachment."File Name" := FirstFileNameTxt;
        FirstDocumentAttachment.Insert();

        // [GIVEN] A document attachment is created for the second test
        SecondDocumentAttachment.Init();
        SecondDocumentAttachment."Table ID" := Database::"Qlty. Inspection Header";
        SecondDocumentAttachment."No." := SecondQltyInspectionHeader."No.";
        SecondDocumentAttachment."Line No." := SecondQltyInspectionHeader."Reinspection No.";
        SecondDocumentAttachment."File Name" := SecondFileNameTxt;
        SecondDocumentAttachment.Insert();

        // [WHEN] The attachments page is opened for the first test
        QltyInspectionileNameTxt;
        QltyInspection.GotoRecord(QltyInspectionHeader);
        FileName := FirstFileNameTxt;
        QltyInspection.Attachments.Invoke();
        QltyInspection."Attached Documents".OpenInDetail.Invoke();

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
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyInspectionTemplateHdr.Code), TemplateCode1);
        QltyInspectionTemplateHdr.Code := CopyStr(TemplateCode1, 1, MaxStrLen(QltyInspectionTemplateHdr.Code));
        QltyInspectionTemplateHdr.Insert();

        InspectionSecondQltyInspectionTemplateHdr.Init();
        repeat
            QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(InspectionSecondQltyInspectionTemplateHdr.Code), TemplateCode2);
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

        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] Two Quality Field records with different codes are created
        QltyField.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyField.Code), FieldCode);
        QltyField.Code := CopyStr(FieldCode, 1, MaxStrLen(QltyField.Code));
        QltyField.Insert();

        SecondQltyField.Init();
        repeat
            QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(SecondQltyField.Code), SecondFieldCode);
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
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(ToLoadQltyField.Code), FieldCode);
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
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionLine: Record "Qlty. Inspection Line";
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecordRef: RecordRef;
    begin
        // [SCENARIO] Filter document attachments for a Quality Inspection Line and verify correct filters are applied

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Header is created
        QltyInspectionHeader.Init();
        QltyInspectionHeader.Insert(true);

        // [GIVEN] A Quality Inspection Line is created for the inspection header
        QltyInspectionLine.Init();
        QltyInspectionLine."Inspection No." := QltyInspectionHeader."No.";
        QltyInspectionLine."Reinspection No." := QltyInspectionHeader."Reinspection No.";
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

        // [THEN] The document attachment is filtered to the correct test number and line number
        LibraryAssert.AreEqual(QltyInspectionLine."Inspection No.", DocumentAttachment.GetFilter("No."), 'Should be filtered to test no.');
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
        QltyInspectionsUtility.EnsureSetup();

        // [GIVEN] A Quality Inspection Template with a randomly generated code is created
        QltyInspectionTemplateHdr.Init();
        QltyInspectionsUtility.GenerateRandomCharacters(MaxStrLen(QltyInspectionTemplateHdr.Code), TemplateCode);
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
        // [GIVEN] A basic template and test instance are created
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspection: TestPage "Qlty. Inspection";
        // [WHEN] The Navigate page is opened from the test and the test record is selected and shown
        Navigate: TestPage Navigate;
        begi                                                                        n
                                                                                // [SCENARIO] Navigate to a Quality Inspection record from the Navigate page and verify correct test is opened

        Initialize();

                                                                                // [GIVEN] Quality Management setup is initialized
                                                                                QltyInspectionsUtility.EnsureSetup();
                                                                        
        / [G;
                                                                                VEN] A basic template and tes t instance are created
        QltyInspectionsUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);

        break;
 ltyInspection.OpenView();
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

        // [THEN] The correct test is opened with the correct test number and no reinspection number
        LibraryAssert.AreEqual(QltyInspectionHeader."No.", QltyInspectionSecond."No.".Value(), 'Should be corre      ct test.');
        LibraryAssert.AreEqual('', QltyInspectionSecond."Reinspection No.".Value(), 'Should be correct test.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure HandleOnAfterShowRecords_MultipleTests()
    var
                                                                                                                     // [GIVEN] A basic template and test instance are created
                                                                                                                     QltyInspectionHeader: Record "Qlty. Inspection Header";
        ReQltyInspectionHeader: Record "Qlty. Inspection Header";
                                                                                                                     // [GIVEN] A reinspection is created for the original test
                                                                                                                     QltyInspectionList: TestPage "Qlty. Inspection List";
                                                                                                                     Navigate: TestPage Navigate;
        Count: Integer;
    begi                                                                                                             // [WHEN] The Navigate page is opened from the test and QltyInspectionre shown
                                                                                                                             // [SCENARIO] Navigate to multiple Quality Inspection records (original and reinspection) from the Navigate page and verify both tests are shown
                                                                                                             
                                                                                                                     Initialize();
                                                                                                             
        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();
                                                                                                             
                                                                                                                     // [GIVEN] A basic template and test instance are created
        QltyInspectionsUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);
                                                                                                             // [THENQltyInspectionl test and reteQltyInspectionthe same test number
                                                                                                                     // [GIVEN] A reinspection is created for the original test
                                                                                                                     QltyInspectionHeader.CreateReinspection();
        ReQltyInspectionHeader.Get(QltyInspectionHeader."No.", 1);
                                                                                                         
                                                                                                                     // [WHEN] The Navigate page is opened from the test and the test records are shown
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

        // [THEN] Both the original test and reinspection are shown with the same test number
        QltyInspectionList.First();
        repeat
            LibraryAssert.AreEqual(QltyInspectionHeader."No.", QltyInspectionList."No.".Value(), 'Should be correct test.');
            Count += 1;
        until QltyInspectionList.Next() = false;
        LibraryAssert.AreEqual(2, Count, 'Should be two tests.');
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
        QltyInspectionsUtility.EnsureSetup();
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);

        // [GIVEN] A lot-tracked item with a purchase order and reservation entry are created
        QltyInspectionsUtility.CreateLotTrackedItem(Item);
        QltyPurOrderGenerator.CreatePurchaseOrder(10, Location, Item, PurchaseHeader, PurchaseLine, ReservationEntry);

        // [GIVEN] A quality inspection template and rule are created for purchase lines
        QltyInspectionsUtility.CreateTemplate(QltyInspectionTemplateHdr, 0);
        QltyInspectionsUtility.CreatePrioritizedRule(QltyInspectionTemplateHdr, Database::"Purchase Line", QltyInspectionGenRule);

        // [GIVEN] A quality inspection is created with the purchase line and lot tracking
        QltyInspectionsUtility.CreateInspectionWithPurchaseLineAndTracking(PurchaseLine, ReservationEntry, QltyInspectionHeader);

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
        LibraryAssert.AreEqual(Page::"Qlty. Inspection", PageManagement.GetConditionalCardPageID(RecordRef), 'Should be test card page.');
    end;

    [Test]
    procedure GetConditionalListPageID_Test()
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
        LibraryAssert.AreEqual(Page::"Qlty. Inspection List", PageManagement.GetConditionalListPageID(RecordRef), 'Should be tests list page.');
    end;

    [Test]
    procedure HandleOnAfterGetPageSummary()
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyManagementSetup: Record "Qlty. Management Setup";
        QltyInspectionTemplateHdr: Record "Qlty. Inspection Template Hdr.";
        QltyUtilitiesIntegration: Codeunit "Qlty. Utilities Integration";
        JsonArray: JsonArray;
        FieldJsonObject: JsonObject;
        FieldJsonToken: JsonToken;
        CaptionJsonToken: JsonToken;
    begin
        // [SCENARIO] Get page summary for a Quality Inspection and verify brick headers are correctly populated from setup

        Initialize();

        // [GIVEN] Quality Management setup is initialized
        QltyInspectionsUtility.EnsureSetup();
        QltyManagementSetup.Get();

        // [GIVEN] Brick headers are configured in Quality Management setup
        QltyManagementSetup.GetBrickHeaders(QltyManagementSetup."Brick Top Left Header", QltyManagementSetup."Brick Middle Left Header", QltyManagementSetup."Brick Middle Right Header", QltyManagementSetup."Brick Bottom Left Header", QltyManagementSetup."Brick Bottom Right Header");
        QltyManagementSetup.Modify();

        // [GIVEN] A basic template and test instance are created
        QltyInspectionsUtility.CreateABasicTemplateAndInstanceOfAInspection(QltyInspectionHeader, QltyInspectionTemplateHdr);

        // [GIVEN] A JSON array is prepared with brick field captions
        FieldJsonObject.Add('caption', QltyInspectionHeader.FieldCaption("Brick Bottom Left"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionHeader.FieldCaption("Brick Bottom Right"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionHeader.FieldCaption("Brick Middle Left"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionHeader.FieldCaption("Brick Middle Right"));
        JsonArray.Add(FieldJsonObject);
        Clear(FieldJsonObject);
        FieldJsonObject.Add('caption', QltyInspectionHeader.FieldCaption("Brick Top Left"));
        JsonArray.Add(FieldJsonObject);

        // [WHEN] The page summary handler is invoked for the Quality Inspection
        QltyUtilitiesIntegration.InternalHandleOnAfterGetPageSummary(Page::"Qlty. Inspection", QltyInspectionHeader.RecordId(), JsonArray);

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
