// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;

using Microsoft.CRM.Outlook;

page 7202 "CDS Admin Credentials"
{
    Caption = 'Dataverse Administrator Credentials', Comment = 'Dataverse is the name of a Microsoft Service and should not be translated.';
    PageType = StandardDialog;
    SourceTable = "Office Admin. Credentials";
    SourceTableTemporary = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            label("Specify the credentials of the user that will be used to import the solution.")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Specifies the credentials of the user that will be used to import and configure the integration solution.';
            }
            field(UserName; Rec.Email)
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = EMail;
                Caption = 'User Name';
                ToolTip = 'Specifies the name of the user that will be used to import and configure the integration solution.';
            }
            field(Password; Rec.Password)
            {
                ApplicationArea = Basic, Suite;
                ExtendedDatatype = Masked;
                ToolTip = 'Specifies the password of the user that will be used to import and configure the integration solution.';
            }
            label(InvalidUserMessage)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'The user must exist in Dataverse and be assigned the System Administrator and Solution Customizer security roles.';
            }
        }
    }

    var
        EmptyUserNameErr: Label 'Enter user name.';
        EmptyPasswordErr: Label 'Enter password.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then begin
            CheckEmailPassword();
            SetConnectionSetupProperties();
        end;
    end;

    [NonDebuggable]
    local procedure CheckEmailPassword()
    begin
        if Rec.Email.Trim() = '' then
            Error(EmptyUserNameErr);
        if Rec.Password = '' then
            Error(EmptyPasswordErr);
    end;

    [NonDebuggable]
    local procedure SetConnectionSetupProperties()
    var
        TempCDSConnectionSetup: Record "CDS Connection Setup" temporary;
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
    begin
        TempCDSConnectionSetup."Authentication Type" := TempCDSConnectionSetup."Authentication Type"::Office365;
        TempCDSConnectionSetup."Proxy Version" := CDSIntegrationImpl.GetLastProxyVersionItem();
        TempCDSConnectionSetup."Server Address" := Rec.Endpoint;
        TempCDSConnectionSetup."User Name" := Rec.Email;
        TempCDSConnectionSetup.SetPassword(Rec.Password);
        CDSIntegrationImpl.UpdateConnectionString(TempCDSConnectionSetup);
        CDSIntegrationImpl.CheckAdminUserPrerequisites(TempCDSConnectionSetup, Rec.Email, Rec.Password, '', '');
    end;
}

