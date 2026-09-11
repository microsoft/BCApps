// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;
using System.Reflection;
using System.Utilities;

/// <summary>
/// Seeds the shipped Composite Layout theme and header/footer parts under Tenant Report Defaults on install and
/// upgrade, stored under this app's own App ID, and removes the parts this version no longer ships. Every part is a
/// resource of this app, so one that cannot be read or written is a build defect and is raised rather than skipped.
/// </summary>
codeunit 9667 "Composite Report Parts Mgt."
{
    Access = Internal;

    internal procedure SeedDefaultParts()
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

        PruneRetiredParts();
    end;

    internal procedure SeedPart(PartName: Text[250]; ResourceFile: Text; Subtype: Enum "Report Layout Subtype"; Description: Text)
    var
        TenantReportLayout: Record "Tenant Report Layout";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
        PartLayout: Codeunit "Temp Blob";
        LayoutInStream: InStream;
    begin
        ClearLastError();

        if not NavApp.ListResources(ResourceFile).Contains(ResourceFile) then
            Error(PartResourceError(PartName, ResourceFile, StrSubstNo(ResourceMissingDetailTxt, ResourceFile)));

        if not TryGetPartLayout(ResourceFile, PartLayout) then
            Error(PartResourceError(PartName, ResourceFile, StrSubstNo(ResourceNotReadableDetailTxt, ResourceFile, GetLastErrorText(true))));

        RemovePart(PartName, GetShippedPartAppId());

        TenantReportLayout.Init();
        TenantReportLayout."Report ID" := CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID();
        TenantReportLayout.Name := PartName;
        TenantReportLayout."App ID" := GetShippedPartAppId();
        TenantReportLayout."Company Name" := '';
        TenantReportLayout."Layout Format" := TenantReportLayout."Layout Format"::Word;
        TenantReportLayout."Layout Subtype" := Subtype;
        TenantReportLayout.Description := CopyStr(Description, 1, MaxStrLen(TenantReportLayout.Description));
        TenantReportLayout."Layout Status" := TenantReportLayout."Layout Status"::Approved;
        TenantReportLayout."MIME Type" := PartMimeType(Subtype);
        PartLayout.CreateInStream(LayoutInStream);
        TenantReportLayout.Layout.ImportStream(LayoutInStream, PartName);
        TenantReportLayout.Insert(true);
    end;

    [TryFunction]
    local procedure TryGetPartLayout(ResourceFile: Text; var PartLayout: Codeunit "Temp Blob")
    var
        ResourceInStream: InStream;
        PartLayoutOutStream: OutStream;
    begin
        NavApp.GetResource(ResourceFile, ResourceInStream);

        PartLayout.CreateOutStream(PartLayoutOutStream);
        CopyStream(PartLayoutOutStream, ResourceInStream);
    end;

    local procedure PartResourceError(PartName: Text; ResourceFile: Text; Detail: Text) LayoutErrorInfo: ErrorInfo
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        LayoutErrorInfo.ErrorType := LayoutErrorInfo.ErrorType::Internal;
        LayoutErrorInfo.Verbosity := LayoutErrorInfo.Verbosity::Error;
        LayoutErrorInfo.DataClassification := LayoutErrorInfo.DataClassification::SystemMetadata;
        LayoutErrorInfo.Message := StrSubstNo(ResourceNotReadableErr, PartName);
        LayoutErrorInfo.DetailedMessage := Detail;

        Dimensions.Add('PartName', PartName);
        Dimensions.Add('ResourceFile', ResourceFile);
        LayoutErrorInfo.CustomDimensions := Dimensions;
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
        ReportLayoutList: Record "Report Layout List";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
    begin
        // No Application ID filter: Report Layout List surfaces tenant layouts with a blank Application ID, and
        // assignments are encoded from that view, so filtering on the shipped App ID would miss the rows that
        // actually reference the part. Clear the assignments of every matching row instead.
        ReportLayoutList.SetRange("Report ID", CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID());
        ReportLayoutList.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(ReportLayoutList.Name)));
        ReportLayoutList.SetRange("Layout Subtype", Subtype);
        ReportLayoutList.SetLoadFields("Application ID", Name, "Layout Subtype");
        if ReportLayoutList.FindSet() then
            repeat
                CompositeLayoutLookupHelper.ClearPartAssignments(ReportLayoutList);
            until ReportLayoutList.Next() = 0;
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
        ResourceNotReadableErr: Label 'The layout file for the report part %1 could not be read. The part was not seeded.', Comment = '%1 = the name of the shipped theme or header/footer part';
        ResourceNotReadableDetailTxt: Label 'Resource: %1. Platform error: %2', Locked = true;
        ResourceMissingDetailTxt: Label 'Resource: %1. The app does not carry this resource.', Locked = true;
        ThemeMimeTypeTxt: Label 'reportlayout/dotx', Locked = true;
        HeaderFooterMimeTypeTxt: Label 'reportlayout/docx', Locked = true;
}
