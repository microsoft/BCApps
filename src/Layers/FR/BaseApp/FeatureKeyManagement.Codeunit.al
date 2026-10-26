// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment.Configuration;

using Microsoft.Pricing.Calculation;
#if not CLEAN30
using System.Apps;
#endif

codeunit 265 "Feature Key Management"
{
    Access = Internal;
    SingleInstance = true;
#if not CLEAN30
    Permissions = tabledata "NAV App Installed App" = r;
#endif

    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        FeatureTelemetry: Codeunit System.Telemetry."Feature Telemetry";
        AutomaticAccountCodesTxt: Label 'AutomaticAccountCodes', Locked = true;
        SIEAuditFileExportTxt: Label 'SIEAuditFileExport', Locked = true;
#if not CLEAN30
        ReportsFRTok: Label 'FRReports', Locked = true;
        ReportsFRAppIdTok: Label '6f93dbc5-c674-430e-b5f4-232449d55c20', Locked = true;
        ReportsFRAppNotInstalledErr: Label 'The Reports FR feature requires the Reports FR app. Install the app on the Extension Management page before enabling or using the feature.';
#endif
#if not CLEAN28
        PaymentTok: Label 'Payment', Locked = true;
#endif
        DocumentReportExperienceTxt: Label 'DocumentReportExperience', Locked = true;
        ConcurrentInventoryPostingLbl: Label 'ConcurrentInventoryPosting', Locked = true;
        ConcurrentInventoryPosting: Boolean;
        ConcurrentInventoryPostingRead: Boolean;
        ConcurrentJobPostingLbl: Label 'ConcurrentJobPosting', Locked = true;
        ConcurrentJobPosting: Boolean;
        ConcurrentJobPostingRead: Boolean;
        ConcurrentResourcePostingLbl: Label 'ConcurrentResourcePosting', Locked = true;
        ConcurrentResourcePosting: Boolean;
        ConcurrentResourcePostingRead: Boolean;


    procedure IsAutomaticAccountCodesEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetAutomaticAccountCodesFeatureKey()));
    end;

    procedure IsSIEAuditFileExportEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(GetSIEAuditFileExportFeatureKeyId()));
    end;

#if not CLEAN30
    procedure IsPaymentManagementEnabled(): Boolean
    begin
#if not CLEAN28
        exit(FeatureManagementFacade.IsEnabled(PaymentTok));
#else
        exit(true);
#endif
    end;
#endif

    procedure IsDocumentReportExperienceEnabled(): Boolean
    begin
        exit(FeatureManagementFacade.IsEnabled(DocumentReportExperienceTxt));
    end;

#if not CLEAN30
    procedure IsReportsFREnabled(): Boolean
    begin
        if not FeatureManagementFacade.IsEnabled(ReportsFRTok, false) then
            exit(false);

        VerifyReportsFRAppInstalled();
        exit(true);
    end;

    local procedure VerifyReportsFRAppInstalled()
    var
        [SecurityFiltering(SecurityFilter::Ignored)]
        NAVAppInstalledApp: Record "NAV App Installed App";
        ReportsFRAppId: Guid;
    begin
        ReportsFRAppId := ReportsFRAppIdTok;
        if not NAVAppInstalledApp.Get(ReportsFRAppId) then
            Error(ReportsFRAppNotInstalledErr);
    end;
#endif

#if not CLEAN27
    [Obsolete('This function is deprecated. Concurrent warehouse posting is always on.', '27.0')]
    procedure IsConcurrentWarehousingPostingEnabled(): Boolean
    begin
        exit(true);
    end;
