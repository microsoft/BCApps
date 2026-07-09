// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using Microsoft;
using Microsoft.Foundation.Navigate;
using System.Utilities;

codeunit 9165 "Help & Support Management"
{
    Permissions = TableData "Support Contact Information" = rimd;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetSupportInformation', '', true, true)]
    local procedure GetSupportInformation(var Name: Text; var Email: Text; var Url: Text)
    var
        SupportContactInformation: Record "Support Contact Information";
    begin
        OnBeforeGetSupportInformation(Name, Email, Url);

        if (Name <> '') or (Email <> '') or (Url <> '') then
            exit;

        if not SupportContactInformation.ReadPermission then
            exit;

        if not SupportContactInformation.Get() then
            exit;

        Name := SupportContactInformation.Name;
        Email := SupportContactInformation.Email;
        Url := SupportContactInformation.URL;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'OpenLastErrorPage', '', true, true)]
    local procedure OpenLastError()
    begin
        PAGE.Run(PAGE::"Latest Error");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetFindEntriesPageId', '', true, true)]
    local procedure GetFindEntriesPage(var PageId: Integer)
    begin
        PageId := Page::Navigate;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSupportInformation(var SupportName: Text; var SupportEmail: Text; var SupportUrl: Text)
    begin
    end;
}

