// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

/// <summary>
/// Codeunit for providing user feedback.
/// </summary>
codeunit 1599 Feedback
{
    local procedure GetDotnetFeedbackType(FeedbackType: Enum "Feedback Type"): Integer
    var
        DotnetFeedbackType: Integer;
    begin
        case FeedbackType of
            FeedbackType::"General Feedback":
                DotnetFeedbackType := 0;
            FeedbackType::"Copilot Feedback":
                DotnetFeedbackType := 1;
        end;
        exit(DotnetFeedbackType);
    end;

    /// <summary>
    /// Enables thumbs up/down feedback for a specific page.
    /// </summary>
    /// <param name="PageID">The ID of the page to enable feedback for.</param>
    /// <param name="FeatureName">The name of the feature being evaluated.</param>
    /// <param name="FeedbackType">The type of feedback to enable.</param>
    /// <param name="FeatureArea">An optional sub-area for the feedback. Use empty string to keep feedback in main area.</param>
    procedure EnablePageFeedback(PageID: Integer; FeatureName: Text[255]; FeedbackType: Enum "Feedback Type"; FeatureArea: Text[255])
    var
        ALFeedback: DotNet ALFeedback;
        DotnetFeedbackType: Integer;
    begin
        DotnetFeedbackType := GetDotnetFeedbackType(FeedbackType);
        ALFeedback.EnablePageFeedback(PageID, FeatureName, DotnetFeedbackType, FeatureArea);
    end;

    /// <summary>
    /// Disables thumbs up/down feedback for a specific page.
    /// </summary>
    /// <param name="PageID">The ID of the page to disable feedback for.</param>
    procedure DisablePageFeedback(PageID: Integer)
    var
        ALFeedback: DotNet ALFeedback;
        DotnetFeedbackType: Integer;
    begin
        ALFeedback.DisablePageFeedback(PageID);
    end;

    /// <summary>
    /// Requests general feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which feedback is requested.</param>
    /// <param name="IsCopilotFeature">Specifies if the feature is a Copilot feature.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature.</param>
    procedure RequestFeedback(FeatureName: Text[255]; IsCopilotFeature: Boolean; FeatureArea: Text[255])
    var
        ALFeedback: DotNet ALFeedback;
    begin
        ALFeedback.RequestFeedback(FeatureName, IsCopilotFeature, FeatureArea);
    end;

    /// <summary>
    /// Requests a 'like' (positive) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which like feedback is requested.</param>
    /// <param name="IsCopilotFeature">Specifies if the feature is a Copilot feature.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature.</param>
    procedure RequestLikeFeedback(FeatureName: Text[255]; IsCopilotFeature: Boolean; FeatureArea: Text[255])
    var
        ALFeedback: DotNet ALFeedback;
    begin
        ALFeedback.RequestLikeFeedback(FeatureName, IsCopilotFeature, FeatureArea);
    end;

    /// <summary>
    /// Requests a 'dislike' (negative) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which dislike feedback is requested.</param>
    /// <param name="IsCopilotFeature">Specifies if the feature is a Copilot feature.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature.</param>
    procedure RequestDislikeFeedback(FeatureName: Text[255]; IsCopilotFeature: Boolean; FeatureArea: Text[255])
    var
        ALFeedback: DotNet ALFeedback;
    begin
        ALFeedback.RequestDislikeFeedback(FeatureName, IsCopilotFeature, FeatureArea);
    end;
}