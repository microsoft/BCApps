# Microsoft User Feedback Module

The Microsoft User Feedback module provides APIs for collecting user feedback and managing surveys within Business Central applications. This module is part of the System Application and enables developers to gather valuable user input for feature improvement and user experience optimization.

## Module Information
- **ID**: f7964d32-7685-400f-8297-4bc17d0aab0e
- **Name**: Microsoft User Feedback
- **Publisher**: Microsoft  
- **Version**: 28.0.0.0
- **Namespace**: `System.Microsoft.UserFeedback`
- **Codeunit**: `Microsoft User Feedback` (ID: 1600)

## Overview
The Microsoft User Feedback module provides comprehensive procedures to:
- Request general, positive (like), and negative (dislike) feedback for features
- Support both regular features and AI-powered features
- Track user activity with timer-based and trigger-based survey mechanisms
- Include contextual data with feedback requests
- Enable targeted feedback collection for specific feature areas

**Note**: This module is designed for use by internal Microsoft apps only.

## API Reference

---

### RequestFeedback
Requests general feedback for a feature, optionally specifying its area and context.

**Signatures:**
```al
procedure RequestFeedback(FeatureName: Text)
procedure RequestFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text)
procedure RequestFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text])
```

**Parameters:**
- `FeatureName`: The name of the feature for which feedback is requested.
- `FeatureArea` (optional): The area or sub-area of the feature. ID on OCV.
- `FeatureAreaDisplayName` (optional): The display name of the feature area.
- `ContextFiles` (optional): Map of filename to base64-encoded file content to attach to the feedback. The key must contain the filename with extension.
- `ContextProperties` (optional): Additional properties to pass to the feedback mechanism as key-value pairs.

---

### RequestLikeFeedback
Requests a 'like' (positive) feedback for a feature, optionally specifying its area and context.

**Signatures:**
```al
procedure RequestLikeFeedback(FeatureName: Text)
procedure RequestLikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text)
procedure RequestLikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextFiles: Dictionary of [Text, Text]; ContextProperties: Dictionary of [Text, Text])
```

**Parameters:**
- `FeatureName`: The name of the feature for which like feedback is requested.
- `FeatureArea` (optional): The area or sub-area of the feature. ID on OCV.
- `FeatureAreaDisplayName` (optional): The display name of the feature area.
- `ContextFiles` (optional): Map of filename to base64-encoded file content to attach to the feedback. The key must contain the filename with extension.
- `ContextProperties` (optional): Additional properties to pass to the feedback mechanism as key-value pairs.

---

### RequestDislikeFeedback
Requests a 'dislike' (negative) feedback for a feature, optionally specifying its area and context.

**Signatures:**
```al
procedure RequestDislikeFeedback(FeatureName: Text)
procedure RequestDislikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text)
procedure RequestDislikeFeedback(FeatureName: Text; FeatureArea: Text; FeatureAreaDisplayName: Text; ContextProperties: Dictionary of [Text, Text]; ContextFiles: Dictionary of [Text, Text])
```

**Parameters:**
- `FeatureName`: The name of the feature for which dislike feedback is requested.
- `FeatureArea` (optional): The area or sub-area of the feature. ID of the sub-area on OCV.
- `FeatureAreaDisplayName` (optional): The display name of the feature area.
- `ContextProperties` (optional): Additional properties to pass to the feedback mechanism as key-value pairs.
- `ContextFiles` (optional): Map of filename to base64-encoded file content to attach to the feedback. The key must contain the filename with extension.

---

### SetIsAIFeedback
Sets whether the feedback being collected is for an AI feature. This method supports fluent API usage by returning the codeunit instance.

**Signature:**
```al
procedure SetIsAIFeedback(IsAIFeedback: Boolean): Codeunit "Microsoft User Feedback"
```

**Parameters:**
- `IsAIFeedback`: True if the feedback is for an AI feature; otherwise, false.

**Returns:**
- The current instance of the "Microsoft User Feedback" codeunit for method chaining.

**Example Usage:**
```al
// For AI features using fluent API
MicrosoftUserFeedback.SetIsAIFeedback(true).RequestFeedback('AI Assistant');

// For regular features
MicrosoftUserFeedback.SetIsAIFeedback(false).RequestLikeFeedback('Data Export', 'EXPORT_001', 'Data Export');
```

---

