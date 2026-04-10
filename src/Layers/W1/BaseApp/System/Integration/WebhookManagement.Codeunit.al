namespace System.Integration;

using Microsoft.Foundation.Company;
using System;
using System.Environment;
using System.Security.AccessControl;
using System.Utilities;

codeunit 5377 "Webhook Management"
{

    trigger OnRun()
    begin
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

    procedure GetNotificationUrl() NotificationUrl: Text[250]
    begin
        NotificationUrl := GetUrl(CLIENTTYPE::OData);
        NotificationUrl := CopyStr(NotificationUrl, 1, StrPos(NotificationUrl, Format(CLIENTTYPE::OData)) - 1) + 'api/webhooks';
    end;

    procedure IsCurrentClientTypeAllowed(): Boolean
    begin
        exit(not (ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Management, CLIENTTYPE::NAS]));
    end;

    procedure IsSyncAllowed(): Boolean
    var
        CompanyInformation: Record "Company Information";
        CompanyInformationMgt: Codeunit "Company Information Mgt.";
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        if not CompanyInformation.Get() then
            exit(false);

        if not EnvironmentInfo.IsSaaS() then
            exit(false);

        if CompanyInformationMgt.IsDemoCompany() then
            exit(false);

        exit(true);
    end;

    procedure FindMatchingWebhookSubscription(var WebhookSubscription: Record "Webhook Subscription"; SubscriptionEndpoint: Text): Boolean
    begin
        WebhookSubscription.SetRange("Company Name", CompanyName);
        if WebhookSubscription.Find('-') then
            repeat
                if WebhookSubscription.Endpoint = SubscriptionEndpoint then
                    exit(true);
            until WebhookSubscription.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FindMatchingWebhookSubscriptionRegex(var WebhookSubscription: Record "Webhook Subscription"; EndpointRegex: DotNet Regex): Boolean
    begin
        WebhookSubscription.SetRange("Company Name", CompanyName);
        if WebhookSubscription.FindSet() then
            repeat
                if EndpointRegex.IsMatch(WebhookSubscription.Endpoint) then
                    exit(true);
            until WebhookSubscription.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure FindWebhookSubscriptionMatchingEndPoint(var WebhookSubscription: Record "Webhook Subscription"; EndpointUri: DotNet Uri; StartIndex: Integer; PathLength: Integer): Boolean
    var
        SubscriptionEndpointUri: DotNet Uri;
        SearchSubString: Text;
        IsSameEndpoint: Boolean;
    begin
        if WebhookSubscription.FindSet() then
            repeat
                SubscriptionEndpointUri := SubscriptionEndpointUri.Uri(WebhookSubscription.Endpoint);
                IsSameEndpoint := false;
                if StartIndex <= 0 then
                    IsSameEndpoint := (EndpointUri.ToString() = SubscriptionEndpointUri.ToString())
                else
                    if (SubscriptionEndpointUri.Scheme = EndpointUri.Scheme) and
                       (SubscriptionEndpointUri.Host = EndpointUri.Host)
                    then begin
                        SearchSubString := CopyStr(EndpointUri.PathAndQuery, StartIndex + PathLength);
                        if StrPos(SubscriptionEndpointUri.PathAndQuery, SearchSubString) > 0 then
                            IsSameEndpoint := true;
                    end;

                if IsSameEndpoint and (CompanyName = WebhookSubscription."Company Name") then
                    exit(true);
            until WebhookSubscription.Next() = 0;
    end;

    procedure FindWebhookSubscriptionMatchingEndPointUri(var WebhookSubscription: Record "Webhook Subscription"; EndpointUriTxt: Text; StartIndex: Integer; PathLength: Integer): Boolean
    var
        EndpointUri: DotNet Uri;
        SubscriptionEndpointUri: DotNet Uri;
        SearchSubString: Text;
        IsSameEndpoint: Boolean;
    begin
        EndpointUri := EndpointUri.Uri(EndpointUriTxt);
        if WebhookSubscription.FindSet() then
            repeat
                SubscriptionEndpointUri := SubscriptionEndpointUri.Uri(WebhookSubscription.Endpoint);
                IsSameEndpoint := false;
                if StartIndex <= 0 then
                    IsSameEndpoint := (EndpointUri.ToString() = SubscriptionEndpointUri.ToString())
                else
                    if (SubscriptionEndpointUri.Scheme = EndpointUri.Scheme) and
                       (SubscriptionEndpointUri.Host = EndpointUri.Host)
                    then begin
                        SearchSubString := CopyStr(EndpointUri.PathAndQuery, StartIndex + PathLength);
                        if StrPos(SubscriptionEndpointUri.PathAndQuery, SearchSubString) > 0 then
                            IsSameEndpoint := true;
                    end;

                if IsSameEndpoint and (CompanyName = WebhookSubscription."Company Name") then
                    exit(true);
            until WebhookSubscription.Next() = 0;
    end;

    procedure IsValidNotificationRunAsUser(UserSecurityId: Guid): Boolean
    var
        User: Record User;
        EmptyGUID: Guid;
    begin
        if UserSecurityId = EmptyGUID then
            exit(false);

        if not User.Get(UserSecurityId) then
            exit(false);

        exit(User."License Type" <> User."License Type"::"External User");
    end;
}

