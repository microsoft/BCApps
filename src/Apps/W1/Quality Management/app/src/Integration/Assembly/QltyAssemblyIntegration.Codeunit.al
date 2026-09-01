// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Assembly;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Assembly.Posting;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Journal;
using Microsoft.QualityManagement.Configuration.GenerationRule;
using Microsoft.QualityManagement.Document;
using Microsoft.QualityManagement.Utilities;
using Microsoft.Warehouse.Journal;

/// <summary>
/// Used to integrate with assembly related events.
/// </summary>
codeunit 20412 "Qlty. Assembly Integration"
{
    Permissions =
        tabledata "Qlty. Inspection Gen. Rule" = r,
        tabledata "Qlty. Inspection Header" = rm;

    /// <summary>
    /// Creates inspections for posted assembly output when an active automatic generation rule applies.
    /// </summary>
    /// <param name="AssemblyHeader">The source assembly header.</param>
    /// <param name="AssemblyLine">The assembly line supplied by the posting event.</param>
    /// <param name="PostedAssemblyHeader">The posted assembly header used as an inspection source.</param>
    /// <param name="ItemJnlPostLine">The item journal posting codeunit supplied by the posting event.</param>
    /// <param name="ResJnlPostLine">The resource journal posting codeunit supplied by the posting event.</param>
    /// <param name="WhseJnlRegisterLine">The warehouse journal registration codeunit supplied by the posting event.</param>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnAfterPost', '', true, true)]
    local procedure HandleOnAfterPost(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        QltyBatchNotifHelper: Codeunit "Qlty. Batch Notif. Helper";
        MgtItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        HasInspection: Boolean;
        IsHandled: Boolean;
    begin
        if not HasAssemblyOutputPostGenRule(QltyInspectionGenRule) then
            exit;

        MgtItemTrackingDocManagement.FindShptRcptEntries(TempSpecTrackingSpecification, Database::"Posted Assembly Header", 0, PostedAssemblyHeader."No.", '', 0, 0, '');
        OnBeforeAttemptCreateInspectionFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader, IsHandled);
        if IsHandled then
            exit;

        QltyBatchNotifHelper.BeginBatch();
        QltyBatchNotifHelper.ConfigureForBatch(QltyInspectionCreate);
        if not TempSpecTrackingSpecification.IsEmpty() then
            repeat
                Clear(QltyInspectionHeader);
                HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(PostedAssemblyHeader, TempSpecTrackingSpecification, AssemblyHeader, UnusedVariant1, false, QltyInspectionGenRule);
                if HasInspection then begin
                    QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                    if QltyInspectionHeader."No." <> '' then begin
                        QltyInspectionHeader."Source Quantity (Base)" := TempSpecTrackingSpecification."Quantity (Base)";
                        QltyInspectionHeader.Modify(false);
                        QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
                    end;
                end;
                OnAfterAttemptCreateInspectionFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader);
            until TempSpecTrackingSpecification.Next(-1) = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(QltyInspectionGenRule);
            OnBeforeAttemptCreateInspectionFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader, IsHandled);
            if IsHandled then
                exit;
            HasInspection := QltyInspectionCreate.CreateInspectionWithMultiVariants(PostedAssemblyHeader, AssemblyHeader, UnusedVariant1, UnusedVariant2, false, TempQltyInspectionGenRule);
            if HasInspection then begin
                QltyInspectionCreate.GetCreatedInspection(QltyInspectionHeader);
                QltyBatchNotifHelper.TrackCreatedInspection(QltyInspectionHeader."No.", QltyInspectionCreate.IsLastInspectionNewlyCreated());
            end;
            OnAfterAttemptCreateInspectionFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader);
        end;
        QltyBatchNotifHelper.EndBatch();
    end;

    /// <summary>
    /// Filters generation rules for automatic assembly output posting.
    /// </summary>
    /// <param name="QltyInspectionGenRule">The generation rule record on which the applicable filters are set.</param>
    /// <returns>True if at least one applicable generation rule exists; otherwise, false.</returns>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Qlty. Inspection Gen. Rule", 'R', InherentPermissionsScope::Permissions)]
    local procedure HasAssemblyOutputPostGenRule(var QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule"): Boolean
    begin
        QltyInspectionGenRule.SetRange("Assembly Trigger", QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        exit(not QltyInspectionGenRule.IsEmpty());
    end;

    /// <summary>
    /// Notifies subscribers before an inspection is created from posted assembly output.
    /// </summary>
    /// <param name="AssemblyHeader">The source assembly header.</param>
    /// <param name="PostedAssemblyHeader">The posted assembly header.</param>
    /// <param name="TempTrackingSpecification">The item tracking specification for the output.</param>
    /// <param name="QltyInspectionHeader">The inspection header available to the subscriber.</param>
    /// <param name="IsHandled">Set to true to skip the default inspection creation.</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeAttemptCreateInspectionFromPostedAssembly(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var IsHandled: Boolean);
    begin
    end;

    /// <summary>
    /// Notifies subscribers after inspection creation is attempted for posted assembly output.
    /// </summary>
    /// <param name="AssemblyHeader">The source assembly header.</param>
    /// <param name="PostedAssemblyHeader">The posted assembly header.</param>
    /// <param name="TempTrackingSpecification">The item tracking specification for the output.</param>
    /// <param name="QltyInspectionHeader">The created or resolved inspection header.</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterAttemptCreateInspectionFromPostedAssembly(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header");
    begin
    end;
}
