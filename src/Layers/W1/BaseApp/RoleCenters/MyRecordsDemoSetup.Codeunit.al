// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.RoleCenters;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Company;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment;
using System.Environment.Configuration;

codeunit 280 "My Records Demo Setup"
{
    Permissions = TableData Customer = r,
                  TableData Vendor = r,
                  TableData Item = r,
                  TableData "My Customer" = rimd,
                  TableData "My Vendor" = rimd,
                  TableData "My Item" = rimd,
                  TableData "My Account" = rimd;

    trigger OnRun()
    begin
    end;

    local procedure SetupMyRecords()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
    begin
        if not GuiAllowed() then
            exit;

        if ClientTypeManagement.GetCurrentClientType() = ClientType::Background then
            exit;

        if GetExecutionContext() <> ExecutionContext::Normal then
            exit;

        if not CompanyInformationMgt.IsDemoCompany() then
            exit;

        if SetupMyCustomer() then
            exit;

        if SetupMyItem() then
            exit;

        if SetupMyVendor() then
            exit;

        SetupMyAccount();
    end;

    local procedure SetupMyCustomer(): Boolean
    var
        Customer: Record Customer;
        MyCustomer: Record "My Customer";
        MaxCustomersToAdd: Integer;
        I: Integer;
    begin
        if not Customer.ReadPermission then
            exit;

        MyCustomer.SetRange("User ID", UserId);
        if not MyCustomer.IsEmpty() then
            exit(true);

        I := 0;
        MaxCustomersToAdd := 5;
        Customer.SetFilter(Balance, '<>0');
        if Customer.FindSet() then
            repeat
                I += 1;
                MyCustomer."User ID" := CopyStr(UserId(), 1, MaxStrLen(MyCustomer."User ID"));
                MyCustomer.Validate("Customer No.", Customer."No.");
                if MyCustomer.Insert() then;
            until (Customer.Next() = 0) or (I >= MaxCustomersToAdd);
    end;

    local procedure SetupMyItem(): Boolean
    var
        Item: Record Item;
        MyItem: Record "My Item";
        MaxItemsToAdd: Integer;
        I: Integer;
    begin
        if not Item.ReadPermission then
            exit;

        MyItem.SetRange("User ID", UserId);
        if not MyItem.IsEmpty() then
            exit(true);

        I := 0;
        MaxItemsToAdd := 5;

        Item.SetFilter("Unit Price", '<>0');
        if Item.FindSet() then
            repeat
                I += 1;
                MyItem."User ID" := CopyStr(UserId(), 1, MaxStrLen(MyItem."User ID"));
                MyItem.Validate("Item No.", Item."No.");
                if MyItem.Insert() then;
            until (Item.Next() = 0) or (I >= MaxItemsToAdd);
    end;

    local procedure SetupMyVendor(): Boolean
    var
        Vendor: Record Vendor;
        MyVendor: Record "My Vendor";
        MaxVendorsToAdd: Integer;
        I: Integer;
    begin
        if not Vendor.ReadPermission then
            exit;

        MyVendor.SetRange("User ID", UserId);
        if not MyVendor.IsEmpty() then
            exit(true);

        I := 0;
        MaxVendorsToAdd := 5;
        Vendor.SetFilter(Balance, '<>0');
        if Vendor.FindSet() then
            repeat
                I += 1;
                MyVendor."User ID" := CopyStr(UserId(), 1, MaxStrLen(MyVendor."User ID"));
                MyVendor.Validate("Vendor No.", Vendor."No.");
                if MyVendor.Insert() then;
            until (Vendor.Next() = 0) or (I >= MaxVendorsToAdd);
    end;

    local procedure SetupMyAccount(): Boolean
    var
        GLAccount: Record "G/L Account";
        MyAccount: Record "My Account";
        MaxAccountsToAdd: Integer;
        I: Integer;
    begin
        if not GLAccount.ReadPermission then
            exit;

        MyAccount.SetRange("User ID", UserId);
        if not MyAccount.IsEmpty() then
            exit(true);

        I := 0;
        MaxAccountsToAdd := 5;
        GLAccount.SetRange("Reconciliation Account", true);
        if GLAccount.FindSet() then
            repeat
                I += 1;
                MyAccount."User ID" := CopyStr(UserId(), 1, MaxStrLen(MyAccount."User ID"));
                MyAccount.Validate("Account No.", GLAccount."No.");
                if MyAccount.Insert() then;
            until (GLAccount.Next() = 0) or (I >= MaxAccountsToAdd);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLoginSubscriber()
    begin
        SetupMyRecords();
    end;
}