### WithCustomQuestion
Sets a custom question to be included in the feedback prompt. This method supports fluent API usage by returning the codeunit instance.

**Signature:**
```al
procedure WithCustomQuestion(Question: Text; QuestionDisplay: Text): Codeunit "Microsoft User Feedback"
```

**Parameters:**
- `Question`: The text of the custom question displayed on the feedback portal.
- `QuestionDisplay`: The display text of the custom question displayed on the UI.

**Returns:**
- The current instance of the "Microsoft User Feedback" codeunit for method chaining.

**Example Usage:**
```al
MicrosoftUserFeedback
    .WithCustomQuestion('ease_of_use', 'How easy was this feature to use?')
    .RequestFeedback('MyFeature');
```

---

### WithCustomQuestionType
Sets the type of the custom question to be included in the feedback prompt. This method supports fluent API usage by returning the codeunit instance.

**Signature:**
```al
procedure WithCustomQuestionType(QuestionType: Enum FeedbackQuestionType): Codeunit "Microsoft User Feedback"
```

**Parameters:**
- `QuestionType`: The type of the custom question.

**Returns:**
- The current instance of the "Microsoft User Feedback" codeunit for method chaining.

**Example Usage:**
```al
MicrosoftUserFeedback
    .WithCustomQuestion('rating', 'How would you rate this feature?')
    .WithCustomQuestionType(FeedbackQuestionType::SingleChoice)
    .RequestFeedback('MyFeature');
```

---

### WithCustomQuestionRequiredBehavior
Sets the required behavior for the custom question to be included in the feedback prompt. This method supports fluent API usage by returning the codeunit instance. Available in two overloads.

**Signatures:**
```al
procedure WithCustomQuestionRequiredBehavior(RequiredBehavior: Enum FeedbackRequiredBehavior; Enabled: Boolean): Codeunit "Microsoft User Feedback"
procedure WithCustomQuestionRequiredBehavior(RequiredBehavior: Dictionary of [Enum FeedbackRequiredBehavior, Text]): Codeunit "Microsoft User Feedback"
```

**Parameters:**
- `RequiredBehavior`: The behaviour (single overload) or a dictionary defining the required behavior for the custom question (dictionary overload).
- `Enabled`: If true, enables the specified required behavior; if false, disables it (single overload only).

**Returns:**
- The current instance of the "Microsoft User Feedback" codeunit for method chaining.

**Example Usage:**
```al
// Single behavior
MicrosoftUserFeedback
    .WithCustomQuestion('feedback', 'Please provide your feedback')
    .WithCustomQuestionRequiredBehavior(FeedbackRequiredBehavior::QuestionNotRequired, true)
    .RequestFeedback('MyFeature');

// Multiple behaviors using dictionary
var
    RequiredBehaviors: Dictionary of [Enum FeedbackRequiredBehavior, Text];
begin
    RequiredBehaviors.Add(FeedbackRequiredBehavior::QuestionNotRequired, 'true');
    MicrosoftUserFeedback
        .WithCustomQuestion('feedback', 'Please provide your feedback')
        .WithCustomQuestionRequiredBehavior(RequiredBehaviors)
        .RequestFeedback('MyFeature');
end;
```

---

### WithCustomQuestionAnswerOption
Adds an answer option for the custom question to be included in the feedback prompt. This method supports fluent API usage by returning the codeunit instance.

Supported for question types other than Text.

**Signature:**
```al
procedure WithCustomQuestionAnswerOption(AnswerOption: Text; AnswerDisplayText: Text): Codeunit "Microsoft User Feedback"
```

**Parameters:**
- `AnswerOption`: The answer option displayed in the feedback portal.
- `AnswerDisplayText`: The display text for the answer option displayed on the UI.

**Returns:**
- The current instance of the "Microsoft User Feedback" codeunit for method chaining.

**Example Usage:**
```al
MicrosoftUserFeedback
    .WithCustomQuestion('rating', 'How would you rate this?')
    .WithCustomQuestionType(FeedbackQuestionType::SingleSelect)
    .WithCustomQuestionAnswerOption('excellent', 'Excellent')
    .WithCustomQuestionAnswerOption('good', 'Good')
    .WithCustomQuestionAnswerOption('fair', 'Fair')
    .WithCustomQuestionAnswerOption('poor', 'Poor')
    .RequestFeedback('MyFeature');
```

