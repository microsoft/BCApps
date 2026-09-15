// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.CashDesk;

using Microsoft.Foundation.Reporting;

codeunit 11771 "Rep. Sel. Manual Handler CZP"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        CashDocumentHeaderCZP: Record "Cash Document Header CZP";
        PostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP";

    procedure SetCashDocumentHeader(NewCashDocumentHeaderCZP: Record "Cash Document Header CZP")
    begin
        CashDocumentHeaderCZP := NewCashDocumentHeaderCZP;
    end;

    procedure SetPostedCashDocumentHeader(NewPostedCashDocumentHdrCZP: Record "Posted Cash Document Hdr. CZP")
    begin
        PostedCashDocumentHdrCZP := NewPostedCashDocumentHdrCZP;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", OnAfterIsCustomerAccount, '', false, false)]
    local procedure OnAfterIsCustomerAccount(DocumentTableId: Integer; var IsCustomer: Boolean)
    begin
        case DocumentTableId of
            Database::"Cash Document Header CZP":
                IsCustomer := CashDocumentHeaderCZP."Partner Type" = CashDocumentHeaderCZP."Partner Type"::Customer;
            Database::"Posted Cash Document Hdr. CZP":
                IsCustomer := PostedCashDocumentHdrCZP."Partner Type" = PostedCashDocumentHdrCZP."Partner Type"::Customer;
            else
                exit;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", OnAfterIsVendorAccount, '', false, false)]
    local procedure OnAfterIsVendorAccount(DocumentTableId: Integer; var IsVendor: Boolean)
    begin
        case DocumentTableId of
            Database::"Cash Document Header CZP":
                IsVendor := CashDocumentHeaderCZP."Partner Type" = CashDocumentHeaderCZP."Partner Type"::Vendor;
            Database::"Posted Cash Document Hdr. CZP":
                IsVendor := PostedCashDocumentHdrCZP."Partner Type" = PostedCashDocumentHdrCZP."Partner Type"::Vendor;
            else
                exit;
        end;
    end;
}