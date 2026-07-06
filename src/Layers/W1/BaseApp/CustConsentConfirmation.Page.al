// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Privacy;

page 1820 "Cust. Consent Confirmation"
{
    Caption = 'Please review terms and conditions';
    PageType = NavigatePage;
    Editable = false;

    layout
    {
        area(content)
        {
            field(ConsentText; ConsentTextValue)
            {
                ApplicationArea = All;
                ShowCaption = false;
                MultiLine = true;
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
            action(Accept)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'I accept';
                ToolTip = 'Agree with the customer consent.';
                Image = Confirm;
                InFooterBar = true;

                trigger OnAction();
                begin
                    Agreed := true;
                    CurrPage.Close();
                end;
            }
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Cancel';
                ToolTip = 'Disagree with the customer consent.';
                Image = Cancel;
                InFooterBar = true;

                trigger OnAction();
                begin
                    Agreed := false;
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        if ConsentTextValue = '' then
            ConsentTextValue := ConsentTxt;
    end;

    var
        PrivacyLinkTxt: Label 'https://go.microsoft.com/fwlink/?linkid=521839';
        ConsentTxt: Label 'By enabling this feature, you consent to your data being shared with third party systems and flowing outside of your organization''s selected geographic boundaries.  You control what data, if any, that you provide to the third-party. The third party may not meet the same compliance and security standards as Microsoft Dynamics 365 Business Central. Your privacy is important to us.  To learn more follow the link below.';
        OpenLinkConsentTxt: Label 'By opening this link, you consent to your data being shared with third party systems and flowing outside of your organization''s selected geographic boundaries.  You control what data, if any, that you provide to the third-party. The third party may not meet the same compliance and security standards as Microsoft Dynamics 365 Business Central. Your privacy is important to us.  To learn more follow the link below.';
        LearnMoreTok: Label 'Privacy and Cookies';
        ConsentTextValue: Text;
        Agreed: Boolean;

    procedure WasAgreed(): Boolean
    begin
        exit(Agreed);
    end;

    procedure SetOpenExternalLinkConsentText()
    begin
        ConsentTextValue := OpenLinkConsentTxt;
    end;

    procedure SetCustomConsentText(CustomConsentText: Text)
    begin
        ConsentTextValue := CustomConsentText;
    end;
}
