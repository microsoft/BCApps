// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;
using System.Environment.Configuration;

/// <summary>
/// Seeds the reusable Composite Layout header/footer and theme parts that ship with the Base Application into
/// the shared pool, so they can be assigned as defaults on any report from the Report themes and header-footer
/// setup page.
/// </summary>
/// <remarks>
/// Parts are written to the platform's virtual Tenant Report Defaults report (2000000001), which is the only
/// report the resolver accepts reusable default parts from. A part declared in a report or reportextension
/// rendering section is bound to that specific report, and there is no design-time way to place a layout on the
/// virtual report, so the rows are inserted as Tenant Report Layout records - the same table the New Theme or
/// Header/Footer dialog writes - at install and upgrade time.
///
/// The layout files ship as app resources from the .resources folder declared in app.json and are read with
/// NavApp.GetResource, which keeps the binaries out of the AL source.
/// </remarks>
codeunit 9667 "Composite Report Parts Mgt."
{
    Access = Internal;
    Permissions = tabledata "Tenant Report Layout" = RIMD;

    /// <summary>
    /// Writes every part that ships with the Base Application into the shared pool. Safe to call repeatedly:
    /// a missing part is inserted and an existing one is refreshed from the shipped file.
    /// </summary>
    procedure SeedDefaultParts()
    begin
        // One line per part shipped: the name it appears under in the UI, the resource file holding the layout,
        // its role, and the description shown next to it. The resource folders mirror the roles -
        // HeaderFooterDesign holds the .docx header/footer parts, ReportTheme holds the .dotx theme templates.
        UpsertPart(ExternalDefaultTxt, 'ReportParts/HeaderFooterDesign/ExternalDefault.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalDefaultDescTxt);
        UpsertPart(ExternalDefaultDetailedTxt, 'ReportParts/HeaderFooterDesign/ExternalDefaultDetailed.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalDefaultDetailedDescTxt);
        UpsertPart(ExternalMinimalisticTxt, 'ReportParts/HeaderFooterDesign/ExternalMinimalistic.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalMinimalisticDescTxt);
        UpsertPart(ExternalMinimalisticDetailedTxt, 'ReportParts/HeaderFooterDesign/ExternalMinimalisticDetailed.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalMinimalisticDetailedDescTxt);
        UpsertPart(ExternalModernTxt, 'ReportParts/HeaderFooterDesign/ExternalModern.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalModernDescTxt);
        UpsertPart(ExternalModernLogoTxt, 'ReportParts/HeaderFooterDesign/ExternalModernLogo.docx', Enum::"Report Layout Subtype"::HeaderFooter, ExternalModernLogoDescTxt);

        //Internal
        UpsertPart(InternalDefaultTxt, 'ReportParts/HeaderFooterDesign/InternalDefault.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalDefaultDescTxt);
        UpsertPart(InternalMinimalisticCenteredTxt, 'ReportParts/HeaderFooterDesign/InternalMinimalisticCentered.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalMinimalisticCenteredDescTxt);
        UpsertPart(InternalMinimalisticTxt, 'ReportParts/HeaderFooterDesign/InternalMinimalistic.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalMinimalisticDescTxt);
        UpsertPart(InternalModernTxt, 'ReportParts/HeaderFooterDesign/InternalModern.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalModernDescTxt);
        UpsertPart(InternalModernMaxiTxt, 'ReportParts/HeaderFooterDesign/InternalModernMaxi.docx', Enum::"Report Layout Subtype"::HeaderFooter, InternalModernMaxiDescTxt);

        //Theme
        UpsertPart(DefaultThemeTxt, 'ReportParts/ReportTheme/Default.dotx', Enum::"Report Layout Subtype"::Theme, DefaultThemeDescTxt);
        UpsertPart(CalmThemeTxt, 'ReportParts/ReportTheme/Calm.dotx', Enum::"Report Layout Subtype"::Theme, CalmThemeDescTxt);
        UpsertPart(PlayfulThemeTxt, 'ReportParts/ReportTheme/Playful.dotx', Enum::"Report Layout Subtype"::Theme, PlayfulThemeDescTxt);
    end;

    /// <summary>
    /// Writes one part into the shared pool, inserting it when missing and replacing it when already there, so
    /// re-seeding picks up a changed layout file.
    /// </summary>
    /// <remarks>
    /// Replacing means delete-then-insert, not Modify. The platform refuses to modify a Tenant Report Layout
    /// whose type or content changes, and that error inside an install trigger rolls the whole publish back, so
    /// the row is removed and written afresh instead. Assignments survive it: Tenant Report Layout Cfg refers to
    /// a part by its composite &lt;app id&gt;::&lt;name&gt; text rather than by a foreign key, and the row returns
    /// under the same name and the same empty application ID.
    ///
    /// A part that an administrator has customized under one of these names is overwritten - the customization
    /// has to be kept under a different name.
    /// </remarks>
    /// <param name="PartName">The name the part is stored and assigned under.</param>
    /// <param name="ResourceFile">Path of the layout file inside the resource folder declared in app.json.</param>
    /// <param name="Subtype">HeaderFooter or Theme. Also decides the MIME type.</param>
    /// <param name="Description">The description shown next to the part in the UI.</param>
    local procedure UpsertPart(PartName: Text[250]; ResourceFile: Text; Subtype: Enum "Report Layout Subtype"; Description: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
        LayoutInStream: InStream;
        EmptyAppId: Guid;
    begin
        // Read before the delete, so a resource that cannot be read leaves the existing part intact.
        NavApp.GetResource(ResourceFile, LayoutInStream);

        if TenantReportLayout.Get(CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID(), PartName, EmptyAppId) then
            TenantReportLayout.Delete(true);

        TenantReportLayout.Init();
        TenantReportLayout."Report ID" := CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID();
        TenantReportLayout.Name := PartName;
        TenantReportLayout."Company Name" := ''; // '' = global (all companies), so seeding once per database is enough
        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Word;
        TenantReportLayout."Layout Subtype" := Subtype;
        TenantReportLayout.Description := CopyStr(Description, 1, MaxStrLen(TenantReportLayout.Description));
        // Only approved parts can be assigned as report defaults, so seed them ready to use.
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

        ThemeMimeTypeTxt: Label 'application/vnd.openxmlformats-officedocument.wordprocessingml.template', Locked = true; // .dotx
        HeaderFooterMimeTypeTxt: Label 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', Locked = true; // .docx
}