#endif

    procedure IsConcurrentInventoryPostingEnabled(): Boolean
    begin
        if not ConcurrentInventoryPostingRead then
            ConcurrentInventoryPosting := FeatureManagementFacade.IsEnabled(ConcurrentInventoryPostingLbl);
        ConcurrentInventoryPostingRead := true;
        OnAfterIsConcurrentInventoryPostingEnabled(ConcurrentInventoryPosting);
        exit(ConcurrentInventoryPosting);
    end;

    procedure IsConcurrentJobPostingEnabled(): Boolean
    begin
        if not ConcurrentJobPostingRead then
            ConcurrentJobPosting := FeatureManagementFacade.IsEnabled(ConcurrentJobPostingLbl);
        ConcurrentJobPostingRead := true;
        exit(ConcurrentJobPosting);
    end;

    procedure IsConcurrentResourcePostingEnabled(): Boolean
    begin
        if not ConcurrentResourcePostingRead then
            ConcurrentResourcePosting := FeatureManagementFacade.IsEnabled(ConcurrentResourcePostingLbl);
        ConcurrentResourcePostingRead := true;
        exit(ConcurrentResourcePosting);
    end;

    local procedure GetAutomaticAccountCodesFeatureKey(): Text[50]
    begin
        exit(AutomaticAccountCodesTxt);
    end;

    local procedure GetSIEAuditFileExportFeatureKeyId(): Text[50]
    begin
        exit(SIEAuditFileExportTxt);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureEnableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureEnableConfirmed(var FeatureKey: Record "Feature Key")
    begin
#if not CLEAN30
        if FeatureKey.ID = ReportsFRTok then
            VerifyReportsFRAppInstalled();
#endif

        // Log feature uptake
        case FeatureKey.ID of
            ConcurrentInventoryPostingLbl:
                FeatureTelemetry.LogUptake('0000OSN', ConcurrentInventoryPostingLbl, Enum::System.Telemetry."Feature Uptake Status"::Discovered);
            ConcurrentJobPostingLbl:
                FeatureTelemetry.LogUptake('0000OSO', ConcurrentJobPostingLbl, Enum::System.Telemetry."Feature Uptake Status"::Discovered);
            ConcurrentResourcePostingLbl:
                FeatureTelemetry.LogUptake('0000OSP', ConcurrentResourcePostingLbl, Enum::System.Telemetry."Feature Uptake Status"::Discovered);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterFeatureDisableConfirmed', '', false, false)]
    local procedure HandleOnAfterFeatureDisableConfirmed(FeatureKey: Record "Feature Key")
    begin
        // Log feature
        case FeatureKey.ID of
            ConcurrentInventoryPostingLbl:
                FeatureTelemetry.LogUptake('0000OSQ', ConcurrentInventoryPostingLbl, Enum::System.Telemetry."Feature Uptake Status"::Undiscovered);
            ConcurrentJobPostingLbl:
                FeatureTelemetry.LogUptake('0000OSR', ConcurrentJobPostingLbl, Enum::System.Telemetry."Feature Uptake Status"::Undiscovered);
            ConcurrentResourcePostingLbl:
                FeatureTelemetry.LogUptake('0000OSS', ConcurrentResourcePostingLbl, Enum::System.Telemetry."Feature Uptake Status"::Undiscovered);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Feature Management Facade", 'OnAfterUpdateData', '', false, false)]
    local procedure HandleOnAfterUpdateData(var FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FeatureTelemetry: Codeunit System.Telemetry."Feature Telemetry";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        // Log feature uptake
        if FeatureDataUpdateStatus."Feature Status" <> FeatureDataUpdateStatus."Feature Status"::Complete then
            exit;
        case FeatureDataUpdateStatus."Feature Key" of
            PriceCalculationMgt.GetFeatureKey():
                FeatureTelemetry.LogUptake('0000LLR', PriceCalculationMgt.GetFeatureTelemetryName(), Enum::System.Telemetry."Feature Uptake Status"::Discovered);
        end;
    end;

    [InternalEvent(false)]
    local procedure OnAfterIsConcurrentInventoryPostingEnabled(var ConcurrentInventoryPosting: Boolean)
    begin
    end;
}