---

### WithCustomQuestionAnswerOptions
Sets the answer options for the custom question to be included in the feedback prompt. This method supports fluent API usage by returning the codeunit instance.

**Signature:**
```al
procedure WithCustomQuestionAnswerOptions(AnswerOptions: Dictionary of [Text, Text]): Codeunit "Microsoft User Feedback"
```

**Parameters:**
- `AnswerOptions`: A dictionary defining the answer options for the custom question, where the key is the option value and the value is the display text.

**Returns:**
- The current instance of the "Microsoft User Feedback" codeunit for method chaining.

**Example Usage:**
```al
var
    AnswerOptions: Dictionary of [Text, Text];
begin
    AnswerOptions.Add('1', 'Very Dissatisfied');
    AnswerOptions.Add('2', 'Dissatisfied');
    AnswerOptions.Add('3', 'Neutral');
    AnswerOptions.Add('4', 'Satisfied');
    AnswerOptions.Add('5', 'Very Satisfied');
    
    MicrosoftUserFeedback
        .WithCustomQuestion('satisfaction', 'How satisfied are you?')
        .WithCustomQuestionType(FeedbackQuestionType::SingleChoice)
        .WithCustomQuestionAnswerOptions(AnswerOptions)
        .RequestFeedback('MyFeature');
end;
```

---

### ClearCustomQuestion
Clears any previously set custom question. This method supports fluent API usage by returning the codeunit instance.

**Signature:**
```al
procedure ClearCustomQuestion(): Codeunit "Microsoft User Feedback"
```

**Returns:**
- The current instance of the "Microsoft User Feedback" codeunit for method chaining.

**Example Usage:**
```al
// Clear custom question if needed
MicrosoftUserFeedback
    .WithCustomQuestion('rating', 'Rate this feature')
    .ClearCustomQuestion()  // Clears the custom question
    .RequestFeedback('MyFeature');  // Will not include a custom question
```

---

### SurveyTimerActivity
Starts or stops a survey timer activity. This is used to start a timer to count up user usage times, which can then trigger a survey prompt after a certain threshold is reached.

For example: 5 minutes of usage time from timer start to timer end.

**Signature:**
```al
procedure SurveyTimerActivity(ActivityName: Text; Start: Boolean)
```
**Parameters:**
- `ActivityName`: The name of the activity for which the timer is started or stopped.
- `Start`: If true, starts the timer; if false, stops the timer.

---

### SurveyTriggerActivity
Sends a one-time trigger event based on a specific activity name. The event could be, for example, a user clicking a button.

**Signature:**
```al
procedure SurveyTriggerActivity(ActivityName: Text)
```
**Parameters:**
- `ActivityName`: The name of the activity that triggers the survey.

---

## Feature Area Parameters

The feedback APIs support optional feature area identification through two related parameters:

- **`FeatureArea`**: A unique identifier for the feature area, typically used as an ID in OCV (Online Customer Voice). This should be a consistent, machine-readable identifier.
- **`FeatureAreaDisplayName`**: A human-readable display name for the feature area that will be shown to users.

**Examples:**
- `FeatureArea: 'REPORTING_001'`, `FeatureAreaDisplayName: 'Reporting & Analytics'`
- `FeatureArea: 'AI_COPILOT_001'`, `FeatureAreaDisplayName: 'AI Copilot Features'`
- `FeatureArea: 'INTEGRATION_001'`, `FeatureAreaDisplayName: 'Data Integration'`

---

## Context Data Support

The Feedback module supports passing additional contextual data with feedback requests through separate parameters:

### ContextFiles Parameter
A dictionary containing file attachments where:
- **Key**: Filename with extension (e.g., `screenshot.png`, `log.txt`)
- **Value**: Base64-encoded file content

### ContextProperties Parameter  
A dictionary containing additional properties where:
- **Key**: Property name (e.g., `UserRole`, `SessionLength`)
- **Value**: Property value (e.g., `Administrator`, `15 minutes`)

**Examples of context data:**
- User session information (role, experience level, session duration)
- Feature configuration details (settings, preferences)
- Performance metrics (response times, data volumes)
- Error logs or diagnostic information
- Screenshots, log files, or other media attachments

---

## Usage Examples

