// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 1305 "O365 Developer Welcome"
{
    Caption = 'Welcome';
    PageType = NavigatePage;
    SourceTable = "O365 Getting Started";

    layout
    {
        area(content)
        {
            group(Control4)
            {
                ShowCaption = false;
                Visible = FirstPageVisible;
                field(Image1; PageDataMediaResources."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Image';
                    Editable = false;
                    ShowCaption = false;
                }
                group(Page1Group)
                {
                    Caption = 'This is your sandbox environment for Dynamics 365 Business Central';
                    field(MainTextLbl; MainTextLbl)
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = false;
                        MultiLine = true;
                        ShowCaption = false;
                    }
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(WelcomeTour)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Learn More';
                Image = Start;
                InFooterBar = true;

                trigger OnAction()
                begin
                    HyperLink(LearnMoreLbl);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    trigger OnOpenPage()
    begin
        FirstPageVisible := true;
        O365GettingStartedPageData.GetPageImage(O365GettingStartedPageData, 1, PAGE::"O365 Getting Started");
        if PageDataMediaResources.Get(O365GettingStartedPageData."Media Resources Ref") then;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        MarkAsCompleted();
    end;

    var
        O365GettingStartedPageData: Record "O365 Getting Started Page Data";
        MainTextLbl: Label 'This Sandbox environment is solely for testing, development and evaluation. You will not use the Sandbox in a live operating environment. Microsoft may, in its sole discretion, change the Sandbox environment or subject it to a fee for a final, commercial version, if any, or may elect not to release one.';
        LearnMoreLbl: Label 'https://aka.ms/d365fobesandbox', Locked = true;
        PageDataMediaResources: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        FirstPageVisible: Boolean;

    local procedure MarkAsCompleted()
    begin
        Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
        Rec."Display Target" := Format(ClientTypeManagement.GetCurrentClientType());
        Rec."Tour in Progress" := false;
        Rec."Tour Completed" := true;
        Rec.Insert();
    end;
}
