#if not CLEAN26
#pragma warning disable AS0072 // Obsolete permission set
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.EServices.EDocumentConnector.Avalara.Models;

/// <summary>
/// Obsolete permission set granting execute access to Avalara objects. Replaced by permission set 6375 "Avalara Objects".
/// </summary>
permissionset 6370 Objects
{
    Access = Public;
    Assignable = false;
    Caption = 'Avalara E-Document Connector - Objects';
    ObsoleteReason = 'This permission set is obsolete. Use permission set 6375 "Avalara Objects" instead.';
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';

    Permissions =
                table "Activation Header" = X,
                table "Activation Mandate" = X,
                table "Avalara Company" = X,
                table "Avalara Document Buffer" = X,
                table "Avalara Input Field" = X,
                table "Avl Message Event" = X,
                table "Avl Message Response Header" = X,
                table "Connection Setup" = X,
                table Mandate = X,
                table "Media Types" = X,
                codeunit Activation = X,
                codeunit Authenticator = X,
                codeunit "Avalara Document Management" = X,
                codeunit "Avalara Functions" = X,
                codeunit "Http Executor" = X,
                codeunit "Integration Impl." = X,
                codeunit Maintenance = X,
                codeunit Metadata = X,
                codeunit Processing = X,
                codeunit Requests = X,
                codeunit Upgrade = X,
                page "Activation Card" = X,
                page "Activation List" = X,
                page "Activation Subform" = X,
                page "Avalara Documents" = X,
                page "Avalara Input Fields" = X,
                page "Avl Full Message Dialog" = X,
                page "Avl Message Events Subform" = X,
                page "Avl Message Response Card" = X,
                page "Company List" = X,
                page "Connection Setup Card" = X,
                page "Mandate List" = X;
}
#pragma warning restore AS0072 // Obsolete permission set
#endif