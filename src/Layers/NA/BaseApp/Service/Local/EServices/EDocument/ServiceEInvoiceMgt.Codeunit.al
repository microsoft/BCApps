// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Service.Document;
using Microsoft.Service.History;

codeunit 27006 "Service E-Invoice Mgt."
{

    [EventSubscriber(ObjectType::Table, Database::"CFDI Relation Document", 'OnAfterInsertRelatedCreditMemos', '', true, true)]
    local procedure OnAfterInsertRelatedCreditMemos(var Rec: Record "CFDI Relation Document")
    begin
        case Rec."Document Table ID" of
            DATABASE::"Service Header", DATABASE::"Service Invoice Header":
                InsertRelatedServiceCreditMemos(Rec);
            else
        end;
    end;

    local procedure InsertRelatedServiceCreditMemos(var Rec: Record "CFDI Relation Document")
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        CFDIRelationDocument: Record "CFDI Relation Document";
    begin
        if Rec."Related Doc. Type" <> Rec."Related Doc. Type"::Invoice then
            exit;

        ServiceCrMemoHeader.SetRange("Bill-to Customer No.", Rec."Customer No.");
        ServiceCrMemoHeader.SetRange("Applies-to Doc. Type", ServiceCrMemoHeader."Applies-to Doc. Type"::Invoice);
        ServiceCrMemoHeader.SetRange("Applies-to Doc. No.", Rec."Related Doc. No.");
        if not ServiceCrMemoHeader.FindSet() then
            exit;

        repeat
            CFDIRelationDocument := Rec;
            CFDIRelationDocument."Related Doc. Type" := CFDIRelationDocument."Related Doc. Type"::"Credit Memo";
            CFDIRelationDocument."Related Doc. No." := ServiceCrMemoHeader."No.";
            CFDIRelationDocument."Fiscal Invoice Number PAC" := ServiceCrMemoHeader."Fiscal Invoice Number PAC";
            if CFDIRelationDocument.Insert() then;
        until ServiceCrMemoHeader.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"CFDI Relation Document", 'OnAfterUpdateFiscalInvoiceNumber', '', true, true)]
    local procedure OnAfterUpdateFiscalInvoiceNumber(var Rec: Record "CFDI Relation Document")
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case Rec."Document Table ID" of
            DATABASE::"Service Header", DATABASE::"Service Invoice Header", DATABASE::"Service Cr.Memo Header":
                if Rec."Related Doc. Type" = Rec."Related Doc. Type"::Invoice then begin
                    ServiceInvoiceHeader.Get(Rec."Related Doc. No.");
                    Rec."Fiscal Invoice Number PAC" := ServiceInvoiceHeader."Fiscal Invoice Number PAC";
                end else begin
                    ServiceCrMemoHeader.Get(Rec."Related Doc. No.");
                    Rec."Fiscal Invoice Number PAC" := ServiceCrMemoHeader."Fiscal Invoice Number PAC";
                end;
        end;
    end;
}