// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Environment.Configuration;
using System.Reflection;
/// <summary>
/// Assigns the header/footer and theme parts that ship with the Base Application to the body layouts of the standard
/// reports, so a fresh installation renders those reports with a header/footer and a theme instead of bare.
/// </summary>
codeunit 9668 "Composite Layout Assign. Mgt."
{
    Access = Internal;
    Permissions = tabledata "Tenant Report Layout Cfg" = RIMD;

    /// <summary>
    /// Applies every assignment that ships with the Base Application: the header/footer design listed for each body
    /// layout, and the theme on every body layout. Safe to call repeatedly - a layout that already has a part keeps it.
    /// </summary>
    /// <returns>The number of assignments written. Rows for layouts or parts that are not installed are skipped.</returns>
    procedure AssignDefaultParts() AssignedCount: Integer
    begin
        AssignedCount := this.AssignShippedHeaderFooters();
        AssignedCount += this.AssignThemeToBodyLayouts(this.DefaultThemeTxt);
    end;

    /// <summary>
    /// The layouts this codeunit configures and the header/footer design each one gets. Only body-only layouts are
    /// listed: those are authored without a header/footer of their own, so a header/footer part has to be merged onto
    /// them at render time.
    /// </summary>
    local procedure AssignShippedHeaderFooters() AssignedCount: Integer
    begin
        // --- Sales reports ---------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(107, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(114, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(115, 'WordBody', this.InternalDefaultTxt));

        // --- Inventory -------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(708, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(713, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(714, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(718, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(5802, 'WordBody', this.InternalDefaultTxt));

        // --- Projects --------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1016, 'JobQuoteBody.docx', this.ExternalModernLogoTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1017, 'JobTaskQuoteBody.docx', this.ExternalModernLogoTxt));

        // --- Sales documents -------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1302, 'StandardSalesProFormaInvBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1303, 'StandardSalesDraftInvoiceBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1304, 'StandardSalesQuoteBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1304, 'StandardESGSalesQuoteBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1304, 'SalesQuoteForSubscriptionBillingBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1305, 'StandardSalesOrderConfBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1305, 'SalesOrderConfForSubscriptionBillingBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'StandardSalesInvoiceBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'StandardSalesInvoiceVatSpecBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'StandardESGSalesInvoiceBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'SalesInvoiceForSubscriptionBillingBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1307, 'StandardSalesCreditMemoBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1307, 'StandardSalesCreditMemoNABody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1308, 'StandardSalesShipmentBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1309, 'StandardSalesReturnRcptBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1316, 'StandardStatementBody.docx', this.ExternalModernTxt));

        // --- Purchase documents ----------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1322, 'StandardPurchaseOrderBody.docx', this.ExternalModernLogoTxt));

        // --- E-Document ------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(6102, 'SampleInvoiceLayoutBody', this.ExternalDefaultDetailedTxt));

        // --- Relationship management -----------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(5085, 'WordLayoutBody', this.InternalMinimalisticCenteredTxt));

        // --- Deferrals -------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1700, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1701, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1702, 'WordBody', this.InternalDefaultTxt));

        // --- Manufacturing ---------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000753, 'WordLayoutBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000780, 'WordLayoutBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000788, 'WordBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000789, 'WordLayoutBody', this.InternalDefaultTxt));

        // --- Payment Practices -----------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(685, 'PaymentPractice_SmallBusinessLayoutBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(685, 'PaymentPractice_PeriodLayoutBody', this.InternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(685, 'PaymentPractice_VendorSizeLayoutBody', this.InternalDefaultTxt));
    end;

    /// <summary>
    /// Assigns a header/footer part to one body layout, writing the layout-level Tenant Report Layout Cfg row for all
    /// companies. Does nothing when the layout is not installed on the tenant, when it is not a Word body layout, when
    /// the part is not in the shared pool, or when the layout already has a header/footer.
    /// </summary>
    /// <returns>True when a row was written.</returns>
    local procedure AssignHeaderFooter(ReportID: Integer; LayoutName: Text; PartName: Text): Boolean
    var
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
        AppId: Guid;
        Composite: Text;
    begin
        if not this.TryGetBodyLayoutAppId(ReportID, LayoutName, AppId) then
            exit(false);
        if not this.ResolvePart(PartName, Enum::"Report Layout Subtype"::HeaderFooter, Composite) then
            exit(false);

        // TODO: APPID-IN-LAYOUTNAME - pass LayoutName instead once the platform resolves the body layout.
        exit(this.WriteLayoutPart(
            ReportID,
            CompositeLayoutLookupHelper.EncodeCompositeName(AppId, LayoutName),
            Composite,
            Enum::"Report Layout Subtype"::HeaderFooter));
    end;

    /// <summary>
    /// Assigns the theme to every body layout installed on the tenant - every Word layout whose name contains "body" -
    /// as one Tenant Report Layout Cfg row per layout.
    /// </summary>
    /// <returns>The number of layouts the theme was written for.</returns>
    local procedure AssignThemeToBodyLayouts(PartName: Text) AssignedCount: Integer
    var
        ReportLayoutList: Record "Report Layout List";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
        Composite: Text;
    begin
        if not this.ResolvePart(PartName, Enum::"Report Layout Subtype"::Theme, Composite) then
            exit(0);

        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.SetRange("Layout Subtype", ReportLayoutList."Layout Subtype"::Body);
        if not ReportLayoutList.FindSet() then
            exit(0);

        repeat
            // TODO: APPID-IN-LAYOUTNAME - pass ReportLayoutList.Name instead once the platform resolves the body layout.
            if this.WriteLayoutPart(
                ReportLayoutList."Report ID",
                CompositeLayoutLookupHelper.EncodeCompositeName(ReportLayoutList."Application ID", ReportLayoutList.Name),
                Composite,
                Enum::"Report Layout Subtype"::Theme)
            then
                AssignedCount += 1;
        until ReportLayoutList.Next() = 0;
    end;

    /// <summary>
    /// Writes one part onto a layout's Tenant Report Layout Cfg row for all companies, filling the column that carries
    /// parts of that subtype. Leaves an already configured column alone, so nothing overwrites an existing assignment.
    /// </summary>
    /// <returns>True when the row was written.</returns>
    // TODO: APPID-IN-LAYOUTNAME - BodyLayoutReference is <AppId>::<LayoutName>; it becomes the plain layout name
    // again once the platform resolves the body layout itself.
    local procedure WriteLayoutPart(ReportID: Integer; BodyLayoutReference: Text; Composite: Text; Subtype: Enum "Report Layout Subtype"): Boolean
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        LayoutNameKey: Text[250];
        RowExists: Boolean;
    begin
        LayoutNameKey := CopyStr(BodyLayoutReference, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name"));
        RowExists := TenantReportLayoutCfg.Get(ReportID, LayoutNameKey, '');

        if RowExists then
            case Subtype of
                Subtype::HeaderFooter:
                    if TenantReportLayoutCfg."Header Part Name" <> '' then
                        exit(false);
                Subtype::Theme:
                    if TenantReportLayoutCfg."Theme Part Name" <> '' then
                        exit(false);
            end
        else begin
            TenantReportLayoutCfg.Init();
            TenantReportLayoutCfg."Report ID" := ReportID;
            TenantReportLayoutCfg."Layout Name" := LayoutNameKey;
            TenantReportLayoutCfg."Company Name" := '';
        end;

        case Subtype of
            Subtype::HeaderFooter:
                TenantReportLayoutCfg."Header Part Name" := CopyStr(Composite, 1, MaxStrLen(TenantReportLayoutCfg."Header Part Name"));
            Subtype::Theme:
                TenantReportLayoutCfg."Theme Part Name" := CopyStr(Composite, 1, MaxStrLen(TenantReportLayoutCfg."Theme Part Name"));
        end;

        if RowExists then
            TenantReportLayoutCfg.Modify(true)
        else
            TenantReportLayoutCfg.Insert(true);
        exit(true);
    end;

    /// <summary>
    /// Whether the report has a body layout of that name installed on the tenant. Only a body layout can carry a
    /// header/footer or a theme: the parts are merged onto it at render time.
    /// </summary>
    // TODO: APPID-IN-LAYOUTNAME - the AppId output exists only to build the configuration key. When the platform
    // resolves the body layout itself, this can go back to answering whether the layout exists.
    /// <summary>
    /// Finds the body layout of that name on the report and reports the ID of the application that owns it, which the
    /// configuration key needs. Returns false when the report has no Word body layout of that name.
    /// </summary>
    local procedure TryGetBodyLayoutAppId(ReportID: Integer; LayoutName: Text; var AppId: Guid): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        Clear(AppId);
        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange(Name, CopyStr(LayoutName, 1, MaxStrLen(ReportLayoutList.Name)));
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.SetRange("Layout Subtype", ReportLayoutList."Layout Subtype"::Body);
        if not ReportLayoutList.FindFirst() then
            exit(false);

        AppId := ReportLayoutList."Application ID";
        exit(true);
    end;

    /// <summary>
    /// Looks up a header/footer or theme part in the shared pool by name and returns the composite reference to store.
    /// </summary>
    local procedure ResolvePart(PartName: Text; Subtype: Enum "Report Layout Subtype"; var Composite: Text): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
        CompositeLayoutLookupHelper: Codeunit "Composite Layout Lookup Helper";
    begin
        Composite := '';
        if PartName = '' then
            exit(false);

        ReportLayoutList.SetRange("Report ID", CompositeLayoutLookupHelper.GetTenantReportDefaultsReportID());
        ReportLayoutList.SetRange(Name, CopyStr(PartName, 1, MaxStrLen(ReportLayoutList.Name)));
        ReportLayoutList.SetRange("Layout Subtype", Subtype);
        if not ReportLayoutList.FindFirst() then
            exit(false);

        Composite := CompositeLayoutLookupHelper.EncodeCompositeName(ReportLayoutList."Application ID", ReportLayoutList.Name);
        exit(true);
    end;

    local procedure CountIf(Assigned: Boolean): Integer
    begin
        if Assigned then
            exit(1);
        exit(0);
    end;

    var
        InternalDefaultTxt: Label 'Internal Default', Locked = true;
        InternalMinimalisticCenteredTxt: Label 'Internal Minimalistic Centered', Locked = true;
        ExternalDefaultTxt: Label 'External Default', Locked = true;
        ExternalDefaultDetailedTxt: Label 'External Default Detailed', Locked = true;
        ExternalModernTxt: Label 'External Modern', Locked = true;
        ExternalModernLogoTxt: Label 'External Modern Logo', Locked = true;
        DefaultThemeTxt: Label 'Default', Locked = true;
}
