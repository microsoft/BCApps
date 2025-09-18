# Feedback API Documentation

This document describes the APIs provided by the `Feedback` codeunit (ID: 1599) in the `System.Feedback` namespace. These APIs enable user feedback collection and management for features and pages in Business Central.

## Overview
The `Feedback` codeunit provides procedures to enable/disable feedback on pages and request feedback (general, like, dislike) for features, including Copilot features and feature areas.

## API Reference

### EnablePageFeedback
Enables thumbs up/down feedback for a specific page.

**Signature:**
```al
procedure EnablePageFeedback(PageID: Integer; FeatureName: Text[255]; FeedbackType: Enum "Feedback Type"; FeatureArea: Text[255])
```
**Parameters:**
- `PageID`: The ID of the page to enable feedback for.
- `FeatureName`: The name of the feature being evaluated.
- `FeedbackType`: The type of feedback to enable (General Feedback, Copilot Feedback).
- `FeatureArea`: An optional sub-area for the feedback. Use empty string to keep feedback in main area.

---

### DisablePageFeedback
Disables thumbs up/down feedback for a specific page.

**Signature:**
```al
procedure DisablePageFeedback(PageID: Integer)
```
**Parameters:**
- `PageID`: The ID of the page to disable feedback for.

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

## Enum: Feedback Type
- `General Feedback`
- `Copilot Feedback`

---

## Usage Example
```al
var
    Feedback: Codeunit Feedback;
begin
    Feedback.EnablePageFeedback(50100, 'MyFeature', FeedbackType::"General Feedback", 'MainArea');
    Feedback.RequestLikeFeedback('MyFeature', false, 'MainArea');
end;
```

---

## License
Licensed under the MIT License. See License.txt in the project root for license information.