### Basic Feedback Request
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
begin
    // Simple feedback request without area specification
    MicrosoftUserFeedback.RequestFeedback('MyFeature');
    
    // Feedback with feature area and display name
    MicrosoftUserFeedback.RequestFeedback('ReportBuilder', 'REPORTING_001', 'Reporting & Analytics');
    
    // Request positive feedback for an AI feature using fluent API
    MicrosoftUserFeedback.SetIsAIFeedback(true).RequestLikeFeedback('AIAssist', 'AI_COPILOT_001', 'AI Copilot Features');
    
    // Request negative feedback for troubleshooting
    MicrosoftUserFeedback.RequestDislikeFeedback('DataSync', 'INTEGRATION_001', 'Data Integration');
end;
```

### Feedback with Context Data
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
    ContextFiles: Dictionary of [Text, Text];
    ContextProperties: Dictionary of [Text, Text];
begin
    // Add context properties
    ContextProperties.Add('UserRole', 'Administrator');
    ContextProperties.Add('SessionLength', '15 minutes');
    ContextProperties.Add('FeatureUsage', 'First time');
    
    // Request feedback with additional context
    MicrosoftUserFeedback.RequestFeedback('ReportBuilder', 'REPORTING_001', 'Reporting & Analytics', ContextFiles, ContextProperties);
    
    // Add file attachment for negative feedback
    ContextFiles.Add('screenshot.png', GetBase64EncodedScreenshot());
    ContextFiles.Add('error.log', GetBase64EncodedLogFile());
    
    MicrosoftUserFeedback.RequestDislikeFeedback('UIComponent', 'UI_COMPONENTS_001', 'User Interface Components', ContextProperties, ContextFiles);
end;
```

### Custom Question Feedback
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
    AnswerOptions: Dictionary of [Text, Text];
begin
    // Simple custom question with single answer options
    MicrosoftUserFeedback
        .WithCustomQuestion('ease_of_use', 'How easy was this to use?')
        .WithCustomQuestionType(FeedbackQuestionType::SingleChoice)
        .WithCustomQuestionAnswerOption('very_easy', 'Very Easy')
        .WithCustomQuestionAnswerOption('easy', 'Easy')
        .WithCustomQuestionAnswerOption('moderate', 'Moderate')
        .WithCustomQuestionAnswerOption('difficult', 'Difficult')
        .WithCustomQuestionAnswerOption('very_difficult', 'Very Difficult')
        .RequestFeedback('MyFeature');
    
    // Custom question with answer options dictionary
    AnswerOptions.Add('1', 'Strongly Disagree');
    AnswerOptions.Add('2', 'Disagree');
    AnswerOptions.Add('3', 'Neutral');
    AnswerOptions.Add('4', 'Agree');
    AnswerOptions.Add('5', 'Strongly Agree');
    
    MicrosoftUserFeedback
        .WithCustomQuestion('feature_satisfaction', 'This feature met my expectations')
        .WithCustomQuestionType(FeedbackQuestionType::SingleChoice)
        .WithCustomQuestionAnswerOptions(AnswerOptions)
        .WithCustomQuestionRequiredBehavior(FeedbackRequiredBehavior::Required, true)
        .RequestFeedback('ReportBuilder', 'REPORTING_001', 'Reporting & Analytics');
end;
```

### Survey Activity Tracking
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
begin
    // Start timing user activity
    MicrosoftUserFeedback.SurveyTimerActivity('DocumentProcessing', true);
    
    // ... user performs document processing tasks ...
    
    // Stop timing when task is complete
    MicrosoftUserFeedback.SurveyTimerActivity('DocumentProcessing', false);
    
    // Trigger survey based on specific user action
    MicrosoftUserFeedback.SurveyTriggerActivity('ReportGeneration');
end;
```

### AI Feature Feedback
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
    ContextFiles: Dictionary of [Text, Text];
    ContextProperties: Dictionary of [Text, Text];
begin
    // Track AI feature usage and gather feedback
    ContextProperties.Add('AIModel', 'GPT-4');
    ContextProperties.Add('PromptLength', '150 characters');
    ContextProperties.Add('ResponseTime', '2.3 seconds');
    ContextProperties.Add('UserExperience', 'Expert');
    
    // Optionally attach the generated content as a file
    ContextFiles.Add('generated_content.txt', GetBase64EncodedContent());
    
    // Positive feedback for AI-generated content using fluent API
    MicrosoftUserFeedback.SetIsAIFeedback(true).RequestLikeFeedback('AITextGeneration', 'AI_TEXT_GEN_001', 'AI Content Creation', ContextFiles, ContextProperties);
    
    // Track user satisfaction with AI suggestions
    MicrosoftUserFeedback.SurveyTriggerActivity('AISuggestionAccepted');
