// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Integration.Sharepoint;

using System.Integration.Graph.Authorization;
using System.RestClient;

codeunit 132974 "SharePoint Graph Auth Mock" implements "Graph Authorization"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Invoked: Boolean;

    procedure IsInvoked(): Boolean
    begin
        exit(Invoked);
    end;

    procedure GetHttpAuthorization(): Interface "Http Authentication";
    var
        HttpAuthenticationAnonymous: Codeunit "Http Authentication Anonymous";
    begin
        Invoked := true;
        exit(HttpAuthenticationAnonymous);
    end;
}