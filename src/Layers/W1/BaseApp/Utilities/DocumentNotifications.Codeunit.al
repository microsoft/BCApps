// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Utilities;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using System.Environment.Configuration;
using System.Security.User;

codeunit 1390 "Document Notifications"
{

    trigger OnRun()
    begin
    end;

    procedure CopySellToCustomerAddressFieldsFromSalesDocument(var ModifyCustomerAddressNotification: Notification)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        UpdateAddress: Page "Update Address";
    begin
        if not ModifyCustomerAddressNotification.HasData(SalesHeader.FieldName("Sell-to Customer No.")) then
            exit;

        OnBeforeCopySellToCustomerAddressFieldsFromSalesDocument(ModifyCustomerAddressNotification, SalesHeader);

        // Document Type
        Evaluate(SalesHeader."Document Type", ModifyCustomerAddressNotification.GetData(SalesHeader.FieldName("Document Type")));
        SalesHeader.Get(SalesHeader."Document Type", ModifyCustomerAddressNotification.GetData(SalesHeader.FieldName("No.")));
        if Customer.Get(ModifyCustomerAddressNotification.GetData(SalesHeader.FieldName("Sell-to Customer No."))) then begin
            UpdateAddress.SetName(Customer.Name);
            UpdateAddress.SetExistingAddress(GetCustomerFullAddress(Customer));
            UpdateAddress.SetUpdatedAddress(GetSalesHeaderFullSellToAddress(SalesHeader));

            if UpdateAddress.RunModal() in [ACTION::OK, ACTION::LookupOK] then begin
                Customer.SetAddress(SalesHeader."Sell-to Address", SalesHeader."Sell-to Address 2",
                  SalesHeader."Sell-to Post Code", SalesHeader."Sell-to City", SalesHeader."Sell-to County",
                  SalesHeader."Sell-to Country/Region Code", SalesHeader."Sell-to Contact");
                OnCopySellToCustomerAddressFieldsFromSalesDocumentOnBeforeModify(Customer, SalesHeader);
                Customer.Modify(true);
            end;
        end;
    end;

    procedure CopyBillToCustomerAddressFieldsFromSalesDocument(ModifyCustomerAddressNotification: Notification)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        UpdateAddress: Page "Update Address";
    begin
        if not ModifyCustomerAddressNotification.HasData(SalesHeader.FieldName("Bill-to Customer No.")) then
            exit;

        OnBeforeCopyBillToCustomerAddressFieldsFromSalesDocument(ModifyCustomerAddressNotification, SalesHeader);

        // Document Type
        Evaluate(SalesHeader."Document Type", ModifyCustomerAddressNotification.GetData(SalesHeader.FieldName("Document Type")));
        SalesHeader.Get(SalesHeader."Document Type", ModifyCustomerAddressNotification.GetData(SalesHeader.FieldName("No.")));
        if Customer.Get(ModifyCustomerAddressNotification.GetData(SalesHeader.FieldName("Bill-to Customer No."))) then begin
            UpdateAddress.SetExistingAddress(GetCustomerFullAddress(Customer));
            UpdateAddress.SetName(Customer.Name);
            UpdateAddress.SetUpdatedAddress(GetSalesHeaderFullBillToAddress(SalesHeader));

            if UpdateAddress.RunModal() in [ACTION::OK, ACTION::LookupOK] then begin
                Customer.SetAddress(SalesHeader."Bill-to Address", SalesHeader."Bill-to Address 2",
                  SalesHeader."Bill-to Post Code", SalesHeader."Bill-to City", SalesHeader."Bill-to County",
                  SalesHeader."Bill-to Country/Region Code", SalesHeader."Bill-to Contact");
                OnCopyBillToCustomerAddressFieldsFromSalesDocumentOnBeforeModify(Customer, SalesHeader);
                Customer.Modify(true);
            end;
        end;
    end;

    local procedure GetCustomerFullAddress(Customer: Record Customer) Result: Text
    var
        AddressArray: array[7] of Text;
    begin
        AddressArray[1] := Customer.Address;
        AddressArray[2] := Customer."Address 2";
        AddressArray[3] := Customer."Post Code";
        AddressArray[4] := Customer.City;
        AddressArray[5] := Customer.County;
        AddressArray[6] := Customer."Country/Region Code";
        AddressArray[7] := Customer.Contact;

        Result := FormatAddress(AddressArray);
        OnAfterGetCustomerFullAddress(AddressArray, Customer, Result);
    end;

    local procedure GetSalesHeaderFullSellToAddress(SalesHeader: Record "Sales Header"): Text
    var
        AddressArray: array[7] of Text;
    begin
        AddressArray[1] := SalesHeader."Sell-to Address";
        AddressArray[2] := SalesHeader."Sell-to Address 2";
        AddressArray[3] := SalesHeader."Sell-to Post Code";
        AddressArray[4] := SalesHeader."Sell-to City";
        AddressArray[5] := SalesHeader."Sell-to County";
        AddressArray[6] := SalesHeader."Sell-to Country/Region Code";
        AddressArray[7] := SalesHeader."Sell-to Contact";

        exit(FormatAddress(AddressArray));
    end;

    local procedure GetSalesHeaderFullBillToAddress(SalesHeader: Record "Sales Header"): Text
    var
        AddressArray: array[7] of Text;
    begin
        AddressArray[1] := SalesHeader."Bill-to Address";
        AddressArray[2] := SalesHeader."Bill-to Address 2";
        AddressArray[3] := SalesHeader."Bill-to Post Code";
        AddressArray[4] := SalesHeader."Bill-to City";
        AddressArray[5] := SalesHeader."Bill-to County";
        AddressArray[6] := SalesHeader."Bill-to Country/Region Code";
        AddressArray[7] := SalesHeader."Bill-to Contact";

        exit(FormatAddress(AddressArray));
    end;

    local procedure FormatAddress(AddressArray: array[7] of Text): Text
    var
        FullAddress: Text;
        Index: Integer;
    begin
        for Index := 1 to 7 do
            if AddressArray[Index] <> '' then
                FullAddress := FullAddress + AddressArray[Index] + ', ';

        if StrLen(FullAddress) > 0 then
            FullAddress := DelStr(FullAddress, StrLen(FullAddress) - 1);

        exit(FullAddress);
    end;

    procedure HideNotificationForCurrentUser(Notification: Notification)
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.DontNotifyCurrentUserAgain(Notification.Id);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableModifyCustomerAddressNotificationOnInitializingWithDefaultState()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetModifyCustomerAddressNotificationDefaultState();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableModifyBillToCustomerAddressNotificationOnInitializingWithDefaultState()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetModifyBillToCustomerAddressNotificationDefaultState();
    end;

    procedure CopyBuyFromVendorAddressFieldsFromSalesDocument(var ModifyVendorAddressNotification: Notification)
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        UpdateAddress: Page "Update Address";
    begin
        if not ModifyVendorAddressNotification.HasData(PurchaseHeader.FieldName("Buy-from Vendor No.")) then
            exit;

        OnBeforeCopyBuyFromVendorAddressFieldsFromSalesDocument(ModifyVendorAddressNotification, PurchaseHeader);

        // Document Type
        Evaluate(PurchaseHeader."Document Type", ModifyVendorAddressNotification.GetData(PurchaseHeader.FieldName("Document Type")));
        PurchaseHeader.Get(PurchaseHeader."Document Type", ModifyVendorAddressNotification.GetData(PurchaseHeader.FieldName("No.")));
        if Vendor.Get(ModifyVendorAddressNotification.GetData(PurchaseHeader.FieldName("Buy-from Vendor No."))) then begin
            UpdateAddress.SetName(Vendor.Name);
            UpdateAddress.SetExistingAddress(GetVendorFullAddress(Vendor));
            UpdateAddress.SetUpdatedAddress(GetPurchaseHeaderFullBuyFromAddress(PurchaseHeader));

            if UpdateAddress.RunModal() in [ACTION::OK, ACTION::LookupOK] then begin
                Vendor.SetAddress(PurchaseHeader."Buy-from Address", PurchaseHeader."Buy-from Address 2",
                  PurchaseHeader."Buy-from Post Code", PurchaseHeader."Buy-from City", PurchaseHeader."Buy-from County",
                  PurchaseHeader."Buy-from Country/Region Code", PurchaseHeader."Buy-from Contact");
                OnCopyBuyFromVendorAddressFieldsFromSalesDocumentOnBeforeModify(Vendor, PurchaseHeader);
                Vendor.Modify(true);
            end;
        end;
    end;

    procedure CopyPayToVendorAddressFieldsFromSalesDocument(ModifyVendorAddressNotification: Notification)
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        UpdateAddress: Page "Update Address";
    begin
        if not ModifyVendorAddressNotification.HasData(PurchaseHeader.FieldName("Pay-to Vendor No.")) then
            exit;

        OnBeforeCopyPayToVendorAddressFieldsFromSalesDocument(ModifyVendorAddressNotification, PurchaseHeader);

        // Document Type
        Evaluate(PurchaseHeader."Document Type", ModifyVendorAddressNotification.GetData(PurchaseHeader.FieldName("Document Type")));
        PurchaseHeader.Get(PurchaseHeader."Document Type", ModifyVendorAddressNotification.GetData(PurchaseHeader.FieldName("No.")));
        if Vendor.Get(ModifyVendorAddressNotification.GetData(PurchaseHeader.FieldName("Pay-to Vendor No."))) then begin
            UpdateAddress.SetName(Vendor.Name);
            UpdateAddress.SetUpdatedAddress(GetPurchaseHeaderFullPayToAddress(PurchaseHeader));
            UpdateAddress.SetExistingAddress(GetVendorFullAddress(Vendor));

            if UpdateAddress.RunModal() in [ACTION::OK, ACTION::LookupOK] then begin
                Vendor.SetAddress(PurchaseHeader."Pay-to Address", PurchaseHeader."Pay-to Address 2",
                  PurchaseHeader."Pay-to Post Code", PurchaseHeader."Pay-to City", PurchaseHeader."Pay-to County",
                  PurchaseHeader."Pay-to Country/Region Code", PurchaseHeader."Pay-to Contact");
                OnCopyPayToVendorAddressFieldsFromSalesDocumentOnBeforeModify(Vendor, PurchaseHeader);
                Vendor.Modify(true);
            end;
        end;
    end;

    procedure ShowVendorLedgerEntry(Notification: Notification)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        EntryNo: Integer;
    begin
        if not Notification.HasData(VendorLedgerEntry.FieldName("Entry No.")) then
            exit;

        Evaluate(EntryNo, Notification.GetData(VendorLedgerEntry.FieldName("Entry No.")));
        VendorLedgerEntry.Get(EntryNo);
        VendorLedgerEntry.SetRecFilter();

        PAGE.RunModal(PAGE::"Vendor Ledger Entries", VendorLedgerEntry);
    end;

    procedure ShowGLSetup(Notification: Notification)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        PAGE.RunModal(PAGE::"General Ledger Setup", GeneralLedgerSetup);
    end;

    procedure ShowUserSetup(Notification: Notification)
    var
        UserSetup: Record "User Setup";
    begin
        UserSetup.SetRange("User ID", UserId);
        PAGE.RunModal(PAGE::"User Setup", UserSetup);
    end;

    local procedure GetVendorFullAddress(Vendor: Record Vendor) Result: Text
    var
        AddressArray: array[7] of Text;
    begin
        AddressArray[1] := Vendor.Address;
        AddressArray[2] := Vendor."Address 2";
        AddressArray[3] := Vendor."Post Code";
        AddressArray[4] := Vendor.City;
        AddressArray[5] := Vendor.County;
        AddressArray[6] := Vendor."Country/Region Code";
        AddressArray[7] := Vendor.Contact;

        Result := FormatAddress(AddressArray);
        OnAfterGetVendorFullAddress(AddressArray, Vendor, Result);
    end;

    local procedure GetPurchaseHeaderFullBuyFromAddress(PurchaseHeader: Record "Purchase Header"): Text
    var
        AddressArray: array[7] of Text;
    begin
        AddressArray[1] := PurchaseHeader."Buy-from Address";
        AddressArray[2] := PurchaseHeader."Buy-from Address 2";
        AddressArray[3] := PurchaseHeader."Buy-from Post Code";
        AddressArray[4] := PurchaseHeader."Buy-from City";
        AddressArray[5] := PurchaseHeader."Buy-from County";
        AddressArray[6] := PurchaseHeader."Buy-from Country/Region Code";
        AddressArray[7] := PurchaseHeader."Buy-from Contact";

        exit(FormatAddress(AddressArray));
    end;

    local procedure GetPurchaseHeaderFullPayToAddress(PurchaseHeader: Record "Purchase Header"): Text
    var
        AddressArray: array[7] of Text;
    begin
        AddressArray[1] := PurchaseHeader."Pay-to Address";
        AddressArray[2] := PurchaseHeader."Pay-to Address 2";
        AddressArray[3] := PurchaseHeader."Pay-to Post Code";
        AddressArray[4] := PurchaseHeader."Pay-to City";
        AddressArray[5] := PurchaseHeader."Pay-to County";
        AddressArray[6] := PurchaseHeader."Pay-to Country/Region Code";
        AddressArray[7] := PurchaseHeader."Pay-to Contact";

        exit(FormatAddress(AddressArray));
    end;

    procedure HidePurchaseNotificationForCurrentUser(Notification: Notification)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.DontNotifyCurrentUserAgain(Notification.Id);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableModifyVendorAddressNotificationOnInitializingWithDefaultState()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetModifyVendorAddressNotificationDefaultState();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableModifyPayToVendorAddressNotificationOnInitializingWithDefaultState()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetModifyPayToVendorAddressNotificationDefaultState();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnablePurchExternalDocAlreadyExistNotificationOnInitializingWithDefaultState()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetShowExternalDocAlreadyExistNotificationDefaultState(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableSalesExternalDocAlreadyExistNotificationOnInitializingWithDefaultState()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetShowExternalDocAlreadyExistNotificationDefaultState(true);
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableWarningWhenPostingSalesQtyZero()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetWarnZeroQuantitySalesPosting();
    end;

    [EventSubscriber(ObjectType::Page, Page::"My Notifications", 'OnInitializingNotificationWithDefaultState', '', false, false)]
    local procedure EnableWarningWhenPostingPurchaseQtyZero()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetWarnZeroQuantityPurchasePosting();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCustomerFullAddress(AddressArray: array[7] of Text; Customer: Record Customer; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetVendorFullAddress(AddressArray: array[7] of Text; Vendor: Record Vendor; var Result: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyBillToCustomerAddressFieldsFromSalesDocument(var ModifyCustomerAddressNotification: Notification; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopySellToCustomerAddressFieldsFromSalesDocument(var ModifyCustomerAddressNotification: Notification; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyBuyFromVendorAddressFieldsFromSalesDocument(var ModifyVendorAddressNotification: Notification; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyPayToVendorAddressFieldsFromSalesDocument(var ModifyVendorAddressNotification: Notification; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyBillToCustomerAddressFieldsFromSalesDocumentOnBeforeModify(var Customer: Record Customer; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopySellToCustomerAddressFieldsFromSalesDocumentOnBeforeModify(var Customer: Record Customer; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyBuyFromVendorAddressFieldsFromSalesDocumentOnBeforeModify(var Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyPayToVendorAddressFieldsFromSalesDocumentOnBeforeModify(var Vendor: Record Vendor; PurchaseHeader: Record "Purchase Header")
    begin
    end;
}

