// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using System.Reflection;

codeunit 6486 "Serv. VAT Specification Mgt."
{
    var
        CanOnlyBeModifiedErr: Label '%1 can only be modified on the %2 tab.', Comment = '%1 - field caption, %2 - page tab caption';
        DetailsTxt: Label 'Details';

    [EventSubscriber(ObjectType::Page, Page::"VAT Specification Subform", 'OnBeforeCheckAmountChange', '', false, false)]
    local procedure OnBeforeCheckAmountChange(ParentControl: Integer; AmountFieldCaption: Text);
    begin
        if ParentControl = PAGE::"Service Order Statistics" then
            Error(CanOnlyBeModifiedErr, AmountFieldCaption, DetailsTxt)
    end;

    [EventSubscriber(ObjectType::Page, Page::"VAT Specification Subform", 'OnAfterModifyRec', '', false, false)]
    local procedure OnAfterModifyRec(var SourceHeader: Variant; var VATAmountLine: Record "VAT Amount Line"; ParentControl: Integer; CurrentTabNo: Integer)
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(SourceHeader);
        if RecRef.Number <> ParentControl then
            exit;

        ServiceHeader := SourceHeader;
        if ((ParentControl = PAGE::"Service Order Statistics") and
            (CurrentTabNo <> 1))
        then
            if VATAmountLine.GetAnyLineModified() then begin
                ServiceLine.UpdateVATOnLines(0, ServiceHeader, ServiceLine, VATAmountLine);
                ServiceLine.UpdateVATOnLines(1, ServiceHeader, ServiceLine, VATAmountLine);
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"VAT Clause", 'OnGetDocumentTypeAndLanguageCode', '', false, false)]
    local procedure OnGetDocumentTypeAndLanguageCode(VATClause: Record "VAT Clause"; RecRelatedVariant: Variant; var DocumentType: Enum "VAT Clause Document Type"; var LanguageCode: Code[10]; var IsHandled: Boolean)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        RecRef: RecordRef;
    begin
        if DataTypeManagement.GetRecordRef(RecRelatedVariant, RecRef) then
            case RecRef.Number of
                Database::"Service Invoice Header":
                    begin
                        RecRef.SetTable(ServiceInvoiceHeader);
                        DocumentType := DocumentType::Invoice;
                        LanguageCode := ServiceInvoiceHeader."Language Code";
                        IsHandled := true;
                    end;
            end;
    end;
}
