// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139540 "Shpfy Host Validation Test"
{
    Subtype = Test;
    TestType = UnitTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        LibraryAssert: Codeunit "Library Assert";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";

    [Test]
    procedure ValidMyShopifyHostnamesAreAccepted()
    begin
        LibraryAssert.IsTrue(AuthenticationMgt.IsValidHostName('test-shop.myshopify.com'), 'A myshopify.com hostname should be valid.');
        LibraryAssert.IsTrue(AuthenticationMgt.IsValidHostName('my-store123.myshopify.com'), 'A myshopify.com hostname should be valid.');
    end;

    [Test]
    procedure ForeignHostnamesAreRejected()
    begin
        LibraryAssert.IsFalse(AuthenticationMgt.IsValidHostName('malicious.example.com'), 'A foreign hostname must be rejected.');
        LibraryAssert.IsFalse(AuthenticationMgt.IsValidHostName('test-shop.myshopify.com.evil.com'), 'A look-alike hostname must be rejected.');
        LibraryAssert.IsFalse(AuthenticationMgt.IsValidHostName('https://test-shop.myshopify.com'), 'A full URL is not a valid bare hostname.');
    end;

    [Test]
    procedure InstallRejectsForeignHostBeforeAuthorizing()
    var
        Shop: Record "Shpfy Shop";
    begin
        asserterror AuthenticationMgt.InstallShopifyApp('malicious.example.com', Shop);

        LibraryAssert.ExpectedError('The URL must refer to the internal shop location at myshopify.com.');
    end;
}
