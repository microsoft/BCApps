// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;
using System.Reflection;

/// <summary>
/// Seeds the shipped Composite Layout theme and header/footer parts under Tenant Report Defaults on install and
/// upgrade, stored under this app's own App ID, and removes the parts this version no longer ships. A part that cannot
/// be read or written is logged and reported as not seeded rather than raised, so it cannot abort install or upgrade.
/// </summary>
codeunit 9667 "Composite Report Parts Mgt."
{
    Access = Internal;
    TableNo = "Tenant Report Layout";

    trigger OnRun()
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        if CallerModuleInfo.Id <> GetShippedPartAppId() then
            Error(CallerNotAllowedErr);

        WritePart(Rec);
    end;

    internal procedure SeedDefaultParts() AllPartsSeeded: Boolean
    var
        FailedCount: Integer;
    begin
        FailedCount += CountFailure(SeedPart(ExternalDefaultTxt, 'ReportParts/HeaderFooterDesign/ExternalDefault.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalDefaultDescTxt));
        FailedCount += CountFailure(SeedPart(ExternalDefaultDetailedTxt, 'ReportParts/HeaderFooterDesign/ExternalDefaultDetailed.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalDefaultDetailedDescTxt));
        FailedCount += CountFailure(SeedPart(ExternalMinimalisticTxt, 'ReportParts/HeaderFooterDesign/ExternalMinimalistic.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalMinimalisticDescTxt));
        FailedCount += CountFailure(SeedPart(ExternalMinimalisticDetailedTxt, 'ReportParts/HeaderFooterDesign/ExternalMinimalisticDetailed.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalMinimalisticDetailedDescTxt));
        FailedCount += CountFailure(SeedPart(ExternalModernTxt, 'ReportParts/HeaderFooterDesign/ExternalModern.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalModernDescTxt));
        FailedCount += CountFailure(SeedPart(ExternalModernLogoTxt, 'ReportParts/HeaderFooterDesign/ExternalModernLogo.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalModernLogoDescTxt));

        FailedCount += CountFailure(SeedPart(InternalDefaultTxt, 'ReportParts/HeaderFooterDesign/InternalDefault.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalDefaultDescTxt));
        FailedCount += CountFailure(SeedPart(InternalMinimalisticCenteredTxt, 'ReportParts/HeaderFooterDesign/InternalMinimalisticCentered.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalMinimalisticCenteredDescTxt));
        FailedCount += CountFailure(SeedPart(InternalMinimalisticTxt, 'ReportParts/HeaderFooterDesign/InternalMinimalistic.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalMinimalisticDescTxt));
        FailedCount += CountFailure(SeedPart(InternalModernTxt, 'ReportParts/HeaderFooterDesign/InternalModern.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalModernDescTxt));
        FailedCount += CountFailure(SeedPart(InternalModernMaxiTxt, 'ReportParts/HeaderFooterDesign/InternalModernMaxi.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalModernMaxiDescTxt));

        FailedCount += CountFailure(SeedPart(DefaultThemeTxt, 'ReportParts/ReportTheme/Default.dotx', Enum::"Report Layout Subtype"::Theme, DefaultThemeDescTxt));
        FailedCount += CountFailure(SeedPart(CalmThemeTxt, 'ReportParts/ReportTheme/Calm.dotx', Enum::"Report Layout Subtype"::Theme, CalmThemeDescTxt));
        FailedCount += CountFailure(SeedPart(PlayfulThemeTxt, 'ReportParts/ReportTheme/Playful.dotx', Enum::"Report Layout Subtype"::Theme, PlayfulThemeDescTxt));

        PruneRetiredParts();

        exit(FailedCount = 0);
    end;

    local procedure PruneRetiredParts()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        TempPartsToDelete: Record "Tenant Report Layout" temporary;
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
    begin
        TenantReportLayout.SetRange("Report ID", CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID());
        TenantReportLayout.SetRange("App ID", GetShippedPartAppId());
        TenantReportLayout.SetLoadFields(Name, "Layout Subtype");
        if TenantReportLayout.FindSet() then
            repeat
                if not IsShippedPart(TenantReportLayout.Name) then begin
                    ClearAssignments(TenantReportLayout.Name, TenantReportLayout."Layout Subtype");
                    TempPartsToDelete.Init();
                    TempPartsToDelete."Report ID" := TenantReportLayout."Report ID";
                    TempPartsToDelete.Name := TenantReportLayout.Name;
                    TempPartsToDelete.Insert();
                end;
            until TenantReportLayout.Next() = 0;

        if TempPartsToDelete.FindSet() then
            repeat
                RemovePart(TempPartsToDelete.Name, GetShippedPartAppId());
            until TempPartsToDelete.Next() = 0;
    end;

    local procedure ClearAssignments(PartName: Text[250]; Subtype: Enum "Report Layout Subtype")
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
        Composite: Text;
    begin
        Composite := CompositeLayoutLookupHelper.EncodeCompositeName(GetShippedPartAppId(), PartName);
        case Subtype of
            Subtype::HeaderFooter:
                begin
                    TenantReportLayoutCfg.SetRange("Header Part Name", CopyStr(Composite, 1, MaxStrLen(TenantReportLayoutCfg."Header Part Name")));
                    TenantReportLayoutCfg.ModifyAll("Header Part Name", '');
                end;
            Subtype::Theme:
                begin
                    TenantReportLayoutCfg.SetRange("Theme Part Name", CopyStr(Composite, 1, MaxStrLen(TenantReportLayoutCfg."Theme Part Name")));
                    TenantReportLayoutCfg.ModifyAll("Theme Part Name", '');
                end;
        end;
    end;

    local procedure CountFailure(PartSeeded: Boolean): Integer
    begin
        if PartSeeded then
            exit(0);
        exit(1);
    end;

    internal procedure GetShippedPartAppId() AppId: Guid
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        AppId := CurrentModuleInfo.Id;
    end;

    internal procedure IsShippedPart(PartName: Text): Boolean
    begin
        exit(
            PartName in
            [ExternalDefaultTxt, ExternalDefaultDetailedTxt, ExternalMinimalisticTxt, ExternalMinimalisticDetailedTxt,
             ExternalModernTxt, ExternalModernLogoTxt,
             InternalDefaultTxt, InternalMinimalisticCenteredTxt, InternalMinimalisticTxt, InternalModernTxt, InternalModernMaxiTxt,
             DefaultThemeTxt, CalmThemeTxt, PlayfulThemeTxt]);
    end;

    internal procedure SeedPart(PartName: Text[250]; ResourceFile: Text; Subtype: Enum "Report Layout Subtype"; Description: Text): Boolean
    var
        TempPartToWrite: Record "Tenant Report Layout" temporary;
    begin
        TempPartToWrite.Init();
        TempPartToWrite.Name := PartName;
        TempPartToWrite."Layout Subtype" := Subtype;
        TempPartToWrite.Description := CopyStr(Description, 1, MaxStrLen(TempPartToWrite.Description));

        ClearLastError();
        if not TryLoadPartLayout(ResourceFile, TempPartToWrite) then begin
            LogPartNotSeeded(PartName, ResourceFile, Subtype, GetLastErrorCode(), GetLastErrorText(true));
            exit(false);
        end;
        TempPartToWrite.Insert();

        ClearLastError();
        if not Codeunit.Run(Codeunit::"Composite Report Parts Mgt.", TempPartToWrite) then begin
            LogPartNotSeeded(PartName, ResourceFile, Subtype, GetLastErrorCode(), GetLastErrorText(true));
            exit(false);
        end;

        exit(true);
    end;

    local procedure LogPartNotSeeded(PartName: Text; ResourceFile: Text; Subtype: Enum "Report Layout Subtype"; ErrorCode: Text; ErrorText: Text)
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('PartName', PartName);
        TelemetryDimensions.Add('ResourceFile', ResourceFile);
        TelemetryDimensions.Add('LayoutSubtype', Format(Subtype, 0, 9));
        TelemetryDimensions.Add('ErrorCode', ErrorCode);
        Session.LogMessage(
            '0000V42', PartNotSeededTxt, Verbosity::Warning, DataClassification::SystemMetadata,
            TelemetryScope::All, TelemetryDimensions);

        Clear(TelemetryDimensions);
        TelemetryDimensions.Add('PartName', PartName);
        TelemetryDimensions.Add('ResourceFile', ResourceFile);
        TelemetryDimensions.Add('ErrorCode', ErrorCode);
        TelemetryDimensions.Add('Error', ErrorText);
        Session.LogMessage(
            '0000V43', PartNotSeededDetailTxt, Verbosity::Warning, DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher, TelemetryDimensions);
    end;

    [TryFunction]
    local procedure TryLoadPartLayout(ResourceFile: Text; var TempPartToWrite: Record "Tenant Report Layout" temporary)
    var
        ResourceInStream: InStream;
    begin
        NavApp.GetResource(ResourceFile, ResourceInStream);
        TempPartToWrite.Layout.ImportStream(ResourceInStream, TempPartToWrite.Name);
    end;

    local procedure WritePart(var TempPartToWrite: Record "Tenant Report Layout")
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
        LayoutInStream: InStream;
    begin
        RemovePart(TempPartToWrite.Name, GetShippedPartAppId());

        TenantReportLayout.Init();
        TenantReportLayout."Report ID" := CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID();
        TenantReportLayout.Name := TempPartToWrite.Name;
        TenantReportLayout."App ID" := GetShippedPartAppId();
        TenantReportLayout."Company Name" := '';
        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Word;
        TenantReportLayout."Layout Subtype" := TempPartToWrite."Layout Subtype";
        TenantReportLayout.Description := TempPartToWrite.Description;
        TenantReportLayout."Layout Status" := TenantReportLayout."Layout Status"::Approved;
        TenantReportLayout."MIME Type" := PartMimeType(TempPartToWrite."Layout Subtype");
        TempPartToWrite.Layout.CreateInStream(LayoutInStream);
        TenantReportLayout.Layout.ImportStream(LayoutInStream, TempPartToWrite.Name);
        TenantReportLayout.Insert(true);
    end;

    local procedure RemovePart(PartName: Text[250]; AppId: Guid)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
    begin
        if TenantReportLayout.Get(CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID(), PartName, AppId) then
            TenantReportLayout.Delete(true);
    end;

    local procedure PartMimeType(Subtype: Enum "Report Layout Subtype"): Text[255]
    begin
        if Subtype = Subtype::Theme then
            exit(ThemeMimeTypeTxt);

        exit(HeaderFooterMimeTypeTxt);
    end;

    var
        ExternalDefaultTxt: Label 'External Default', Locked = true;
        ExternalDefaultDetailedTxt: Label 'External Default Detailed', Locked = true;
        ExternalMinimalisticTxt: Label 'External Minimalistic', Locked = true;
        ExternalMinimalisticDetailedTxt: Label 'External Minimalistic Detailed', Locked = true;
        ExternalModernTxt: Label 'External Modern', Locked = true;
        ExternalModernLogoTxt: Label 'External Modern Logo', Locked = true;
        InternalDefaultTxt: Label 'Internal Default', Locked = true;
        InternalMinimalisticCenteredTxt: Label 'Internal Minimalistic Centered', Locked = true;
        InternalMinimalisticTxt: Label 'Internal Minimalistic', Locked = true;
        InternalModernTxt: Label 'Internal Modern', Locked = true;
        InternalModernMaxiTxt: Label 'Internal Modern Maxi', Locked = true;
        DefaultThemeTxt: Label 'Default', Locked = true;
        CalmThemeTxt: Label 'Calm', Locked = true;
        PlayfulThemeTxt: Label 'Playful', Locked = true;

        ExternalDefaultDescTxt: Label 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email and fax number. Standard external layout for customer-facing documents.';
        ExternalDefaultDetailedDescTxt: Label 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Detailed external layout.';
        ExternalMinimalisticDescTxt: Label 'Header/footer design for portrait or landscape, minimalistic. Header with company logo and report name only; footer with page number, company name, homepage, phone, email and fax. A clean, light external layout.';
        ExternalMinimalisticDetailedDescTxt: Label 'Header/footer design for portrait or landscape, minimalistic. Header with company logo and report name; footer with page number, company name, homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no.';
        ExternalModernDescTxt: Label 'Header/footer design for portrait or landscape, modern style without logo. Header with report name, document date and company name in uppercase; footer with page number and full contact details (homepage, phone, email, fax, VAT, giro, bank).';
        ExternalModernLogoDescTxt: Label 'Header/footer design for portrait or landscape. Header with company logo, report name, document date and page number; footer with homepage, phone, email, fax plus bank, bank account, VAT reg. no. and giro no. Modern external layout.';
        InternalDefaultDescTxt: Label 'Header/footer design for portrait or landscape, for internal documents. Header with company logo, report name and document date; footer with page number.';
        InternalMinimalisticCenteredDescTxt: Label 'Header/footer design for portrait or landscape, minimalist and centred, for internal documents. Header with centred logo, report name and document date; footer with page number.';
        InternalMinimalisticDescTxt: Label 'Header/footer design for portrait or landscape, minimalistic, for internal documents. Header with report name and document date; footer with page number.';
        InternalModernDescTxt: Label 'Header/footer design for portrait or landscape, modern style, for internal documents. Header with company logo, report name and document date; footer with page number.';
        InternalModernMaxiDescTxt: Label 'Header/footer design for portrait or landscape, modern style with a large header, for internal documents. Header with company logo, report name and document date; footer with page number.';

        DefaultThemeDescTxt: Label 'Simple and clear, so the details that matter stand out. Styling-only theme: neutral Segoe UI in semibold and regular for hierarchy, dark-grey text on white, calm accent colours, and softly banded table rows. Works for most reports out of the box.';
        CalmThemeDescTxt: Label 'Classic and calm, and easy to read. Styling-only theme: Sitka serif in semibold and regular for hierarchy, with dark-green text on a soft beige background. A timeless look that gives your reports a quieter, more classic feel.';
        PlayfulThemeDescTxt: Label 'Dynamic and lively, a fresh take on a professional report. Styling-only theme: geometric Bahnschrift in semibold and regular for hierarchy, with backgrounds alternating between green and pink for an energetic, modern feel.';

        CallerNotAllowedErr: Label 'Only the application that ships the composite report parts can write them.';

        PartNotSeededTxt: Label 'Composite layout parts: a shipped theme or header/footer part could not be written to the shared pool and was skipped. The remaining parts were seeded.', Locked = true;
        PartNotSeededDetailTxt: Label 'Composite layout parts: the reason a shipped theme or header/footer part could not be written. Publisher-scoped because the platform error text can echo customer content.', Locked = true;


        ThemeMimeTypeTxt: Label 'reportlayout/dotx', Locked = true;
        HeaderFooterMimeTypeTxt: Label 'reportlayout/docx', Locked = true;
}
