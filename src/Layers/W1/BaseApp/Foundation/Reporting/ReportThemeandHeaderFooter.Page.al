// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using Microsoft.Shared.Report;
using System.Environment.Configuration;
using System.Reflection;

/// <summary>
/// Central registry of reusable Composite Layout artifacts — the Theme and Header/Footer layout parts that can be
/// assigned as report defaults. Lists out-of-box and tenant-defined parts with their publisher and status, and lets
/// administrators add, export and remove tenant-defined parts.
/// </summary>
page 9666 "Report Theme and Header/Footer"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report themes and header-footer setup';
    AdditionalSearchTerms = 'Composite Layout, Document Theme, Header Footer Part, Report Themes and Header/Footers';
    PageType = List;
    SourceTable = "Report Layout List";
    UsageCategory = Administration;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    Extensible = true;
    AboutTitle = 'About report themes and header/footer setup';
    AboutText = 'Manage reusable theme and header/footer layout parts that can be assigned as defaults to your Word report layouts. Add, export, delete, and change the approval status of parts.';

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the theme or header/footer part.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the theme or header/footer part.';
                }
                field(Type; Rec."Layout Subtype")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    ToolTip = 'Specifies whether the artifact is a Theme or a Header/Footer part.';
                }
                field(Publisher; PublisherDisplay)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Publisher';
                    ToolTip = 'Specifies the publisher of the artifact: Microsoft for the parts that ship with Business Central, the publishing extension for parts that come from another app, and Tenant-defined for parts uploaded here.';
                }
                field(Status; Rec."Layout Status")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Status';
                    ToolTip = 'Specifies the lifecycle status of the artifact. New parts start as Draft; only Approved parts can be assigned as report defaults.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(NewTheme)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New theme';
                Image = New;
                AccessByPermission = tabledata "Tenant Report Layout" = M;
                ToolTip = 'Upload a new theme part.';

                trigger OnAction()
                begin
                    CreateArtifact(Enum::"Report Layout Subtype"::Theme);
                end;
            }
            action(NewHeaderFooter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'New header/footer';
                Image = New;
                AccessByPermission = tabledata "Tenant Report Layout" = M;
                ToolTip = 'Upload a new header/footer part.';

                trigger OnAction()
                begin
                    CreateArtifact(Enum::"Report Layout Subtype"::HeaderFooter);
                end;
            }
            action(ImportShippedParts)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Import default themes and header/footers';
                Image = Import;
                AccessByPermission = tabledata "Tenant Report Layout" = M;
                ToolTip = 'Import all themes and header/footer parts that ship with Business Central into the shared pool. Missing parts are added and parts that are already there are refreshed from the shipped file.';

                trigger OnAction()
                begin
                    ImportShippedPartsAction();
                end;
            }
            action(AssignShippedDesigns)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Assign default designs to report layouts';
                Image = ApplyEntries;
                AccessByPermission = tabledata "Tenant Report Layout Cfg" = M;
                ToolTip = 'Assign the shipped header/footer design to every body-only Word layout that has none, and the default theme as the global default. This is the same assignment that runs on installation and upgrade; layouts that already have a header/footer keep it.';

                trigger OnAction()
                begin
                    AssignShippedDesignsAction();
                end;
            }
            action(AssignThemeHeaderFooter)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Assign Theme and Header/Footer Design';
                Image = Setup;
                AccessByPermission = tabledata "Tenant Report Layout Cfg" = M;
                ToolTip = 'Assign the theme and header/footer design that apply to every report with no more specific assignment. A layout, report or company assignment overrides this global default.';

                trigger OnAction()
                begin
                    AssignGlobalDefaultParts();
                end;
            }
            action(ExportArtifact)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Export';
                Image = Export;
                ToolTip = 'Export the selected artifact file.';

                trigger OnAction()
                begin
                    ReportLayoutsImpl.ExportReportLayout(Rec, false);
                end;
            }
            action(ShowInfo)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show info';
                Image = Info;
                ToolTip = 'Show details of the selected theme or header/footer part, including how many report configurations currently use it.';

                trigger OnAction()
                begin
                    ShowPartInfo();
                end;
            }
            action(EditDescription)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit description';
                Image = Edit;
                Scope = Repeater;
                AccessByPermission = tabledata "Tenant Report Layout" = M;
                ToolTip = 'Edit the description of the selected tenant-defined theme or header/footer part. Out-of-box parts cannot be edited.';

                trigger OnAction()
                begin
                    EditPartDescription();
                end;
            }
            action(ReplaceArtifact)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Replace';
                Image = Import;
                Scope = Repeater;
                AccessByPermission = tabledata "Tenant Report Layout" = M;
                ToolTip = 'Replace the layout file of the selected tenant-defined theme or header/footer part. Out-of-box parts cannot be replaced.';

                trigger OnAction()
                begin
                    ReplaceSelectedArtifact();
                end;
            }
            action(DeleteArtifact)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                AccessByPermission = tabledata "Tenant Report Layout" = M;
                ToolTip = 'Delete the selected tenant-defined artifact. Out-of-box parts cannot be deleted.';

                trigger OnAction()
                begin
                    DeleteSelectedArtifact();
                end;
            }
            group(StatusActions)
            {
                Caption = 'Part Status';
                Image = Status;

                action(SetApproved)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Approved';
                    Image = Approve;
                    Scope = Repeater;
                    ToolTip = 'Approve the selected parts so they can be assigned as report defaults.';

                    trigger OnAction()
                    begin
                        SetStatus(Enum::"Report Layout Status"::Approved);
                    end;
                }
                action(SetDraft)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Draft';
                    Image = OpenWorksheet;
                    Scope = Repeater;
                    ToolTip = 'Move the selected parts back to Draft. Draft parts cannot be assigned as report defaults.';

                    trigger OnAction()
                    begin
                        SetStatus(Enum::"Report Layout Status"::Draft);
                    end;
                }
                action(SetPendingApproval)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Pending Approval';
                    Image = AddWatch;
                    Scope = Repeater;
                    ToolTip = 'Mark the selected parts as pending approval.';

                    trigger OnAction()
                    begin
                        SetStatus(Enum::"Report Layout Status"::"Pending Approval");
                    end;
                }
                action(SetRetired)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Retired';
                    Image = Archive;
                    Scope = Repeater;
                    ToolTip = 'Retire the selected parts so they are no longer offered for assignment.';

                    trigger OnAction()
                    begin
                        SetStatus(Enum::"Report Layout Status"::Retired);
                    end;
                }
            }
        }
        area(navigation)
        {
            action(ReportsUsingPart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reports using this part';
                Image = "Report";
                Scope = Repeater;
                ToolTip = 'Show the reports the selected theme or header/footer design is assigned to, with the layouts it applies to and the level each resolves from.';

                trigger OnAction()
                begin
                    ShowReportsUsingPart();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(NewTheme_Promoted; NewTheme) { }
                actionref(NewHeaderFooter_Promoted; NewHeaderFooter) { }
                actionref(ImportShippedParts_Promoted; ImportShippedParts) { }
                actionref(AssignShippedDesigns_Promoted; AssignShippedDesigns) { }
                actionref(AssignThemeHeaderFooter_Promoted; AssignThemeHeaderFooter) { }
                actionref(ReportsUsingPart_Promoted; ReportsUsingPart) { }
                actionref(ReplaceArtifact_Promoted; ReplaceArtifact) { }
                actionref(ShowInfo_Promoted; ShowInfo) { }
                actionref(EditDescription_Promoted; EditDescription) { }
                actionref(SetApproved_Promoted; SetApproved) { }
                actionref(SetDraft_Promoted; SetDraft) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PublisherDisplay := PartPublisherDisplay();
    end;

    /// <summary>
    /// The publisher to show for a part. The parts that ship with the Base Application are stored as tenant layouts,
    /// because there is no design-time way to place a layout on the Tenant Report Defaults report, so the platform
    /// reports no publisher for them. Naming Microsoft for those keeps them from reading as something the tenant made,
    /// while a part that really comes from an extension keeps the publisher the platform reports.
    /// </summary>
    local procedure PartPublisherDisplay(): Text
    begin
        if Rec."Layout Publisher" <> '' then
            exit(Rec."Layout Publisher");
        if not Rec."User Defined" then
            exit('');
        if CompositeReportPartsMgt.IsShippedPart(Rec.Name) then
            exit(MicrosoftPublisherTxt);
        exit(TenantDefinedTxt);
    end;

    trigger OnOpenPage()
    var
        FeatureKeyManagement: Codeunit "Feature Key Management";
    begin
        if not FeatureKeyManagement.IsDocumentReportExperienceEnabled() then
            Error(FeatureNotEnabledErr);

        // Show only the Composite Layout artifacts (themes and header/footer parts), not body layouts.
        Rec.FilterGroup(2);
        Rec.SetFilter("Layout Subtype", '%1|%2', Rec."Layout Subtype"::HeaderFooter, Rec."Layout Subtype"::Theme);
        Rec.FilterGroup(0);
    end;

    local procedure CreateArtifact(Subtype: Enum "Report Layout Subtype")
    var
        NewPartDialog: Page "New Report Theme Header/Footer";
        ExcelSheetConfiguration: Enum "Excel Sheet Configuration";
        ReturnReportID: Integer;
        ReturnLayoutName: Text;
    begin
        NewPartDialog.SetSubtype(Subtype);
        if NewPartDialog.RunModal() <> Action::OK then
            exit;

        // Create the part under Tenant Report Defaults as a global Word layout so it can be
        // assigned to any report. InsertNewLayout prompts for the file and validates the subtype.
        ReportLayoutsImpl.InsertNewLayout(
            LookupHelper.GetTenantReportDefaultsReportID(),
            NewPartDialog.GetPartName(),
            NewPartDialog.GetPartDescription(),
            Rec."Layout Format"::Word,
            true,
            false,
            ExcelSheetConfiguration,
            Subtype,
            ReturnReportID,
            ReturnLayoutName);
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Writes every theme and header/footer part that ships with the Base Application into the shared pool, the same
    /// seeding that runs at install and upgrade, so an administrator can restore or refresh the shipped set on demand.
    /// </summary>
    /// <remarks>
    /// Seeding replaces a part that already exists under a shipped name with the shipped file, so a change made to one
    /// of those parts is lost. Assignments survive, because Tenant Report Layout Cfg references a part by name rather
    /// than by a foreign key. Confirm first: reverting an administrator's own edit is not something to do silently.
    /// </remarks>
    local procedure ImportShippedPartsAction()
    var
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
    begin
        if not Confirm(ImportShippedPartsQst, false) then
            exit;

        CompositeReportPartsMgt.SeedDefaultParts();
        CurrPage.Update(false);
        Message(ImportShippedPartsDoneMsg);
    end;

    /// <summary>
    /// Runs the assignment that ships with the Base Application - the same one that runs at install and upgrade - so an
    /// administrator can apply it without republishing, for instance after installing an app that adds report layouts.
    /// </summary>
    local procedure AssignShippedDesignsAction()
    var
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        AssignedCount: Integer;
    begin
        // No confirmation: the assignment only fills in layouts that have no header/footer, so it cannot overwrite a
        // choice an administrator has made.
        AssignedCount := CompositeLayoutAssignMgt.AssignDefaultParts();
        Message(AssignShippedDesignsDoneMsg, AssignedCount);
    end;

    /// <summary>
    /// Opens the assignment dialog on the global default: the Tenant Report Layout Cfg wildcard row (Report ID 0, empty
    /// Layout Name, all companies) that the platform resolver falls back to for every report and layout with nothing
    /// more specific configured.
    /// </summary>
    /// <remarks>
    /// The global default is the assignment this page can offer, because a registry of parts carries no report context.
    /// Per-layout and per-report assignments are made from Report Layouts, and the company default from Company
    /// Information; both override what is set here.
    ///
    /// Note that a header/footer set globally also reaches layouts that were never meant to carry one - the e-mail
    /// body layouts among them - since a blank column means "not configured at this level" to the resolver rather than
    /// "explicitly none". Hence the dialog rather than a one-click assign: the choice is stated before it is written.
    /// </remarks>
    local procedure AssignGlobalDefaultParts()
    var
        HeaderFooterThemeAssignment: Page "Header/Footer Theme Assignment";
    begin
        HeaderFooterThemeAssignment.SetLayout(0, '');
        HeaderFooterThemeAssignment.RunModal();
        CurrPage.Update(false);
    end;

    /// <summary>
    /// Shows where the selected part is used, by opening the Report Layout Themes and Header/Footers page filtered to
    /// the reports that assign it. That page resolves the theme and header/footer per layout, so it also shows which
    /// layouts of those reports the part reaches and at which level it applies.
    /// </summary>
    local procedure ShowReportsUsingPart()
    var
        ReportLayoutList: Record "Report Layout List";
        LayoutThemeHeaderFooter: Page "Layout Theme and Header/Footer";
        ReportIDFilter: Text;
        IsGlobalDefault: Boolean;
    begin
        if not LookupHelper.GetPartAssignmentReportFilter(Rec, ReportIDFilter, IsGlobalDefault) then begin
            Message(PartNotAssignedMsg, Rec.Name);
            exit;
        end;

        // A global default reaches every report that has nothing more specific configured, which no report filter can
        // express. Say that out loud, then show the reports the part is assigned to explicitly - if there are any.
        if IsGlobalDefault then
            Message(PartIsGlobalDefaultMsg, Rec.Name);
        if ReportIDFilter = '' then
            exit;

        // Themes and header/footer parts apply to Word layouts only - the same filter the Report Layouts page applies
        // when it opens this page for a single report.
        ReportLayoutList.SetFilter("Report ID", ReportIDFilter);
        ReportLayoutList.SetRange("Layout Format", ReportLayoutList."Layout Format"::Word);
        LayoutThemeHeaderFooter.SetTableView(ReportLayoutList);
        LayoutThemeHeaderFooter.SetPartContext(Rec.Name);
        LayoutThemeHeaderFooter.Run();
    end;

    local procedure SetStatus(NewStatus: Enum "Report Layout Status")
    var
        SelectedLayouts: Record "Report Layout List";
        UpdateCount: Integer;
        AssignedCount: Integer;
    begin
        CurrPage.SetSelectionFilter(SelectedLayouts);

        // Moving an assigned part away from Approved does not unassign it — it will keep applying at print time
        // (status is not enforced at render). Warn so the change isn't made unknowingly.
        if NewStatus <> NewStatus::Approved then begin
            AssignedCount := CountAssignedInSelection(SelectedLayouts);
            if AssignedCount > 0 then
                if not Confirm(DemoteAssignedQst, false, AssignedCount) then
                    exit;
        end;

        UpdateCount := ReportLayoutsImpl.SetLayoutStatusBatch(SelectedLayouts, NewStatus);
        if UpdateCount > 0 then
            Message(StatusChangedMsg, UpdateCount, NewStatus);
        CurrPage.Update(false);
    end;

    local procedure CountAssignedInSelection(var SelectedLayouts: Record "Report Layout List"): Integer
    var
        Total: Integer;
    begin
        // Only user-defined parts can actually change status; count assignments for those.
        if SelectedLayouts.FindSet() then
            repeat
                if SelectedLayouts."User Defined" then
                    Total += LookupHelper.CountPartAssignments(SelectedLayouts);
            until SelectedLayouts.Next() = 0;
        exit(Total);
    end;

    local procedure ReplaceSelectedArtifact()
    var
        ReturnReportID: Integer;
        ReturnLayoutName: Text;
        TypeText: Text;
    begin
        if not Rec."User Defined" then
            Error(CannotReplaceOobErr);

        if Rec."Layout Subtype" = Rec."Layout Subtype"::Theme then
            TypeText := ThemeTypeTxt
        else
            TypeText := HeaderFooterTypeTxt;

        if not Confirm(ReplaceArtifactQst, false, TypeText, Rec.Name) then
            exit;

        ReportLayoutsImpl.ReplaceLayout(Rec."Report ID", Rec.Name, Rec.Description, Rec."Layout Format", ReturnReportID, ReturnLayoutName);
        CurrPage.Update(false);
    end;

    local procedure EditPartDescription()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        EditDescriptionDialog: Page "New Report Theme Header/Footer";
    begin
        if not Rec."User Defined" then
            Error(CannotEditOobErr);

        if not TenantReportLayout.Get(Rec."Report ID", Rec.Name, EmptyGuid) then
            exit;

        EditDescriptionDialog.SetEditDescriptionMode(TenantReportLayout.Description);
        if EditDescriptionDialog.RunModal() <> Action::OK then
            exit;

        ReportLayoutsImpl.UpdateReportLayoutDescription(Rec."Report ID", Rec.Name, EditDescriptionDialog.GetPartDescription());
        CurrPage.Update(false);
    end;

    local procedure ShowPartInfo()
    var
        TypeText: Text;
        PublisherText: Text;
        AssignedCount: Integer;
    begin
        if Rec."Layout Subtype" = Rec."Layout Subtype"::Theme then
            TypeText := ThemeTypeTxt
        else
            TypeText := HeaderFooterTypeTxt;

        PublisherText := PartPublisherDisplay();

        AssignedCount := LookupHelper.CountPartAssignments(Rec);

        // Pass values as parameters so any backslashes in the data are not turned into line breaks.
        Message(PartInfoLbl, Rec.Name, Rec.Description, TypeText, Format(Rec."Layout Status"), PublisherText, AssignedCount);
    end;

    local procedure DeleteSelectedArtifact()
    var
        TenantReportLayout: Record "Tenant Report Layout";
        AssignedCount: Integer;
    begin
        if not Rec."User Defined" then
            Error(CannotDeleteOobErr);

        AssignedCount := LookupHelper.CountPartAssignments(Rec);
        if AssignedCount > 0 then begin
            if not Confirm(DeletePartWithReferencesQst, false, Rec.Name, AssignedCount) then
                exit;
        end else
            if not Confirm(DeleteArtifactQst, false, Rec.Name) then
                exit;

        // EmptyGuid is the App ID key part - empty for tenant-defined layouts.
        if not TenantReportLayout.Get(Rec."Report ID", Rec.Name, EmptyGuid) then
            exit;
        LookupHelper.ClearPartAssignments(Rec);
        ReportLayoutsImpl.DeleteReportLayout(TenantReportLayout);
        CurrPage.Update(false);
    end;

    var
        ReportLayoutsImpl: Codeunit "Report Layouts Impl.";
        LookupHelper: Codeunit "Composite Layout Lookup Helper";
        CompositeReportPartsMgt: Codeunit "Composite Report Parts Mgt.";
        EmptyGuid: Guid;
        PublisherDisplay: Text;
        FeatureNotEnabledErr: Label 'The Composite Layout feature is gated by the Document Report Experience preview. Enable it in Feature Management before opening this page.';
        CannotDeleteOobErr: Label 'Out-of-box themes and header/footer parts cannot be deleted.';
        CannotReplaceOobErr: Label 'Out-of-box themes and header/footer parts cannot be replaced.';
        CannotEditOobErr: Label 'Out-of-box themes and header/footer parts cannot be edited.';
        ReplaceArtifactQst: Label 'Replace the %1 layout file for "%2"?', Comment = '%1 = layout type (Theme or Header/Footer); %2 = artifact name';
        ThemeTypeTxt: Label 'Theme';
        HeaderFooterTypeTxt: Label 'Header/Footer';
        TenantDefinedTxt: Label 'Tenant-defined';
        MicrosoftPublisherTxt: Label 'Microsoft', Locked = true;
        PartInfoLbl: Label 'Name: %1\Description: %2\Type: %3\Status: %4\Publisher: %5\Used in %6 report configuration(s).', Comment = '%1 = part name; %2 = description; %3 = type (Theme or Header/Footer); %4 = status; %5 = publisher; %6 = number of report configurations that reference the part';
        DeleteArtifactQst: Label 'Delete the artifact %1?', Comment = '%1 = artifact name';
        DeletePartWithReferencesQst: Label 'The part "%1" is assigned in %2 report configuration(s). Deleting it will clear those assignments and the affected reports will render without this part. Do you want to continue?', Comment = '%1 = artifact name; %2 = number of configurations';
        StatusChangedMsg: Label 'The status of %1 part(s) was changed to %2.', Comment = '%1 = number of parts; %2 = new status';
        DemoteAssignedQst: Label 'The selected part(s) are currently assigned in %1 report configuration(s) and will keep applying when reports are printed, even after this status change. Change the status anyway?', Comment = '%1 = number of configurations';
        ImportShippedPartsQst: Label 'Import all themes and header/footer designs that ship with Business Central?\\A part that already exists under a shipped name is replaced with the shipped file, so any change made to it is lost. Assignments to reports and layouts are kept.';
        ImportShippedPartsDoneMsg: Label 'The themes and header/footer designs that ship with Business Central were imported.';
        AssignShippedDesignsDoneMsg: Label '%1 assignment(s) were written. Layouts that already had a header/footer, and reports whose layouts are not installed, were left unchanged.', Comment = '%1 = number of assignments written';
        PartNotAssignedMsg: Label 'The part %1 is not assigned to any report yet. Assign it to a layout from Report Layouts, to a company from Company Information, or as the global default from this page.', Comment = '%1 = part name';
        PartIsGlobalDefaultMsg: Label 'The part %1 is assigned as the global default, so it applies to every report and layout that has no theme or header/footer of its own.', Comment = '%1 = part name';
}
