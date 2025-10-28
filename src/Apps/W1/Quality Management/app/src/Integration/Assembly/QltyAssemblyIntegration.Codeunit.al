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
        QltyInspectionTestHeader: Record "Qlty. Inspection Test Header";
        QltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule";
        TempSpecTrackingSpecification: Record "Tracking Specification" temporary;
        TempQltyInTestGenerationRule: Record "Qlty. In. Test Generation Rule" temporary;
        QltyInspectionTestCreate: Codeunit "Qlty. Inspection Test - Create";
        MgtItemTrackingDocManagement: Codeunit "Item Tracking Doc. Management";
        UnusedVariant1: Variant;
        UnusedVariant2: Variant;
        HasTest: Boolean;
        Handled: Boolean;
    begin
        QltyInTestGenerationRule.SetRange("Assembly Trigger", QltyInTestGenerationRule."Assembly Trigger"::OnAssemblyOutputPost);
        QltyInTestGenerationRule.SetFilter("Activation Trigger", '%1|%2', QltyInTestGenerationRule."Activation Trigger"::"Manual or Automatic", QltyInTestGenerationRule."Activation Trigger"::"Automatic only");
        if QltyInTestGenerationRule.IsEmpty() then
            exit;

        MgtItemTrackingDocManagement.FindShptRcptEntries(TempSpecTrackingSpecification, Database::"Posted Assembly Header", 0, PostedAssemblyHeader."No.", '', 0, 0, '');
        OnBeforeAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionTestHeader, Handled);
        if Handled then
            exit;

        if not TempSpecTrackingSpecification.IsEmpty() then
            repeat
                HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(PostedAssemblyHeader, TempSpecTrackingSpecification, AssemblyHeader, UnusedVariant1, false, QltyInTestGenerationRule);
                if HasTest then begin
                    QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
                    QltyInspectionTestHeader."Source Quantity (Base)" := TempSpecTrackingSpecification."Quantity (Base)";
                    QltyInspectionTestHeader.Modify(false);
                end;
                OnAfterAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionTestHeader);
            until TempSpecTrackingSpecification.Next(-1) = 0
        else begin
            TempQltyInTestGenerationRule.CopyFilters(QltyInTestGenerationRule);
            OnBeforeAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionTestHeader, Handled);
            if Handled then
                exit;
            HasTest := QltyInspectionTestCreate.CreateTestWithMultiVariants(PostedAssemblyHeader, AssemblyHeader, UnusedVariant1, UnusedVariant2, false, TempQltyInTestGenerationRule);
            if HasTest then
                QltyInspectionTestCreate.GetCreatedTest(QltyInspectionTestHeader);
            OnAfterAttemptCreateTestFromPostedAssembly(AssemblyHeader, PostedAssemblyHeader, TempSpecTrackingSpecification, QltyInspectionTestHeader);
        end;
    end;

    /// <summary>
    /// Provides an opportunity to modify the automated assembly output Quality Inspection Test creation behavior.
    /// </summary>
    /// <param name="AssemblyHeader">Assembly Header</param>
    /// <param name="PostedAssemblyHeader">Posted Assembly Header</param>
    /// <param name="TempTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionTestHeader">Quality Inspection Test to be created</param>
    /// <param name="Handled">Provides an opportunity to replace the default behavior</param>
    [IntegrationEvent(false, false)]
    procedure OnBeforeAttemptCreateTestFromPostedAssembly(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header"; var Handled: Boolean);
    begin
    end;

    /// <summary>
    /// Provides an opportunity to modify the automatically created Quality Inspection Test after assembly output.
    /// </summary>
    /// <param name="AssemblyHeader">Assembly Header</param>
    /// <param name="PostedAssemblyHeader">Posted Assembly Header</param>
    /// <param name="TempTrackingSpecification">Tracking Specification</param>
    /// <param name="QltyInspectionTestHeader">created Quality Inspection Test</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterAttemptCreateTestFromPostedAssembly(var AssemblyHeader: Record "Assembly Header"; var PostedAssemblyHeader: Record "Posted Assembly Header"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var QltyInspectionTestHeader: Record "Qlty. Inspection Test Header");
    begin
    end;
}
