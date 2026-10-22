// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reports;

using Microsoft.Bank.Check;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Reports;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Reporting;
using System.Environment.Configuration;
using System.Reflection;
using System.Security.Encryption;
using System.Upgrade;
using System.Utilities;

codeunit 10822 "Report Layouts FR"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Report Layout Selection" = rimd,
                  tabledata "Custom Report Layout" = rimd,
                  tabledata "Tenant Report Layout Selection" = rimd,
                  tabledata "Tenant Report Layout" = rimd,
                  tabledata "Object Options" = rimd,
#if not CLEAN30
                  tabledata "Feature Data Update Status" = m,
#endif
                  tabledata "Report Layout List" = r;

    internal procedure InitializeCompany()
#if not CLEAN30
    var
        FeatureKey: Record "Feature Key";
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
#endif
    begin
#if not CLEAN30
        if not FeatureKey.Get(ReportsFR.GetFeatureKeyId()) then
            exit;
        if FeatureKey."Data Update Required" then
            PrepareCompanyFeatureStatus(FeatureKey, FeatureDataUpdateStatus);
        if not IsActivationConfigured(FeatureKey) then
            exit;

        // Use configured activation, not IsEnabled: a company's pending update must run first.
        if FeatureDataUpdateStatus."Feature Status" = "Feature Status"::Complete then
            MigrateCheckLayout()
        else begin
            // A seeded historical tag is not proof that this company's pending setup has run.
            InitializeCheckLayout();
            FeatureManagementFacade.UpdateData(FeatureDataUpdateStatus);
        end;
#else
        InitializeCheckLayout();
#endif
        MigrateCompanyData();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    internal procedure MigrateCompanyData()
    var
        Migration: Codeunit "FR Fin. Schedule Migration";
        FinancialScheduleMgt: Codeunit "FR Financial Schedule Mgt.";
    begin
        MigrateCheckLayout();
        if Migration.IsMigrated() then
            exit;
        SetDefaultReportLayouts();
        FinancialScheduleMgt.ClassifyFinancialSchedules();
        Migration.Migrate();
    end;

