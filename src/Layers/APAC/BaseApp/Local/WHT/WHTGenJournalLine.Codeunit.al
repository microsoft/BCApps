// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

codeunit 28043 "WHT Gen Journal Line"
{

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnCleanLineOnAfterUpdateCountryCodeAndVATRegNo', '', true, false)]
    local procedure OnCleanLineOnAfterUpdateCountryCodeAndVATRegNo(var Rec: Record "Gen. Journal Line"; var xRec: Record "Gen. Journal Line")
    begin
        Rec."WHT Business Posting Group" := '';
        Rec."WHT Product Posting Group" := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnGenJnlLineGetVendorAccount', '', true, false)]
    procedure OnGenJnlLineGetVendorAccount(Vendor: Record Vendor; var Rec: Record "Gen. Journal Line")
    begin
        Rec."Skip WHT" := Vendor.ABN <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnBeforeCheckConfirmDifferentVendorAndPayToVendor', '', true, false)]
    local procedure OnBeforeCheckConfirmDifferentVendorAndPayToVendor(var GenJorunalLine: Record "Gen. Journal Line"; Vendor: Record Vendor; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
        GenJorunalLine."WHT Business Posting Group" := Vendor."WHT Business Posting Group";
        GenJorunalLine."WHT Product Posting Group" := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnGetGLAccountOnAfterCopyVATSetupToJnlLines', '', true, false)]
    local procedure OnGetGLAccountOnAfterCopyVATSetupToJnlLines(var Rec: Record "Gen. Journal Line"; var GLAcc: Record "G/L Account")
    begin
        Rec."WHT Business Posting Group" := GLAcc."WHT Business Posting Group";
        Rec."WHT Product Posting Group" := GLAcc."WHT Product Posting Group";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnGetAccountNoOnAfterClearPostingGroupsForClosingDate', '', true, false)]
    local procedure OnGetAccountNoOnAfterClearPostingGroupsForClosingDate(var Rec: Record "Gen. Journal Line")
    begin
        Rec."WHT Business Posting Group" := '';
        Rec."WHT Product Posting Group" := '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Line", 'OnGetCustomerAccountOnBeforeValidatePaymentTermsCode', '', true, false)]
    local procedure OnGetCustomerAccountOnBeforeValidatePaymentTermsCode(var GenJournalLine: Record "Gen. Journal Line"; var Customer: Record Customer; HideValidationDialog: Boolean)
    begin
        GenJournalLine."WHT Business Posting Group" := Customer."WHT Business Posting Group";
        GenJournalLine."WHT Product Posting Group" := '';
    end;


}