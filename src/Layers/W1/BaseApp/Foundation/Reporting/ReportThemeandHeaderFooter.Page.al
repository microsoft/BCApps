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
                field(Type; Rec."Layout Subtype")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Type';
                    ToolTip = 'Specifies whether the artifact is a Theme or a Header/Footer part.';
                }
                field(Publisher; Rec."Layout Publisher")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Publisher';
                    ToolTip = 'Specifies the extension and publisher that owns the artifact. Empty for tenant-defined parts.';
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
                ToolTip = 'Upload a new header/footer part.';

                trigger OnAction()
                begin
                    CreateArtifact(Enum::"Report Layout Subtype"::HeaderFooter);
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
            action(DeleteArtifact)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the selected tenant-defined artifact. Out-of-box parts cannot be deleted.';

                trigger OnAction()
                begin
                    DeleteSelectedArtifact();
                end;
            }
            group(StatusActions)
            {
                Caption = 'Status';
                Image = Status;

                action(SetApproved)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Approved';
                    Image = Approve;
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
                    ToolTip = 'Retire the selected parts so they are no longer offered for assignment.';

                    trigger OnAction()
                    begin
                        SetStatus(Enum::"Report Layout Status"::Retired);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(NewTheme_Promoted; NewTheme) { }
                actionref(NewHeaderFooter_Promoted; NewHeaderFooter) { }
                actionref(SetApproved_Promoted; SetApproved) { }
                actionref(SetDraft_Promoted; SetDraft) { }
            }
        }
    }

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
            '',
            Rec."Layout Format"::Word,
            true,
            false,
            ExcelSheetConfiguration,
            Subtype,
            ReturnReportID,
            ReturnLayoutName);
        CurrPage.Update(false);
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
        EmptyGuid: Guid;
        FeatureNotEnabledErr: Label 'The Composite Layout feature is gated by the Document Report Experience preview. Enable it in Feature Management before opening this page.';
        CannotDeleteOobErr: Label 'Out-of-box themes and header/footer parts cannot be deleted.';
        DeleteArtifactQst: Label 'Delete the artifact %1?', Comment = '%1 = artifact name';
        DeletePartWithReferencesQst: Label 'The part "%1" is assigned in %2 report configuration(s). Deleting it will clear those assignments and the affected reports will render without this part. Do you want to continue?', Comment = '%1 = artifact name; %2 = number of configurations';
        StatusChangedMsg: Label 'The status of %1 part(s) was changed to %2.', Comment = '%1 = number of parts; %2 = new status';
        DemoteAssignedQst: Label 'The selected part(s) are currently assigned in %1 report configuration(s) and will keep applying when reports are printed, even after this status change. Change the status anyway?', Comment = '%1 = number of configurations';
}
