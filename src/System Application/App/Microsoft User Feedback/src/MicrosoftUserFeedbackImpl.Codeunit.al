// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

/// <summary>
/// Implementation codeunit for providing feedback to Microsoft. To be used by internal Microsoft apps only.
/// </summary>
codeunit 1589 "Microsoft User Feedback Impl"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>
    /// Requests general feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature. ID on OCV.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    /// <param name="ContextFiles">Map of filename to base64 file to attach to the feedback. Must contain the filename in the extension.</param>
    /// <param name="ContextProperties">Additional data to pass properties to the feedback mechanism.</param>
    /// <param name="CallerModuleInfo">Information about the module making the request.</param>
    procedure RequestFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    begin
        this.CheckFeedbackCollectionAllowed(CallerModuleInfo);

        if (this.IsAIFeedback) then
            ContextProperties.Add('IsAIFeature', 'true');

        Feedback.RequestFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, ContextFiles, ContextProperties);
    end;

    /// <summary>
    /// Requests a 'like' (positive) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which like feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    /// <param name="ContextFiles">Map of filename to base64 file to attach to the feedback. Must contain the filename in the extension.</param>
    /// <param name="ContextProperties">Additional data to pass properties to the feedback mechanism.</param>
    /// <param name="CallerModuleInfo">Information about the module making the request.</param>
    procedure RequestLikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    begin
        this.CheckFeedbackCollectionAllowed(CallerModuleInfo);

        if (this.IsAIFeedback) then
            ContextProperties.Add('IsAIFeature', 'true');

        Feedback.RequestLikeFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, ContextFiles, ContextProperties);
    end;

    /// <summary>
    /// Requests a 'dislike' (negative) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which dislike feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature. ID of the sub-area on OCV.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    /// <param name="ContextFiles">Map of filename to base64 file to attach to the feedback. Must contain the filename in the extension.</param>
    /// <param name="ContextProperties">Additional data to pass properties to the feedback mechanism.</param>
    /// <param name="CallerModuleInfo">Information about the module making the request.</param>
    procedure RequestDislikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextProperties: Dictionary of [Text, Text]; ContextFiles: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    begin
        this.CheckFeedbackCollectionAllowed(CallerModuleInfo);

        if (this.IsAIFeedback) then
            ContextProperties.Add('IsAIFeature', 'true');

        Feedback.RequestDislikeFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, ContextProperties, ContextFiles);
    end;

    /// <summary>
    /// Sets whether the General/Like/Dislike feedback being collected is for an AI feature.
    /// </summary>
    /// <param name="AIFeedback">True if the feedback is for an AI feature; otherwise, false.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure SetIsAIFeedback(AIFeedback: Boolean): Codeunit "Microsoft User Feedback Impl"
    begin
        this.IsAIFeedback := AIFeedback;
        exit(this);
    end;

    /// <summary>
    /// Starts or stops a survey timer activity. This is used to start a timer to count up user usage
    /// times, which can then trigger a survey prompt after a certain threshold is reached.
    /// </summary>
    /// <param name="ActivityName">The name of the activity for which the timer is started or stopped.</param>
    /// <param name="Start">If true, starts the timer; if false, stops the timer.</param>
    /// <param name="CallerModuleInfo">Information about the module making the request.</param>
    procedure SurveyTimerActivity(ActivityName: Text; Start: Boolean; CallerModuleInfo: ModuleInfo)
    begin
        this.CheckFeedbackCollectionAllowed(CallerModuleInfo);
        Feedback.SurveyTimerActivity(ActivityName, Start);
    end;

    /// <summary>
    /// Sends a one-time trigger event based on a specific activity name.
    /// The event could be, for example, a user clicking a button
    /// </summary>
    /// <param name="ActivityName">The name of the activity that triggers the survey.</param>
    /// <param name="CallerModuleInfo">Information about the module making the request.</param>
    procedure SurveyTriggerActivity(ActivityName: Text; CallerModuleInfo: ModuleInfo)
    begin
        this.CheckFeedbackCollectionAllowed(CallerModuleInfo);
        Feedback.SurveyTriggerActivity(ActivityName);
    end;

    local procedure CheckFeedbackCollectionAllowed(CallerModuleInfo: ModuleInfo)
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);

        if CallerModuleInfo.Publisher() <> CurrentModuleInfo.Publisher() then
            Error(this.OnlyMicrosoftAllowedErr, CurrentModuleInfo.Publisher())
    end;

    var
        Feedback: Codeunit Feedback;
        IsAIFeedback: Boolean;
        OnlyMicrosoftAllowedErr: Label 'Only the publisher %1 can collect feedback using this mechanism.', Comment = '%1 is the publisher of the module allowed to use this module.';
}