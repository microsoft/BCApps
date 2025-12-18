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
            Feedback.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, this.QuestionType, this.RequiredBehaviorDictionary, this.Options);

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
            Feedback.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, this.QuestionType, this.RequiredBehaviorDictionary, this.Options);

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
    procedure RequestDislikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text]; CallerModuleInfo: ModuleInfo)
    begin
        this.CheckFeedbackCollectionAllowed(CallerModuleInfo);

        if (this.IsAIFeedback) then
            ContextProperties.Add('IsAIFeature', 'true');

        if (this.CustomQuestionSet) then
            Feedback.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, this.QuestionType, this.RequiredBehaviorDictionary, this.Options);

        Feedback.RequestDislikeFeedback(FeatureName, FeatureArea, FeatureAreaDisplayName, ContextFiles, ContextProperties);
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
        this.SetCustomQuestion(Question, QuestionDisplay, this.QuestionType, this.RequiredBehaviorDictionary, this.Options);

        exit(this);
    end;

    /// <summary>
    /// Sets the type of the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="Type">The type of the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionType(Type: Enum FeedbackQuestionType): Codeunit "Microsoft User Feedback Impl"
    begin
        this.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, Type, this.RequiredBehaviorDictionary, this.Options);
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
        if (this.RequiredBehaviorDictionary.ContainsKey(RequiredBehavior)) then
            this.RequiredBehaviorDictionary.Remove(RequiredBehavior);

        if (Enabled) then
            this.RequiredBehaviorDictionary.Add(RequiredBehavior, 'true');

        this.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, this.QuestionType, this.RequiredBehaviorDictionary, this.Options);
        exit(this);
    end;

    /// <summary>
    /// Sets the required behavior for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="RequiredBehavior">A dictionary defining the required behavior for the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionRequiredBehavior(RequiredBehavior: Dictionary of [Enum FeedbackRequiredBehavior, Text]): Codeunit "Microsoft User Feedback Impl"
    begin
        this.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, this.QuestionType, RequiredBehavior, this.Options);
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
        this.Options.Add(AnswerOption, AnswerDisplayText);
        this.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, this.QuestionType, this.RequiredBehaviorDictionary, this.Options);
        exit(this);
    end;

    /// <summary>
    /// Sets the answer options for the custom question to be included in the feedback prompt.
    /// </summary>
    /// <param name="AnswerOptions">A dictionary defining the answer options for the custom question.</param>
    /// <returns>The current instance of the "Microsoft User Feedback Impl" codeunit.</returns>
    procedure WithCustomQuestionAnswerOptions(AnswerOptions: Dictionary of [Text, Text]): Codeunit "Microsoft User Feedback Impl"
    begin
        this.SetCustomQuestion(this.QuestionText, this.QuestionDisplayText, this.QuestionType, this.RequiredBehaviorDictionary, AnswerOptions);
        exit(this);
    end;

    local procedure SetCustomQuestion(Question: Text; QuestionDisplay: Text; Type: Enum FeedbackQuestionType; RequiredBehavior: Dictionary of [Enum FeedbackRequiredBehavior, Text]; AnswerOptions: Dictionary of [Text, Text]): Codeunit "Microsoft User Feedback Impl"
    begin
        this.QuestionText := Question;
        this.QuestionDisplayText := QuestionDisplay;
        this.QuestionType := Type;
        this.RequiredBehaviorDictionary := RequiredBehavior;
        this.Options := AnswerOptions;
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
        this.QuestionText := '';
        this.QuestionDisplayText := '';
        this.QuestionType := FeedbackQuestionType::Text;

        foreach RequiredBehaviorKey in this.RequiredBehaviorDictionary.Keys do
            this.RequiredBehaviorDictionary.Remove(RequiredBehaviorKey);

        foreach AnswerOptionKey in this.Options.Keys do
            this.Options.Remove(AnswerOptionKey);

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
        QuestionText: Text;
        QuestionDisplayText: Text;
        QuestionType: Enum FeedbackQuestionType;
        RequiredBehaviorDictionary: Dictionary of [Enum FeedbackRequiredBehavior, Text];
        Options: Dictionary of [Text, Text];
        OnlyMicrosoftAllowedErr: Label 'Only the publisher %1 can collect feedback using this mechanism.', Comment = '%1 is the publisher of the module allowed to use this module.';
}