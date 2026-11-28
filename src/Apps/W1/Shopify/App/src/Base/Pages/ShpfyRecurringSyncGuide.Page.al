// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using System.Environment;
using System.Utilities;

page 30177 "Shpfy Recurring Sync Guide"
{
    Caption = 'Recurring Shopify Synchronization Setup Guide';
    PageType = NavigatePage;
    SourceTable = "Shpfy Shop";
    SourceTableTemporary = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(StandardBanner)
            {
                Caption = '';
                Editable = false;
                Visible = TopBannerVisible;

                field(MediaResourcesStd; MediaResourcesStandard."Media Reference")
                {
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Welcome)
            {
                ShowCaption = false;
                Visible = WelcomeStepVisible;

                group(WelcomeHeading)
                {
                    Caption = 'Welcome to recurring Shopify synchronization';
                    InstructionalText = 'Recurring synchronization keeps Business Central and Shopify data up to date without repeatedly running synchronization actions.';
                }
                group(WelcomeDescription)
                {
                    ShowCaption = false;
                    InstructionalText = 'This guide suggests synchronizations and frequencies based on the current Shopify shop setup. You can change the recommendations before creating the schedules.';
                }
                group(LetsGo)
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Select Next to choose which Shopify synchronizations should run automatically.';
                }
            }
            group(Selection)
            {
                ShowCaption = false;
                Visible = SelectionStepVisible;

                group(SelectionHeading)
                {
                    Caption = 'Choose what to synchronize';
                    InstructionalText = 'Select the synchronizations that should run automatically. An unavailable option shows a missing setting or prerequisite.';
                }
                part(SelectionPart; "Shpfy Recurring Sync Selection")
                {
                    ShowFilter = false;
                    UpdatePropagation = Both;
                }
                group(ConfiguredSchedules)
                {
                    ShowCaption = false;
                    Visible = HasSchedules;

                    field(ViewRecurringSynchronizations; ViewRecurringSynchronizationsLbl)
                    {
                        Editable = false;
                        ShowCaption = false;
                        ToolTip = 'Open details for "View recurring synchronizations"';

                        trigger OnDrillDown()
                        var
                            RecurringSyncList: Page "Shpfy Recurring Sync List";
                        begin
                            RecurringSyncList.SetShop(Shop);
                            RecurringSyncList.RunModal();
                            HasSchedules := CurrPage.SelectionPart.Page.Refresh();
                            CurrPage.Update(false);
                        end;
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
                Caption = 'Back';
                ToolTip = 'Go back to the previous step.';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ShowWelcomeStep();
                    CurrPage.Update(false);
                end;
            }
            action(ActionNext)
            {
                Caption = 'Next';
                ToolTip = 'Go to the next step and choose which synchronizations to schedule.';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    ShowSelectionStep();
                end;
            }
            action(ActionFinish)
            {
                Caption = 'Finish';
                ToolTip = 'Create recurring schedules for the selected synchronizations.';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    Result: Text;
                begin
                    Result := CurrPage.SelectionPart.Page.CreateSchedules();
                    if Result <> '' then
                        Message(Result);
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanner();
    end;

    trigger OnOpenPage()
    begin
        ShowWelcomeStep();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if SelectionStepVisible then
            FinishActionEnabled := CurrPage.SelectionPart.Page.CanFinish()
        else
            FinishActionEnabled := false;
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        Shop: Record "Shpfy Shop";
        BackActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        HasSchedules: Boolean;
        NextActionEnabled: Boolean;
        SelectionStepVisible: Boolean;
        TopBannerVisible: Boolean;
        WelcomeStepVisible: Boolean;
        ViewRecurringSynchronizationsLbl: Label 'View recurring synchronizations';

    internal procedure SetShop(ShopToSet: Record "Shpfy Shop")
    begin
        Shop := ShopToSet;
        Rec := ShopToSet;
        Rec.Insert(false);
    end;

    local procedure ShowWelcomeStep()
    begin
        WelcomeStepVisible := true;
        SelectionStepVisible := false;
        BackActionEnabled := false;
        NextActionEnabled := true;
        FinishActionEnabled := false;
    end;

    local procedure ShowSelectionStep()
    begin
        Shop.Get(Shop.Code);
        CurrPage.SelectionPart.Page.Load(Shop, HasSchedules);
        WelcomeStepVisible := false;
        SelectionStepVisible := true;
        BackActionEnabled := true;
        NextActionEnabled := false;
        FinishActionEnabled := CurrPage.SelectionPart.Page.CanFinish();
        CurrPage.Update(false);
    end;

    local procedure LoadTopBanner()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(CurrentClientType())) then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") then
                TopBannerVisible := MediaResourcesStandard."Media Reference".HasValue();
    end;
}
