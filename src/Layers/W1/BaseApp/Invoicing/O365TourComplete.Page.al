// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
#pragma warning disable AA0247
page 1306 "O365 Tour Complete"
{
    Caption = 'Tour Complete';
    PageType = NavigatePage;
    SourceTable = "O365 Getting Started";

    layout
    {
        area(content)
        {
            group(Control2)
            {
                Editable = false;
                ShowCaption = false;
                Visible = CurrentPage = 1;
                field(Image1; ImagePageDataMediaResources."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Image1';
                    Editable = false;
                    ShowCaption = false;
                }
                group(Page1Group)
                {
                    Caption = 'That''s it';
                    field(BodyText1; BodyText)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'BodyText1';
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
            action(ReturnToGettingStarted)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Return to Getting Started';
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                var
                    DummyO365GettingStarted: Page "O365 Getting Started";
                begin
                    ShowToursWizard := true;
                    CurrPage.Close();
                    Rec."Current Page" := DummyO365GettingStarted.GetNextPageID(1, Rec."Current Page");
                    Rec.Modify();

                    PAGE.Run(PAGE::"O365 Getting Started");
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateImageAndBodyText();
    end;

    trigger OnInit()
    begin
        Rec.SetRange("User ID", UserId);
    end;

    trigger OnOpenPage()
    begin
        CurrentPage := 1;
        if UserTours.IsAvailable() and O365GettingStartedMgt.AreUserToursEnabled() then begin
            UserTours := UserTours.Create();
            UserTours.StopUserTour();
        end;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if ShowToursWizard then
            exit(true);

        if Rec."Tour Completed" then begin
            Rec."Tour in Progress" := false;
            Rec.Modify();
            exit(true);
        end;

        exit(ConfirmClosingOfTheWizard());
    end;

    var
        ImageO365GettingStartedPageData: Record "O365 Getting Started Page Data";
        ImagePageDataMediaResources: Record "Media Resources";
        O365GettingStartedMgt: Codeunit "O365 Getting Started Mgt.";
        [RunOnClient]
        [WithEvents]
        UserTours: DotNet UserTours;
        BodyText: Text;
        ExitWizardQst: Label 'Are you sure that you want to exit the Getting Started tour?';
        ExitWizardInstructionTxt: Label '\\You can always resume the Getting Started tour later from the Home page.';
        ShowToursWizard: Boolean;
        CurrentPage: Integer;
        Tour1Txt: Label 'We''d love to show you more of how %1 can streamline your business.', Comment = '%1=PRODUCTNAME.MARKETING';

    local procedure MarkWizardAsDone()
    begin
        Rec."Tour in Progress" := false;
        Rec."Tour Completed" := true;
        Rec.Modify();

        if UserTours.IsAvailable() and O365GettingStartedMgt.AreUserToursEnabled() then begin
            UserTours := UserTours.Create();
            UserTours.StopNotifyShowTourWizard();
        end;
    end;

    local procedure ConfirmClosingOfTheWizard(): Boolean
    var
        ConfirmQst: Text;
    begin
        ConfirmQst := ExitWizardQst + ExitWizardInstructionTxt;
        if not Confirm(ConfirmQst) then
            exit(false);

        MarkWizardAsDone();
        exit(true);
    end;

    local procedure UpdateImageAndBodyText()
    begin
        ImageO365GettingStartedPageData.GetPageImage(
          ImageO365GettingStartedPageData, CurrentPage, PAGE::"O365 Tour Complete");
        if ImagePageDataMediaResources.Get(ImageO365GettingStartedPageData."Media Resources Ref") then;

        BodyText := StrSubstNo(Tour1Txt, PRODUCTNAME.Marketing());
    end;
}
