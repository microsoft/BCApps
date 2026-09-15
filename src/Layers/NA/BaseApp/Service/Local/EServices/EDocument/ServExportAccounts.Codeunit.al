// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Service.History;

codeunit 27090 "Serv. Export Accounts"
{

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Export Accounts", 'OnFindUUIDCFDI', '', true, true)]
    local procedure OnFindUUIDCFDI(SourceCode: Code[10]; SourceCodeSetup: Record "Source Code Setup"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; var UUID: Text)
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        case SourceCode of
            SourceCodeSetup."Service Management":
                case DocumentType of
                    DocumentType::Invoice:
                        if ServiceInvoiceHeader.Get(DocumentNo) then
                            UUID := ServiceInvoiceHeader."Fiscal Invoice Number PAC";
                    DocumentType::"Credit Memo":
                        if ServiceCrMemoHeader.Get(DocumentNo) then
                            UUID := ServiceCrMemoHeader."Fiscal Invoice Number PAC";
                end;
        end;
    end;
}
