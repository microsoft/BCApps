// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using Microsoft.Utilities;

page 1613 "Exchange Client Credentials"
{
    Caption = 'Application Client ID and Secret';
    PageType = StandardDialog;
    SourceTable = "Name/Value Buffer";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            label(SpecifyClientIdAndSecret)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Specify the ID, application secret and redirect URL of the Microsoft Entra application that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
            field(ClientId; Rec.Name)
            {
                ApplicationArea = RelationshipMgmt;
                ExtendedDatatype = EMail;
                Caption = 'Client ID';
                ToolTip = 'Specifies the ID of the Microsoft Entra application that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
            field(ClientSecret; Rec.Value)
            {
                ApplicationArea = RelationshipMgmt;
                ExtendedDatatype = Masked;
                Caption = 'Client Secret';
                ToolTip = 'Specifies the secret of the Microsoft Entra application that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
            field(RedirectURL; Rec."Value Long")
            {
                ApplicationArea = RelationshipMgmt;
                ExtendedDatatype = URL;
                Caption = 'Redirect URL';
                ToolTip = 'Specifies the redirect URL of the Microsoft Entra application that will be used to connect to Exchange.', Comment = 'Exchange and Microsoft Entra are names of a Microsoft service and a Microsoft Azure resource and should not be translated.';
            }
        }
    }

    var
        EmptyClientIdErr: Label 'You must specify the Microsoft Entra application ID.';
        EmptyClientSecretErr: Label 'You must specify the Microsoft Entra application secret.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::LookupOK, Action::OK] then begin
            if Rec.Name = '' then
                Error(EmptyClientIdErr);
            if Rec.Value = '' then
                Error(EmptyClientSecretErr);
        end;
    end;
}

