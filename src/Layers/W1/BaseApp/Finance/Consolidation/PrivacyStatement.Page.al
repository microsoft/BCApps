// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

page 109 "Privacy Statement"
{
    PageType = NavigatePage;
    layout
    {
        area(Content)
        {
            field(ConsentLbl; ConsentLbl)
            {
                ApplicationArea = All;
                ShowCaption = false;
                Editable = false;
                Caption = ' ';
                MultiLine = true;
                ToolTip = 'Accept the terms and conditions.';
            }
            field(Consent; ConsentState)
            {
                ApplicationArea = All;
                Caption = 'I accept';
                ToolTip = 'Accept the terms and conditions.';
            }
            field(LearnMore; LearnMoreTok)
            {
                ApplicationArea = All;
                Editable = false;
                ShowCaption = false;
                Caption = ' ';
                ToolTip = 'View information about the privacy.';

                trigger OnDrillDown()
                begin
                    Hyperlink(PrivacyLinkTxt);
                end;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(Ok)
            {
                ApplicationArea = All;
                InFooterBar = true;
                Caption = 'OK';

                trigger OnAction()
                begin
                    CurrPage.Close();
                end;
            }
        }
    }

    var
        ConsentState: Boolean;
        ConsentLbl: Label 'By enabling this feature, you consent to your data being shared with a Microsoft service that might be outside of your organization''s selected geographic boundaries and might have different compliance and security standards than Microsoft Dynamics Business Central. Your privacy is important to us, and you can choose whether to share data with the service. To learn more, follow the link below.';
        LearnMoreTok: Label 'Privacy and Cookies';
        PrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=521839';

    internal procedure GetConsentState(): Boolean
    begin
        exit(ConsentState);
    end;

}
