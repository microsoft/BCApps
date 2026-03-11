// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.API;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;


codeunit 135575 "E-Doc. API Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    [Test]
    procedure GetEDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        EDocument: Record "E-Document";
        LibrarygraphMgt: Codeunit "Library - Graph Mgt";
        TargetURL: Text;
        Response: Text;
        EDocsApiServiceNameTok: Label 'eDocuments', Locked = true;
    begin
        // [SCENARIO] Get E-Document from api page

        // [GIVEN] Related document for e document
        CreatePurchaseHeader(PurchaseHeader);
        // [GIVEN]  E-Document
        CreateEDocument(PurchaseHeader, EDocument);
        Commit(); //Commit to make data visible for api
        // [GIVEN] URL to get E-Document
        TargetURL := LibraryGraphMgt.CreateTargetURL(EDocument.SystemId, Page::"E-Documents API", EDocsApiServiceNameTok);

        // [WHEN] Getting E-Document from API
        LibraryGraphMgt.GetFromWebService(Response, TargetURL);

        // [THEN] Response should contain correct E-Document data
        VerifyEDocumentResponse(EDocument, Response);
    end;

    [Test]
    procedure CreateEDocument()
    var
        EDocumentService: Record "E-Document Service";
        Assert: Codeunit Assert;
        Any: Codeunit Any;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        JSONRequest: Text;
        TargetURL: Text;
        Response: Text;
        CreateEDocumentsServiceTxt: Label 'createEDocuments', Locked = true;
    begin
        // [SCENARIO] Create E-Document using api page

        // [GIVEN] E-Document service
        EDocumentService.Init();
        EDocumentService.Code := CopyStr(Any.AlphanumericText(MaxStrLen(EDocumentService.Code)), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService.Insert(false);
        // [GIVEN] JSON containing e document data
        GetEDocumentCreateRequest(EDocumentService.Code, JSONRequest);

        // [WHEN] Creating E-Document using API
        TargetURL := LibraryGraphMgt.CreateTargetURL('', Page::"New E-Documents API", CreateEDocumentsServiceTxt);
        asserterror LibraryGraphMgt.PostToWebService(TargetURL, JSONRequest, Response);

        // [THEN] Response is empty
        Assert.AreEqual('', Response, 'Response should be empty.');
    end;

    local procedure VerifyEDocumentResponse(EDocument: Record "E-Document"; Response: Text)
    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        AmtInclVatTxt: Text;
        AmtExclVatTxt: Text;
        AmtInclVat: Decimal;
        AmtExclVat: Decimal;
    begin
        Assert.AreNotEqual('', Response, 'Response should not be empty');
        LibraryGraphMgt.VerifyIDFieldInJson(Response, 'systemId');
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'entryNumber', Format(EDocument."Entry No"));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'documentRecordId', Format(EDocument."Document Record ID"));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'billPayNumber', EDocument."Bill-to/Pay-to No.");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'documentNumber', EDocument."Document No.");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'documentType', Format(EDocument."Document Type"));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'documentDate', Format(EDocument."Document Date", 0, 9));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'dueDate', Format(EDocument."Due Date", 0, 9));
        LibraryGraphMgt.GetPropertyValueFromJSON(Response, 'amountInclVat', AmtInclVatTxt);
        LibraryGraphMgt.GetPropertyValueFromJSON(Response, 'amountExclVat', AmtExclVatTxt);
        Evaluate(AmtExclVat, AmtExclVatTxt);
        Evaluate(AmtInclVat, AmtInclVatTxt);
        Assert.AreEqual(EDocument."Amount Incl. VAT", AmtInclVat, 'Amount Incl. VAT does not match');
        Assert.AreEqual(EDocument."Amount Excl. VAT", AmtExclVat, 'Amount Excl. VAT does not match');
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'orderNumber', EDocument."Order No.");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'postingDate', Format(EDocument."Posting Date", 0, 9));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'direction', Format(EDocument.Direction));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'incomingEDocumentNumber', EDocument."Incoming E-Document No.");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'status', Format(EDocument.Status));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'sourceType', Format(EDocument."Source Type"));
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'recCompanyVat', EDocument."Receiving Company VAT Reg. No.");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'recCompanyGLN', EDocument."Receiving Company GLN");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'recCompanyName', EDocument."Receiving Company Name");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'recCompanyAddress', EDocument."Receiving Company Address");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'currencyCode', EDocument."Currency Code");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'workflowCode', EDocument."Workflow Code");
        LibraryGraphMgt.VerifyPropertyInJSON(Response, 'fileName', EDocument."File Name");
    end;

    local procedure CreateEDocument(var PurchaseHeader: Record "Purchase Header"; var EDocument: Record "E-Document")
    var
        Any: Codeunit Any;
    begin
        EDocument.Init();
        EDocument."Entry No" := Any.IntegerInRange(10000, 99999);
        EDocument."Document Record ID" := PurchaseHeader.RecordId();
        EDocument."Bill-to/Pay-to No." := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Bill-to/Pay-to No.")), 1, MaxStrLen(EDocument."Bill-to/Pay-to No."));
        EDocument."Document No." := PurchaseHeader."No.";
        EDocument."Document Type" := EDocument."Document Type"::"Sales Order";
        EDocument."Document Date" := Today();
        EDocument."Due Date" := Today();
        EDocument."Amount Excl. VAT" := Any.DecimalInRange(1000, 2);
        EDocument."Amount Incl. VAT" := EDocument."Amount Excl. VAT" * 1.2;
        EDocument."Order No." := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Order No.")), 1, MaxStrLen(EDocument."Order No."));
        EDocument."Posting Date" := Today();
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument."Incoming E-Document No." := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Incoming E-Document No.")), 1, MaxStrLen(EDocument."Incoming E-Document No."));
        EDocument.Status := EDocument.Status::Processed;
        EDocument."Source Type" := EDocument."Source Type"::Vendor;
        EDocument."Receiving Company VAT Reg. No." := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Receiving Company VAT Reg. No.")), 1, MaxStrLen(EDocument."Receiving Company VAT Reg. No."));
        EDocument."Receiving Company GLN" := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Receiving Company GLN")), 1, MaxStrLen(EDocument."Receiving Company GLN"));
        EDocument."Receiving Company Name" := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Receiving Company Name")), 1, MaxStrLen(EDocument."Receiving Company Name"));
        EDocument."Receiving Company Address" := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Receiving Company Address")), 1, MaxStrLen(EDocument."Receiving Company Address"));
        EDocument."Currency Code" := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Currency Code")), 1, MaxStrLen(EDocument."Currency Code"));
        EDocument."Workflow Code" := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."Workflow Code")), 1, MaxStrLen(EDocument."Workflow Code"));
        EDocument."File Name" := CopyStr(Any.AlphanumericText(MaxStrLen(EDocument."File Name")), 1, MaxStrLen(EDocument."File Name"));
        EDocument.Insert(false);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    var
        Any: Codeunit Any;
    begin
        PurchaseHeader.Init();
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := CopyStr(Any.AlphanumericText(MaxStrLen(PurchaseHeader."No.")), 1, MaxStrLen(PurchaseHeader."No."));
        PurchaseHeader.Insert(false);
    end;

    local procedure GetEDocumentCreateRequest(EDocumentServiceCode: Code[20]; var JSONRequest: Text)
    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
    begin
        JSONRequest := LibraryGraphMgt.AddPropertytoJSON(JSONRequest, 'eDocumentService', EDocumentServiceCode);
        JSONRequest := LibraryGraphMgt.AddPropertytoJSON(JSONRequest, 'base64file', NavApp.GetResourceAsText('API/base64file.txt', TextEncoding::UTF8));
        JSONRequest := LibraryGraphMgt.AddPropertytoJSON(JSONRequest, 'fileName', 'test.xml');
        JSONRequest := LibraryGraphMgt.AddPropertytoJSON(JSONRequest, 'processDocument', 'false');
    end;
}
