// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

codeunit 11366 "VAT Statement Line NL"
{

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Line", OnAfterValidateEvent, 'Type', false, false)]
    local procedure OnAfterValidateEventType(var Rec: Record "VAT Statement Line"; xRec: Record "VAT Statement Line")
    begin
        if Rec.Type <> xRec.Type then
            Rec.UpdateElecTaxDeclCategoryCode();
    end;
}
