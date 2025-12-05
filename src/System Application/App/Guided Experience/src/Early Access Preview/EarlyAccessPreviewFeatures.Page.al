// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Feedback;

page 1965 "Early Access Preview Features"
{
    PageType = List;
    SourceTable = "Guided Experience Item";
    SourceTableTemporary = true;
    Caption = 'Early Access Preview: New Features';
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            usercontrol(BannerImage; BannerPicture)
            {
                ApplicationArea = All;
            }
            repeater(Features)
            {
                field("Feature Name"; Rec."Short Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the new feature.', Locked = false;

                    trigger OnDrillDown()
                    begin
                        if Rec."Help URL" <> '' then
                            Hyperlink(Rec."Help URL");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the new feature.', Locked = false;
                }
                field("Help URL"; Rec."Help URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL to the help documentation for this feature.', Locked = false;
                    Visible = false;
                }
                field("Video URL"; WatchVideoLbl)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL to a video demonstrating this feature.', Locked = false;
                    Caption = 'Video';

                    trigger OnDrillDown()
                    begin
                        if Rec."Video URL" <> '' then
                            Hyperlink(Rec."Video URL")
                        else
                            Message(NoVideoAvailableMsg);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProvideFeedback)
            {
                ApplicationArea = All;
                Caption = 'Provide Release Feedback';
                ToolTip = 'Provide general feedback on this early access preview release.';
                Image = Questionnaire;

                trigger OnAction()
                var
                    Feedback: Codeunit "Microsoft User Feedback";
                begin
                    Feedback.RequestFeedback('Early Access Preview');
                end;
            }
            action(ProvideFeatureFeedback)
            {
                ApplicationArea = All;
                Caption = 'Provide Feature Feedback';
                ToolTip = 'Provide feedback on the currently selected feature.';
                Image = Comment;

                trigger OnAction()
                var
                    Feedback: Codeunit "Microsoft User Feedback";
                begin
                    Feedback.RequestFeedback(Rec."Short Title");
                end;
            }
            action(ViewHelp)
            {
                ApplicationArea = All;
                Caption = 'View Help';
                ToolTip = 'Open the help documentation for this feature.', Locked = false;
                Image = Help;

                trigger OnAction()
                begin
                    if Rec."Help URL" <> '' then
                        Hyperlink(Rec."Help URL")
                    else
                        Message(NoHelpAvailableMsg);
                end;
            }
            action(WatchVideo)
            {
                ApplicationArea = All;
                Caption = 'Watch Video';
                ToolTip = 'Watch a video demonstrating this feature.', Locked = false;
                Image = Picture;

                trigger OnAction()
                begin
                    if Rec."Video URL" <> '' then
                        Hyperlink(Rec."Video URL")
                    else
                        Message(NoVideoAvailableMsg);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
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
            group(Category_General)
            {
                Caption = 'General Product Feedback';
                actionref(ProvideFeedback_Promoted; ProvideFeedback)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        EarlyAccessPreviewMgt: Codeunit "Early Access Preview Mgt.";
    begin
        EarlyAccessPreviewMgt.LoadNewFeatures(Rec);
    end;

    var
        WatchVideoLbl: Label 'Watch Video';
        NoVideoAvailableMsg: Label 'No video is available for this feature.';
        NoHelpAvailableMsg: Label 'No help is available for this feature.';
}

#pragma warning disable AA0215
controladdin BannerPicture
{
    Images = 'Resources/EarlyAccessPreview/EAPBanner.png';
    VerticalStretch = false;
    HorizontalStretch = true;
    RequestedHeight = 150;
    StartupScript = 'startup.js';
}
#pragma warning restore AA0215
