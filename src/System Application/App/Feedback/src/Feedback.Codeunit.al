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

    /// <summary>
    /// Starts or stops a survey timer activity. This is used to start a timer to count up user usage
    /// times, which can then trigger a survey prompt after a certain threshold is reached.
    /// </summary>
    /// <param name="ActivityName">The name of the activity for which the timer is started or stopped.</param>
    /// <param name="Start">If true, starts the timer; if false, stops the timer.</param>
    procedure SurveyTimerActivity(ActivityName: Text[255]; Start: Boolean)
    var
        ALFeedback: DotNet ALFeedback;
    begin
        ALFeedback.SurveyTimerActivity(ActivityName, Start);
    end;

    /// <summary>
    /// Sends a one-time trigger event based on a specific activity name.
    /// The event could be, for example, a user clicking a button
    /// </summary>
    /// <param name="ActivityName">The name of the activity that triggers the survey.</param>
    procedure SurveyTriggerActivity(ActivityName: Text[255])
    var
        ALFeedback: DotNet ALFeedback;
    begin
        ALFeedback.SurveyTriggerActivity(ActivityName);
    end;
}