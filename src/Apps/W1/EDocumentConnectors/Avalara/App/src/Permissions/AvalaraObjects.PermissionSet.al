// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.EServices.EDocumentConnector.Avalara.Models;

/// <summary>
/// Grants execute permissions on all Avalara E-Document connector objects (tables, codeunits, pages).
/// </summary>
permissionset 6375 "Avalara Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'Avalara E-Doc. - Objects', MaxLength = 30;

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