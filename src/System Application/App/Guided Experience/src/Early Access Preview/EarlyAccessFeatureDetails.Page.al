// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Feedback;

page 1999 "Early Access Feature Details"
{
    PageType = Card;
    Caption = 'Feature details';
    DataCaptionExpression = FeatureName;
    Editable = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(FeatureName; FeatureName)
                {
                    ApplicationArea = All;
                    Caption = 'Feature';
                    ToolTip = 'Specifies the currently selected feature.';
                    MultiLine = true;
                }
                field(Category; Category)
                {
                    ApplicationArea = All;
                    Caption = 'Category';
                    ToolTip = 'Specifies the category of the feature.';
                }
                field(ReleaseVersion; ReleaseVersion)
                {
                    ApplicationArea = All;
                    Caption = 'Release version';
                    ToolTip = 'Specifies the Business Central release that introduced the feature. This does not indicate whether it is deployed in this environment.';
                }
            }
            group(OverviewGroup)
            {
                Caption = 'Overview';

                field(Overview; Overview)
                {
                    ApplicationArea = All;
                    Caption = 'Overview';
                    ShowCaption = false;
                    ToolTip = 'Specifies what the selected feature does and how it can help you.';
                    MultiLine = true;
                }
            }
            group(GettingStartedGroup)
            {
                Caption = 'Getting started';
                Visible = HasGettingStarted;

                field(GettingStarted; GettingStarted)
                {
                    ApplicationArea = All;
                    Caption = 'Getting started';
                    ShowCaption = false;
                    ToolTip = 'Specifies the steps to get started with the selected feature, in order.';
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProvideFeatureFeedback)
            {
                ApplicationArea = All;
                Caption = 'Provide Feature Feedback';
                ToolTip = 'Provide feedback on this feature.';
                Image = Comment;

                trigger OnAction()
                var
                    Feedback: Codeunit "Microsoft User Feedback";
                begin
                    Feedback.RequestFeedback(FeatureName, EarlyAccessPreviewFeatureAreaTok, EarlyAccessPreviewFeatureAreaDisplayNameTok);
                end;
            }
            action(ViewHelp)
            {
                ApplicationArea = All;
                Caption = 'View Help';
                ToolTip = 'Open the help documentation for this feature.';
                Image = Help;
                Enabled = HasHelpUrl;

                trigger OnAction()
                begin
                    if HelpUrl = '' then
                        exit;
                    Hyperlink(HelpUrl);
                end;
            }
            action(WatchVideo)
            {
                ApplicationArea = All;
                Caption = 'Watch Video';
                ToolTip = 'Watch a video demonstrating this feature.';
                Image = Picture;
                Enabled = HasVideoUrl;

                trigger OnAction()
                begin
                    if VideoUrl = '' then
                        exit;
                    Hyperlink(VideoUrl);
                end;
            }
        }
        area(Promoted)
        {
            actionref(ProvideFeatureFeedback_Promoted; ProvideFeatureFeedback)
            {
            }
            actionref(ViewHelp_Promoted; ViewHelp)
            {
            }
            actionref(WatchVideo_Promoted; WatchVideo)
            {
            }
        }
    }

    internal procedure SetFeature(GuidedExperienceItem: Record "Guided Experience Item"; NewReleaseVersion: Text; NewOverview: Text; NewGettingStarted: Text)
    begin
        FeatureName := GuidedExperienceItem.Title;
        Category := GuidedExperienceItem.Keywords;
        HelpUrl := GuidedExperienceItem."Help URL";
        VideoUrl := GuidedExperienceItem."Video URL";
        ReleaseVersion := NewReleaseVersion;
        Overview := NewOverview;
        GettingStarted := NewGettingStarted;
        HasHelpUrl := HelpUrl <> '';
        HasVideoUrl := VideoUrl <> '';
        HasGettingStarted := GettingStarted <> '';
    end;

    var
        FeatureName: Text;
        Category: Text;
        HelpUrl: Text;
        VideoUrl: Text;
        ReleaseVersion: Text;
        Overview: Text;
        GettingStarted: Text;
        HasHelpUrl: Boolean;
        HasVideoUrl: Boolean;
        HasGettingStarted: Boolean;
        EarlyAccessPreviewFeatureAreaTok: Label 'EarlyAccessPreview', Locked = true;
        EarlyAccessPreviewFeatureAreaDisplayNameTok: Label 'Early Access Preview', Locked = true;
}
