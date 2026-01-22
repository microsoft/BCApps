// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Feedback;

/// <summary>
/// Codeunit for providing feedback to Microsoft. To be used by internal Microsoft apps only.
/// </summary>
codeunit 1590 "Microsoft User Feedback"
{
    Access = Public;
    InherentPermissions = X;
    InherentEntitlements = X;

    /// <summary>
    /// Requests general feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which feedback is requested.</param>
    procedure RequestFeedback(FeatureName: Text)
    var
        CallerModuleInfo: ModuleInfo;
        EmptyContextFiles: Dictionary of [Text, Text];
        EmptyContextProperties: Dictionary of [Text, Text];
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestFeedback(FeatureName, '', '', EmptyContextFiles, EmptyContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests general feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature. ID on OCV.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    procedure RequestFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text)
    var
        CallerModuleInfo: ModuleInfo;
        EmptyContextFiles: Dictionary of [Text, Text];
        EmptyContextProperties: Dictionary of [Text, Text];
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, EmptyContextFiles, EmptyContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests general feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature. ID on OCV.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    /// <param name="ContextFiles">Map of filename to base64 file to attach to the feedback. Must contain the filename in the extension.</param>
    /// <param name="ContextProperties">Additional data to pass properties to the feedback mechanism.</param>
    procedure RequestFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text])
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, ContextFiles, ContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests a 'like' (positive) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which like feedback is requested.</param>
    procedure RequestLikeFeedback(FeatureName: Text)
    var
        CallerModuleInfo: ModuleInfo;
        EmptyContextFiles: Dictionary of [Text, Text];
        EmptyContextProperties: Dictionary of [Text, Text];
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestLikeFeedback(FeatureName, '', '', EmptyContextFiles, EmptyContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests a 'like' (positive) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which like feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature. ID on OCV.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    procedure RequestLikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text)
    var
        CallerModuleInfo: ModuleInfo;
        EmptyContextFiles: Dictionary of [Text, Text];
        EmptyContextProperties: Dictionary of [Text, Text];
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestLikeFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, EmptyContextFiles, EmptyContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests a 'like' (positive) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which like feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature.</param>
    /// <param name="ContextFiles">Map of filename to base64 file to attach to the feedback. Must contain the filename in the extension.</param>
    /// <param name="ContextProperties">Additional data to pass properties to the feedback mechanism.</param>
    procedure RequestLikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text])
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestLikeFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, ContextFiles, ContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests a 'dislike' (negative) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which dislike feedback is requested.</param>
    procedure RequestDislikeFeedback(FeatureName: Text)
    var
        CallerModuleInfo: ModuleInfo;
        EmptyContextFiles: Dictionary of [Text, Text];
        EmptyContextProperties: Dictionary of [Text, Text];
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestDislikeFeedback(FeatureName, '', '', EmptyContextFiles, EmptyContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests a 'dislike' (negative) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which dislike feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature. ID of the sub-area on OCV.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    procedure RequestDislikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text)
    var
        CallerModuleInfo: ModuleInfo;
        EmptyContextFiles: Dictionary of [Text, Text];
        EmptyContextProperties: Dictionary of [Text, Text];
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestDislikeFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, EmptyContextFiles, EmptyContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Requests a 'dislike' (negative) feedback for a feature, optionally specifying if it is a Copilot feature and its area.
    /// </summary>
    /// <param name="FeatureName">The name of the feature for which dislike feedback is requested.</param>
    /// <param name="FeatureArea">The area or sub-area of the feature. ID of the sub-area on OCV.</param>
    /// <param name="FeatureAreaDisplayName">The display name of the feature area.</param>
    /// <param name="ContextFiles">Map of filename to base64 file to attach to the feedback. Must contain the filename in the extension.</param>
    /// <param name="ContextProperties">Additional data to pass properties to the feedback mechanism.</param>
    procedure RequestDislikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text])
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.RequestDislikeFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, ContextFiles, ContextProperties, CallerModuleInfo);
    end;

    /// <summary>
    /// Sets whether the General/Like/Dislike feedback being collected is for an AI feature.
    /// </summary>
    /// <param name="IsAIFeedback">True if the feedback is for an AI feature; otherwise, false.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure SetIsAIFeedback(IsAIFeedback: Boolean): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.SetIsAIFeedback(IsAIFeedback);
        exit(this);
    end;

    /// <summary>
    /// Sets a custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="Question">The text of the custom question.</param>
    /// <param name="QuestionDisplay">The display text of the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestion(Question: Text; QuestionDisplay: Text): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.WithCustomQuestion(Question, QuestionDisplay);
        exit(this);
    end;

    /// <summary>
    /// Sets the type of the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="QuestionType">The type of the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionType(QuestionType: Enum FeedbackQuestionType): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.WithCustomQuestionType(QuestionType);
        exit(this);
    end;

    /// <summary>
    /// Sets the required behavior for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="RequiredBehavior">The behaviour.</param>
    /// <param name="Enabled">If true, enables the specified required behavior; if false, disables it.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionRequiredBehavior(RequiredBehavior: Enum FeedbackRequiredBehavior; Enabled: Boolean): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.WithCustomQuestionRequiredBehavior(RequiredBehavior, Enabled);
        exit(this);
    end;

    /// <summary>
    /// Sets the required behavior for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="RequiredBehavior">A dictionary defining the required behavior for the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionRequiredBehavior(RequiredBehavior: Dictionary of [Enum FeedbackRequiredBehavior, Text]): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.WithCustomQuestionRequiredBehavior(RequiredBehavior);
        exit(this);
    end;

    /// <summary>
    /// Adds an answer option for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="AnswerOption">The answer option.</param>
    /// <param name="AnswerDisplayText">The display text for the answer option.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionAnswerOption(AnswerOption: Text; AnswerDisplayText: Text): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.WithCustomQuestionAnswerOption(AnswerOption, AnswerDisplayText);
        exit(this);
    end;

    /// <summary>
    /// Sets the answer options for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="AnswerOptions">A dictionary defining the answer options for the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionAnswerOptions(AnswerOptions: Dictionary of [Text, Text]): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.WithCustomQuestionAnswerOptions(AnswerOptions);
        exit(this);
    end;

    /// <summary>
    /// Clears any previously set custom question.
    /// </summary>
    /// <returns>The current instance of the "Microsoft User Feedback" codeunit.</returns>
    procedure ClearCustomQuestion(): Codeunit "Microsoft User Feedback"
    begin
        this.FeedbackImpl := this.FeedbackImpl.ClearCustomQuestion();
        exit(this);
    end;

    /// <summary>
    /// Starts or stops a survey timer activity. This is used to start a timer to count up user usage
    /// times, which can then trigger a survey prompt after a certain threshold is reached.
    /// </summary>
    /// <param name="ActivityName">The name of the activity for which the timer is started or stopped.</param>
    /// <param name="Start">If true, starts the timer; if false, stops the timer.</param>
    procedure SurveyTimerActivity(ActivityName: Text; Start: Boolean)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.SurveyTimerActivity(ActivityName, Start, CallerModuleInfo);
    end;

    /// <summary>
    /// Sends a one-time trigger event based on a specific activity name.
    /// The event could be, for example, a user clicking a button
    /// </summary>
    /// <param name="ActivityName">The name of the activity that triggers the survey.</param>
    procedure SurveyTriggerActivity(ActivityName: Text)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        this.FeedbackImpl.SurveyTriggerActivity(ActivityName, CallerModuleInfo);
    end;

    var
        FeedbackImpl: Codeunit "Microsoft User Feedback Impl";
}