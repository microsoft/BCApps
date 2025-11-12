// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.SyncEngine;

using System.Reflection;

page 5363 "Match Based Coupling Criteria"
{
    Caption = 'Select Coupling Criteria';
    DataCaptionExpression = Rec."Integration Table Mapping Name";
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "Integration Field Mapping";

    layout
    {
        area(content)
        {
            group(Control13)
            {
                Caption = ' ';
                ShowCaption = false;

                field(SynchAfterMatchBasedCouplingControl; SynchAfterMatchBasedCoupling)
                {
                    ApplicationArea = Suite;
                    Caption = 'Synchronize After Coupling';
                    Visible = true;
                    Enabled = true;
                    ToolTip = 'Specifies whether to synchronize data for the coupled records. On pages, the data will synchronize when you choose OK. In the assisted setup guide, the data will synchronize when you choose Finish.';

                    trigger OnValidate()
                    begin
                        SaveIntegrationTableMapping();
                    end;
                }
                field(ConflictResolutionControl; ConflictResolution)
                {
                    ApplicationArea = Suite;
                    Caption = 'Resolve Update Conflicts';
                    Visible = ConflictResolutionControlVisible;
                    Enabled = ConflictResolutionControlVisible;
                    ToolTip = 'Specifies the strategy to use for automatically resolving conflicts that might occur when synchronizing the coupled records.';

                    trigger OnValidate()
                    begin
                        SaveIntegrationTableMapping();
                    end;
                }
                field(CreateNewInCaseOfNoMatchControl; CreateNewInCaseOfNoMatch)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create New If Unable to Find a Match';
                    Visible = CreateNewInCaseOfNoMatchControlVisible;
                    Enabled = CreateNewInCaseOfNoMatchControlVisible;
                    ToolTip = 'Specifies whether to create a new Dataverse entity to couple the Business Central record to, in case no match is found by using the matching fields.';

                    trigger OnValidate()
                    begin
                        SaveIntegrationTableMapping();
                    end;
                }
            }

            repeater(Group)
            {
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the number of the field in Business Central.';
                }
                field(FieldName; NAVFieldName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the field in Business Central.';
                }
                field("Integration Table Field No."; Rec."Integration Table Field No.")
                {
                    ApplicationArea = Suite;
                    BlankZero = true;
                    Editable = false;
                    Visible = false;
                    ToolTip = 'Specifies the number of the field in Dynamics 365 Sales.';
                }
                field(IntegrationFieldName; CRMFieldName)
                {
                    ApplicationArea = Suite;
                    Caption = 'Integration Field Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the field in Dynamics 365 Sales.';
                }
                field("Use For Match-Based Coupling"; Rec."Use For Match-Based Coupling")
                {
                    ApplicationArea = Suite;
                    Caption = 'Match on this Field';
                    ToolTip = 'Specifies whether to match on this field when looking for the entity to couple to.';
                }
                field("Case-Sensitive Matching"; Rec."Case-Sensitive Matching")
                {
                    ApplicationArea = Suite;
                    Caption = 'Case-sensitive Matching';
                    ToolTip = 'Specifies whether the matching on this field should be case-sensitive.';
                }
                field("Match Priority"; Rec."Match Priority")
                {
                    ApplicationArea = Suite;
                    Caption = 'Match Priority';
                    ToolTip = 'Specifies in which priority order will the groups of matching fields be used to find a match.';
                }
            }

        }
    }

    actions
    {
        area(Processing)
        {
            action(ResetTransformationRules)
            {
                ApplicationArea = Suite;
                Caption = 'Reset Criteria';
                Image = ResetStatus;
                ToolTip = 'Resets the coupling criteria.';

                trigger OnAction()
                var
                    IntegrationFieldMapping: Record "Integration Field Mapping";
                begin
                    IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
                    IntegrationFieldMapping.SetRange("Use For Match-Based Coupling", true);
                    IntegrationFieldMapping.ModifyAll("Use For Match-Based Coupling", false);
                    IntegrationFieldMapping.Reset();
                    IntegrationFieldMapping.SetRange("Integration Table Mapping Name", IntegrationTableMapping.Name);
                    IntegrationFieldMapping.SetRange("Case-Sensitive Matching", true);
                    IntegrationFieldMapping.ModifyAll("Case-Sensitive Matching", false);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IntegrationTableMapping.SetFilter(Name, Rec.GetFilter("Integration Table Mapping Name"));
        IntegrationTableMapping.FindFirst();
        SetControlVisibility();
        SetSynchSettings();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = Action::LookupOK then
            SaveIntegrationTableMapping();
        exit(true);
    end;

    trigger OnAfterGetRecord()
    begin
        GetFieldCaptions();
    end;

    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        TypeHelper: Codeunit "Type Helper";
        ConflictResolution: Enum "Integration Update Conflict Resolution";
        SynchAfterMatchBasedCoupling: Boolean;
        CreateNewInCaseOfNoMatch: Boolean;
        NAVFieldName: Text;
        CRMFieldName: Text;
        ConflictResolutionControlVisible: Boolean;
        CreateNewInCaseOfNoMatchControlVisible: Boolean;

    local procedure SetControlVisibility()
    var
        IsHandled: Boolean;
    begin
        ConflictResolutionControlVisible := (IntegrationTableMapping.Direction = IntegrationTableMapping.Direction::Bidirectional);
        IntegrationTableMapping.OnIsCreateNewInCaseOfNoMatchControlVisible(IntegrationTableMapping, CreateNewInCaseOfNoMatchControlVisible, IsHandled);
        if not IsHandled then
            CreateNewInCaseOfNoMatchControlVisible := (IntegrationTableMapping.Direction <> IntegrationTableMapping.Direction::FromIntegrationTable);
    end;

    local procedure SaveIntegrationTableMapping()
    begin
        if IntegrationTableMapping.Find() then begin
            IntegrationTableMapping."Create New in Case of No Match" := CreateNewInCaseOfNoMatch;
            IntegrationTableMapping."Synch. After Bulk Coupling" := SynchAfterMatchBasedCoupling;
            IntegrationTableMapping."Update-Conflict Resolution" := ConflictResolution;
            IntegrationTableMapping.Modify();
        end;
    end;

    local procedure SetSynchSettings()
    begin
        CreateNewInCaseOfNoMatch := IntegrationTableMapping."Create New in Case of No Match";
        SynchAfterMatchBasedCoupling := IntegrationTableMapping."Synch. After Bulk Coupling";
        ConflictResolution := IntegrationTableMapping."Update-Conflict Resolution";
    end;

    local procedure GetFieldCaptions()
    begin
        NAVFieldName := GetFieldCaption(IntegrationTableMapping."Table ID", Rec."Field No.");
        CRMFieldName := GetFieldCaption(IntegrationTableMapping."Integration Table ID", Rec."Integration Table Field No.");
    end;

    local procedure GetFieldCaption(TableID: Integer; FieldID: Integer): Text
    var
        "Field": Record "Field";
    begin
        if (TableID <> 0) and (FieldID <> 0) then
            if TypeHelper.GetField(TableID, FieldID, Field) then
                exit(Field."Field Caption");
        exit('');
    end;
}

