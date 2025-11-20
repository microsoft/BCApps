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

        if (this.CustomQuestionSet) then
            Feedback.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, this._QuestionType, this._RequiredBehavior, this._Options);

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

        if (this.CustomQuestionSet) then
            Feedback.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, this._QuestionType, this._RequiredBehavior, this._Options);

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

        if (this.CustomQuestionSet) then
            Feedback.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, this._QuestionType, this._RequiredBehavior, this._Options);

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
    /// Sets a custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="Question">The text of the custom question.</param>
    /// <param name="QuestionDisplay">The display text of the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestion(Question: Text; QuestionDisplay: Text): Codeunit "Microsoft User Feedback Impl"
    begin
        this.SetCustomQuestion(Question, QuestionDisplay, this._QuestionType, this._RequiredBehavior, this._Options);

        exit(this);
    end;

    /// <summary>
    /// Sets the type of the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="QuestionType">The type of the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionType(QuestionType: Enum FeedbackQuestionType): Codeunit "Microsoft User Feedback Impl"
    begin
        this.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, QuestionType, this._RequiredBehavior, this._Options);
        exit(this);
    end;

    /// <summary>
    /// Sets the required behavior for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="RequiredBehavior">The behaviour.</param>
    /// <param name="Enabled">If true, enables the specified required behavior; if false, disables it.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionRequiredBehavior(RequiredBehavior: Enum FeedbackRequiredBehavior; Enabled: Boolean): Codeunit "Microsoft User Feedback Impl"
    begin
        if (this._RequiredBehavior.ContainsKey(RequiredBehavior)) then
            this._RequiredBehavior.Remove(RequiredBehavior);

        if (Enabled) then
            this._RequiredBehavior.Add(RequiredBehavior, 'true');

        this.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, this._QuestionType, this._RequiredBehavior, this._Options);
        exit(this);
    end;

    /// <summary>
    /// Sets the required behavior for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="RequiredBehavior">A dictionary defining the required behavior for the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionRequiredBehavior(RequiredBehavior: Dictionary of [Enum FeedbackRequiredBehavior, Text]): Codeunit "Microsoft User Feedback Impl"
    begin
        this.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, this._QuestionType, RequiredBehavior, this._Options);
        exit(this);
    end;

    /// <summary>
    /// Adds an answer option for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="AnswerOption">The answer option.</param>
    /// <param name="AnswerDisplayText">The display text for the answer option.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionAnswerOption(AnswerOption: Text; AnswerDisplayText: Text): Codeunit "Microsoft User Feedback Impl"
    begin
        this._Options.Add(AnswerOption, AnswerDisplayText);
        this.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, this._QuestionType, this._RequiredBehavior, this._Options);
        exit(this);
    end;

    /// <summary>
    /// Sets the answer options for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="AnswerOptions">A dictionary defining the answer options for the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionAnswerOptions(AnswerOptions: Dictionary of [Text, Text]): Codeunit "Microsoft User Feedback Impl"
    begin
        this.SetCustomQuestion(this._QuestionText, this._QuestionDisplayText, this._QuestionType, this._RequiredBehavior, AnswerOptions);
        exit(this);
    end;

    local procedure SetCustomQuestion(Question: Text; QuestionDisplay: Text; QuestionType: Enum FeedbackQuestionType; RequiredBehavior: Dictionary of [Enum FeedbackRequiredBehavior, Text]; AnswerOptions: Dictionary of [Text, Text]): Codeunit "Microsoft User Feedback Impl"
    begin
        this._QuestionText := Question;
        this._QuestionDisplayText := QuestionDisplay;
        this._QuestionType := QuestionType;
        this._RequiredBehavior := RequiredBehavior;
        this._Options := AnswerOptions;
        this.CustomQuestionSet := true;

        exit(this);
    end;

    /// <summary>
    /// Clears any previously set custom question.
    /// </summary>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure ClearCustomQuestion(): Codeunit "Microsoft User Feedback Impl"
    var
        RequiredBehaviorKey: Enum FeedbackRequiredBehavior;
        AnswerOptionKey: Text;
    begin
        Feedback.ClearCustomQuestion();
        this.CustomQuestionSet := false;
        this._QuestionText := '';
        this._QuestionDisplayText := '';
        this._QuestionType := FeedbackQuestionType::Text;

        foreach RequiredBehaviorKey in this._RequiredBehavior.Keys do
            this._RequiredBehavior.Remove(RequiredBehaviorKey);

        foreach AnswerOptionKey in this._Options.Keys do
            this._Options.Remove(AnswerOptionKey);

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
        CustomQuestionSet: Boolean;
        _QuestionText: Text;
        _QuestionDisplayText: Text;
        _QuestionType: Enum FeedbackQuestionType;
        _RequiredBehavior: Dictionary of [Enum FeedbackRequiredBehavior, Text];
        _Options: Dictionary of [Text, Text];
        OnlyMicrosoftAllowedErr: Label 'Only the publisher %1 can collect feedback using this mechanism.', Comment = '%1 is the publisher of the module allowed to use this module.';
}