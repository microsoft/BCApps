// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;

codeunit 139640 "E-Doc. Import Publisher Mock"
{
    EventSubscriberInstance = Manual;

    var
        OnBeforeLogErrorIfItemNotFoundCount: Integer;
        LastItemFoundOnEntry: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"E-Doc. Import", 'OnBeforeLogErrorIfItemNotFound', '', false, false)]
    local procedure CaptureOnBeforeLogErrorIfItemNotFound(EDocument: Record "E-Document"; SourceDocumentLine: RecordRef; EDocService: Record "E-Document Service"; var ItemFound: Boolean)
    begin
        OnBeforeLogErrorIfItemNotFoundCount += 1;
        LastItemFoundOnEntry := ItemFound;
    end;

    procedure GetOnBeforeLogErrorIfItemNotFoundCount(): Integer
    begin
        exit(OnBeforeLogErrorIfItemNotFoundCount);
    end;

    procedure GetLastItemFoundOnEntry(): Boolean
    begin
        exit(LastItemFoundOnEntry);
    end;
}
