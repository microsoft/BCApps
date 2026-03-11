// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 139609 "Shpfy Order Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        isInitialized: Boolean;

    local procedure Initialize();

    begin
        if isInitialized then
            exit;
        LibraryRandom.Init();
        isInitialized := true;
    end;

    [Test]
    procedure TestSalesOrderWithShopifyOrderNo()
    var
        ShopifyOrderNo: Code[50];
    begin
        Initialize();
        ShopifyOrderNo := CopyStr(LibraryRandom.RandText(MaxStrLen(ShopifyOrderNo)), 1, MaxStrLen(ShopifyOrderNo));
        Assert.AreEqual(ShopifyOrderNo, CreateSalesOrder(ShopifyOrderNo), 'Shpfy Order No. must be the same as on the order');
        ShopifyOrderNo := '';
        Assert.AreEqual(ShopifyOrderNo, CreateSalesOrder(ShopifyOrderNo), 'Shpfy Order No. must be blank');

    end;

    [Test]
    procedure TestSalesOrderArchive()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        SalesLineArchive: Record "Sales Line Archive";
        ShopifyOrderNo: Code[50];
    begin
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        ShopifyOrderNo := CopyStr(LibraryRandom.RandText(MaxStrLen(ShopifyOrderNo)), 1, MaxStrLen(ShopifyOrderNo));
        CreateSalesOrder(ShopifyOrderNo, SalesHeader);
        SalesHeaderArchive.SetRange("Document Type", SalesHeaderArchive."Document Type"::Order);
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindLast();
        Assert.AreEqual(ShopifyOrderNo, SalesHeaderArchive."Shpfy Order No.", 'Shpfy Order No. must be the same as on the order header');
        SalesLineArchive.SetRange("Document Type", SalesLineArchive."Document Type"::Order);
        SalesLineArchive.SetRange("Document No.", SalesHeaderArchive."No.");
        SalesLineArchive.FindLast();
        Assert.AreEqual(ShopifyOrderNo, SalesLineArchive."Shpfy Order No.", 'Shpfy Order No. must be the same as on the order line');
    end;

    local procedure CreateSalesOrder(ShopifyOrderNo: Code[50]): Code[50]
    var
        SalesHeader: Record "Sales Header";
    begin
        exit(CreateSalesOrder(ShopifyOrderNo, SalesHeader));
    end;

    local procedure CreateSalesOrder(ShopifyOrderNo: Code[50]; var SalesHeader: Record "Sales Header"): Code[50]
    var
        Customer: Record Customer;
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesLine: Record "Sales Line";
        OrderNo: Code[50];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesOrder(SalesHeader);
        OrderNo := SalesHeader."No.";
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesHeader."Shpfy Order No." := ShopifyOrderNo;
        SalesHeader.Modify();
        SalesLine."Shpfy Order No." := ShopifyOrderNo;
        SalesLine.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."Shpfy Order No.");
    end;

}
