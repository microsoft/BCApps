// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Compensations;

using Microsoft.Foundation.Reporting;

codeunit 11766 "Rep. Sel. Manual Handler CZC"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
        PostedCompensationHeaderCZC: Record "Posted Compensation Header CZC";

    procedure SetCompensationHeader(NewCompensationHeaderCZC: Record "Compensation Header CZC")
    begin
        CompensationHeaderCZC := NewCompensationHeaderCZC;
    end;

    procedure SetPostedCompensationHeader(NewPostedCompensationHeaderCZC: Record "Posted Compensation Header CZC")
    begin
        PostedCompensationHeaderCZC := NewPostedCompensationHeaderCZC;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", OnAfterIsCustomerAccount, '', false, false)]
    local procedure OnAfterIsCustomerAccount(DocumentTableId: Integer; var IsCustomer: Boolean)
    begin
        case DocumentTableId of
            Database::"Compensation Header CZC":
                IsCustomer := CompensationHeaderCZC."Company Type" = CompensationHeaderCZC."Company Type"::Customer;
            Database::"Posted Compensation Header CZC":
                IsCustomer := PostedCompensationHeaderCZC."Company Type" = PostedCompensationHeaderCZC."Company Type"::Customer;
            else
                exit;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Report Selections", OnAfterIsVendorAccount, '', false, false)]
    local procedure OnAfterIsVendorAccount(DocumentTableId: Integer; var IsVendor: Boolean)
    begin
        case DocumentTableId of
            Database::"Compensation Header CZC":
                IsVendor := CompensationHeaderCZC."Company Type" = CompensationHeaderCZC."Company Type"::Vendor;
            Database::"Posted Compensation Header CZC":
                IsVendor := PostedCompensationHeaderCZC."Company Type" = PostedCompensationHeaderCZC."Company Type"::Vendor;
            else
                exit;
        end;
    end;
}