end;
```

### Combined Fluent API Usage
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
    ContextProperties: Dictionary of [Text, Text];
    AnswerOptions: Dictionary of [Text, Text];
begin
    // Add context properties
    ContextProperties.Add('UserRole', 'Power User');
    ContextProperties.Add('FeatureVersion', '2.0');
    
    // Setup answer options
    AnswerOptions.Add('yes', 'Yes');
    AnswerOptions.Add('no', 'No');
    AnswerOptions.Add('maybe', 'Maybe');
    
    // Combine multiple fluent API methods
    MicrosoftUserFeedback
        .SetIsAIFeedback(true)
        .WithCustomQuestion('would_recommend', 'Would you recommend this feature?')
        .WithCustomQuestionType(FeedbackQuestionType::SingleChoice)
        .WithCustomQuestionAnswerOptions(AnswerOptions)
        .WithCustomQuestionRequiredBehavior(FeedbackRequiredBehavior::Required, true)
        .RequestLikeFeedback('AIAssistant', 'AI_ASSIST_001', 'AI Assistant Features', Dictionary of [Text, Text].Create(), ContextProperties);
end;
```

---

## API Changes and Migration Guide

### Fluent API Pattern for AI Features
The API has been updated to use a fluent pattern for indicating AI features. Instead of passing a boolean `IsAIFeature` parameter to each feedback method, use the `SetIsAIFeedback()` method:

**Before (deprecated):**
```al
// Old API with IsAIFeature parameter (no longer supported)
MicrosoftUserFeedback.RequestFeedback('MyFeature', true, 'AREA_001', 'Feature Area');
```

**After (current):**
```al
// New fluent API pattern
MicrosoftUserFeedback.SetIsAIFeedback(true).RequestFeedback('MyFeature', 'AREA_001', 'Feature Area');

// Or for non-AI features, you can omit SetIsAIFeedback (defaults to false)
MicrosoftUserFeedback.RequestFeedback('MyFeature', 'AREA_001', 'Feature Area');
```

### Migration Steps
1. **Remove `IsAIFeature` parameters** from all feedback method calls
2. **Add `SetIsAIFeedback(true)`** before feedback methods for AI features
3. **Update method signatures** to use the simplified parameter lists
4. **Leverage method chaining** for cleaner code organization

### Benefits of the New Pattern
- **Cleaner API**: Removes repetitive boolean parameters from method signatures
- **Fluent interface**: Enables method chaining for more readable code
- **Flexible**: Allows setting AI feedback flag once and making multiple feedback calls
- **Consistent**: Maintains the same functionality with improved developer experience

---

## Best Practices

### Feedback Collection
- Use descriptive and consistent feature names across your application
- Use `SetIsAIFeedback(true)` before calling feedback methods for AI-related features to help categorize AI-related feedback
- Include relevant feature areas to enable targeted analysis
- Provide meaningful context data to improve feedback quality
- Leverage the fluent API pattern for cleaner code when setting AI feedback flags

### Custom Questions
- Use custom questions to gather specific insights about your feature
- Choose appropriate question types (single choice, multiple choice, text, etc.) based on the data you need
- Provide clear, concise question text and display names
- Use answer options to guide users and ensure consistent responses
- Consider making questions required when the feedback is critical for your analysis
- Clear custom questions when they're no longer needed to avoid confusion

### Survey Management  
- Use timer activities for features where usage duration matters (e.g., report builders, data entry forms)
- Use trigger activities for discrete user actions (e.g., button clicks, feature completions)
- Choose descriptive activity names that clearly identify the user behavior being tracked

### Context Data Guidelines
#### Properties (ContextProperties)
- Include relevant user context (role, experience level, session information)
- Add performance metrics when applicable (response times, data volumes)
- Use descriptive property names that clearly indicate the data being provided
- Keep property values concise and informative

#### Files (ContextFiles)
- Attach diagnostic files for negative feedback scenarios (error logs, screenshots)
- Include generated content files for AI feedback
- Ensure filenames include proper file extensions
- Keep file attachments reasonably sized and relevant
- Use base64 encoding for file content

