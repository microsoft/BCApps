namespace System.Automation;

using System;
using System.Azure.Identity;
using System.Environment;
using System.Integration;

codeunit 6400 "Flow Service Management"
{
    // // Manages access to Microsoft Power Automate (previously called Microsoft Flow) service API
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = TableData "Flow Service Configuration" = r;

    trigger OnRun()
    begin
    end;

    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
#if not CLEAN25
        DotNetString: DotNet String;
#endif
        JObject: DotNet JObject;

        FlowUrlProdTxt: Label 'https://make.powerautomate.com/', Locked = true;
        FlowUrlTip1Txt: Label 'https://make.test.powerautomate.com/', Locked = true;
        FlowARMResourceUrlTxt: Label 'https://management.core.windows.net/', Locked = true;
        GenericErr: Label 'An error occurred while trying to access the Power Automate service. Please try again or contact your system administrator if the error persists.';
        FlowResourceNameTxt: Label 'Flow Services';
        FlowAccessDeniedErr: Label 'Windows Azure Service Management API permissions need to be enabled for Power Automate in the Azure portal. Contact your system administrator.';
        FlowLinkUrlFormatTxt: Label '%1/flows/%2/details', Locked = true;
        FlowLinkInvalidFlowIdErr: Label 'An invalid flow ID was provided.';
        NullGuidReceivedMsg: Label 'Encountered an null GUID value as Power Automate Environment ID.', Locked = true;
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token for Power Automate services.', Locked = true;
        EmptyPowerPlatformTenantTelemetryMsg: Label 'Encountered an empty Power Platform Tenant URL for Power Automate services.', Locked = true;
        PowerAutomateURLTelemetryMsg: Label 'Power Automate Environment URL: %1', Locked = true, Comment = '%1: URL used to access Power Automate environments';
        PowerAutomatePickerTelemetryCategoryLbl: Label 'AL Power Automate Environment Picker', Locked = true;
        MicrosoftPowerAutomatePrivacyIdTxt: Label 'Power Automate', Locked = true;

#if not CLEAN25
        FlowSearchTemplatesUrlTxt: Label 'https://make.powerautomate.com/templates/?q=%1', Locked = true, Comment = '%1: a query string to use for template search';
        FlowServiceResourceUrlTxt: Label 'https://service.flow.microsoft.com/', Locked = true, Comment = 'Note: while the url of Power Automate changed, the AAD resource still contains the old product name"Flow".';
        FlowTemplatePageSizeTxt: Label '20', Locked = true;
        FlowTemplateDestinationNewTxt: Label 'new', Locked = true;
        FlowTemplateDestinationDetailsTxt: Label 'details', Locked = true;
        FlowManageLinkUrlFormatTxt: Label '%1environments/%2/flows/', Locked = true;
        FlowPPEErr: Label 'Power Automate integration is only supported on a production environment.';
        TemplateFilterTxt: Label 'Microsoft Dynamics 365 Business Central', Locked = true;
        SalesFilterTxt: Label 'Sales', Locked = true;
        PurchasingFilterTxt: Label 'Purchase', Locked = true;
        JournalFilterTxt: Label 'General Journal', Locked = true;
        CustomerFilterTxt: Label 'Customer', Locked = true;
        ItemFilterTxt: Label 'Item', Locked = true;
        VendorFilterTxt: Label 'Vendor', Locked = true;
#endif

    procedure GetFlowUrl(): Text
    var
        FlowServiceConfiguration: Record "Flow Service Configuration";
        FlowUrl: Text;
    begin
        FlowUrl := FlowUrlProdTxt;
        if FlowServiceConfiguration.FindFirst() then
            case FlowServiceConfiguration."Flow Service" of
                FlowServiceConfiguration."Flow Service"::"Testing Service (TIP 1)":
                    FlowUrl := FlowUrlTip1Txt;
            end;

        exit(FlowUrl);
    end;

    procedure GetFlowEnvironmentsApi(): Text
    var
        FlowEnvironmentsApi: Text;
    begin
        if TryGetFlowEnvironmentsApi(FlowEnvironmentsApi) then
            exit(FlowEnvironmentsApi);

        exit('');
    end;

    procedure GetFlowDetailsUrl(FlowId: Guid) FlowDetailsUrl: Text
    begin
        if IsNullGuid(FlowId) then
            Error(FlowLinkInvalidFlowIdErr);

        FlowDetailsUrl := StrSubstNo(FlowLinkUrlFormatTxt, GetFlowUrl(), LowerCase(Format(FlowId, 0, 4)));
    end;

    procedure GetGenericError(): Text
    begin
        exit(GenericErr);
    end;

    procedure CanApproveForAll(): Boolean
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        exit(FlowUserEnvironmentConfig.WritePermission());
    end;

    procedure GetPowerAutomatePrivacyNoticeId(): Code[50]
    begin
        exit(MicrosoftPowerAutomatePrivacyIdTxt);
    end;

    procedure GetFlowEnvironmentID() FlowEnvironmentId: Text
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        // Check if a user has a specific environment configured
        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then
            FlowEnvironmentId := FlowUserEnvironmentConfig."Environment ID"
        else
            // If not, check if the default environment is configured
            if FlowUserEnvironmentConfig.Get(EmptyGuid) then
                FlowEnvironmentId := FlowUserEnvironmentConfig."Environment ID";
    end;

    procedure GetSelectedFlowEnvironmentName() FlowEnvironmentName: Text
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        FlowEnvironmentName := '';
        if not HasUserSelectedFlowEnvironment() then
            exit;
        // Check if a user has a specific environment configured
        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then
            FlowEnvironmentName := FlowUserEnvironmentConfig."Environment Display Name"
        else
            // If not, check if the default environment is configured
            if FlowUserEnvironmentConfig.Get(EmptyGuid) then
                FlowEnvironmentName := FlowUserEnvironmentConfig."Environment Display Name"
    end;

    [Scope('OnPrem')]
    procedure GetEnvironments(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        WebRequestHelper: Codeunit "Web Request Helper";
        ResponseText: Text;
        Handled: Boolean;
        AccessToken: SecretText;
    begin
        Handled := false;
        OnBeforeSendGetEnvironmentRequest(ResponseText, Handled);
        if not Handled then begin
            AccessToken := AzureAdMgt.GetAccessTokenAsSecretText(FlowARMResourceUrlTxt, FlowResourceNameTxt, false);

            if AccessToken.IsEmpty() then
                Session.LogMessage('0000MJX', EmptyAccessTokenTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerAutomatePickerTelemetryCategoryLbl);

            // Gets a list of Flow user environments from the Flow API.
            if not WebRequestHelper.GetResponseTextUsingCharset('GET', GetFlowEnvironmentsApi(), AccessToken, ResponseText)
            then
                Error(GenericErr);
        end;

        ParseResponseTextForEnvironments(ResponseText, TempFlowUserEnvironmentBuffer);
    end;

    procedure ParseResponseTextForEnvironments(ResponseText: Text; var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EnvironmentInformation: Codeunit "Environment Information";
        Current: DotNet GenericKeyValuePair2;
        JObj: DotNet JObject;
        JObjProp: DotNet JObject;
        ObjectEnumerator: DotNet IEnumerator;
        JArray: DotNet JArray;
        ArrayEnumerator: DotNet IEnumerator;
        JToken: DotNet JToken;
        JProperty: DotNet JProperty;
    begin
        // Parse the ResponseText from Flow environments api for a list of environments
        ObjectEnumerator := JObject.Parse(ResponseText).GetEnumerator();

        while ObjectEnumerator.MoveNext() do begin
            Current := ObjectEnumerator.Current;

            if Format(Current.Key) = 'value' then begin
                JArray := Current.Value();
                ArrayEnumerator := JArray.GetEnumerator();

                while ArrayEnumerator.MoveNext() do begin
                    JObj := ArrayEnumerator.Current;
                    JObjProp := JObj.SelectToken('properties');

                    if not IsNull(JObjProp) then begin
                        JProperty := JObjProp.Property('provisioningState');

                        // only interested in those that succeeded
                        if LowerCase(Format(JProperty.Value)) = 'succeeded' then begin
                            JToken := JObj.SelectToken('name');
                            JProperty := JObjProp.Property('displayName');

                            TempFlowUserEnvironmentBuffer.Init();
                            TempFlowUserEnvironmentBuffer."Environment ID" := JToken.ToString();
                            TempFlowUserEnvironmentBuffer."Environment Display Name" := Format(JProperty.Value);

                            if EnvironmentInformation.GetLinkedPowerPlatformEnvironmentId() = TempFlowUserEnvironmentBuffer."Environment Id" then
                                TempFlowUserEnvironmentBuffer.Linked := true;

                            // mark current environment as enabled/selected if it is currently the user selected environment
                            FlowUserEnvironmentConfig.Reset();
                            FlowUserEnvironmentConfig.SetRange("Environment ID", JToken.ToString());
                            FlowUserEnvironmentConfig.SetRange("User Security ID", UserSecurityId());
                            TempFlowUserEnvironmentBuffer.Enabled := FlowUserEnvironmentConfig.FindFirst();

                            // check if environment is the default
                            JProperty := JObjProp.Property('isDefault');
                            if LowerCase(Format(JProperty.Value)) = 'true' then
                                TempFlowUserEnvironmentBuffer.Default := true;

                            TempFlowUserEnvironmentBuffer.Insert();
                        end;
                    end;
                end;
            end;
        end;
    end;

    procedure SaveFlowUserEnvironmentSelection(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        // User previously selected environment so update
        if FlowUserEnvironmentConfig.Get(UserSecurityId()) then begin
            FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
            FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
            FlowUserEnvironmentConfig.Modify();
            exit;
        end;

        // User has no previous selection so add new one
        FlowUserEnvironmentConfig.Init();
        FlowUserEnvironmentConfig."User Security ID" := UserSecurityId();
        FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
        FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
        FlowUserEnvironmentConfig.Insert();
    end;

    procedure UseLinkedEnvironment()
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
    begin
        // Remove all previous selections if exists
        FlowUserEnvironmentConfig.Reset();
        FlowUserEnvironmentConfig.DeleteAll();
    end;

    procedure SaveFlowEnvironmentSelectionForAll(var TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary)
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        // Remove all previous selections
        FlowUserEnvironmentConfig.Reset();
        FlowUserEnvironmentConfig.DeleteAll();

        // Add new selection for all users
        FlowUserEnvironmentConfig.Init();
        FlowUserEnvironmentConfig."User Security ID" := EmptyGuid;
        FlowUserEnvironmentConfig."Environment ID" := TempFlowUserEnvironmentBuffer."Environment ID";
        FlowUserEnvironmentConfig."Environment Display Name" := TempFlowUserEnvironmentBuffer."Environment Display Name";
        FlowUserEnvironmentConfig.Insert();
    end;

    procedure HasUserSelectedFlowEnvironment(): Boolean
    var
        FlowUserEnvironmentConfig: Record "Flow User Environment Config";
        EmptyGuid: Guid;
    begin
        exit(FlowUserEnvironmentConfig.Get(UserSecurityId()) or FlowUserEnvironmentConfig.Get(EmptyGuid));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", 'GetPowerPlatformEnvironmentId', '', true, true)]
    local procedure GetEnvironmentId(Scenario: Text; var EnvironmentId: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        GUIDValue: Guid;
        LinkedEnvironmentId: Text;
        EmptyGuidText: Text;
    begin
        EmptyGuidText := '00000000-0000-0000-0000-000000000000';
        EnvironmentId := '';
        if HasUserSelectedFlowEnvironment() then
            // if a user has a specific environment configured, use it
            EnvironmentId := GetFlowEnvironmentID()
        else begin
            // if not, use the linked environment if exists
            LinkedEnvironmentId := EnvironmentInformation.GetLinkedPowerPlatformEnvironmentId();
            if (LinkedEnvironmentId <> '') and (Evaluate(GUIDValue, LinkedEnvironmentId)) then begin
                EnvironmentId := LinkedEnvironmentId;

                if (LinkedEnvironmentId = EmptyGuidText) then
                    Session.LogMessage('0000NBM', NullGuidReceivedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerAutomatePickerTelemetryCategoryLbl);
                ;
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Azure AD Access Dialog", 'OnOAuthAccessDenied', '', false, false)]
    local procedure CheckOAuthAccessDenied(description: Text; resourceFriendlyName: Text)
    begin
        if StrPos(resourceFriendlyName, FlowResourceNameTxt) > 0 then
            if StrPos(description, 'AADSTS65005') > 0 then
                Error(FlowAccessDeniedErr);
    end;

    [TryFunction]
    local procedure TryGetFlowEnvironmentsApi(var FlowEnvironmentsApi: Text)
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
    begin
        if AzureADTenant.GetPowerPlatformTenantURL() = '' then begin
            Session.LogMessage('0000Q79', EmptyPowerPlatformTenantTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerAutomatePickerTelemetryCategoryLbl);
            FlowEnvironmentsApi := '';
            exit;
        end;

        FlowEnvironmentsApi := 'https://' + AzureADTenant.GetPowerPlatformTenantURL() + '/powerautomate/environments?api-version=1';
        Session.LogMessage('0000Q7A', StrSubstNo(PowerAutomateURLTelemetryMsg, FlowEnvironmentsApi), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerAutomatePickerTelemetryCategoryLbl);
    end;

    [InternalEvent(false)]
    internal procedure OnBeforeSendGetEnvironmentRequest(var ResponseText: Text; var Handled: Boolean)
    begin
    end;

#if not CLEAN25
    [Obsolete('We do not provide localization for Power Automate anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetLocale(): Text
    var
        CultureInfo: DotNet CultureInfo;
        TextInfo: DotNet TextInfo;
    begin
        CultureInfo := CultureInfo.CultureInfo(GlobalLanguage);
        TextInfo := CultureInfo.TextInfo;
        exit(LowerCase(TextInfo.CultureName));
    end;

    [Obsolete('We do not support providing the Power Automate manage URL anymore.', '25.0')]
    procedure GetFlowManageUrl() Url: Text
    begin
        Url := StrSubstNo(FlowManageLinkUrlFormatTxt, GetFlowUrl(), GetFlowEnvironmentID());
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowARMResourceUrl(): Text
    begin
        exit(FlowARMResourceUrlTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowServiceResourceUrl(): Text
    begin
        exit(FlowServiceResourceUrlTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowResourceName(): Text
    begin
        exit(FlowResourceNameTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowTemplatePageSize(): Text
    begin
        // Notice: the behaviour of the pagesize parameter for templates depends on the destination parameter:
        //  - If destination=new and pagesize=x, then the list loads x templates in the initial view, but a button is present to "load more templates"
        //  - If destination=details and pagesize=x, then the list loads x templates in the view, but since no button is present to "load more templates",
        //    the user is stuck in a view with only x templates

        exit(FlowTemplatePageSizeTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowTemplateDestinationNew(): Text
    begin
        // This value asks flow to embed the full flow creation experience from template into the iframe, see:
        //   https://go.microsoft.com/fwlink/?linkid=2206517
        // Currently, this is broken from Flow (see BUG 34364), so we load the Details experience instead

        exit(FlowTemplateDestinationNewTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowTemplateDestinationDetails(): Text
    begin
        // This value asks flow to embed only the template list in the iframe, and on template click open the experience in a new tab, see:
        //   https://go.microsoft.com/fwlink/?linkid=2206173

        exit(FlowTemplateDestinationDetailsTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    [NonDebuggable]
    [Scope('OnPrem')]
    procedure IsUserReadyForFlow(): Boolean
    begin
        if not AzureAdMgt.IsAzureADAppSetupDone() then
            exit(false);
#pragma warning disable AL0432
        exit(not DotNetString.IsNullOrWhiteSpace(AzureAdMgt.GetAccessTokenAsSecretText(GetFlowARMResourceUrl(), GetFlowResourceName(), false).Unwrap()));
#pragma warning restore AL0432
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowPPEError(): Text
    begin
        exit(FlowPPEErr);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetTemplateFilter(): Text
    begin
        // Gets the default text value that filters Flow templates when opening page 6400.
        exit(TemplateFilterTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetSalesTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Sales pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + SalesFilterTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetPurchasingTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Purchasing pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + PurchasingFilterTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetJournalTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for General Journal pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + JournalFilterTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetCustomerTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Customer pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + CustomerFilterTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetItemTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Item pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + ItemFilterTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetVendorTemplateFilter(): Text
    begin
        // Gets a text value that filters Flow templates for Vendor pages when opening page 6400.
        exit(TemplateFilterTxt + ' ' + VendorFilterTxt);
    end;

    [Obsolete('This function is not used anymore. We rely on Power Automate internal services instead.', '25.0')]
    procedure GetFlowTemplateSearchUrl(): Text
    begin
        exit(FlowSearchTemplatesUrlTxt);
    end;

    [Obsolete('This function is not used anymore. We do not set the default environment anymore. We rely on Power Automate instead.', '25.0')]
    [Scope('OnPrem')]
    procedure SetSelectedFlowEnvironmentIDToDefault()
    var
        TempFlowUserEnvironmentBuffer: Record "Flow User Environment Buffer" temporary;
        WebRequestHelper: Codeunit "Web Request Helper";
        ResponseText: Text;
        PostResult: Boolean;
        Handled: Boolean;
        AccessToken: SecretText;
    begin
        Handled := false;
#pragma warning disable AL0432
        OnBeforeSetDefaultEnvironmentRequest(ResponseText, Handled);
#pragma warning restore AL0432
        if not Handled then begin
            GetEnvironments(TempFlowUserEnvironmentBuffer);
            TempFlowUserEnvironmentBuffer.SetRange(Default, true);
            if TempFlowUserEnvironmentBuffer.FindFirst() then
                SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer)
            else begin
                AccessToken := AzureAdMgt.GetAccessTokenAsSecretText(FlowARMResourceUrlTxt, FlowResourceNameTxt, false);

                if AccessToken.IsEmpty() then
                    Session.LogMessage('0000MJY', EmptyAccessTokenTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerAutomatePickerTelemetryCategoryLbl);

                // No environment found so make a post call to create default environment. Post call returns error but actually creates environment
                PostResult := WebRequestHelper.GetResponseTextUsingCharset('POST', GetFlowEnvironmentsApi(), AccessToken, ResponseText);

                if not PostResult then
                    ; // Do nothing. Need to store the result of the POST call so that error from POST call doesn't bubble up. May need to look at this later.

                // we should have environments now so go ahead and set selected environment
                GetEnvironments(TempFlowUserEnvironmentBuffer);
                TempFlowUserEnvironmentBuffer.SetRange(Default, true);
                if TempFlowUserEnvironmentBuffer.FindFirst() then
                    SaveFlowUserEnvironmentSelection(TempFlowUserEnvironmentBuffer)
            end;
        end;
    end;

    [Obsolete('This function is not used anymore. We do not set the default environment anymore. We rely on Power Automate instead.', '25.0')]
    [InternalEvent(false)]
    internal procedure OnBeforeSetDefaultEnvironmentRequest(var ResponseText: Text; var Handled: Boolean)
    begin
    end;
#endif
}
