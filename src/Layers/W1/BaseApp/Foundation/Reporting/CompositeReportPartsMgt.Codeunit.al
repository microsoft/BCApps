// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;
using System.Reflection;

/// <summary>
/// Seeds the reusable Composite Layout header/footer and theme parts that ship with the Base Application into
/// the shared pool, so they can be assigned as defaults on any report from the Report themes and header-footer
/// setup page.
/// </summary>
codeunit 9667 "Composite Report Parts Mgt."
{
    Access = Internal;
    Permissions = tabledata "Tenant Report Layout" = RIMD;

    /// <summary>
    /// Writes every part that ships with the Base Application into the shared pool. Safe to call repeatedly:
    /// a missing part is inserted and an existing one is refreshed from the shipped file. Each part is written in
    /// isolation, so one that cannot be written is reported and skipped rather than failing the whole pass - this runs
    /// during install and upgrade of the Base Application, where an uncaught error would abort the entire operation.
    /// </summary>
    procedure SeedDefaultParts()
    begin
        SeedPart(ExternalDefaultTxt, 'ReportParts/HeaderFooterDesign/ExternalDefault.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalDefaultDescTxt);
        SeedPart(ExternalDefaultDetailedTxt, 'ReportParts/HeaderFooterDesign/ExternalDefaultDetailed.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalDefaultDetailedDescTxt);
        SeedPart(ExternalMinimalisticTxt, 'ReportParts/HeaderFooterDesign/ExternalMinimalistic.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalMinimalisticDescTxt);
        SeedPart(ExternalMinimalisticDetailedTxt, 'ReportParts/HeaderFooterDesign/ExternalMinimalisticDetailed.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalMinimalisticDetailedDescTxt);
        SeedPart(ExternalModernTxt, 'ReportParts/HeaderFooterDesign/ExternalModern.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalModernDescTxt);
        SeedPart(ExternalModernLogoTxt, 'ReportParts/HeaderFooterDesign/ExternalModernLogo.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalModernLogoDescTxt);

        SeedPart(InternalDefaultTxt, 'ReportParts/HeaderFooterDesign/InternalDefault.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalDefaultDescTxt);
        SeedPart(InternalMinimalisticCenteredTxt, 'ReportParts/HeaderFooterDesign/InternalMinimalisticCentered.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalMinimalisticCenteredDescTxt);
        SeedPart(InternalMinimalisticTxt, 'ReportParts/HeaderFooterDesign/InternalMinimalistic.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalMinimalisticDescTxt);
        SeedPart(InternalModernTxt, 'ReportParts/HeaderFooterDesign/InternalModern.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalModernDescTxt);
        SeedPart(InternalModernMaxiTxt, 'ReportParts/HeaderFooterDesign/InternalModernMaxi.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalModernMaxiDescTxt);

        SeedPart(DefaultThemeTxt, 'ReportParts/ReportTheme/Default.dotx', Enum::"Report Layout Subtype"::Theme, DefaultThemeDescTxt);
        SeedPart(CalmThemeTxt, 'ReportParts/ReportTheme/Calm.dotx', Enum::"Report Layout Subtype"::Theme, CalmThemeDescTxt);
        SeedPart(PlayfulThemeTxt, 'ReportParts/ReportTheme/Playful.dotx', Enum::"Report Layout Subtype"::Theme, PlayfulThemeDescTxt);
    end;

    /// <summary>
    /// Whether the given part name is one of the themes or header/footer designs that ship with the Base Application.
    /// </summary>
    internal procedure IsShippedPart(PartName: Text): Boolean
    begin
        exit(
            PartName in
            [ExternalDefaultTxt, ExternalDefaultDetailedTxt, ExternalMinimalisticTxt, ExternalMinimalisticDetailedTxt,
             ExternalModernTxt, ExternalModernLogoTxt,
             InternalDefaultTxt, InternalMinimalisticCenteredTxt, InternalMinimalisticTxt, InternalModernTxt, InternalModernMaxiTxt,
             DefaultThemeTxt, CalmThemeTxt, PlayfulThemeTxt]);
    end;

    /// <summary>
    /// Writes one part, containing any failure to that part. A missing packaged resource or a tenant layout the
    /// platform refuses is reported and skipped, so the remaining parts are still seeded and the install or upgrade
    /// this runs under is not aborted.
    /// </summary>
    /// <param name="PartName">The name the part is stored and assigned under.</param>
    /// <param name="ResourceFile">Path of the layout file inside the resource folder declared in app.json.</param>
    /// <param name="Subtype">HeaderFooter or Theme. Also decides the MIME type.</param>
    /// <param name="Description">The description shown next to the part in the UI.</param>
    local procedure SeedPart(PartName: Text[250]; ResourceFile: Text; Subtype: Enum "Report Layout Subtype"; Description: Text)
    begin
        ClearLastError();
        if not TryUpsertPart(PartName, ResourceFile, Subtype, Description) then
            LogPartNotSeeded(PartName, ResourceFile, Subtype, GetLastErrorText());
    end;

    /// <summary>
    /// Signals that one shipped part could not be written. The part name and resource path are shipped constants, so
    /// they identify which part failed; the error text says why the platform or the resource loader refused it.
    /// </summary>
    local procedure LogPartNotSeeded(PartName: Text; ResourceFile: Text; Subtype: Enum "Report Layout Subtype"; ErrorText: Text)
    var
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('PartName', PartName);
        TelemetryDimensions.Add('ResourceFile', ResourceFile);
        TelemetryDimensions.Add('LayoutSubtype', Format(Subtype, 0, 9));
        TelemetryDimensions.Add('Error', ErrorText);
        Session.LogMessage(
            '0000V42', PartNotSeededTxt, Verbosity::Error, DataClassification::SystemMetadata,
            TelemetryScope::All, TelemetryDimensions);
    end;

    /// <summary>
    /// Writes one part into the shared pool, inserting it when missing and replacing it when already there, so
    /// re-seeding picks up a changed layout file.
    /// </summary>
    /// <remarks>
    /// The resource is read before the existing row is deleted, so the most likely failure - a resource missing from
    /// the package - leaves the part that is already there untouched instead of removing it and failing to replace it.
    /// A try method does not roll back what it already wrote, so keep the read first.
    /// </remarks>
    /// <param name="PartName">The name the part is stored and assigned under.</param>
    /// <param name="ResourceFile">Path of the layout file inside the resource folder declared in app.json.</param>
    /// <param name="Subtype">HeaderFooter or Theme. Also decides the MIME type.</param>
    /// <param name="Description">The description shown next to the part in the UI.</param>
    [TryFunction]
    local procedure TryUpsertPart(PartName: Text[250]; ResourceFile: Text; Subtype: Enum "Report Layout Subtype"; Description: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
        LayoutInStream: InStream;
        EmptyAppId: Guid;
    begin
        NavApp.GetResource(ResourceFile, LayoutInStream);

        if TenantReportLayout.Get(CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID(), PartName, EmptyAppId) then
            TenantReportLayout.Delete(true);

        TenantReportLayout.Init();
        TenantReportLayout."Report ID" := CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID();
        TenantReportLayout.Name := PartName;
        TenantReportLayout."Company Name" := '';
        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Word;
        TenantReportLayout."Layout Subtype" := Subtype;
        TenantReportLayout.Description := CopyStr(Description, 1, MaxStrLen(TenantReportLayout.Description));
        TenantReportLayout."Layout Status" := TenantReportLayout."Layout Status"::Approved;
        TenantReportLayout."MIME Type" := PartMimeType(Subtype);
        TenantReportLayout.Layout.ImportStream(LayoutInStream, PartName);
        TenantReportLayout.Insert(true);
    end;

    /// <summary>
    /// The Word MIME type matching a part's role: themes ship as .dotx templates, header/footer parts as .docx
    /// documents. The platform stores this alongside the layout and hands it back on download.
    /// </summary>
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

        PartNotSeededTxt: Label 'Composite layout parts: a shipped theme or header/footer part could not be written to the shared pool and was skipped. The remaining parts were seeded.', Locked = true;

        ThemeMimeTypeTxt: Label 'application/vnd.openxmlformats-officedocument.wordprocessingml.template', Locked = true;
        HeaderFooterMimeTypeTxt: Label 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', Locked = true;
}