#if not CLEAN30
    internal procedure PrepareCompanyFeatureStatus(FeatureKey: Record "Feature Key"; var FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
    begin
        FeatureKey.TestField(ID, ReportsFR.GetFeatureKeyId());
        FeatureKey.TestField("Data Update Required", true);
        FeatureManagementFacade.GetFeatureDataUpdateStatus(FeatureKey, FeatureDataUpdateStatus);
        if FeatureDataUpdateStatus."Data Update Required" then
            exit;

        // Existing status rows retain the metadata from their creation, even after the platform changes it.
        FeatureDataUpdateStatus."Data Update Required" := true;
        FeatureDataUpdateStatus.Modify();
    end;

    internal procedure IsActivationConfigured(FeatureKey: Record "Feature Key"): Boolean
    begin
        if FeatureKey.Enabled = FeatureKey.Enabled::None then
            exit(false);
        VerifyFeatureMetadata(FeatureKey);
        exit(true);
    end;

    internal procedure VerifyFeatureMetadata(FeatureKey: Record "Feature Key")
    var
#pragma warning disable AL0432
        ReportsFR: Codeunit "Reports FR";
#pragma warning restore AL0432
    begin
        FeatureKey.TestField(ID, ReportsFR.GetFeatureKeyId());
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure OnCompanyInitialize()
    begin
        InitializeCompany();
    end;

    internal procedure MigrateCheckLayout()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetCheckLayoutUpgradeTag()) then
            exit;

        InitializeCheckLayout();
    end;

    internal procedure InitializeCheckLayout()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        InitializeCheckLayout(CurrentModuleInfo.Id());
    end;

    internal procedure InitializeCheckLayout(AppId: Guid)
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        SetDefaultCheckLayout(AppId);
        if not UpgradeTag.HasUpgradeTag(GetCheckLayoutUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(GetCheckLayoutUpgradeTag());
    end;

    internal procedure GetCheckLayoutUpgradeTag(): Code[250]
    begin
        // Do not register this completion tag with SetAllUpgradeTags: new companies need layout setup.
        exit('MS-ReportsFR-CheckLayout-20261017');
    end;

    internal procedure SetDefaultCheckLayout(): Boolean
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        exit(SetDefaultCheckLayout(CurrentModuleInfo.Id()));
    end;

    local procedure SetDefaultCheckLayout(AppId: Guid): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        ReportLayoutSelection: Record "Report Layout Selection";
        TenantReportLayoutSelection: Record "Tenant Report Layout Selection";
        BaseApplicationId: Guid;
        EmptyGuid: Guid;
        SelectedCompany: Text[30];
        HasCompanySelection: Boolean;
    begin
        SelectedCompany := CopyStr(CompanyName(), 1, MaxStrLen(SelectedCompany));
        if not ReportLayoutSelection.Get(Report::Check, SelectedCompany) then
            if not ReportLayoutSelection.Get(Report::Check, '') then
                ReportLayoutSelection.Init();
        if ReportLayoutSelection."Report ID" <> 0 then
            if (ReportLayoutSelection.Type <> ReportLayoutSelection.Type::"RDLC (built-in)") or
               (ReportLayoutSelection."Custom Report Layout Code" <> '')
            then
                exit(true);

        HasCompanySelection := TenantReportLayoutSelection.Get(Report::Check, SelectedCompany, EmptyGuid);
        if not HasCompanySelection then
            if not TenantReportLayoutSelection.Get(Report::Check, '', EmptyGuid) then
                TenantReportLayoutSelection.Init();

        BaseApplicationId := BaseApplicationIdTok;
        if TenantReportLayoutSelection."Report ID" <> 0 then
            if (TenantReportLayoutSelection."App ID" <> BaseApplicationId) or
               (TenantReportLayoutSelection."Layout Name" <> 'RDLCLayout')
            then
                exit(true);

        GetCheckLayout(ReportLayoutList, AppId);

        TenantReportLayoutSelection."Report ID" := Report::Check;
        TenantReportLayoutSelection."Company Name" := SelectedCompany;
        TenantReportLayoutSelection."User ID" := EmptyGuid;
        TenantReportLayoutSelection."App ID" := ReportLayoutList."Application ID";
        TenantReportLayoutSelection."Layout Name" := ReportLayoutList.Name;
        if HasCompanySelection then
            TenantReportLayoutSelection.Modify(true)
        else
            TenantReportLayoutSelection.Insert(true);

        if not ReportLayoutSelection.Get(Report::Check, SelectedCompany) then begin
            ReportLayoutSelection.Init();
            ReportLayoutSelection."Report ID" := Report::Check;
            ReportLayoutSelection."Company Name" := SelectedCompany;
            ReportLayoutSelection.Type := ReportLayoutSelection.Type::"RDLC (built-in)";
            ReportLayoutSelection.Insert(true);
        end;

        exit(true);
    end;

    internal procedure GetCheckLayout(var ReportLayoutList: Record "Report Layout List"; AppId: Guid)
    begin
        ReportLayoutList.SetRange("Report ID", Report::Check);
        ReportLayoutList.SetRange(Name, 'CheckFR');
        ReportLayoutList.SetRange("Application ID", AppId);
        if not ReportLayoutList.FindFirst() then
            Error(MissingCheckLayoutErr);
    end;

    var
        ApplicationIdTok: Label '{6f93dbc5-c674-430e-b5f4-232449d55c20}', Locked = true;
        LayoutNameTok: Label 'FRFinancialReporting', Locked = true;
        BaseApplicationIdTok: Label '{437dbf0e-84ff-417a-965d-ed2bb9650972}', Locked = true;
        MissingCheckLayoutErr: Label 'The CheckFR layout from Reports FR is not available. Install the Reports FR layout and retry the feature data update. Check layout migration has not completed.';
        MissingLayoutErr: Label 'The French Trial Balance/Previous Year layout is unavailable. Publish Reports FR before activating French financial reporting.';
        UnsupportedLayoutErr: Label 'Report %1 has a custom layout that cannot be migrated automatically. Update its bindings to the French report columns before activating Reports FR.', Comment = '%1 = report ID';
        LayoutConflictErr: Label 'A replacement French report already has a different layout with the migration identifier. Reconcile the existing and legacy layouts before retrying.';

    [CommitBehavior(CommitBehavior::Error)]
    procedure SetDefaultReportLayouts()
    begin
        MigrateTrialBalanceLayouts();
        CopyLegacyReportLayouts(10811, 10854);
        CopyLegacyReportLayouts(10842, 10855);
        CopyReportSettings(10811, 10854);
        CopyReportSettings(10842, 10855);
        SetTrialBalanceDefaultLayout();
        OnAfterSetDefaultReportLayouts();
    end;

    local procedure SetTrialBalanceDefaultLayout()
    var
        LayoutList: Record "Report Layout List";
        Selection: Record "Report Layout Selection";
        TenantSelection: Record "Tenant Report Layout Selection";
        EmptyGuid: Guid;
        SelectedCompany: Text[30];
    begin
        LayoutList.SetRange("Report ID", Report::"Trial Balance/Previous Year");
        LayoutList.SetRange(Name, LayoutNameTok);
        LayoutList.SetRange("Application ID", ApplicationIdTok);
        if LayoutList.IsEmpty() then
            Error(MissingLayoutErr);

        SelectedCompany := CopyStr(CompanyName(), 1, MaxStrLen(SelectedCompany));
        if Selection.Get(Report::"Trial Balance/Previous Year", SelectedCompany) then
            if Selection."Custom Report Layout Code" <> '' then
                exit;
        TenantSelection.SetRange("Report ID", Report::"Trial Balance/Previous Year");
        TenantSelection.SetFilter("Company Name", '%1|%2', '', SelectedCompany);
        if TenantSelection.FindSet() then
            repeat
                if IsDeliberateLayout(TenantSelection) and IsNullGuid(TenantSelection."User ID") then
                    exit;
            until TenantSelection.Next() = 0;

        TenantSelection.Reset();
        if not TenantSelection.Get(Report::"Trial Balance/Previous Year", SelectedCompany, EmptyGuid) then begin
            TenantSelection."Report ID" := Report::"Trial Balance/Previous Year";
            TenantSelection."Company Name" := SelectedCompany;
            TenantSelection."User ID" := EmptyGuid;
            TenantSelection."App ID" := ApplicationIdTok;
            TenantSelection."Layout Name" := LayoutNameTok;
            TenantSelection.Insert(true);
        end else begin
            TenantSelection."App ID" := ApplicationIdTok;
            TenantSelection."Layout Name" := LayoutNameTok;
            TenantSelection.Modify(true);
        end;
        if not Selection.Get(Report::"Trial Balance/Previous Year", SelectedCompany) then begin
            Selection."Report ID" := Report::"Trial Balance/Previous Year";
            Selection."Company Name" := SelectedCompany;
            Selection.Type := Selection.Type::"RDLC (built-in)";
            Selection.Insert(true);
        end;
    end;

    procedure MigrateTrialBalanceLayout(Input: InStream; Output: OutStream)
    var
        Document: XmlDocument;
        Nodes: XmlNodeList;
        Node: XmlNode;
        Element: XmlElement;
        Attribute: XmlAttribute;
        TextValue: Text;
    begin
        if not XmlDocument.ReadFrom(Input, Document) then
            Error(UnsupportedLayoutErr, Report::"Trial Balance/Previous Year");
        Document.SelectNodes('//*[local-name()="Field"]', Nodes);
        foreach Node in Nodes do begin
            Element := Node.AsXmlElement();
            if Element.Attributes().Get('Name', Attribute) then
                Element.SetAttribute('Name', MapField(Attribute.Value()));
        end;
        Document.SelectNodes('//*[not(*)]', Nodes);
        foreach Node in Nodes do begin
            Element := Node.AsXmlElement();
            TextValue := Element.InnerText();
            if Element.LocalName() = 'DataField' then
                TextValue := MapField(TextValue)
            else
                TextValue := MapExpression(TextValue);
            if TextValue <> Element.InnerText() then begin
                Element.RemoveNodes();
                Element.Add(XmlText.Create(TextValue));
            end;
        end;
        Document.WriteTo(Output);
    end;

    local procedure MigrateTrialBalanceLayouts()
    var
        CustomLayout: Record "Custom Report Layout";
        TenantLayout: Record "Tenant Report Layout";
        SourceBlob: Codeunit "Temp Blob";
        TargetBlob: Codeunit "Temp Blob";
        Input: InStream;
        Output: OutStream;
        EmptyGuid: Guid;
    begin
        CustomLayout.SetRange("Report ID", Report::"Trial Balance/Previous Year");
        CustomLayout.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if CustomLayout.FindSet(true) then
            repeat
                if CustomLayout.Type <> CustomLayout.Type::RDLC then
                    Error(UnsupportedLayoutErr, CustomLayout."Report ID");
                CustomLayout.CalcFields(Layout);
                CustomLayout.Layout.CreateInStream(Input);
                TargetBlob.CreateOutStream(Output);
                MigrateTrialBalanceLayout(Input, Output);
                TargetBlob.CreateInStream(Input);
                Clear(CustomLayout.Layout);
                CustomLayout.Layout.CreateOutStream(Output);
                CopyStream(Output, Input);
                CustomLayout.Modify(true);
                Clear(TargetBlob);
            until CustomLayout.Next() = 0;

        TenantLayout.SetRange("Report ID", Report::"Trial Balance/Previous Year");
        TenantLayout.SetRange("App ID", EmptyGuid);
        TenantLayout.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if TenantLayout.FindSet(true) then
            repeat
                if TenantLayout."Layout Format" <> TenantLayout."Layout Format"::RDLC then
                    Error(UnsupportedLayoutErr, TenantLayout."Report ID");
                SourceBlob.CreateOutStream(Output);
                TenantLayout.Layout.ExportStream(Output);
                SourceBlob.CreateInStream(Input);
                TargetBlob.CreateOutStream(Output);
                MigrateTrialBalanceLayout(Input, Output);
                TargetBlob.CreateInStream(Input);
                TenantLayout.Layout.ImportStream(Input, TenantLayout.Description);
                TenantLayout.Modify(true);
                Clear(SourceBlob);
                Clear(TargetBlob);
            until TenantLayout.Next() = 0;
    end;

    local procedure IsDeliberateLayout(Selection: Record "Tenant Report Layout Selection"): Boolean
    var
        TenantLayout: Record "Tenant Report Layout";
        EmptyGuid: Guid;
        BaseApplicationId: Guid;
    begin
        if Selection."App ID" = ApplicationIdTok then
            exit(true);
        if TenantLayout.Get(Selection."Report ID", Selection."Layout Name", EmptyGuid) then
            exit(true);
        Evaluate(BaseApplicationId, '{437dbf0e-84ff-417a-965d-ed2bb9650972}');
        if (Selection."App ID" <> BaseApplicationId) and (not IsNullGuid(Selection."App ID")) then
            Error(UnsupportedLayoutErr, Selection."Report ID");
        exit(false);
    end;

    local procedure CopyLegacyReportLayouts(OldReportID: Integer; NewReportID: Integer)
    var
        LegacyCustom: Record "Custom Report Layout";
        LegacyTenantLayout: Record "Tenant Report Layout";
        DestinationTenantLayout: Record "Tenant Report Layout";
        LegacySelection: Record "Report Layout Selection";
        DestinationSelection: Record "Report Layout Selection";
        LegacyTenantSelection: Record "Tenant Report Layout Selection";
        DestinationTenantSelection: Record "Tenant Report Layout Selection";
        DefaultLayout: Record "Report Layout List";
        NewCode: Code[20];
        EmptyGuid: Guid;
    begin
        LegacyCustom.SetRange("Report ID", OldReportID);
        LegacyCustom.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if LegacyCustom.FindSet() then
            repeat
                CopyLegacyCustomLayout(LegacyCustom, NewReportID);
            until LegacyCustom.Next() = 0;

        LegacyTenantLayout.SetRange("Report ID", OldReportID);
        LegacyTenantLayout.SetRange("App ID", EmptyGuid);
        LegacyTenantLayout.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if LegacyTenantLayout.FindSet() then
            repeat
                if LegacyTenantLayout."Layout Format" <> LegacyTenantLayout."Layout Format"::RDLC then
                    Error(UnsupportedLayoutErr, OldReportID);
                if DestinationTenantLayout.Get(NewReportID, LegacyTenantLayout.Name, EmptyGuid) then begin
                    if (DestinationTenantLayout.Layout.MediaId() <> LegacyTenantLayout.Layout.MediaId()) or
                       (DestinationTenantLayout."Company Name" <> LegacyTenantLayout."Company Name")
                    then
                        Error(LayoutConflictErr);
                end else begin
                    DestinationTenantLayout := LegacyTenantLayout;
                    DestinationTenantLayout."Report ID" := NewReportID;
                    Clear(DestinationTenantLayout.SystemId);
                    DestinationTenantLayout.Insert(true);
                end;
            until LegacyTenantLayout.Next() = 0;

        LegacySelection.SetRange("Report ID", OldReportID);
        LegacySelection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if LegacySelection.FindSet() then
            repeat
                if not DestinationSelection.Get(NewReportID, LegacySelection."Company Name") then begin
                    NewCode := '';
                    if LegacySelection."Custom Report Layout Code" <> '' then begin
                        LegacyCustom.Get(LegacySelection."Custom Report Layout Code");
                        NewCode := CopyLegacyCustomLayout(LegacyCustom, NewReportID);
                    end;
                    DestinationSelection := LegacySelection;
                    DestinationSelection."Report ID" := NewReportID;
                    DestinationSelection."Custom Report Layout Code" := NewCode;
                    Clear(DestinationSelection.SystemId);
                    DestinationSelection.Insert(false);
                end;
            until LegacySelection.Next() = 0;

        LegacyTenantSelection.SetRange("Report ID", OldReportID);
        LegacyTenantSelection.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if LegacyTenantSelection.FindSet() then
            repeat
                if not DestinationTenantSelection.Get(NewReportID, LegacyTenantSelection."Company Name", LegacyTenantSelection."User ID") then begin
                    DestinationTenantSelection := LegacyTenantSelection;
                    DestinationTenantSelection."Report ID" := NewReportID;
                    if LegacyTenantLayout.Get(OldReportID, LegacyTenantSelection."Layout Name", EmptyGuid) then
                        DestinationTenantSelection."App ID" := EmptyGuid
                    else begin
                        if not IsNullGuid(LegacyTenantSelection."App ID") and
                           (LegacyTenantSelection."App ID" <> BaseApplicationIdTok)
                        then
                            Error(UnsupportedLayoutErr, OldReportID);
                        DefaultLayout.SetRange("Report ID", NewReportID);
                        DefaultLayout.SetRange("Application ID", ApplicationIdTok);
                        DefaultLayout.SetRange("Layout Format", DefaultLayout."Layout Format"::RDLC);
                        if not DefaultLayout.FindFirst() then
                            Error(UnsupportedLayoutErr, OldReportID);
                        DestinationTenantSelection."App ID" := DefaultLayout."Application ID";
                        DestinationTenantSelection."Layout Name" := DefaultLayout.Name;
                    end;
                    Clear(DestinationTenantSelection.SystemId);
                    DestinationTenantSelection.Insert(true);
                end;
            until LegacyTenantSelection.Next() = 0;
    end;

    local procedure CopyLegacyCustomLayout(var Source: Record "Custom Report Layout"; NewReportID: Integer): Code[20]
    var
        Destination: Record "Custom Report Layout";
        Code: Code[20];
    begin
        if Source.Type <> Source.Type::RDLC then
            Error(UnsupportedLayoutErr, Source."Report ID");
        Code := CopyStr(
            'FR' + Format(NewReportID, 0, 9) + '-' + DelChr(Format(Source.SystemId), '=', '{}-'),
            1, MaxStrLen(Code));
        if Destination.Get(Code) then begin
            if (Destination."Report ID" <> NewReportID) or (Destination.Type <> Source.Type) or
               (Destination."Company Name" <> Source."Company Name") or
               (CustomLayoutHash(Destination) <> CustomLayoutHash(Source))
            then
                Error(LayoutConflictErr);
            exit(Code);
        end;
        Source.CalcFields(Layout);
        Destination.TransferFields(Source);
        Destination.Code := Code;
        Destination."Report ID" := NewReportID;
        Destination."App ID" := ApplicationIdTok;
        Destination."Built-In" := false;
        Clear(Destination.SystemId);
        Destination.Insert(false);
        exit(Code);
    end;

    local procedure CustomLayoutHash(var CustomLayout: Record "Custom Report Layout"): Text
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        Input: InStream;
    begin
        CustomLayout.CalcFields(Layout);
        CustomLayout.Layout.CreateInStream(Input);
        exit(CryptographyManagement.GenerateHash(Input, 2));
    end;

    local procedure CopyReportSettings(OldReportID: Integer; NewReportID: Integer)
    var
        Legacy: Record "Object Options";
        Destination: Record "Object Options";
        Document: XmlDocument;
        Root: XmlElement;
        Input: InStream;
        Output: OutStream;
    begin
        Legacy.SetRange("Object Type", Legacy."Object Type"::Report);
        Legacy.SetRange("Object ID", OldReportID);
        Legacy.SetFilter("Company Name", '%1|%2', '', CompanyName());
        if Legacy.FindSet() then
            repeat
                if not Destination.Get(
                    Legacy."Parameter Name", NewReportID, Legacy."Object Type", Legacy."User Name", Legacy."Company Name")
                then begin
                    Legacy.CalcFields("Option Data");
                    Destination.TransferFields(Legacy);
                    Destination."Object ID" := NewReportID;
                    Clear(Destination.SystemId);
                    if Legacy."Option Data".HasValue() then begin
                        Legacy."Option Data".CreateInStream(Input, TextEncoding::UTF8);
                        if not XmlDocument.ReadFrom(Input, Document) then
                            Error(UnsupportedLayoutErr, OldReportID);
                        Document.GetRoot(Root);
                        Root.SetAttribute('id', Format(NewReportID, 0, 9));
                        Clear(Destination."Option Data");
                        Destination."Option Data".CreateOutStream(Output, TextEncoding::UTF8);
                        Document.WriteTo(Output);
                    end;
                    Destination.Insert(false);
                end;
            until Legacy.Next() = 0;
    end;

    local procedure MapField(Name: Text): Text
    begin
        case Name of
            'FiscalYearNetChange':
                exit('FRPeriodDebitAmount');
            'FiscalYearNetChangeFormat':
                exit('FRPeriodDebitAmountFormat');
            'FiscalYearCreditChange':
                exit('FRPeriodCreditAmount');
            'FiscalYearCreditChangeFormat':
                exit('FRPeriodCreditAmountFormat');
            'FiscalYearDebitBalance':
                exit('FRCumulativeDebitAmount');
            'FiscalYearDebitBalanceFormat':
                exit('FRCumulativeDebitAmountFormat');
            'FiscalYearCreditBalance':
                exit('FRCumulativeCreditAmount');
            'FiscalYearCreditBalanceFormat':
                exit('FRCumulativeCreditAmountFormat');
            'GLFilter_GLAccount':
                exit('FRAccountFilter');
            'GLFilter':
                exit('FRFilter');
            'Period':
                exit('FRPeriodText');
            'No_GLAccount':
                exit('FRHeaderAccountNo');
            'No1_GLAccount':
                exit('FRAccountNo');
            'No1_GLAccountCaption':
                exit('FRAccountNoCaption');
            'GLAccountNameIndented':
                exit('FRAccountName');
            'NoofBlankLines_GLAccount':
                exit('FRBlankLines');
            'CurrReportPageNoCaption':
                exit('FRPageCaption');
            'PADSTRGLAccountIndentation2GLAccountNameCaption':
                exit('FRNameCaption');
            'FiscalYearDebitChangeCaption':
                exit('FRDebitCaption');
            'FiscalYearCreditChangeCaption':
                exit('FRCreditCaption');
            'NetChangeIncreasePctCaption':
                exit('FRPercentCaption');
            'LastYearNetChangeCaption':
                exit('FRLastYearCaption');
        end;
        exit(Name);
    end;

    local procedure MapExpression(Expression: Text): Text
    var
        Names: List of [Text];
        Name: Text;
    begin
        Names.AddRange(
            'FiscalYearNetChangeFormat', 'FiscalYearNetChange', 'FiscalYearCreditChangeFormat', 'FiscalYearCreditChange',
            'FiscalYearDebitBalanceFormat', 'FiscalYearDebitBalance', 'FiscalYearCreditBalanceFormat', 'FiscalYearCreditBalance',
            'GLFilter_GLAccount', 'GLFilter', 'Period', 'No_GLAccount', 'No1_GLAccountCaption', 'No1_GLAccount',
            'GLAccountNameIndented', 'NoofBlankLines_GLAccount', 'CurrReportPageNoCaption',
            'PADSTRGLAccountIndentation2GLAccountNameCaption', 'FiscalYearDebitChangeCaption', 'FiscalYearCreditChangeCaption',
            'NetChangeIncreasePctCaption', 'LastYearNetChangeCaption');
        foreach Name in Names do begin
            Expression := Expression.Replace('Fields!' + Name + '.', 'Fields!' + MapField(Name) + '.');
            Expression := Expression.Replace('Fields("' + Name + '")', 'Fields("' + MapField(Name) + '")');
        end;
        exit(Expression);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultReportLayouts()
    begin
    end;
}
