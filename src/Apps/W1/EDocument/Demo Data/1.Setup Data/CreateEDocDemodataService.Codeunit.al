// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.DemoData;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;

codeunit 5424 "Create E-Doc DemoData Service"
{
    Access = Internal;

    trigger OnRun()
    begin
        CreateEDocService();
    end;

    local procedure CreateEDocService()
    var
        EDocumentService: Record "E-Document Service";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
    begin
        EDocumentService.Init();
        EDocumentService.Code := CopyStr(EDocumentServiceCode(), 1, MaxStrLen(EDocumentService.Code));
        EDocumentService."Import Process" := EDocumentService."Import Process"::"Version 2.0";
        EDocumentService."Automatic Import Processing" := "E-Doc. Automatic Processing"::No;
        EDocumentService.Insert(true);

        EDocServiceSupportedType.Init();
        EDocServiceSupportedType."E-Document Service Code" := EDocumentService.Code;
        EDocServiceSupportedType."Source Document Type" := EDocServiceSupportedType."Source Document Type"::"Purchase Invoice";
        EDocServiceSupportedType.Direction := EDocServiceSupportedType.Direction::Incoming;
        EDocServiceSupportedType.Insert(false);
    end;

    procedure EDocumentServiceCode(): Code[20]
    begin
        exit('E-DOC DEMO DATA');
    end;
}