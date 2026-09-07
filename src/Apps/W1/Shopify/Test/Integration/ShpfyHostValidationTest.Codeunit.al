// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

/// <summary>
/// Unit tests for the Shopify shop hostname validation used before the OAuth authorize and token
/// endpoints are called. Only *.myshopify.com hostnames are accepted so the Microsoft-owned client
/// secret and authorization code cannot be redirected to a malicious host.
/// </summary>
codeunit 139649 "Shpfy Host Validation Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";

    [Test]
    procedure ValidMyShopifyHostnamesAreAccepted()
    begin
        // [SCENARIO] A genuine *.myshopify.com hostname is accepted.
        LibraryAssert.IsTrue(AuthenticationMgt.IsValidHostName('test-shop.myshopify.com'), 'A myshopify.com hostname should be valid.');
        LibraryAssert.IsTrue(AuthenticationMgt.IsValidHostName('my-store123.myshopify.com'), 'A myshopify.com hostname should be valid.');
    end;

    [Test]
    procedure ForeignHostnamesAreRejected()
    begin
        // [SCENARIO] Foreign or look-alike hostnames are rejected so credentials cannot be redirected.
        LibraryAssert.IsFalse(AuthenticationMgt.IsValidHostName('malicious.example.com'), 'A foreign hostname must be rejected.');
        LibraryAssert.IsFalse(AuthenticationMgt.IsValidHostName('test-shop.myshopify.com.evil.com'), 'A look-alike hostname must be rejected.');
        LibraryAssert.IsFalse(AuthenticationMgt.IsValidHostName('https://test-shop.myshopify.com'), 'A full URL is not a valid bare hostname.');
    end;
}
