// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.EServices.EDocument;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using System.Automation;

codeunit 500 "Enum Assignment Management"
{
    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0470
        DocumentTypeEnumErr: Label '%1 Document Type %2 enum cannot be converted to %3 Document Type enum.';
#pragma warning restore AA0470

    procedure GetSalesApprovalDocumentType(SalesDocumentType: Enum "Sales Document Type") ApprovalDocumentType: Enum "Approval Document Type"
    var
        IsHandled: Boolean;
    begin
        case SalesDocumentType of
            SalesDocumentType::Quote:
                exit(ApprovalDocumentType::Quote);
            SalesDocumentType::Order:
                exit(ApprovalDocumentType::Order);
            SalesDocumentType::Invoice:
                exit(ApprovalDocumentType::Invoice);
            SalesDocumentType::"Credit Memo":
                exit(ApprovalDocumentType::"Credit Memo");
            SalesDocumentType::"Blanket Order":
                exit(ApprovalDocumentType::"Blanket Order");
            SalesDocumentType::"Return Order":
                exit(ApprovalDocumentType::"Return Order");
            else begin
                IsHandled := false;
                OnGetSalesApprovalDocumentType(SalesDocumentType, ApprovalDocumentType, IsHandled);
                if not IsHandled then
                    error(DocumentTypeEnumErr, 'Sales', SalesDocumentType, 'Approval');
            end;
        end;
    end;

    procedure GetSalesIncomingDocumentType(SalesDocumentType: Enum "Sales Document Type") IncomingDocumentType: Enum "Incoming Document Type"
    var
        IsHandled: Boolean;
    begin
        case SalesDocumentType of
            SalesDocumentType::Quote:
                exit(IncomingDocumentType::Quote);
            SalesDocumentType::Order:
                exit(IncomingDocumentType::Order);
            SalesDocumentType::Invoice:
                exit(IncomingDocumentType::Invoice);
            SalesDocumentType::"Credit Memo":
                exit(IncomingDocumentType::"Credit Memo");
            SalesDocumentType::"Blanket Order":
                exit(IncomingDocumentType::"Blanket Order");
            SalesDocumentType::"Return Order":
                exit(IncomingDocumentType::"Return Order");
            else begin
                IsHandled := false;
                OnGetSalesIncomingDocumentType(SalesDocumentType, IncomingDocumentType, IsHandled);
                if not IsHandled then
                    error(DocumentTypeEnumErr, 'Sales', SalesDocumentType, 'Incoming');
            end;
        end;
    end;

#if not CLEAN25
    [Obsolete('Replaced by sane procedure in codeunit ServDocExchangeMgt', '25.0')]
    procedure GetServiceIncomingDocumentType(ServiceDocumentType: Enum Microsoft.Service.Document."Service Document Type") IncomingDocumentType: Enum "Incoming Document Type"
    var
        ServDocExchangeMgt: Codeunit "Serv. Doc. Exchange Mgt.";
    begin
        exit(ServDocExchangeMgt.GetServiceIncomingDocumentType(ServiceDocumentType));
    end;
#endif

    procedure GetPurchApprovalDocumentType(PurchDocumentType: Enum "Purchase Document Type") ApprovalDocumentType: Enum "Approval Document Type"
    var
        IsHandled: Boolean;
    begin
        case PurchDocumentType of
            PurchDocumentType::Quote:
                exit(ApprovalDocumentType::Quote);
            PurchDocumentType::Order:
                exit(ApprovalDocumentType::Order);
            PurchDocumentType::Invoice:
                exit(ApprovalDocumentType::Invoice);
            PurchDocumentType::"Credit Memo":
                exit(ApprovalDocumentType::"Credit Memo");
            PurchDocumentType::"Blanket Order":
                exit(ApprovalDocumentType::"Blanket Order");
            PurchDocumentType::"Return Order":
                exit(ApprovalDocumentType::"Return Order");
            else begin
                IsHandled := false;
                OnGetPurchApprovalDocumentType(PurchDocumentType, ApprovalDocumentType, IsHandled);
                if not IsHandled then
                    error(DocumentTypeEnumErr, 'Purchase', PurchDocumentType, 'Approval');
            end;
        end;
    end;

    procedure GetPurchIncomingDocumentType(PurchDocumentType: Enum "Purchase Document Type") IncomingDocumentType: Enum "Incoming Document Type"
    var
        IsHandled: Boolean;
    begin
        case PurchDocumentType of
            PurchDocumentType::Quote:
                exit(IncomingDocumentType::Quote);
            PurchDocumentType::Order:
                exit(IncomingDocumentType::Order);
            PurchDocumentType::Invoice:
                exit(IncomingDocumentType::Invoice);
            PurchDocumentType::"Credit Memo":
                exit(IncomingDocumentType::"Credit Memo");
            PurchDocumentType::"Blanket Order":
                exit(IncomingDocumentType::"Blanket Order");
            PurchDocumentType::"Return Order":
                exit(IncomingDocumentType::"Return Order");
            else begin
                IsHandled := false;
                OnGetPurchIncomingDocumentType(PurchDocumentType, IncomingDocumentType, IsHandled);
                if not IsHandled then
                    error(DocumentTypeEnumErr, 'Purchase', PurchDocumentType, 'Incoming');
            end;
        end;
    end;

    procedure GetSalesLineTypeFromPurchLineType(PurchLineType: Enum "Purchase Line Type") SalesLineType: Enum "Sales Line Type"
    var
        IsHandled: Boolean;
    begin
        case PurchLineType of
            PurchLineType::" ":
                exit(SalesLineType::" ");
            PurchLineType::"G/L Account":
                exit(SalesLineType::"G/L Account");
            PurchLineType::Item:
                exit(SalesLineType::Item);
            PurchLineType::Resource:
                exit(SalesLineType::Resource);
            PurchLineType::"Fixed Asset":
                exit(SalesLineType::"Fixed Asset");
            PurchLineType::"Charge (Item)":
                exit(SalesLineType::"Charge (Item)");
            else begin
                IsHandled := false;
                OnGetSalesLineTypeFromPurchLineType(PurchLineType, SalesLineType, IsHandled);
                if not IsHandled then
                    error(DocumentTypeEnumErr, 'Purchase', PurchLineType, 'Sales');
            end;
        end;
    end;

    procedure GetPurchLineTypeFromSalesLineType(SalesLineType: Enum "Sales Line Type") PurchLineType: Enum "Purchase Line Type"
    var
        IsHandled: Boolean;
    begin
        case PurchLineType of
            SalesLineType::" ":
                exit(PurchLineType::" ");
            SalesLineType::"G/L Account":
                exit(PurchLineType::"G/L Account");
            SalesLineType::Item:
                exit(PurchLineType::Item);
            SalesLineType::Resource:
                exit(PurchLineType::Resource);
            SalesLineType::"Fixed Asset":
                exit(PurchLineType::"Fixed Asset");
            SalesLineType::"Charge (Item)":
                exit(PurchLineType::"Charge (Item)");
            else begin
                IsHandled := false;
                OnGetPurchLineTypeFromSalesLineType(SalesLineType, PurchLineType, IsHandled);
                if not IsHandled then
                    error(DocumentTypeEnumErr, 'Sales', SalesLineType, 'Purchase');
            end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesApprovalDocumentType(SalesDocumentType: Enum "Sales Document Type"; var ApprovalDocumentType: Enum "Approval Document Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesIncomingDocumentType(SalesDocumentType: Enum "Sales Document Type"; var IncomingDocumentType: Enum "Incoming Document Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchApprovalDocumentType(PurchDocumentType: Enum "Purchase Document Type"; var ApprovalDocumentType: Enum "Approval Document Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchIncomingDocumentType(PurchDocumentType: Enum "Purchase Document Type"; var IncomingDocumentType: Enum "Incoming Document Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSalesLineTypeFromPurchLineType(PurchLineType: Enum "Purchase Line Type"; var SalesLineType: Enum "Sales Line Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetPurchLineTypeFromSalesLineType(SalesLineType: Enum "Sales Line Type"; var PurchLineType: Enum "Purchase Line Type"; var IsHandled: Boolean)
    begin
    end;
}

