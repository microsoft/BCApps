// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

/// <summary>
/// API Page that enables a user to manage available features.
/// </summary>
page 2613 "API - Feature Management"
{
    PageType = API;
    Caption = 'feature', Locked = true;
    EntityCaption = 'Feature';
    EntitySetCaption = 'Features';
    APIPublisher = 'microsoft';
    APIGroup = 'featureManagement';
    APIVersion = 'v1.0';
    EntityName = 'feature';
    EntitySetName = 'features';
    SourceTable = "Feature Key";
    DelayedInsert = true;
    ODataKeyFields = ID;
    Editable = false;
    Extensible = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(id; Rec.ID)
                {
                    Caption = 'ID';
                }
                field(enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(learnMoreLink; Rec."Learn More Link")
                {
                    Caption = 'Learn More Link';
                }
                field(mandatoryBy; Rec."Mandatory By")
                {
                    Caption = 'Mandatory By';
                }
                field(canTry; Rec."Can Try")
                {
                    Caption = 'Can Try';
                }
                field(isOneWay; Rec."Is One Way")
                {
                    Caption = 'Is One Way';
                }
                field(dataUpdateRequired; Rec."Data Update Required")
                {
                    Caption = 'Data Update Required';
                }
                field(mandatoryByVersion; Rec."Mandatory By Version")
                {
                    Caption = 'Mandatory By Version';
                }
                field(descriptionInEnglish; Rec."Description In English")
                {
                    Caption = 'Description In English';
                }
            }
        }
    }

    [ServiceEnabled]
    procedure EnableFeature() IsEnabled: Boolean
    var
        FeatureDataUpdateStatus: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        if Rec.Enabled = Rec.Enabled::"All Users" then
            Error('Feature with ID %1 is already enabled.', Rec.ID);

        Rec.Enabled := Rec.Enabled::"All Users";
        IsEnabled := Rec.Modify(true);

        // Update data if needed
        // Probably need to change the logic to run this in the background
        FeatureManagementFacade.Update(FeatureDataUpdateStatus);
    end;

    [ServiceEnabled]
    procedure DisableFeature(): Text
    begin
        if Rec.Enabled = Rec.Enabled::None then
            Error('Feature with ID %1 is already disabled.', Rec.ID);

        if Rec."Is One Way" then
            Error('Feature with ID %1 is one way and cannot be disabled.', Rec.ID);

        Rec.Enabled := Rec.Enabled::None;
        Rec.Modify(true);

        exit(rec.ID + Format(Rec.Enabled));
    end;
}