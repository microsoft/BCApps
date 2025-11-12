namespace System.Integration.PowerBI;

using System.Environment;
using System.Telemetry;
using System.Utilities;
using System.Environment.Configuration;
using System.Integration;
using System.Globalization;

page 6325 "Power BI Embedded Report Part"
{
    Caption = 'Power BI';
    PageType = CardPart;
    SourceTable = "Power BI Displayed Element";
    Editable = false;
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            group(OptInControlGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::GetStarted;

                field(OptInGettingStarted; GettingStartedTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Specifies whether the Power BI functionality is enabled.';

                    trigger OnDrillDown()
                    var
                        PowerBIEmbedSetupWizard: Page "Power BI Embed Setup Wizard";
                    begin
                        FeatureTelemetry.LogUptake('0000GJP', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
                        Commit();

                        PowerBIEmbedSetupWizard.SetContext(PageContext);
                        if PowerBIEmbedSetupWizard.RunModal() <> Action::Cancel then
                            ReloadPageState();
                    end;
                }
                field(OptInImageField; MediaResources."Media Reference")
                {
                    Caption = '';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(DeployReportsGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::ShouldDeploy;

                field(DeployReportsLink; DeployReportsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Specifies that the user can upload one or more demo reports for this page.';

                    trigger OnDrillDown()
                    begin
                        StartAutoDeployment();
                        Message(ReportsDeployingMsg);

                        CurrPage.Update(false);
                    end;
                }
                field(OptInImageField2; MediaResources."Media Reference")
                {
                    Caption = '';
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(ReportGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::ElementVisible;

                usercontrol(WebReportViewer; WebPageViewer)
                {
                    ApplicationArea = All;
                    Visible = false;
                }

                usercontrol(PowerBIAddin; PowerBIManagement)
                {
                    ApplicationArea = All;

                    trigger ControlAddInReady()
                    begin
                        AddInReady := true;

                        if not Rec.IsEmpty() then
                            SetReport();
                    end;

                    trigger ReportLoaded(ReportFilters: Text; ActivePageName: Text; ActivePageFilters: Text; CorrelationId: Text)
                    begin
                        PowerBiServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::Report);
                        if not AvailableReportLevelFilters.ReadFrom(ReportFilters) then
                            Clear(AvailableReportLevelFilters);

                        PushFiltersToAddin();
                    end;

                    trigger DashboardLoaded(CorrelationId: Text)
                    begin
                        PowerBiServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::Dashboard);
                    end;

                    trigger DashboardTileLoaded(CorrelationId: Text)
                    begin
                        PowerBiServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::"Dashboard Tile");
                    end;

                    trigger ErrorOccurred(Operation: Text; ErrorText: Text)
                    begin
                        PowerBiServiceMgt.LogEmbedError(Operation);
                        ShowError(Operation, ErrorText);
                    end;

                    trigger ReportPageChanged(newPage: Text; newPageFilters: Text)
                    begin
                        Rec.ReportPage := CopyStr(newPage, 1, MaxStrLen(Rec.ReportPage));
                        Rec.Modify(true);
                    end;
                }
            }
#if not CLEAN25
            group(ErrorGroup)
            {
                ShowCaption = false;
                Visible = false;
                ObsoleteReason = 'Error messages are now shown as page notifications.';
                ObsoleteState = Pending;
                ObsoleteTag = '25.0';
                label(Spacer)
                {
                    ApplicationArea = All;
                    Caption = ' ';
                    Visible = false;
                    ObsoleteReason = 'Error messages are now shown as page notifications.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
                field(ErrorMessageText; ErrorMessageText)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                    ShowCaption = false;
                    ToolTip = 'Specifies the error message from Power BI.';
                    Visible = false;
                    ObsoleteReason = 'Error messages are now shown as page notifications.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '25.0';
                }
            }
#endif
            group(NoReportGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::NoElementSelected;

                label(Spacer1)
                {
                    ApplicationArea = All;
                    Caption = ' ';
                }
                label(EmptyMessage)
                {
                    ApplicationArea = All;
                    Caption = 'There are no enabled reports.';
                    Editable = false;
                    ShowCaption = false;
                }
                field(SelectReportsLink; SelectReportsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Specifies that the user can select the reports to show from here.';
                    Visible = not LockedToFirstElement;

                    trigger OnDrillDown()
                    begin
                        SelectReports();
                    end;
                }
            }
            group(DeployingReportsGroup)
            {
                ShowCaption = false;
                Visible = PageState = PageState::NoElementSelectedButDeploying;

                label(Spacer2)
                {
                    ApplicationArea = All;
                    Caption = ' ';
                }
                label(EmptyMessage2)
                {
                    ApplicationArea = All;
                    Caption = 'There are no enabled reports.';
                    Editable = false;
                    ShowCaption = false;
                }
                label(NoReportsMessage)
                {
                    ApplicationArea = All;
                    Caption = 'If you just started the upload of new reports from Business Central, choose Reload to see if they''ve completed.';
                    Editable = false;
                    ShowCaption = false;
                }
                field(SelectReportsLink2; SelectReportsTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Specifies that the user can select the reports to show from here.';
                    Visible = not LockedToFirstElement;

                    trigger OnDrillDown()
                    begin
                        SelectReports();
                    end;
                }
                field(RefreshPartLink; RefreshPartTxt)
                {
                    ApplicationArea = All;
                    Editable = false;
                    ShowCaption = false;
                    Style = StrongAccent;
                    StyleExpr = true;
                    ToolTip = 'Specifies that the user can reload the page part. If reports have been deployed in the background, reloading the page part will make them visible.';

                    trigger OnDrillDown()
                    var
                        PreviousPageState: Option;
                    begin
                        PreviousPageState := PageState;
                        ReloadPageState();

                        CurrPage.Update(false);

                        if (PageState = PageState::NoElementSelectedButDeploying) and (PreviousPageState = PageState::NoElementSelectedButDeploying) then
                            Message(StillDeployingMsg);
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Select Report")
            {
                ApplicationArea = All;
                Caption = 'Select Report';
                ToolTip = 'Select the report.';
                Image = SelectChart;
                Visible = not LockedToFirstElement;
                Enabled = PageState <> PageState::GetStarted;

                trigger OnAction()
                begin
                    SelectReports();
                    FeatureTelemetry.LogUsage('0000L04', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), 'Power BI reports selected');
                end;
            }
            action("Previous Report")
            {
                ApplicationArea = All;
                Caption = 'Previous';
                ToolTip = 'Go to the previous Power BI element.';
                Image = PreviousSet;
                Visible = not LockedToFirstElement;
                Enabled = PageState = PageState::ElementVisible;

                trigger OnAction()
                begin
                    if Rec.Next(-1) = 0 then
                        Rec.FindLast();

                    if AddInReady then
                        SetReport();

                    FeatureTelemetry.LogUsage('0000L05', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), 'Power BI report changed', GetTelemetryDimensions());
                end;
            }
            action("Next Report")
            {
                ApplicationArea = All;
                Caption = 'Next';
                ToolTip = 'Go to the next Power BI element.';
                Image = NextSet;
                Visible = not LockedToFirstElement;
                Enabled = PageState = PageState::ElementVisible;

                trigger OnAction()
                begin
                    if Rec.Next() = 0 then
                        Rec.FindFirst();

                    if AddInReady then
                        SetReport();

                    FeatureTelemetry.LogUsage('0000L08', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), 'Power BI report changed', GetTelemetryDimensions());
                end;
            }
            action(ExpandReport)
            {
                ApplicationArea = All;
                Caption = 'Expand';
                ToolTip = 'Opens the currently selected element in a larger page.';
                Image = PowerBI;
                Enabled = PageState = PageState::ElementVisible;

                trigger OnAction()
                var
                    PowerBIElementAddinHost: Page "Power BI Element Addin Host";
                begin
                    PowerBIElementAddinHost.SetDisplayedElement(Rec);
                    PowerBIElementAddinHost.SetPowerBIFilter(PowerBIFilter);
                    PowerBIElementAddinHost.Run();

                    ReloadPageState();
                    FeatureTelemetry.LogUsage('0000L09', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), 'Power BI element expanded', GetTelemetryDimensions());
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Reload';
                ToolTip = 'Reloads the Power BI subpage.';
                Image = Refresh;
                Enabled = PageState <> PageState::GetStarted;

                trigger OnAction()
                begin
                    ReloadPageState();
                end;
            }
            action("Upload Report")
            {
                ApplicationArea = All;
                Caption = 'Upload Report';
                ToolTip = 'Uploads a report from a PBIX file.';
                Image = Add;
                Visible = IsSaaSUser;
                Enabled = (PageState = PageState::ElementVisible) or (PageState = PageState::NoElementSelected) or (PageState = PageState::NoElementSelectedButDeploying) or (PageState = PageState::ShouldDeploy);

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Upload Power BI Report");
                    ReloadPageState();
                end;
            }
            action("Reset My Reports")
            {
                ApplicationArea = All;
                Caption = 'Reset My Reports';
                ToolTip = 'Resets all Power BI setup in Business Central, for the current user. Reports in your Power BI workspaces are not affected and need to be removed manually.';
                Image = Reuse;

                trigger OnAction()
                var
                    PowerBIReportUploads: Record "Power BI Report Uploads";
                    PowerBIContextSettings: Record "Power BI Context Settings";
                    LocalPowerBIDisplayedElement: Record "Power BI Displayed Element";
                begin
                    if Confirm(ResetReportsCurrentUserQst, false) then begin
                        Session.LogMessage('0000LSP', ReportsResetUserTelemetryMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

                        PowerBIContextSettings.SetRange(UserSID, UserSecurityId());
                        PowerBIContextSettings.DeleteAll();
                        LocalPowerBIDisplayedElement.SetRange(UserSID, UserSecurityId());
                        LocalPowerBIDisplayedElement.DeleteAll();
                        PowerBIReportUploads.SetRange("User ID", UserSecurityId());
                        PowerBIReportUploads.DeleteAll();

                        Commit();
                        ReloadPageState();

                        FeatureTelemetry.LogUptake('0000LSO', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), Enum::"Feature Uptake Status"::Undiscovered);
                    end;
                end;
            }
            action("Reset All Reports")
            {
                ApplicationArea = All;
                Caption = 'Reset Reports for All Users';
                ToolTip = 'Resets all Power BI setup in Business Central, for all users. Reports in your Power BI workspaces are not affected and need to be removed manually.';
                Image = Reuse;
                Visible = IsPBIAdmin;

                trigger OnAction()
                var
                    PowerBIReportUploads: Record "Power BI Report Uploads";
                    PowerBIContextSettings: Record "Power BI Context Settings";
                    PowerBICustomerReports: Record "Power BI Customer Reports";
                    LocalPowerBIDisplayedElement: Record "Power BI Displayed Element";
                    ChosenOption: Integer;
                begin
                    ChosenOption := StrMenu(ResetReportsOptionsTxt, 1, ResetReportsQst);

                    Session.LogMessage('0000GJQ', StrSubstNo(ReportsResetTelemetryMsg, ChosenOption), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());

                    if ChosenOption in [1, 2] then begin // Delete reports only or delete all
                        PowerBIContextSettings.DeleteAll();
                        LocalPowerBIDisplayedElement.DeleteAll();

                        if ChosenOption = 2 then begin // Delete all
                            PowerBICustomerReports.DeleteAll();
                            PowerBIReportUploads.DeleteAll();
                        end;

                        Commit();
                        ReloadPageState();

                        FeatureTelemetry.LogUptake('0000L03', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), Enum::"Feature Uptake Status"::Undiscovered);
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        IsPBIAdmin := PowerBiServiceMgt.IsUserAdminForPowerBI(UserSecurityId());
        IsSaaSUser := EnvironmentInformation.IsSaaSInfrastructure(); // SaaS but not Docker
    end;

    trigger OnOpenPage()
    begin
        // The web client doesn't open parts that are not visible
        IsPartVisible := true;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        PreviousFilterGroup: Integer;
    begin
        Rec.SetRange(UserSID, UserSecurityId());

        PreviousFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4);

        if PageContext = '' then
            PageContext := CopyStr(Rec.GetFilter(Context), 1, MaxStrLen(PageContext));

        if PageContext = '' then
            PageContext := PowerBiServiceMgt.GetEnglishContext();

        Rec.SetRange(Context, PageContext);
        Rec.FilterGroup(PreviousFilterGroup);

        ReloadPageState();

        if Rec.IsEmpty() then
            exit(true);

        exit(Rec.Find(Which));
    end;

    trigger OnModifyRecord(): Boolean
    begin
        // Workaround: Even if the page is Editable = false, modifications can be issued to the record, and the record
        // can be non-existent because of custom logic in OnFindRecord.
        if IsNullGuid(Rec.UserSID) and (Rec.ElementId = '') then
            exit(false);
    end;

    var
        PowerBIFilter: Record "Power BI Filter";
        MediaResources: Record "Media Resources";
        PowerBiServiceMgt: Codeunit "Power BI Service Mgt.";
        PowerBiFilterHelper: Codeunit "Power BI Filter Helper";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ErrorNotificationMsg: Label 'An error occurred while loading Power BI. Your Power BI embedded content might not work. Here are the error details: "%1:%2"', Comment = '%1: A short error code. %2: The tecnical details of the error.';
        ResetReportsQst: Label 'This action will clear some or all of the Power BI report setup for all users in the company you''re currently working with. Note: This action doesn''t delete reports in Power BI workspaces.';
        ResetReportsCurrentUserQst: Label 'This action will clear all of your Power BI report setup in the company you''re currently working with. Note: This action doesn''t delete reports in Power BI workspaces.\\Do you want to continue?';
        ResetReportsOptionsTxt: Label 'Clear Power BI report selections for all pages and users,Reset the entire Power BI report setup', Comment = 'A comma-separated list of options';
        PowerBiOptInImageNameLbl: Label 'PowerBi-OptIn-480px.png', Locked = true;
        GettingStartedTxt: Label 'Get started with Power BI';
        DeployReportsTxt: Label 'Upload demo reports for this page';
        UnsupportedElementTypeErr: Label 'Displaying Power BI elements of type %1 is currently not supported.', Comment = '%1 = an element type, such as Report or Workspace';
        ReportsDeployingMsg: Label 'We are uploading a demo report to Power BI in the background for you. Once the upload finishes, choose Reload to see it in this page.\\If you have already reports in your Power BI workspace, you can choose Select Reports instead.';
        StillDeployingMsg: Label 'We are still uploading your demo report. Once the upload finishes, choose Reload again to see it in this page.\\If you have already reports in your Power BI workspace, you can choose Select Reports instead.';
        RefreshPartTxt: Label 'Reload';
        SelectReportsTxt: Label 'Select reports';
        PageState: Option GetStarted,ShouldDeploy,NoElementSelected,NoElementSelectedButDeploying,ElementVisible;
        AvailableReportLevelFilters: JsonArray;
        PageContext: Text[30];
        AddInReady: Boolean;
