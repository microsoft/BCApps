// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument.Interfactura.Tests;

using Microsoft.EServices.EDocument;

codeunit 148755 "E-Document Service Setup Tests"
{
    Subtype = Test;
    Permissions = tabledata "E-Document Service" = rimd,
                  tabledata "E-Doc. Service Supported Type" = rimd;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CFDIFormatCreatesSupportedSourceDocumentTypes()
    var
        EDocumentService: Record "E-Document Service";
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Selecting CFDI creates all supported Mexican source document types
        Initialize();

        // [GIVEN] A new E-Document Service
        EDocumentService.Code := 'MX-TEST';
        EDocumentService.Insert();

        // [WHEN] CFDI is selected as the document format
        EDocumentService.Validate("Document Format", EDocumentService."Document Format"::CFDI);
        EDocumentService.Modify();

        // [THEN] Sales Invoice is supported
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Sales Invoice");

        // [THEN] Sales Credit Memo is supported
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Sales Credit Memo");

        // [THEN] Service Invoice is supported
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Service Invoice");

        // [THEN] Service Credit Memo is supported
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Service Credit Memo");

        // [THEN] Sales Shipment is supported
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Sales Shipment");

        // [THEN] Transfer Shipment is supported
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Transfer Shipment");

        // [THEN] Purchase Invoice and Purchase Credit Memo are supported for incoming documents
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Purchase Invoice");
        Assert.AreEqual(SupportedType.Direction::Incoming, SupportedType.Direction, 'Purchase Invoice must be supported for incoming documents only.');
        VerifySupportedType(SupportedType, EDocumentService.Code, "E-Document Type"::"Purchase Credit Memo");
        Assert.AreEqual(SupportedType.Direction::Incoming, SupportedType.Direction, 'Purchase Credit Memo must be supported for incoming documents only.');
    end;

    [Test]
    procedure CFDIFormatDoesNotDuplicateSupportedTypesOnReconfigure()
    var
        EDocumentService: Record "E-Document Service";
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        // [FEATURE] [AI test 0.4]
        // [SCENARIO] Reconfiguring the CFDI format should not duplicate the supported source document types
        Initialize();

        // [GIVEN] A new CFDI service
        EDocumentService.Code := 'MX-RECONFIG';
        EDocumentService.Insert();

        // [WHEN] The service is set to CFDI twice
        EDocumentService.Validate("Document Format", EDocumentService."Document Format"::CFDI);
        EDocumentService.Modify();
        EDocumentService.Validate("Document Format", EDocumentService."Document Format"::CFDI);
        EDocumentService.Modify();

        // [THEN] Each supported source document type is still unique for the service
        SupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        SupportedType.SetRange("Source Document Type", "E-Document Type"::"Sales Invoice");
        Assert.RecordCount(SupportedType, 1);
        SupportedType.SetRange("Source Document Type", "E-Document Type"::"Sales Shipment");
        Assert.RecordCount(SupportedType, 1);
        SupportedType.SetRange("Source Document Type", "E-Document Type"::"Purchase Invoice");
        Assert.RecordCount(SupportedType, 1);
    end;

    local procedure Initialize()
    var
        EDocumentService: Record "E-Document Service";
        SupportedType: Record "E-Doc. Service Supported Type";
    begin
        SupportedType.SetRange("E-Document Service Code", 'MX-TEST');
        SupportedType.DeleteAll();
        EDocumentService.SetRange(Code, 'MX-TEST');
        EDocumentService.DeleteAll();
    end;

    local procedure VerifySupportedType(var SupportedType: Record "E-Doc. Service Supported Type"; ServiceCode: Code[20]; DocumentType: Enum "E-Document Type")
    begin
        SupportedType.SetRange("E-Document Service Code", ServiceCode);
        SupportedType.SetRange("Source Document Type", DocumentType);
        Assert.RecordCount(SupportedType, 1);
        SupportedType.FindFirst();
    end;
}
