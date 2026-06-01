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
    ApplicationArea = All;
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Early Access, Preview, New Features, What''s New, Release';
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
            usercontrol(BannerImage; EarlyAccessPreviewBanner)
            {
                ApplicationArea = All;
            }
            repeater(Features)
            {
                field("Feature Name"; Rec.Title)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the name of the new feature.';
                    Caption = 'Feature';

                    trigger OnDrillDown()
                    begin
                        if Rec."Help URL" = '' then
                            exit;
                        Hyperlink(Rec."Help URL");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a description of the new feature.';

                    trigger OnDrillDown()
                    begin
                        Message(Rec.Description);
                    end;
                }
                field(Category; Rec.Keywords)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the category of the new feature.';
                }
                field("Help URL"; Rec."Help URL")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL to the help documentation for this feature.';
                    Visible = false;
                }
                field("Video URL"; VideoFieldText)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the URL to a video demonstrating this feature.';
                    Caption = 'Video';
                    Enabled = HasVideoUrl;

                    trigger OnDrillDown()
                    begin
                        if Rec."Video URL" = '' then
                            exit;
                        Hyperlink(Rec."Video URL")
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
                    Feedback.RequestFeedback(Rec.Title);
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
                    if Rec."Help URL" = '' then
                        exit;
                    Hyperlink(Rec."Help URL");
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
                    if Rec."Video URL" = '' then
                        exit;
                    Hyperlink(Rec."Video URL")
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
            actionref(ProvideFeedback_Promoted; ProvideFeedback)
            {
            }
        }
    }

    trigger OnOpenPage()
    var
        EarlyAccessPreviewMgt: Codeunit "Early Access Preview Mgt.";
    begin
        EarlyAccessPreviewMgt.LoadNewFeatures(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        HasVideoUrl := Rec."Video URL" <> '';
        HasHelpUrl := Rec."Help URL" <> '';
        UpdateFieldText();
    end;

    trigger OnAfterGetRecord()
    begin
        UpdateFieldText();
    end;

    local procedure UpdateFieldText()
    begin
        if Rec."Video URL" <> '' then
            VideoFieldText := WatchVideoLbl
        else
            VideoFieldText := '';
    end;

    var
        HasVideoUrl: Boolean;
        HasHelpUrl: Boolean;
        VideoFieldText: Text;
        WatchVideoLbl: Label 'Watch Video';
}

