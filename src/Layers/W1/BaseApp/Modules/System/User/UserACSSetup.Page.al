namespace System.Security.User;

using System;
using System.Environment;
using System.Security.AccessControl;

page 9811 "User ACS Setup"
{
    Caption = 'User ACS Setup';
    DataCaptionExpression = Rec."Full Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = true;
    PageType = Card;
    SourceTable = User;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("User Name"; Rec."User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the user''s name. If the user is required to present credentials when starting the client, this is the name that the user must present.';
                }
                field(NameID; NameID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ACS Name ID';
                    Editable = false;
                    ToolTip = 'Specifies the name identifier provided by the ACS security token. You cannot enter a value in this field; it is populated automatically when the user logs on for the first time..';
                }
                field(AuthenticationID; AuthenticationID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Authentication Key';
                    Editable = false;
                    ToolTip = 'Specifies the authentication key that is generated after you choose Generate Auth Key in the User ACS Setup dialog box. After you configure your Azure deployment and your Business Central components for ACS, send this value and the User Name value to the user, and then direct the user to provide these values when they log on to a Business Central client.';
                }
                field(ACSStatus; ACSStatus)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ACS Status';
                    Editable = false;
                    ToolTip = 'Specifies the current authentication status of the user.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Generate Auth Key")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Generate Auth Key';
                Image = Setup;
                ToolTip = 'Generate an authentication key for Access Control Service authentication.';

                trigger OnAction()
                var
                    Convert: DotNet Convert;
                    UTF8Encoding: DotNet UTF8Encoding;
                    CreatedGuid: Text;
                begin
                    CreatedGuid := CreateGuid();
                    UTF8Encoding := UTF8Encoding.UTF8Encoding();

                    AuthenticationID := Convert.ToBase64String(UTF8Encoding.GetBytes(CreatedGuid));

                    IdentityManagement.SetAuthenticationKey(Rec."User Security ID", AuthenticationID);
                    ACSStatus := IdentityManagement.GetACSStatus(Rec."User Security ID");

                    CurrPage.Update();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Generate Auth Key_Promoted"; "Generate Auth Key")
                {
                }
            }
        }
    }

    trigger OnInit()
    var
        UserPermissions: Codeunit "User Permissions";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if (Rec."User Security ID" <> UserSecurityId()) and EnvironmentInfo.IsSaaS() then
            if not UserPermissions.CanManageUsersOnTenant(UserSecurityID()) then
                error(CannotEditForOtherUsersErr);
    end;

    trigger OnAfterGetRecord()
    begin
        NameID := IdentityManagement.GetNameIdentifier(Rec."User Security ID");
        ACSStatus := IdentityManagement.GetACSStatus(Rec."User Security ID");
        AuthenticationID := IdentityManagement.GetAuthenticationKey(Rec."User Security ID");
    end;

    trigger OnModifyRecord(): Boolean
    begin
        IdentityManagement.SetAuthenticationKey(Rec."User Security ID", AuthenticationID);
    end;

    var
        IdentityManagement: Codeunit "Identity Management";
        NameID: Text[250];
        AuthenticationID: Text[80];
        ACSStatus: Option Disabled,Pending,Registered,Unknown;
        CannotEditForOtherUsersErr: Label 'You can only change your own ACS setup.';
}

