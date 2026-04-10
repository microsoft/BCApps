namespace System.Security.Authentication;

using System.Environment;
using System.Security.User;
using System.Utilities;

page 9870 "WS Access Key Wizard"
{
    Caption = 'Web Service Access Key';
    AdditionalSearchTerms = 'Web Service Access key,Access key';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = NavigatePage;
    ShowFilter = false;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(Banner1)
            {
                Editable = false;
                Visible = TopBannerVisible and not ActionFinishEnabled;
                ShowCaption = false;
                field(MediaResourcesStandard; StandardIconMediaResources."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Banner2)
            {
                Editable = false;
                Visible = TopBannerVisible and ActionFinishEnabled;
                ShowCaption = false;
                field(MediaResourcesDone; DoneIconMediaResources."Media Reference")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                ShowCaption = false;
                Visible = CurrentStep = 1;
                group("Para1.1")
                {
                    ShowCaption = false;
                    group("Para1.1.1")
                    {
                        ShowCaption = false;
                        InstructionalText = 'A web service access key is assigned to your Business Central account.';
                    }
                    group("Para1.1.2")
                    {
                        ShowCaption = false;
                        InstructionalText = 'Business Central will stop supporting integrations that use an access key on October 1, 2022. You must remove your access key.';
                    }
                    group("Para1.1.3")
                    {
                        ShowCaption = false;
                        InstructionalText = '​Your access to Business Central on the web, tablet, and phone is not affected.';
                    }
                    group("Para1.1.4")
                    {
                        ShowCaption = false;
                        InstructionalText = '​We''ll guide you in the simple removal process.';
                    }
                }
            }
            group(Step2)
            {
                Caption = '';
                Visible = CurrentStep = 2;
                group("Para2.1")
                {
                    ShowCaption = false;
                    group("Para2.1.1")
                    {
                        ShowCaption = false;
                        InstructionalText = 'Choose Finish to complete the key removal.';
                    }
                    group("Para2.1.2")
                    {
                        ShowCaption = false;
                        InstructionalText = 'If you are not sure you are using the key, you may contact your administrator before removing it.';
                    }
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                ToolTip = 'Go to the previous page.';
                Enabled = BackEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextEnabled;
                Image = NextRecord;
                ToolTip = 'Next';
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }

            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                ToolTip = 'Complete and complete the key removal.';
                Enabled = ActionFinishEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    UserCard: Page "User Card";
                    WSDeprecationSuccesMsg: Label 'Using Web Service Access Key to authenticate connections, have now been succesfully disabled.';
                begin
                    if UserCard.RemoveWebServiceAccessKey(UserSecurityId()) then
                        Message(WSDeprecationSuccesMsg);
                    CurrPage.Close();
                end;
            }
        }
    }


    trigger OnOpenPage()
    begin
        LoadTopBanners();
        CurrentStep := 0;
        NextStep(true);
    end;

    local procedure GetTotalNumberOfSteps(): Integer
    begin
        exit(2);
    end;

    local procedure NextStep(Forward: Boolean)
    begin
        if Forward then
            CurrentStep += 1
        else
            CurrentStep -= 1;

        ActionFinishEnabled := CurrentStep = GetTotalNumberOfSteps();
        NextEnabled := CurrentStep <> GetTotalNumberOfSteps();
        BackEnabled := CurrentStep <> 1;
        CurrPage.Update();
    end;

    local procedure LoadTopBanners()
    var
        ClientTypeManagement: Codeunit "Client Type Management";
    begin
        if StandardIconMediaRepository.Get(AssistedSetupStandardIconTxt, FORMAT(ClientTypeManagement.GetCurrentClientType())) and
           DoneIconMediaRepository.Get(AssistedSetupDoneIconTxt, Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if StandardIconMediaResources.Get(StandardIconMediaRepository."Media Resources Ref") and
               DoneIconMediaResources.Get(DoneIconMediaRepository."Media Resources Ref")
            then
                TopBannerVisible := DoneIconMediaResources."Media Reference".HasValue();
    end;

    var
        StandardIconMediaRepository: Record "Media Repository";
        DoneIconMediaRepository: Record "Media Repository";
        StandardIconMediaResources: Record "Media Resources";
        DoneIconMediaResources: Record "Media Resources";
        CurrentStep: Integer;
        TopBannerVisible: Boolean;
        ActionFinishEnabled: Boolean;
        NextEnabled: Boolean;
        BackEnabled: Boolean;
        AssistedSetupStandardIconTxt: Label 'AssistedSetup-NoText-400px.png', Locked = true;
        AssistedSetupDoneIconTxt: Label 'AssistedSetupDone-NoText-400px.png', Locked = true;
}