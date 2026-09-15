#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System.Environment;
using System.Integration;

page 4010 "Intelligent Cloud"
{
    Caption = 'Intelligent Cloud';
    Editable = false;
    PageType = Card;
    ShowFilter = false;
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';
    ObsoleteReason = 'The Intelligent Cloud Insights feature is deprecated. Go to the article Deprecated Features in the Base App in the Business Central documentation to learn more.';

    layout
    {
        area(content)
        {
            usercontrol(WebPageViewer; WebPageViewer)
            {
                ApplicationArea = Basic, Suite;
                Visible = ShowIntelligentCloud;

                trigger ControlAddInReady(callbackUrl: Text)
                begin
                    AddInReady := true;
                    NavigateToUrl();
                end;

                trigger DocumentReady()
                begin
                end;

                trigger Callback(data: Text)
                begin
                end;

                trigger Refresh(callbackUrl: Text)
                begin
                    if AddInReady then
                        NavigateToUrl();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ShowIntelligentCloud := not EnvironmentInfo.IsSaaS();
        ShowDeprecatedNotification();
    end;

    var
        EnvironmentInfo: Codeunit "Environment Information";
        AddInReady: Boolean;
        IntelligentCloudUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2009848&clcid=0x409', Locked = true;
        IntelligentCloudDeprecatedMsg: Label 'The Intelligent Cloud Insights feature is being deprecated and will be removed in a later release. Please go to the article Deprecated Features in the Base App in the Business Central documentation to learn more.';
        ShowIntelligentCloud: Boolean;

    local procedure ShowDeprecatedNotification()
    var
        DeprecatedNotification: Notification;
    begin
        DeprecatedNotification.Id := CreateGuid();
        DeprecatedNotification.Message(IntelligentCloudDeprecatedMsg);
        DeprecatedNotification.Send();
    end;

    local procedure NavigateToUrl()
    begin
        CurrPage.WebPageViewer.Navigate(IntelligentCloudUrlTxt);
    end;

    procedure GetIntelligentCloudInsightsUrl(): Text
    var
        BaseUrl: Text;
        ParameterUrl: Text;
        NoDomainUrl: Text;
    begin
        BaseUrl := GetUrl(CLIENTTYPE::Web);
        ParameterUrl := GetUrl(CLIENTTYPE::Web, '', OBJECTTYPE::Page, 4013);
        NoDomainUrl := DelChr(ParameterUrl, '<', BaseUrl);

        exit(StrSubstNo('https://businesscentral.dynamics.com/%1', NoDomainUrl));
    end;
}
#endif