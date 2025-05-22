
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Privacy;

page 1569 "Microsoft Learn Privacy Notice"
{
    Caption = 'Your privacy is important';
    PageType = NavigatePage;
    SourceTable = "Privacy Notice";
    SourceTableTemporary = true;
    RefreshOnActivate = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            label(PrivacyNoticeLabel)
            {
                ApplicationArea = All;
                Caption = 'This feature uses documentation and content from Microsoft Learn, an online service operated by Microsoft.';
            }

            label(DataMovementLabel)
            {
                ApplicationArea = All;
                Caption = 'By allowing data movement, you agree to data being processed by the Microsoft Learn service outside of your environment''s geographic region or compliance boundary.';
            }

            field(LearnMore; LearnMoreTxt)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Caption = ' ';
                ToolTip = 'View information about the Microsoft Learn service.';

                trigger OnDrillDown()
                begin
                    Hyperlink(LearnMoreLinkTxt);
                end;
            }

            label(ApproveForOrganization)
            {
                ApplicationArea = All;
                Visible = not UserCanApproveForOrganization;
                Caption = 'Your administrator must allow data movement to continue.';
            }

            field(AllowDataMovement; AllowDataMovement)
            {
                ApplicationArea = All;
                Visible = UserCanApproveForOrganization;
                Caption = 'Allow data movement';
                ToolTip = 'Specifies if data movement for the Microsoft Learn service has been approved.';
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Reject)
            {
                ApplicationArea = All;
                Caption = 'Back';
                ToolTip = 'Disagree to the terms and conditions.';
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
            action(Accept)
            {
                ApplicationArea = All;
                Caption = 'Continue';
                ToolTip = 'Agree to the terms and conditions.';
                Image = NextRecord;
                InFooterBar = true;
                Enabled = AllowDataMovement;

                trigger OnAction()
                var
                    PrivacyNotice: Codeunit "Privacy Notice";
                begin
                    if PrivacyNoticeRecord.ID <> '' then
                        PrivacyNotice.SetApprovalState(PrivacyNoticeRecord.ID, "Privacy Notice Approval State"::Agreed);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        PrivacyNoticeCodeunit: Codeunit "Privacy Notice";
    begin
        UserCanApproveForOrganization := PrivacyNoticeCodeunit.CanCurrentUserApproveForOrganization();
        PrivacyNoticeRecord := Rec;
    end;

    var
        PrivacyNoticeRecord: Record "Privacy Notice";
        LearnMoreTxt: Label 'Learn more';
        LearnMoreLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2303361', Locked = true;
        UserCanApproveForOrganization: Boolean;
        AllowDataMovement: Boolean;
}
