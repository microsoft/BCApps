// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Sales.Customer;
using System.Environment;
using System.Utilities;

page 1816 "Job Creation Wizard"
{
    Caption = 'Create New Project';
    DelayedInsert = true;
    PageType = NavigatePage;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            group(Control96)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesStandard.""Media Reference"""; MediaResourcesStandard."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control98)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and FinalStepVisible;
#pragma warning disable AA0100
                field("MediaResourcesDone.""Media Reference"""; MediaResourcesDone."Media Reference")
#pragma warning restore AA0100
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control25)
            {
                ShowCaption = false;
                Visible = FirstStepVisible;
                group("Welcome to Create New Job")
                {
                    Caption = 'Welcome to Create New Project';
                    Visible = FirstStepVisible;
                    group(Control23)
                    {
                        InstructionalText = 'Do you want to create a new project from an existing project?';
                        ShowCaption = false;
                        Visible = FirstStepVisible;
                        field(FromExistingJob; FromExistingJob)
                        {
                            ApplicationArea = Jobs;
                            CaptionClass = Format(FromExistingJob);
                        }
                    }
                }
            }
            group(Control19)
            {
                ShowCaption = false;
                Visible = CreationStepVisible;
                group(Control20)
                {
                    Caption = 'Welcome to Create New Project';
                    Visible = CreationStepVisible;
                    group(Control18)
                    {
                        InstructionalText = 'Fill in the following fields for the new project.';
                        ShowCaption = false;
                        Visible = CreationStepVisible;
                        field("No."; Rec."No.")
                        {
                            ApplicationArea = Jobs;
                            Caption = 'No.';

                            trigger OnAssistEdit()
                            begin
                                if Rec.AssistEdit(xRec) then
                                    CurrPage.Update();
                            end;
                        }
                        field(Description; Rec.Description)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Description';
                        }
                        field("Sell-to Customer No."; SellToCustomerNo)
                        {
                            ApplicationArea = Jobs;
                            Caption = 'Sell-to Customer No.';
                            TableRelation = Customer;
                            ToolTip = 'Specifies the number of the customer who will receive the products and be billed by default.';

                            trigger OnLookup(var Text: Text): Boolean
                            var
                                Customer: Record Customer;
                            begin
                                if Page.RunModal(0, Customer) = Action::LookupOK then
                                    SellToCustomerNo := Customer."No.";
                            end;
                        }
                    }
                    group(Control9)
                    {
                        InstructionalText = 'To select the tasks to copy from an existing project, choose Next.';
                        ShowCaption = false;
                    }
                }
            }
            group(Control8)
            {
                ShowCaption = false;
                Visible = FinalStepVisible;
                group("That's it!")
                {
                    Caption = 'That''s it!';
                    group(Control4)
                    {
                        InstructionalText = 'To view your new project, choose Finish.';
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
            action(ActionBack)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(ActionNext)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
            action(ActionFinish)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                begin
                    FinishAction();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
    end;

    trigger OnOpenPage()
    begin
        Rec.Init();
        FromExistingJob := true;
        Step := Step::Start;
        StartStep();
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Creation,Finish;
        SellToCustomerNo: Code[20];
        TopBannerVisible: Boolean;
        FirstStepVisible: Boolean;
        CreationStepVisible: Boolean;
        FinalStepVisible: Boolean;
        FinishActionEnabled: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FromExistingJob: Boolean;
        SelectJobNumberMsg: Label 'To continue, specify the project number that you want to copy.';
        SelectCustomerNumberMsg: Label 'To continue, specify the customer of the new project.';

    local procedure FinishAction()
    begin
        PAGE.Run(PAGE::"Job Card", Rec);
        CurrPage.Close();
    end;

    local procedure NextStep(Backwards: Boolean)
    begin
        if Backwards then begin
            case Step of
                Step::Creation:
                    StartStep();
            end;
            Step := Step - 1
        end else begin
            case Step of
                Step::Start:
                    CreationStep();
                Step::Creation:
                    FinalStep();
            end;
            Step := Step + 1;
        end;
    end;

    local procedure StartStep()
    begin
        DisableAllControls();
        FirstStepVisible := true;
        NextActionEnabled := true;
    end;

    local procedure CreationStep()
    begin
        // If user clicked "Back", the Job will already exist, so don't try to create it again.
        if Rec."No." = '' then begin
            Rec.Insert(true);
            Commit();
        end;

        if not FromExistingJob then
            FinishAction();

        DisableAllControls();
        BackActionEnabled := true;
        NextActionEnabled := true;
        CreationStepVisible := true;
    end;

    local procedure FinalStep()
    var
        CopyJobTasks: Page "Copy Job Tasks";
    begin
        if Rec."No." = '' then begin
            Message(SelectJobNumberMsg);
            Step := Step - 1;
            exit;
        end;

        if SellToCustomerNo = '' then begin
            Message(SelectCustomerNumberMsg);
            Step := Step - 1;
            exit;
        end;

        Rec.SetHideValidationDialog(true);
        Rec.Validate("Sell-to Customer No.", SellToCustomerNo);
        CopyJobTasks.SetToJob(Rec);
        CopyJobTasks.Run();

        DisableAllControls();
        FinalStepVisible := true;
        FinishActionEnabled := true;
    end;

    local procedure DisableAllControls()
    begin
        FinishActionEnabled := false;
        BackActionEnabled := false;
        NextActionEnabled := false;
        FirstStepVisible := false;
        CreationStepVisible := false;
        FinalStepVisible := false;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;
}

