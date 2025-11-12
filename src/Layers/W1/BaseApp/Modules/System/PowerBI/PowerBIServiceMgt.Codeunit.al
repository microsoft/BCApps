namespace System.Integration.PowerBI;

using System;
using System.Azure.Identity;
using System.Environment.Configuration;
using System.Integration;
using System.Reflection;
using System.Security.User;
using System.Telemetry;
using System.Threading;

codeunit 6301 "Power BI Service Mgt."
{
    var
        AzureAdMgt: Codeunit "Azure AD Mgt.";
        GenericErr: Label 'An error occurred while trying to get reports from the Power BI service. Please try again or contact your system administrator if the error persists.';
        PowerBiResourceNameTxt: Label 'Power BI Services';
#if not CLEAN27
        MainPageRatioTxt: Label '16:9', Locked = true;
        FactboxRatioTxt: Label '4:3', Locked = true;
#endif
        FailedAuthErr: Label 'We failed to authenticate with Power BI. Try to sign out and in again. This problem typically happens if you no longer have a license for Power BI or if you just changed your email or password.';
        UnauthorizedErr: Label 'You do not have a Power BI account. If you have just activated a license, it might take several minutes for the changes to be effective in Power BI.';
        PowerBIEmbedReportUrlTemplateTxt: Label 'https://app.powerbi.com/reportEmbed?reportId=%1', Locked = true;
        Dyn365AppSourceUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862352', Locked = true;
        PowerBIMyOrgUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=862353', Locked = true;
        JobQueueCategoryCodeTxt: Label 'PBI EMBED', Locked = true;
        JobQueueCategoryDescriptionTxt: Label 'Synchronize Power BI reports', MaxLength = 30;
        // Telemetry constants
        EmbedCorrelationTelemetryTxt: Label 'Embed element started with type: %1, and correlation: %2', Locked = true;
        EmbedErrorOccurredTelemetryTxt: Label 'Embed error occurred with category: %1', Locked = true;
        PowerBiEmbedFeatureTelemetryTok: Label 'Power BI Embed', Locked = true;
        PowerBiLicenseCheckErrorTelemetryMsg: Label 'Power BI license check finished with error.', Locked = true;
        PowerBiLicenseCheckSuccessTelemetryMsg: Label 'Power BI license check returned success.', Locked = true;
        PowerBiTelemetryCategoryLbl: Label 'AL Power BI Embedded', Locked = true;
        EmptyAccessTokenTelemetryMsg: Label 'Encountered an empty access token.', Locked = true;
        ScheduleSyncTelemetryMsg: Label 'Scheduling sync for UTC datetime: %1.', Locked = true;

    [Scope('OnPrem')]
    procedure CheckForPowerBILicenseInForeground(): Boolean
    var
        PowerBIServiceProvider: Interface "Power BI Service Provider";
        OperationResult: DotNet OperationResult;
    begin
        CreateServiceProvider(PowerBIServiceProvider);

        PowerBIServiceProvider.CheckUserLicense(OperationResult);

        if OperationResult.Successful then
            Session.LogMessage('0000C0H', PowerBiLicenseCheckSuccessTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl)
        else
            Session.LogMessage('0000B6Y', PowerBiLicenseCheckErrorTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);

        exit(OperationResult.Successful);
    end;

    [Scope('OnPrem')]
    procedure IsUserReadyForPowerBI(): Boolean
    begin
        if not AzureAdMgt.IsAzureADAppSetupDone() then
            exit(false);

        exit(not AzureAdMgt.GetAccessTokenAsSecretText(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false).IsEmpty());
    end;

    procedure GetPowerBIResourceUrl(): Text
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
    begin
        exit(PowerBIUrlMgt.GetPowerBIResourceUrl());
    end;

    procedure GetPowerBiResourceName(): Text
    begin
        exit(PowerBiResourceNameTxt);
    end;

    procedure GetGenericError(): Text
    begin
        exit(GenericErr);
    end;

#if not CLEAN27
    [Obsolete('This function is now deprecated, and the client decides the addin ratio instead.', '27.0')]
    procedure GetFactboxRatio(): Text
    begin
        exit(FactboxRatioTxt);
    end;

    [Obsolete('This function is now deprecated, and the client decides the addin ratio instead.', '27.0')]
    procedure GetMainPageRatio(): Text
    begin
        exit(MainPageRatioTxt);
    end;
#endif

    procedure GetContentPacksServicesUrl(): Text
    begin
        // Gets the URL for AppSource's list of content packs, like Power BI's Services button, filtered to Dynamics reports.
        exit(Dyn365AppSourceUrlTxt);
    end;

    procedure GetContentPacksMyOrganizationUrl(): Text
    begin
        // Gets the URL for Power BI's embedded AppSource page listing reports shared by the user's organization.
        exit(PowerBIMyOrgUrlTxt);
    end;

    [Scope('OnPrem')]
    procedure SynchronizeReportsInBackground(Context: Text[50])
    var
        JobQueueEntry: Record "Job Queue Entry";
        ScheduledDateTime: DateTime;
    begin
        ScheduledDateTime := CurrentDateTime();

        Session.LogMessage('0000FB2', StrSubstNo(ScheduleSyncTelemetryMsg, Format(ScheduledDateTime, 50, 9)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
        JobQueueEntry.ScheduleJobQueueEntryForLater(Codeunit::"Power BI Report Synchronizer", ScheduledDateTime, GetJobQueueCategoryCode(), Context)
    end;

    [Scope('OnPrem')]
    procedure IsUserSynchronizingReports(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Power BI Report Synchronizer");
        JobQueueEntry.SetFilter(Status, '%1|%2|%3|%4', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process", JobQueueEntry.Status::"On Hold", JobQueueEntry.Status::"On Hold with Inactivity Timeout");

        if not JobQueueEntry.IsEmpty() then
            exit(true);

        exit(false);
    end;

    [Scope('OnPrem')]
    procedure GetReportsUrl(): Text
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
    begin
        exit(PowerBIUrlMgt.GetPowerBIReportsUrl());
    end;

    [Scope('OnPrem')]
    procedure GetEnglishContext(): Code[30]
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
    begin
        // Returns an English profile ID for the Report Selection
        ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        exit(AllProfile."Profile ID");
    end;

    /// <summary>
    /// Add a Power BI report visual to the database, so that it's displayed in a certain context for the current user.
    /// </summary>
    /// <param name="ReportId">The ID of the Power BI Report that contains the visual to embed</param>
    /// <param name="ReportPageId">The name of the page in the report that contains the visual to embed</param>
    /// <param name="ReportVisualId">The ID of the report visual to embed</param>
    /// <param name="Context">The context where the Power BI report visual should show up</param>
    /// <remarks>
    /// The easiest way to get the necessary IDs for report visuals is to:
    ///   1. Open the Power BI report in the browser
    ///   2. Hover over the visual you want to embed, and click on the three dots menu
    ///   3. Choose to "Share" the visual, and choose "Link to this Visual"
    ///   4. Use the "Copy" button to copy the URL
    ///   5. From the URL, you can find:
    ///     a. The Report ID after the /reports/ segment 
    ///     b. The Report Page right after the Report ID
    ///     c. The visual ID in a URL query parameter called "visual"
    ///
    /// Example URL with placeholders:
    /// https://app.powerbi.com/groups/me/reports/REPORT_ID/PAGE_ID?[...]&amp;visual=VISUAL_ID
    /// </remarks>
    procedure AddReportVisualForContext(ReportId: Guid; ReportPageId: Text[200]; ReportVisualId: Text[200]; Context: Text[50])
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        if not PowerBIDisplayedElement.Get(UserSecurityId(), Context, PowerBIDisplayedElement.MakeReportVisualKey(ReportId, ReportPageId, ReportVisualId), PowerBIDisplayedElement.ElementType::"Report Visual") then begin
            PowerBIDisplayedElement.Init();
            PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::"Report Visual";
            PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportVisualKey(ReportId, ReportPageId, ReportVisualId);
            // NOTE: The Power BI team recommends to get the embed URL from the Power BI REST APIs, as the URL format might change in the future. 
            // However, currently the approach below is also supported.
            PowerBIDisplayedElement.ElementEmbedUrl := StrSubstNo(PowerBIEmbedReportUrlTemplateTxt, ReportId);
            PowerBIDisplayedElement.Context := Context;
            PowerBIDisplayedElement.UserSID := UserSecurityId();
            PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
            PowerBIDisplayedElement.ShowPanesInNormalMode := false;
            PowerBIDisplayedElement.Insert(true);
        end;

        PowerBIContextSettings.CreateOrReadForCurrentUser(Context);
        if not PowerBIContextSettings.LockToSelectedElement then begin
            PowerBIContextSettings.LockToSelectedElement := true;
            PowerBIContextSettings.Modify(true);
        end;
    end;

    /// <summary>
    /// Add a Power BI report to the database, so that it's displayed in a certain context for the current user.
    /// </summary>
    /// <param name="ReportId">The ID of the Power BI Report to embed</param>
    /// <param name="Context">The context where the Power BI report should show up</param>
    procedure AddReportForContext(ReportId: Guid; Context: Text[50])
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        if not PowerBIDisplayedElement.Get(UserSecurityId(), Context, PowerBIDisplayedElement.MakeReportKey(ReportId), PowerBIDisplayedElement.ElementType::"Report") then begin
            PowerBIDisplayedElement.Init();
            PowerBIDisplayedElement.ElementType := PowerBIDisplayedElement.ElementType::"Report";
            PowerBIDisplayedElement.ElementId := PowerBIDisplayedElement.MakeReportKey(ReportId);
            // NOTE: The Power BI team recommends to get the embed URL from the Power BI REST APIs, as the URL format might change in the future. 
            // However, currently the approach below is also supported.
            PowerBIDisplayedElement.ElementEmbedUrl := StrSubstNo(PowerBIEmbedReportUrlTemplateTxt, ReportId);
            PowerBIDisplayedElement.Context := Context;
            PowerBIDisplayedElement.UserSID := UserSecurityId();
            PowerBIDisplayedElement.ShowPanesInExpandedMode := true;
            PowerBIDisplayedElement.ShowPanesInNormalMode := false;
            PowerBIDisplayedElement.Insert(true);
        end;

        PowerBIContextSettings.CreateOrReadForCurrentUser(Context);
        if not PowerBIContextSettings.LockToSelectedElement then begin
            PowerBIContextSettings.LockToSelectedElement := true;
            PowerBIContextSettings.Modify(true);
        end;
    end;

    procedure IsUserAdminForPowerBI(UserSecurityId: Guid): Boolean
    var
        UserPermissions: Codeunit "User Permissions";
    begin
        exit(UserPermissions.IsSuper(UserSecurityId));
    end;

    procedure CheckPowerBITablePermissions(): Boolean
    var
        PowerBIBlob: Record "Power BI Blob";
        PowerBIDefaultSelection: Record "Power BI Default Selection";
        PowerBIContextSettings: Record "Power BI Context Settings";
        [SecurityFiltering(SecurityFilter::Ignored)]
        PowerBIContextSettings2: Record "Power BI Context Settings";
        PowerBICustomerReports: Record "Power BI Customer Reports";
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
    begin
        exit(PowerBIBlob.ReadPermission()
            and PowerBIDefaultSelection.ReadPermission()
            and PowerBICustomerReports.ReadPermission()
            and PowerBIContextSettings2.WritePermission() and PowerBIContextSettings.ReadPermission()
            and PowerBIDisplayedElement.ReadPermission());
    end;

    procedure GetPowerBiTelemetryCategory(): Text
    begin
        exit(PowerBiTelemetryCategoryLbl);
    end;

    [Scope('OnPrem')]
    procedure GetJobQueueCategoryCode(): Code[10]
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        JobQueueCategory.InsertRec(
            CopyStr(JobQueueCategoryCodeTxt, 1, MaxStrLen(JobQueueCategory.Code)),
            CopyStr(JobQueueCategoryDescriptionTxt, 1, MaxStrLen(JobQueueCategory.Description)));

        exit(JobQueueCategory.Code);
    end;

    internal procedure GetPowerBiFeatureTelemetryName(): Text
    begin
        exit(PowerBiEmbedFeatureTelemetryTok);
    end;

    [NonDebuggable]
    procedure InitializeAddinToken(PowerBIManagement: ControlAddIn PowerBIManagement)
    var
        AccessToken: Text;
        HttpUtility: DotNet HttpUtility;
    begin
        AccessToken := HttpUtility.JavaScriptStringEncode(
            AzureAdMgt.GetAccessTokenAsSecretText(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false).Unwrap()
            );

        if AccessToken = '' then begin
            Session.LogMessage('0000KQL', EmptyAccessTokenTelemetryMsg, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            Error(FailedAuthErr);
        end;

        PowerBIManagement.SetToken(AccessToken);
    end;

    procedure LogVisualLoaded(CorrelationId: Text; EmbedType: Enum "Power BI Element Type")
    begin
        Session.LogMessage('0000KAF', StrSubstNo(EmbedCorrelationTelemetryTxt, EmbedType, CorrelationId),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetPowerBiTelemetryCategory());
    end;

    procedure LogEmbedError(ErrorCategory: Text)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogError('0000L02', GetPowerBiFeatureTelemetryName(), ErrorCategory, 'Error loading Power BI visual');

        Session.LogMessage('0000KAE', StrSubstNo(EmbedErrorOccurredTelemetryTxt, ErrorCategory),
            Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetPowerBiTelemetryCategory());
    end;

    internal procedure CreateServiceProvider(var PowerBIServiceProvider: Interface "Power BI Service Provider")
    var
        PowerBIUrlMgt: Codeunit "Power BI Url Mgt";
        PowerBIRestServiceProvider: Codeunit "Power BI Rest Service Provider";
        AzureAccessToken: SecretText;
        Handled: Boolean;
    begin
        OnServiceProviderCreate(PowerBIServiceProvider, Handled);

        if Handled then
            exit;

        AzureAccessToken := AzureAdMgt.GetAccessTokenAsSecretText(GetPowerBIResourceUrl(), GetPowerBiResourceName(), false);

        if AzureAccessToken.IsEmpty() then begin
            Session.LogMessage('0000B62', EmptyAccessTokenTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiTelemetryCategoryLbl);
            Error(UnauthorizedErr);
        end;

        PowerBIRestServiceProvider.Initialize(AzureAccessToken, PowerBIUrlMgt.GetPowerBIApiUrl());
        PowerBIServiceProvider := PowerBIRestServiceProvider;
    end;

    [InternalEvent(false)]
    local procedure OnServiceProviderCreate(var PowerBIServiceProvider: Interface "Power BI Service Provider"; var Handled: Boolean)
    begin
    end;
}