// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;
using System.Environment.Configuration;

/// <summary>
/// Assigns the header/footer and theme parts that ship with the Base Application to the body layouts of the standard
/// reports, so a fresh installation renders those reports with a header/footer and a theme instead of bare.
/// </summary>
/// <remarks>
/// Assignments are written to Tenant Report Layout Cfg - the table the platform Composite Layout resolver consults when
/// it merges a Word body layout with a header/footer part and a theme part at render time - at the layout level
/// (Report ID + body layout name) with an empty Company Name, so they apply to every company. This is the same row the
/// Assign Theme and Header/Footer dialog writes when an administrator sets a layout's parts by hand.
///
/// Parts are referenced by the composite reference the platform stores, &lt;app id&gt;::&lt;layout name&gt;. The app id
/// is not hardcoded: every part name is resolved against Report Layout List at run time, so the same code works whether
/// the parts are tenant-uploaded or shipped by an extension.
///
/// Existing configuration is never overwritten. A layout that already has a header/footer - because an administrator
/// chose one, or because a previous run assigned it - is left alone, so re-running on upgrade fills in what is new
/// without reverting anyone's choice.
/// </remarks>
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
    /// <remarks>
    /// Rows name the layout's registered Name, not its caption and not its file name, because Tenant Report Layout Cfg
    /// keys on the Name. Report 1700's body-only layout, for instance, is named WordBody while its file is
    /// DeferralSummaryGLBody.docx. The caption is quoted after the rows that are simply called WordBody, which says
    /// nothing on its own.
    ///
    /// Some rows name layouts shipped by other extensions - E-Document, Subscription Billing, Sustainability, Payment
    /// Practices. No dependency is needed for them: the configuration keys on the report id as a plain integer and the
    /// layout is resolved by name at run time, so these rows apply wherever that extension is installed and are skipped
    /// where it is not. The same holds for layouts that only exist in a localization layer.
    ///
    /// The e-mail body layouts and the label layouts are deliberately absent from this list. They already render as
    /// intended, and merging a header/footer onto them would put one on a layout that was never meant to carry it. They
    /// do get the theme, which is styling only, because they declare the body subtype - see AssignThemeToBodyLayouts.
    /// </remarks>
    local procedure AssignShippedHeaderFooters() AssignedCount: Integer
    begin
        // --- Sales reports ---------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(107, 'WordBody', this.InternalDefaultTxt));                    // Customer - Order Summary
        AssignedCount += this.CountIf(this.AssignHeaderFooter(114, 'WordBody', this.InternalDefaultTxt));                    // Salesperson - Sales Statistics
        AssignedCount += this.CountIf(this.AssignHeaderFooter(115, 'WordBody', this.InternalDefaultTxt));                    // Salesperson - Commission

        // --- Inventory -------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(708, 'WordBody', this.InternalDefaultTxt));                    // Inventory - Order Details
        AssignedCount += this.CountIf(this.AssignHeaderFooter(713, 'WordBody', this.InternalDefaultTxt));                    // Inventory - Customer Sales
        AssignedCount += this.CountIf(this.AssignHeaderFooter(714, 'WordBody', this.InternalDefaultTxt));                    // Inventory - Vendor Purchases
        AssignedCount += this.CountIf(this.AssignHeaderFooter(718, 'WordBody', this.InternalDefaultTxt));                    // Inventory - Sales Back Orders
        AssignedCount += this.CountIf(this.AssignHeaderFooter(5802, 'WordBody', this.InternalDefaultTxt));                   // Inventory Valuation - WIP

        // --- Projects --------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1016, 'JobQuoteBody.docx', this.ExternalModernLogoTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1017, 'JobTaskQuoteBody.docx', this.ExternalModernLogoTxt));

        // --- Sales documents -------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1302, 'StandardSalesProFormaInvBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1303, 'StandardSalesDraftInvoiceBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1304, 'StandardSalesQuoteBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1304, 'StandardESGSalesQuoteBody.docx', this.ExternalDefaultTxt));              // Sustainability
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1304, 'SalesQuoteForSubscriptionBillingBody.docx', this.ExternalDefaultTxt));   // Subscription Billing
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1305, 'StandardSalesOrderConfBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1305, 'SalesOrderConfForSubscriptionBillingBody.docx', this.ExternalDefaultTxt)); // Subscription Billing
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'StandardSalesInvoiceBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'StandardSalesInvoiceVatSpecBody.docx', this.ExternalDefaultTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'StandardESGSalesInvoiceBody.docx', this.ExternalDefaultDetailedTxt));    // Sustainability
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1306, 'SalesInvoiceForSubscriptionBillingBody.docx', this.ExternalDefaultTxt)); // Subscription Billing
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1307, 'StandardSalesCreditMemoBody.docx', this.ExternalDefaultDetailedTxt));
        // The E-Document app names its credit memo layout StandardSalesInvoiceBody.docx. Confusing, but it sits on
        // report 1307, so it does not collide with the invoice layout of the same name on 1306.
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1307, 'StandardSalesInvoiceBody.docx', this.ExternalDefaultDetailedTxt));       // E-Document
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1307, 'StandardSalesCreditMemoNABody.docx', this.ExternalDefaultDetailedTxt));  // NA layer
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1308, 'StandardSalesShipmentBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1309, 'StandardSalesReturnRcptBody.docx', this.ExternalDefaultDetailedTxt));
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1316, 'StandardStatementBody.docx', this.ExternalModernTxt));

        // --- Purchase documents ----------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1322, 'StandardPurchaseOrderBody.docx', this.ExternalModernLogoTxt));

        // --- E-Document ------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(6102, 'SampleInvoiceLayoutBody', this.ExternalDefaultDetailedTxt));             // E-Document

        // --- Relationship management -----------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(5085, 'WordLayoutBody', this.InternalMinimalisticCenteredTxt));                 // Contact - Cover Sheet

        // --- Deferrals -------------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1700, 'WordBody', this.InternalDefaultTxt));                   // Deferral Summary - G/L
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1701, 'WordBody', this.InternalDefaultTxt));                   // Deferral Summary - Sales
        AssignedCount += this.CountIf(this.AssignHeaderFooter(1702, 'WordBody', this.InternalDefaultTxt));                   // Deferral Summary - Purchasing

        // --- Manufacturing ---------------------------------------------------------------------------
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000753, 'WordLayoutBody', this.InternalDefaultTxt));         // Quantity Explosion of BOM
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000780, 'WordLayoutBody', this.InternalDefaultTxt));         // Capacity Task List
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000788, 'WordBody', this.InternalDefaultTxt));               // Prod. Order - Shortage List
        AssignedCount += this.CountIf(this.AssignHeaderFooter(99000789, 'WordLayoutBody', this.InternalDefaultTxt));         // Subcontractor - Dispatch List

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
    /// <remarks>
    /// A layout that is not installed is skipped rather than written. A row keyed to a name no layout has would never
    /// match at render time, and it would hide the far more likely cause: the name here not matching the tenant's.
    /// </remarks>
    /// <returns>True when a row was written.</returns>
    local procedure AssignHeaderFooter(ReportID: Integer; LayoutName: Text; PartName: Text): Boolean
    var
        Composite: Text;
    begin
        if not this.IsBodyLayoutInstalled(ReportID, LayoutName) then
            exit(false);
        if not this.ResolvePart(PartName, Enum::"Report Layout Subtype"::HeaderFooter, Composite) then
            exit(false);

        exit(this.WriteLayoutPart(ReportID, LayoutName, Composite, Enum::"Report Layout Subtype"::HeaderFooter));
    end;

    /// <summary>
    /// Assigns the theme to every body layout installed on the tenant, one Tenant Report Layout Cfg row per layout.
    /// </summary>
    /// <remarks>
    /// Per body layout, deliberately not as the global wildcard row (Report ID 0). The wildcard row would theme every
    /// layout of every report, including the e-mail bodies and the label layouts, because a blank Theme Part Name means
    /// "not configured at this level" to the resolver and it keeps walking to the global default. Writing the theme only
    /// where it belongs leaves every other layout resolving to None, which is what those layouts should show.
    ///
    /// Newly installed reports are therefore not themed until this runs again, which the upgrade does on every upgrade,
    /// and the Assign default designs action does on demand.
    /// </remarks>
    /// <returns>The number of layouts the theme was written for.</returns>
    local procedure AssignThemeToBodyLayouts(PartName: Text) AssignedCount: Integer
    var
        ReportLayoutList: Record "Report Layout List";
        Composite: Text;
    begin
        if not this.ResolvePart(PartName, Enum::"Report Layout Subtype"::Theme, Composite) then
            exit(0);

        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.SetRange("Layout Subtype", 4);
        if not ReportLayoutList.FindSet() then
            exit(0);

        repeat
            if this.WriteLayoutPart(ReportLayoutList."Report ID", ReportLayoutList.Name, Composite, Enum::"Report Layout Subtype"::Theme) then
                AssignedCount += 1;
        until ReportLayoutList.Next() = 0;
    end;

    /// <summary>
    /// Writes one part onto a layout's Tenant Report Layout Cfg row for all companies, filling the column that carries
    /// parts of that subtype. Leaves an already configured column alone, so nothing overwrites an existing assignment.
    /// </summary>
    /// <returns>True when the row was written.</returns>
    local procedure WriteLayoutPart(ReportID: Integer; LayoutName: Text; Composite: Text; Subtype: Enum "Report Layout Subtype"): Boolean
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        LayoutNameKey: Text[250];
        RowExists: Boolean;
    begin
        LayoutNameKey := CopyStr(LayoutName, 1, MaxStrLen(TenantReportLayoutCfg."Layout Name"));
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
            TenantReportLayoutCfg."Company Name" := ''; // '' = all companies
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
    local procedure IsBodyLayoutInstalled(ReportID: Integer; LayoutName: Text): Boolean
    var
        ReportLayoutList: Record "Report Layout List";
    begin
        ReportLayoutList.SetRange("Report ID", ReportID);
        ReportLayoutList.SetRange(Name, CopyStr(LayoutName, 1, MaxStrLen(ReportLayoutList.Name)));
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        ReportLayoutList.SetRange("Layout Subtype", 4);
        exit(not ReportLayoutList.IsEmpty());
    end;

    /// <summary>
    /// Looks up a header/footer or theme part in the shared pool by name and returns the composite reference to store.
    /// </summary>
    /// <remarks>
    /// Report Layout List is a virtual table whose key starts with Report ID, so filtering it on Name and Layout
    /// Subtype alone yields nothing: the leading key field has to be set. Every reusable part lives on the Tenant
    /// Report Defaults report, the same one Composite Report Parts Mgt. seeds.
    /// </remarks>
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
        // The part names as Composite Report Parts Mgt. seeds them. A name that does not match a seeded part simply
        // resolves to nothing and the row is skipped, so the two lists have to stay in step.
        InternalDefaultTxt: Label 'Internal Default', Locked = true;
        InternalMinimalisticCenteredTxt: Label 'Internal Minimalistic Centered', Locked = true;
        ExternalDefaultTxt: Label 'External Default', Locked = true;
        ExternalDefaultDetailedTxt: Label 'External Default Detailed', Locked = true;
        ExternalModernTxt: Label 'External Modern', Locked = true;
        ExternalModernLogoTxt: Label 'External Modern Logo', Locked = true;
        DefaultThemeTxt: Label 'Default', Locked = true;
}
