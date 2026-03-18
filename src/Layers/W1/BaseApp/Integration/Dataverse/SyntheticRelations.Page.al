// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.Dataverse;
using System.Telemetry;

page 5376 "Synthetic Relations"
{
    PageType = List;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    SourceTableTemporary = true;
    SourceTable = "Synth. Relation Mapping Buffer";
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Relations)
            {
                field("Synth. Relation Name"; Rec."Synth. Relation Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Name';
                    ToolTip = 'Specifies the name of the relation.';
                    DrillDown = true;
                    trigger OnDrillDown()
                    var
                        SyntheticRelationDetails: Page "Synthetic Relation Details";
                    begin
                        SyntheticRelationDetails.SetRelation(Rec);
                        SyntheticRelationDetails.Run();
                    end;
                }
                field("Rel. Native Entity Name"; Rec."Rel. Native Entity Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronized table';
                    ToolTip = 'Specifies the name of the synchronized table in the relation.';
                }
                field("Rel. Virtual Entity Name"; Rec."Rel. Virtual Entity Name")
                {
                    ApplicationArea = Suite;
                    Caption = 'Virtual table';
                    ToolTip = 'Specifies the name of the virtual table in the relation.';
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            action("Manage in Dataverse")
            {
                ApplicationArea = Suite;
                ToolTip = 'Manage configuration settings for synthetic relations in your Dataverse environment.';
                Caption = 'Manage in Dataverse';
                Image = Setup;

                trigger OnAction()
                begin
                    CDSIntegrationImpl.ShowSyntheticRelationsConfig();
                end;
            }
        }
        area(Processing)
        {
            action(NewRelation)
            {
                ApplicationArea = Suite;
                ToolTip = 'Create a new synthetic relation.';
                Caption = 'New';
                Image = New;
                trigger OnAction()
                var
                    NewSyntheticRelationWiz: Page "New Synthetic Relation Wiz.";
                begin
                    NewSyntheticRelationWiz.SetExistingBCTableRelations(Rec);
                    NewSyntheticRelationWiz.Run();
                end;
            }
            action(RemoveRelation)
            {
                ApplicationArea = Suite;
                ToolTip = 'Remove a synthetic relation.';
                Caption = 'Remove';
                Image = Delete;
                Enabled = not SyntheticRelationsAreEmpty;
                trigger OnAction()
                begin
                    SyntheticRelations.DeleteSyntheticRelation(Rec);
                    LoadExistingBCTableRelations();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = Suite;
                ToolTip = 'Refresh the loaded relations.';
                Caption = 'Refresh';
                Image = Refresh;
                trigger OnAction()
                begin
                    LoadExistingBCTableRelations();
                end;
            }
        }
        area(Promoted)
        {
            actionref(ManageinDataverse_Promoted; "Manage in Dataverse")
            {
            }
            actionref(NewRelation_Promoted; NewRelation)
            {
            }
            actionref(RemoveRelation_Promoted; RemoveRelation)
            {
            }
            actionref(Refresh_Promoted; Refresh)
            {
            }
        }
    }

    var
        CDSIntegrationImpl: Codeunit "CDS Integration Impl.";
        SyntheticRelations: Codeunit "Synthetic Relations";
        SyntheticRelationsAreEmpty: Boolean;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000MQ2', SyntheticRelations.GetFeatureTelemetryName(), Enum::"Feature Uptake Status"::Discovered);
        LoadExistingBCTableRelations();
    end;

    local procedure LoadExistingBCTableRelations()
    begin
        SyntheticRelations.LoadExistingBCTableRelations(Rec);
        Rec.Reset();
        SyntheticRelationsAreEmpty := Rec.Count() = 0;
    end;

}
