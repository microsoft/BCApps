// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import.Purchase;


page 6185 "E-Doc. Draft Feedback"
{
    PageType = ConfirmationDialog;
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'E-Document Draft Feedback';
    Extensible = false;

    layout
    {
        area(Content)
        {
            label(FeedbackTitle)
            {
                ApplicationArea = All;
                Caption = 'Your experience helps us improve.';
                Style = Strong;
            }
            label(FeedbackText)
            {
                ApplicationArea = All;
                Caption = 'AP workflows differ across regions, and sometimes Payables Agent may not cover a local requirement, a validation rule, or a something your team depends on. If you’ve noticed anything like this — something that felt missing or didn’t align with your local process — we’d really appreciate you telling us.';
            }
            label(FeedbackQst)
            {
                ApplicationArea = All;
                Caption = 'Provide feedback?';
            }
        }
    }
}