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
using Microsoft.Warehouse.Journal;

/// <summary>
/// Used to integrate with assembly related events.
/// </summary>
codeunit 20412 "Qlty. Assembly Integration"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Assembly-Post", 'OnAfterPost', '', true, true)]
    local procedure HandleOnAfterPost(var AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; PostedAssemblyHeader: Record "Posted Assembly Header"; var ItemJnlPostLine: Codeunit "Item Jnl.-Post Line"; var ResJnlPostLine: Codeunit "Res. Jnl.-Post Line"; var WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line")
    var
        QltyInspectionHeader: Record "Qlty. Inspection Header";
        QltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInspectionGenRule: Record "Qlty. Inspection Gen. Rule" temporary;
        QltyInspectionCreate: Codeunit "Qlty. Inspection - Create";
        MgtItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        HasTest: Boolean;
        Handled: Boolean;
    begin
        QltyInspectionGenRule.SetRange("Assembly Trigger", QltyInspectionGenRule."Assembly Trigger"::OnAssemblyOutputPost);
        QltyInspectionGenRule.SetFilter("Activation Trigger", '%1|%2', QltyInspectionGenRule."Activation Trigger"::"Manual or Automatic", QltyInspectionGenRule."Activation Trigger"::"Automatic only");
        if QltyInspectionGenRule.IsEmpty() then
            exit;

        MgtItemTrackingDocManagement.FindShptRcptEntries(TempSpecTrackingSpecification, Database::"Posted Assembly Header", 0, PostedAssemblyHeader."No.", '', 0, 0, '');
        OnBeforeAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader, Handled);
        if Handled then
            exit;

        if not TempSpecTrackingSpecification.IsEmpty() then
            repeat
                HasTest := QltyInspectionCreate.CreateTestWithMultiVariants(PostedAssemblyHeader, TempSpecTrackingSpecification, AssemblyHeader, UnusedVariant1, false, QltyInspectionGenRule);
                if HasTest then begin
                    QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
                    QltyInspectionHeader."Source Quantity (Base)" := TempSpecTrackingSpecification."Quantity (Base)";
                    QltyInspectionHeader.Modify(false);
                end;
                OnAfterAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader);
            until TempSpecTrackingSpecification.Next(-1) = 0
        else begin
            TempQltyInspectionGenRule.CopyFilters(QltyInspectionGenRule);
            OnBeforeAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader, Handled);
            if Handled then
                exit;
            HasTest := QltyInspectionCreate.CreateTestWithMultiVariants(PostedAssemblyHeader, AssemblyHeader, UnusedVariant1, UnusedVariant2, false, TempQltyInspectionGenRule);
            if HasTest then
                QltyInspectionCreate.GetCreatedTest(QltyInspectionHeader);
            OnAfterAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionHeader);
        end;
    end;

    /// <summary>
    /// Provides an opportunity to modify the automated assembly output Quality Inspection creation behavior.
    /// </summary>
    /// <param name="AssemblyHeader">Assembly Header</param>
    /// <param name="PostedAssemblyHeader">Posted Assembly Header</param>
    /// <param name="TempTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionHeader">Quality Inspection to be created</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeAttemptCreateTestFromPostedAssembly(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header"; var Handled: Boolean);
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the automatically created Quality Inspection after assembly output.
    /// </summary>
    /// <param name="AssemblyHeader">Assembly Header</param>
    /// <param name="PostedAssemblyHeader">Posted Assembly Header</param>
    /// <param name="TempTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionHeader">created Quality Inspection</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterAttemptCreateTestFromPostedAssembly(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionHeader: Record "Qlty. Inspection Header");
    begin
    end;
}
