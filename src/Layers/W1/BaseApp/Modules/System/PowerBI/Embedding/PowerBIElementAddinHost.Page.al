namespace System.Integration.PowerBI;
using System.Telemetry;
using System.Environment.Configuration;
using System.Globalization;

page 6324 "Power BI Element Addin Host"
{
    Caption = 'Power BI';
    PageType = UserControlHost;

    layout
    {
        area(content)
        {
            usercontrol(PowerBIManagement; PowerBIManagement)
            {
                ApplicationArea = All;

                trigger ControlAddInReady()
                begin
                    InitializeAddIn();
                end;

                trigger ReportLoaded(ReportFilters: Text; ActivePageName: Text; ActivePageFilters: Text; CorrelationId: Text)
                begin
                    PowerBIServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::Report);
                    if not AvailableReportLevelFilters.ReadFrom(ReportFilters) then
                        Clear(AvailableReportLevelFilters);

                    PushFiltersToAddin();
                end;

                trigger DashboardLoaded(CorrelationId: Text)
                begin
                    PowerBIServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::Dashboard);
                end;

                trigger DashboardTileLoaded(CorrelationId: Text)
                begin
                    PowerBIServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::"Dashboard Tile");
                end;

                trigger ReportVisualLoaded(CorrelationId: Text)
                begin
                    PowerBIServiceMgt.LogVisualLoaded(CorrelationId, Enum::"Power BI Element Type"::"Report Visual");
                end;

                trigger ErrorOccurred(Operation: Text; ErrorText: Text)
                begin
                    PowerBIServiceMgt.LogEmbedError(Operation);
                    ShowError(Operation, ErrorText);
                end;

                trigger ReportPageChanged(newPage: Text; newPageFilters: Text)
                begin
                    if PowerBIDisplayedElement.IsTemporary() then
                        exit;

                    PowerBIDisplayedElement.ReportPage := CopyStr(newPage, 1, MaxStrLen(PowerBIDisplayedElement.ReportPage));
                    if not PowerBIDisplayedElement.Modify(true) then
                        Session.LogMessage('0000LK8', FailedToUpdatePageTelemetryMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', PowerBiServiceMgt.GetPowerBiTelemetryCategory());
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not PowerBIServiceMgt.IsUserReadyForPowerBI() then
            ShowError('Unauthorized', UnauthorizedErr);
    end;

    var
        PowerBIDisplayedElement: Record "Power BI Displayed Element";
        PowerBIFilter: Record "Power BI Filter";
        PowerBIServiceMgt: Codeunit "Power BI Service Mgt.";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        PowerBiFilterHelper: Codeunit "Power BI Filter Helper";
        AvailableReportLevelFilters: JsonArray;
        ErrorNotificationMsg: Label 'An error occurred while loading Power BI. Your Power BI embedded content might not work. Here are the error details: "%1: %2"', Comment = '%1: a short error code. %2: a verbose error message in english';
        UnsupportedElementTypeErr: Label 'Displaying Power BI elements of type %1 is currently not supported.', Comment = '%1 = an element type, such as Report or Workspace';
        UnauthorizedErr: Label 'You do not have a Power BI account. If you have just activated a license, it might take several minutes for the changes to be effective in Power BI.';
        FailedToUpdatePageTelemetryMsg: Label 'Failed to update the page for the Power BI report.', Locked = true;

    procedure SetDisplayedElement(InputPowerBIDisplayedElement: Record "Power BI Displayed Element")
    begin
        PowerBIDisplayedElement := InputPowerBIDisplayedElement;
    end;

    internal procedure SetPowerBIFilter(var NewPowerBIFilter: Record "Power BI Filter")
    begin
        PowerBIFilter.Copy(NewPowerBIFilter, true);

        PushFiltersToAddin();
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
        PowerBiFilterHelper.VariantToFilterRecord(InputSelectionVariant, PowerBiFilter);
        PushFiltersToAddin();
    end;

    local procedure PushFiltersToAddin()
    var
        ReportFiltersJArray: JsonArray;
        ReportFiltersToSet: Text;
        AvailableReportFiltersText: Text;
    begin
        if AvailableReportLevelFilters.Count() = 0 then
            exit;

        if PowerBIDisplayedElement.ElementType <> PowerBIDisplayedElement.ElementType::"Report" then
            exit;

        ReportFiltersJArray := PowerBiFilterHelper.MergeIntoFirstFilter(AvailableReportLevelFilters, PowerBiFilter);

        ReportFiltersJArray.WriteTo(ReportFiltersToSet);
        AvailableReportLevelFilters.WriteTo(AvailableReportFiltersText);

        if ReportFiltersToSet = AvailableReportFiltersText then
            exit;

        CurrPage.PowerBIManagement.UpdateReportFilters(ReportFiltersToSet);
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

    local procedure InitializeAddIn()
    var
        Language: Codeunit Language;
        DashboardId: Guid;
        ReportId: Guid;
        TileId: Guid;
        PageName: Text[200];
        VisualName: Text[200];
    begin
        if (PowerBIDisplayedElement.ShowPanesInExpandedMode) then begin
            CurrPage.PowerBIManagement.SetFiltersVisible(true);
            CurrPage.PowerBIManagement.SetPageSelectionVisible(true);
        end;

        CurrPage.PowerBIManagement.AddBottomPadding(true);
        CurrPage.PowerBIManagement.SetLocale(Language.GetUserLanguageTag());
        PowerBiServiceMgt.InitializeAddinToken(CurrPage.PowerBIManagement);

        if PowerBIDisplayedElement.ElementEmbedUrl <> '' then
            case PowerBIDisplayedElement.ElementType of
                "Power BI Element Type"::"Report":
                    begin
                        PowerBIDisplayedElement.ParseReportKey(ReportId);
                        CurrPage.PowerBIManagement.EmbedPowerBIReport(PowerBIDisplayedElement.ElementEmbedUrl, ReportId, PowerBIDisplayedElement.ReportPage);
                    end;
                "Power BI Element Type"::"Report Visual":
                    begin
                        PowerBIDisplayedElement.ParseReportVisualKey(ReportId, PageName, VisualName);
                        CurrPage.PowerBIManagement.EmbedPowerBIReportVisual(PowerBIDisplayedElement.ElementEmbedUrl, ReportId, PageName, VisualName);
                    end;
                "Power BI Element Type"::Dashboard:
                    begin
                        PowerBIDisplayedElement.ParseDashboardKey(DashboardId);
                        CurrPage.PowerBIManagement.EmbedPowerBIDashboard(PowerBIDisplayedElement.ElementEmbedUrl, DashboardId);
                    end;
                "Power BI Element Type"::"Dashboard Tile":
                    begin
                        PowerBIDisplayedElement.ParseDashboardTileKey(DashboardId, TileId);
                        CurrPage.PowerBIManagement.EmbedPowerBIDashboardTile(PowerBIDisplayedElement.ElementEmbedUrl, DashboardId, TileId);
                    end;
                else
                    ShowError('UnsupportedElementType', StrSubstNo(UnsupportedElementTypeErr, PowerBIDisplayedElement.ElementType));
            end;

        FeatureTelemetry.LogUsage('0000LSN', PowerBIServiceMgt.GetPowerBiFeatureTelemetryName(), 'Power BI element loaded', PowerBIDisplayedElement.GetTelemetryDimensions());

        CurrPage.Update();
    end;
}
