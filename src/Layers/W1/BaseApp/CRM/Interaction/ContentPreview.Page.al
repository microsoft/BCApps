// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using System.Integration;

page 5084 "Content Preview"
{
    Caption = 'Content Preview';

    layout
    {
        area(content)
        {
            group(EmailBody)
            {
                Caption = 'Email Body';
                usercontrol(BodyHTMLMessage; WebPageViewer)
                {
                    ApplicationArea = RelationshipMgmt;

                    trigger ControlAddInReady(callbackUrl: Text)
                    begin
                        CurrPage.BodyHTMLMessage.LinksOpenInNewWindow();
                        CurrPage.BodyHTMLMessage.SetContent(HTMLContent);
                    end;

                    trigger DocumentReady()
                    begin
                    end;

                    trigger Callback(data: Text)
                    begin
                    end;

                    trigger Refresh(callbackUrl: Text)
                    begin
                        CurrPage.BodyHTMLMessage.LinksOpenInNewWindow();
                        CurrPage.BodyHTMLMessage.SetContent(HTMLContent);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        HTMLContent: Text;

    procedure SetContent(InHTMLContent: Text)
    begin
        HTMLContent := InHTMLContent;
    end;
}

