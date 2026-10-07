// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8377 "MCP Billing Confirmation"
{
    ApplicationArea = All;
    Caption = 'Billing acknowledgement';
    Extensible = false;
    PageType = ConfirmationDialog;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field(BillingNotice; BillingNoticeText)
            {
                ApplicationArea = All;
                Editable = false;
                MultiLine = true;
                ShowCaption = false;
                ToolTip = 'Specifies that activating the server feature incurs additional charges.';
            }
            field(LearnMore; LearnMoreLbl)
            {
                ApplicationArea = All;
                DrillDown = true;
                Editable = false;
                ShowCaption = false;
                Style = StandardAccent;
                StyleExpr = true;
                ToolTip = 'Open documentation about pricing and terms for the billable server feature.';

                trigger OnDrillDown()
                begin
                    Hyperlink(LearnMoreUrlLbl);
                end;
            }
            field(ConfirmationQuestion; ConfirmationQuestionText)
            {
                ApplicationArea = All;
                Editable = false;
                MultiLine = true;
                ShowCaption = false;
                ToolTip = 'Specifies whether to activate the billable server feature.';
            }
        }
    }

    internal procedure SetFeature(Feature: Enum "MCP Server Feature")
    var
        FeatureName: Text;
    begin
        FeatureName := Format(Feature).Replace(PreviewBillableSuffixTok, '');
        BillingNoticeText := StrSubstNo(BillingNoticeLbl, FeatureName);
        ConfirmationQuestionText := StrSubstNo(ConfirmationQuestionLbl, FeatureName);
    end;

    var
        BillingNoticeText: Text;
        ConfirmationQuestionText: Text;
        BillingNoticeLbl: Label 'Use of %1 will incur additional charges. By activating %1, you acknowledge that charges will apply according to the applicable pricing and terms.', Comment = '%1 = server feature name';
        ConfirmationQuestionLbl: Label 'Do you want to activate %1?', Comment = '%1 = server feature name';
        LearnMoreLbl: Label 'Learn more';
        LearnMoreUrlLbl: Label 'https://go.microsoft.com/fwlink/?LinkId=2383165', Locked = true;
        PreviewBillableSuffixTok: Label ' (Preview/Billable)', Locked = true;
}
