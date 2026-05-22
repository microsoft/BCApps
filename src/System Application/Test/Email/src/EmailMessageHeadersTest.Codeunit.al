// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Email;

using System.Email;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

codeunit 134707 "Email Message Headers Test"
{
    Subtype = Test;
    Permissions = tabledata "Email Message" = rm;

    var
        Assert: Codeunit "Library Assert";
        PermissionsMock: Codeunit "Permissions Mock";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure RoundTripsHeadersJson()
    var
        Message: Codeunit "Email Message";
        HeadersJson: JsonObject;
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');
        HeadersJson.Add('authentication-results', 'spf=pass');
        HeadersJson.Add('x-ms-exchange-organization-authas', 'Internal');
        Message.SetHeaders(HeadersJson);

        Assert.IsTrue(Message.Get(Message.GetId()), 'Message not found after reload');
        Assert.IsTrue(Message.TryGetHeader('Authentication-Results', Value), 'Header lookup should succeed case-insensitively');
        Assert.AreEqual('spf=pass', Value, 'Authentication-Results header value mismatch');
        Assert.IsTrue(Message.TryGetHeader('X-MS-Exchange-Organization-AuthAs', Value), 'AuthAs header lookup should succeed');
        Assert.AreEqual('Internal', Value, 'AuthAs header value mismatch');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure TryGetHeaderReturnsFalseOnEmptyBlob()
    var
        Message: Codeunit "Email Message";
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');

        Assert.IsFalse(Message.TryGetHeader('any-header', Value), 'Empty blob should return false');
        Assert.AreEqual('', Value, 'Value should be empty when no headers stored');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure SetHeadersWithEmptyJsonClearsBlob()
    var
        Message: Codeunit "Email Message";
        HeadersJson: JsonObject;
        EmptyHeadersJson: JsonObject;
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');
        HeadersJson.Add('authentication-results', 'spf=pass');
        Message.SetHeaders(HeadersJson);

        Message.SetHeaders(EmptyHeadersJson);

        Assert.IsTrue(Message.Get(Message.GetId()), 'Message not found after reload');
        Assert.IsFalse(Message.TryGetHeader('Authentication-Results', Value), 'Headers should be cleared after empty SetHeaders');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure MultiValueHeaderRetainsAllValuesJoinedWithLineFeed()
    var
        Message: Codeunit "Email Message";
        HeadersJson: JsonObject;
        Value: Text;
    begin
        PermissionsMock.Set('Email Edit');

        Message.Create('to@test.com', 'subject', 'body');
        HeadersJson.Add('received', 'from hop1' + #10 + 'from hop2');
        Message.SetHeaders(HeadersJson);

        Assert.IsTrue(Message.Get(Message.GetId()), 'Message not found after reload');
        Assert.IsTrue(Message.TryGetHeader('Received', Value), 'Multi-value header lookup should succeed');
        Assert.AreEqual('from hop1' + #10 + 'from hop2', Value, 'Multi-value header should preserve line-feed joiner');
    end;
}