## License
Licensed under the MIT License. See License.txt in the project root for license information.
MicrosoftUserFeedback.SetIsAIFeedback(true).RequestFeedback('AI Assistant');

// For regular features
MicrosoftUserFeedback.SetIsAIFeedback(false).RequestLikeFeedback('Data Export', 'EXPORT_001', 'Data Export');
```

---

### SurveyTimerActivity
Starts or stops a survey timer activity. This is used to start a timer to count up user usage times, which can then trigger a survey prompt after a certain threshold is reached.

For example: 5 minutes of usage time from timer start to timer end.

**Signature:**
```al
procedure SurveyTimerActivity(ActivityName: Text; Start: Boolean)
```
**Parameters:**
- `ActivityName`: The name of the activity for which the timer is started or stopped.
- `Start`: If true, starts the timer; if false, stops the timer.

---

### SurveyTriggerActivity
Sends a one-time trigger event based on a specific activity name. The event could be, for example, a user clicking a button.

**Signature:**
```al
procedure SurveyTriggerActivity(ActivityName: Text)
```
**Parameters:**
- `ActivityName`: The name of the activity that triggers the survey.

---

## Feature Area Parameters

The feedback APIs support optional feature area identification through two related parameters:

- **`FeatureArea`**: A unique identifier for the feature area, typically used as an ID in OCV (Online Customer Voice). This should be a consistent, machine-readable identifier.
- **`FeatureAreaDisplayName`**: A human-readable display name for the feature area that will be shown to users.

**Examples:**
- `FeatureArea: 'REPORTING_001'`, `FeatureAreaDisplayName: 'Reporting & Analytics'`
- `FeatureArea: 'AI_COPILOT_001'`, `FeatureAreaDisplayName: 'AI Copilot Features'`
- `FeatureArea: 'INTEGRATION_001'`, `FeatureAreaDisplayName: 'Data Integration'`

---

## Context Data Support

The Feedback module supports passing additional contextual data with feedback requests through separate parameters:

### ContextFiles Parameter
A dictionary containing file attachments where:
- **Key**: Filename with extension (e.g., `screenshot.png`, `log.txt`)
- **Value**: Base64-encoded file content

### ContextProperties Parameter  
A dictionary containing additional properties where:
- **Key**: Property name (e.g., `UserRole`, `SessionLength`)
- **Value**: Property value (e.g., `Administrator`, `15 minutes`)

**Examples of context data:**
- User session information (role, experience level, session duration)
- Feature configuration details (settings, preferences)
- Performance metrics (response times, data volumes)
- Error logs or diagnostic information
- Screenshots, log files, or other media attachments

---

## Usage Examples

### Basic Feedback Request
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
begin
    // Simple feedback request without area specification
    MicrosoftUserFeedback.RequestFeedback('MyFeature');
    
    // Feedback with feature area and display name
    MicrosoftUserFeedback.RequestFeedback('ReportBuilder', 'REPORTING_001', 'Reporting & Analytics');
    
    // Request positive feedback for an AI feature using fluent API
    MicrosoftUserFeedback.SetIsAIFeedback(true).RequestLikeFeedback('AIAssist', 'AI_COPILOT_001', 'AI Copilot Features');
    
    // Request negative feedback for troubleshooting
    MicrosoftUserFeedback.RequestDislikeFeedback('DataSync', 'INTEGRATION_001', 'Data Integration');
end;
```

### Feedback with Context Data
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
    ContextFiles: Dictionary of [Text, Text];
    ContextProperties: Dictionary of [Text, Text];
begin
    // Add context properties
    ContextProperties.Add('UserRole', 'Administrator');
    ContextProperties.Add('SessionLength', '15 minutes');
    ContextProperties.Add('FeatureUsage', 'First time');
    
    // Request feedback with additional context
    MicrosoftUserFeedback.RequestFeedback('ReportBuilder', 'REPORTING_001', 'Reporting & Analytics', ContextFiles, ContextProperties);
    
    // Add file attachment for negative feedback
    ContextFiles.Add('screenshot.png', GetBase64EncodedScreenshot());
    ContextFiles.Add('error.log', GetBase64EncodedLogFile());
    
    MicrosoftUserFeedback.RequestDislikeFeedback('UIComponent', 'UI_COMPONENTS_001', 'User Interface Components', ContextProperties, ContextFiles);
