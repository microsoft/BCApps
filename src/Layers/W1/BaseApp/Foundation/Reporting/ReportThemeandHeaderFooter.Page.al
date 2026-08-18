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
            action(AssignShippedDesigns)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Assign default designs to report layouts';
                Image = ApplyEntries;
                AccessByPermission = tabledata "Tenant Report Layout Cfg" = M;
                ToolTip = 'Assign the shipped header/footer design to the body layouts that have none, and the default theme to every body layout. This is the same assignment that runs on installation and upgrade; a layout that already has a theme or header/footer keeps it.';

                trigger OnAction()
                begin
                    AssignShippedDesignsAction();
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
                actionref(AssignShippedDesigns_Promoted; AssignShippedDesigns) { }
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
    /// Runs the assignment that ships with the Base Application - the same one that runs at install and upgrade - so an
    /// administrator can apply it without republishing, for instance after installing an app that adds report layouts.
    /// </summary>
    local procedure AssignShippedDesignsAction()
    var
        CompositeLayoutAssignMgt: Codeunit "Composite Layout Assign. Mgt.";
        AssignedCount: Integer;
    begin
        AssignedCount := CompositeLayoutAssignMgt.AssignDefaultParts();
        Message(AssignShippedDesignsDoneMsg, AssignedCount);
    end;

    /// <summary>
    /// Shows where the selected part is used: the report layout configuration list, filtered on the column that carries
    /// the part - Header/Footer Part for a header/footer, Theme Part for a theme - so every row shown is a report and
    /// layout the selected part applies to.
    /// </summary>
    local procedure ShowReportsUsingPart()
    var
        TenantReportLayoutCfg: Record "Tenant Report Layout Cfg";
        TenantReportLayoutCfgList: Page "Tenant Report Layout Cfg";
    begin
        if not LookupHelper.SetPartAssignmentFilter(TenantReportLayoutCfg, Rec) then
            exit;
        if TenantReportLayoutCfg.IsEmpty() then begin
            Message(PartNotAssignedMsg, Rec.Name);
            exit;
        end;

        TenantReportLayoutCfgList.SetTableView(TenantReportLayoutCfg);
        TenantReportLayoutCfgList.Run();
    end;

    local procedure SetStatus(NewStatus: Enum "Report Layout Status")
    var
        SelectedLayouts: Record "Report Layout List";
        UpdateCount: Integer;
        AssignedCount: Integer;
    begin
        CurrPage.SetSelectionFilter(SelectedLayouts);

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
        AssignShippedDesignsDoneMsg: Label '%1 assignment(s) were written. Layouts that already had a header/footer, and reports whose layouts are not installed, were left unchanged.', Comment = '%1 = number of assignments written';
        PartNotAssignedMsg: Label 'The part %1 is not assigned to any report layout yet.', Comment = '%1 = part name';
}