#if not CLEAN25
        ErrorMessageText: Text;
#endif
        IsSaaSUser: Boolean;
        IsPBIAdmin: Boolean;
        IsPartVisible: Boolean;
        LockedToFirstElement: Boolean;
        // Telemetry labels
        NoOptInImageTxt: Label 'There is no Power BI Opt-in image in the Database with ID: %1', Locked = true;
        ReportsResetTelemetryMsg: Label 'User has reset Power BI setup for everyone, option chosen: %1', Locked = true;
        ReportsResetUserTelemetryMsg: Label 'User has reset their own Power BI setup.', Locked = true;

    local procedure ReloadPageState()
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        PowerBIReportSynchronizer: Codeunit "Power BI Report Synchronizer";
    begin
        ClearNotifications();

        PowerBIContextSettings.SetRange(UserSID, UserSecurityId());
        if PowerBIContextSettings.IsEmpty() then begin
            LoadOptInImage();
            PageState := PageState::GetStarted;
            exit;
        end;

        PowerBIContextSettings.CreateOrReadForCurrentUser(PageContext);
        LockedToFirstElement := PowerBIContextSettings.LockToSelectedElement;

        if not Rec.Get(UserSecurityId(), PageContext, PowerBIContextSettings.SelectedElementId, PowerBIContextSettings.SelectedElementType) then
            if Rec.FindFirst() then;

        if Rec.IsEmpty() then begin
            if PowerBiServiceMgt.IsUserSynchronizingReports() then begin
                PageState := PageState::NoElementSelectedButDeploying;
                exit;
            end;

            if PowerBIReportSynchronizer.UserNeedsToSynchronize(PageContext) then begin
                LoadOptInImage();
                PageState := PageState::ShouldDeploy;
                exit;
            end;

            PageState := PageState::NoElementSelected;
            exit;
        end;

        PageState := PageState::ElementVisible;

        if AddInReady then
            SetReport();
    end;

    local procedure StartAutoDeployment()
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
    begin
        // Ensure user config for context before deployment
        if PageContext = '' then
            exit;

        PowerBIContextSettings.CreateOrReadForCurrentUser(PageContext);
        PowerBiServiceMgt.SynchronizeReportsInBackground(PageContext);
    end;

    local procedure SetReport()
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        Language: Codeunit Language;
        DashboardId: Guid;
        ReportId: Guid;
        TileId: Guid;
        PageName: Text[200];
        VisualName: Text[200];
    begin
        FeatureTelemetry.LogUptake('0000GJR', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), Enum::"Feature Uptake Status"::Used);

        PowerBIContextSettings.CreateOrUpdateSelectedElement(Rec);
        ClearNotifications();

        if (rec.ShowPanesInNormalMode) then begin
            CurrPage.PowerBIAddin.SetFiltersVisible(true);
            CurrPage.PowerBIAddin.SetPageSelectionVisible(true);
        end;

        CurrPage.PowerBIAddin.SetTransparentBackground(true);
        CurrPage.PowerBIAddin.SetLocale(Language.GetUserLanguageTag());
        PowerBiServiceMgt.InitializeAddinToken(CurrPage.PowerBIAddin);

        case Rec.ElementType of
            "Power BI Element Type"::"Report":
                begin
                    Rec.ParseReportKey(ReportId);
                    CurrPage.PowerBIAddin.EmbedPowerBIReport(Rec.ElementEmbedUrl, ReportId, Rec.ReportPage);
                end;
            "Power BI Element Type"::"Report Visual":
                begin
                    Rec.ParseReportVisualKey(ReportId, PageName, VisualName);
                    CurrPage.PowerBIAddin.EmbedPowerBIReportVisual(Rec.ElementEmbedUrl, ReportId, PageName, VisualName);
                end;
            "Power BI Element Type"::Dashboard:
                begin
                    Rec.ParseDashboardKey(DashboardId);
                    CurrPage.PowerBIAddin.EmbedPowerBIDashboard(Rec.ElementEmbedUrl, DashboardId);
                end;
            "Power BI Element Type"::"Dashboard Tile":
                begin
                    Rec.ParseDashboardTileKey(DashboardId, TileId);
                    CurrPage.PowerBIAddin.EmbedPowerBIDashboardTile(Rec.ElementEmbedUrl, DashboardId, TileId);
                end;
            else
                ShowError('UnsupportedElementType', StrSubstNo(UnsupportedElementTypeErr, Rec.ElementType));
        end;
    end;

    local procedure SelectReports()
    var
        PowerBIWSReportSelection: Page "Power BI WS Report Selection";
    begin
        PowerBIWSReportSelection.SetContext(PageContext);
        PowerBIWSReportSelection.LookupMode(true);
        PowerBIWSReportSelection.RunModal();

        ReloadPageState();
    end;

    local procedure ShowError(ErrorCategory: Text; ErrorMessage: Text)
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        Notif: Notification;
    begin
        Notif.Id := CreateGuid();
        Notif.Message(StrSubstNo(ErrorNotificationMsg, ErrorCategory, ErrorMessage));
        Notif.Scope := NotificationScope::LocalScope;

        NotificationLifecycleMgt.SendNotification(Notif, PowerBIContextSettings.RecordId());
    end;

    local procedure ClearNotifications()
    var
        PowerBIContextSettings: Record "Power BI Context Settings";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        NotificationLifecycleMgt.RecallNotificationsForRecord(PowerBIContextSettings.RecordId(), true);
    end;

    local procedure LoadOptInImage()
    var
        MediaRepository: Record "Media Repository";
    begin
        if not MediaResources."Media Reference".HasValue() then begin
            if MediaRepository.GetForCurrentClientType(PowerBiOptInImageNameLbl) then
                if MediaResources.Get(MediaRepository."Media Resources Ref") then
                    exit;

            // Very old tenants might not have this image: let's not spam telemetry with warnings
            Session.LogMessage('0000GJT', StrSubstNo(NoOptInImageTxt, PowerBiOptInImageNameLbl), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
        end;
    end;

    local procedure ShouldCalculateFilter(): Boolean
    begin
        // When the page just opened, we want to have an initial filter pointing to the single selected record (the first in the list).
        // This will be applied when (and if) the part is actually visible.
        // If we have already the initial filter, we should calculate filters only if the part is visible and there is a filter to use.
        if not PowerBIFilter.IsEmpty() then
            exit(IsPartVisible and (AvailableReportLevelFilters.Count() > 0));

        exit(true);
    end;

    local procedure GetTelemetryDimensions(): Dictionary of [Text, Text]
    begin
        exit(Rec.GetTelemetryDimensions());
    end;

    local procedure PushFiltersToAddin()
    var
        ReportFiltersJArray: JsonArray;
        ReportFiltersToSet: Text;
        AvailableReportFiltersText: Text;
    begin
        if AvailableReportLevelFilters.Count() = 0 then
            exit;

        if Rec.ElementType <> Rec.ElementType::"Report" then
            exit;

        ReportFiltersJArray := PowerBiFilterHelper.MergeIntoFirstFilter(AvailableReportLevelFilters, PowerBiFilter);

        ReportFiltersJArray.WriteTo(ReportFiltersToSet);
        AvailableReportLevelFilters.WriteTo(AvailableReportFiltersText);

        if ReportFiltersToSet = AvailableReportFiltersText then
            exit;

        CurrPage.PowerBIAddin.UpdateReportFilters(ReportFiltersToSet);
    end;

    #region ExternalInterface

#if not CLEAN25
    [Obsolete('Setting the page ratio is no longer supported. The add-in will instead be sized based on the available space in the client.', '25.0')]
    procedure InitPageRatio(ReportFrameRatioInput: Text)
    begin
    end;

    [Obsolete('Setting full page mode is no longer supported. The add-in will instead be sized based on the available space in the client.', '25.0')]
    procedure SetFullPageMode(NewFullPageMode: Boolean)
    begin
    end;
#endif

    procedure SetPageContext(InputContext: Text)
    begin
        PageContext := CopyStr(InputContext, 1, MaxStrLen(PageContext));
    end;

    /// <summary>
    /// Filters the currently displayed Power BI report to multiple values.
    /// These values are picked from the field number <paramref name="FieldNumber"/> in the records within the filter of <paramref name="FilteringVariant"/>.
    /// </summary>
    /// <remarks>
    /// The values will be applied to the first filter defined in the Power BI report. If no record falls within the filter, the filter is reset to all values.
    /// </remarks>
    /// <param name="FilteringVariant">A Record or RecordRef filtered to the records to show in the Power BI Report.</param>
    /// <param name="FieldNumber">The number of the field of <paramref name="FilteringVariant"/> that should be used for filtering the Power BI Report.</param>
    procedure SetFilterToMultipleValues(FilteringVariant: Variant; FieldNumber: Integer)
    var
        FilteringRecordRef: RecordRef;
    begin
        if not ShouldCalculateFilter() then
            exit;

        case true of
            FilteringVariant.IsRecordRef():
                FilteringRecordRef := FilteringVariant;
            FilteringVariant.IsRecord():
                FilteringRecordRef.GetTable(FilteringVariant);
            else
                exit;
        end;

        PowerBiFilterHelper.RecordRefToFilterRecord(FilteringRecordRef, FieldNumber, PowerBiFilter);

        PushFiltersToAddin();
    end;

    /// <summary>
    /// Filters the currently displayed Power BI report to a single value. Only values of primitive types (such as Text, Code, Guid, Integer, Date) are supported.
    /// </summary>
    /// <remarks>
    /// The value will be applied to the first filter defined in the Power BI report.
    /// </remarks>
    /// <param name="InputSelectionVariant">A value to set as filter for the Power BI Report.</param>
    procedure SetCurrentListSelection(InputSelectionVariant: Variant)
    begin
        if not ShouldCalculateFilter() then
            exit;

        PowerBiFilterHelper.VariantToFilterRecord(InputSelectionVariant, PowerBiFilter);
        PushFiltersToAddin();
    end;

    [Scope('OnPrem')]
    procedure GetOptinImageName(): Text[250]
    begin
        exit(PowerBiOptInImageNameLbl);
    end;

    #endregion
}