end;
```

### Survey Activity Tracking
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
begin
    // Start timing user activity
    MicrosoftUserFeedback.SurveyTimerActivity('DocumentProcessing', true);
    
    // ... user performs document processing tasks ...
    
    // Stop timing when task is complete
    MicrosoftUserFeedback.SurveyTimerActivity('DocumentProcessing', false);
    
    // Trigger survey based on specific user action
    MicrosoftUserFeedback.SurveyTriggerActivity('ReportGeneration');
end;
```

### AI Feature Feedback
```al
var
    MicrosoftUserFeedback: Codeunit "Microsoft User Feedback";
    ContextFiles: Dictionary of [Text, Text];
    ContextProperties: Dictionary of [Text, Text];
begin
    // Track AI feature usage and gather feedback
    ContextProperties.Add('AIModel', 'GPT-4');
    ContextProperties.Add('PromptLength', '150 characters');
    ContextProperties.Add('ResponseTime', '2.3 seconds');
    ContextProperties.Add('UserExperience', 'Expert');
    
    // Optionally attach the generated content as a file
    ContextFiles.Add('generated_content.txt', GetBase64EncodedContent());
    
    // Positive feedback for AI-generated content using fluent API
    MicrosoftUserFeedback.SetIsAIFeedback(true).RequestLikeFeedback('AITextGeneration', 'AI_TEXT_GEN_001', 'AI Content Creation', ContextFiles, ContextProperties);
    
    // Track user satisfaction with AI suggestions
    MicrosoftUserFeedback.SurveyTriggerActivity('AISuggestionAccepted');
end;
```

---

## API Changes and Migration Guide

### Fluent API Pattern for AI Features
The API has been updated to use a fluent pattern for indicating AI features. Instead of passing a boolean `IsAIFeature` parameter to each feedback method, use the `SetIsAIFeedback()` method:

**Before (deprecated):**
```al
// Old API with IsAIFeature parameter (no longer supported)
MicrosoftUserFeedback.RequestFeedback('MyFeature', true, 'AREA_001', 'Feature Area');
```

**After (current):**
```al
// New fluent API pattern
MicrosoftUserFeedback.SetIsAIFeedback(true).RequestFeedback('MyFeature', 'AREA_001', 'Feature Area');

// Or for non-AI features, you can omit SetIsAIFeedback (defaults to false)
MicrosoftUserFeedback.RequestFeedback('MyFeature', 'AREA_001', 'Feature Area');
```

### Migration Steps
1. **Remove `IsAIFeature` parameters** from all feedback method calls
2. **Add `SetIsAIFeedback(true)`** before feedback methods for AI features
3. **Update method signatures** to use the simplified parameter lists
4. **Leverage method chaining** for cleaner code organization

### Benefits of the New Pattern
- **Cleaner API**: Removes repetitive boolean parameters from method signatures
- **Fluent interface**: Enables method chaining for more readable code
- **Flexible**: Allows setting AI feedback flag once and making multiple feedback calls
- **Consistent**: Maintains the same functionality with improved developer experience

---

## Best Practices

### Feedback Collection
- Use descriptive and consistent feature names across your application
- Use `SetIsAIFeedback(true)` before calling feedback methods for AI-related features to help categorize AI-related feedback
- Include relevant feature areas to enable targeted analysis
- Provide meaningful context data to improve feedback quality
- Leverage the fluent API pattern for cleaner code when setting AI feedback flags

### Survey Management  
- Use timer activities for features where usage duration matters (e.g., report builders, data entry forms)
- Use trigger activities for discrete user actions (e.g., button clicks, feature completions)
- Choose descriptive activity names that clearly identify the user behavior being tracked

### Context Data Guidelines
#### Properties (ContextProperties)
- Include relevant user context (role, experience level, session information)
- Add performance metrics when applicable (response times, data volumes)
- Use descriptive property names that clearly indicate the data being provided
- Keep property values concise and informative

#### Files (ContextFiles)
- Attach diagnostic files for negative feedback scenarios (error logs, screenshots)
- Include generated content files for AI feedback
- Ensure filenames include proper file extensions
- Keep file attachments reasonably sized and relevant
- Use base64 encoding for file content

## License
Licensed under the MIT License. See License.txt in the project root for license information.