# Feedback API Documentation

This document describes the APIs provided by the `Feedback` codeunit (ID: 1599) in the `System.Feedback` namespace. These APIs enable user feedback collection and survey management for features in Business Central.

## Overview
The `Feedback` codeunit provides procedures to request feedback (general, like, dislike) for features, including Copilot features and feature areas, as well as triggering surveys.

## API Reference

---

### RequestFeedback
Requests general feedback for a feature, optionally specifying if it is a Copilot feature and its area.

**Signature:**
```al
procedure RequestFeedback(FeatureName: Text[255]; IsCopilotFeature: Boolean; FeatureArea: Text[255])
```
**Parameters:**
- `FeatureName`: The name of the feature for which feedback is requested.
- `IsCopilotFeature`: Specifies if the feature is a Copilot feature.
- `FeatureArea`: The area or sub-area of the feature.

---

### RequestLikeFeedback
Requests a 'like' (positive) feedback for a feature, optionally specifying if it is a Copilot feature and its area.

**Signature:**
```al
procedure RequestLikeFeedback(FeatureName: Text[255]; IsCopilotFeature: Boolean; FeatureArea: Text[255])
```
**Parameters:**
- `FeatureName`: The name of the feature for which like feedback is requested.
- `IsCopilotFeature`: Specifies if the feature is a Copilot feature.
- `FeatureArea`: The area or sub-area of the feature.

---

### RequestDislikeFeedback
Requests a 'dislike' (negative) feedback for a feature, optionally specifying if it is a Copilot feature and its area.

**Signature:**
```al
procedure RequestDislikeFeedback(FeatureName: Text[255]; IsCopilotFeature: Boolean; FeatureArea: Text[255])
```
**Parameters:**
- `FeatureName`: The name of the feature for which dislike feedback is requested.
- `IsCopilotFeature`: Specifies if the feature is a Copilot feature.
- `FeatureArea`: The area or sub-area of the feature.

---

### SurveyTimerActivity
Starts or stops a survey timer activity. This is used to start a timer to count up user usage times, which can then trigger a survey prompt after a certain threshold is reached.

For example: 5 minutes of usage time from timer start to timer end.

**Signature:**
```al
procedure SurveyTimerActivity(ActivityName: Text[255]; Start: Boolean)
```
**Parameters:**
- `ActivityName`: The name of the activity for which the timer is started or stopped.
- `Start`: If true, starts the timer; if false, stops the timer.

---

### SurveyTriggerActivity
Sends a one-time trigger event based on a specific activity name. The event could be, for example, a user clicking a button.

**Signature:**
```al
procedure SurveyTriggerActivity(ActivityName: Text[255])
```
**Parameters:**
- `ActivityName`: The name of the activity that triggers the survey.

---

## Usage Examples

### Basic Feedback Request
```al
var
    Feedback: Codeunit Feedback;
begin
    // Request general feedback for a feature
    Feedback.RequestFeedback('MyFeature', false, 'MainArea');
    
    // Request positive feedback for a Copilot feature
    Feedback.RequestLikeFeedback('CopilotAssist', true, 'AI');
    
    // Request negative feedback for troubleshooting
    Feedback.RequestDislikeFeedback('DataSync', false, 'Integration');
end;
```

### Survey Activity Tracking
```al
var
    Feedback: Codeunit Feedback;
begin
    // Start timing user activity
    Feedback.SurveyTimerActivity('DocumentProcessing', true);
    
    // ... user performs document processing tasks ...
    
    // Stop timing when task is complete
    Feedback.SurveyTimerActivity('DocumentProcessing', false);
    
    // Trigger survey based on specific user action
    Feedback.SurveyTriggerActivity('ReportGeneration');
end;
```

---

## License
Licensed under the MIT License. See License.txt in the project root for license information.
