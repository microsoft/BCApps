// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 577 "Change Global Dimensions"
{
    Caption = 'Change Global Dimensions';
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    ShowFilter = false;
    SourceTable = "Change Global Dim. Header";

    layout
    {
        area(content)
        {
            group(Options)
            {
                Caption = 'Options';
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = IsGlobalDimCodeEnabled;
                    StyleExpr = CurrGlobalDimCodeStyle1;
                    TableRelation = Dimension;
                    ToolTip = 'Specifies another global dimension that you want to use. The second field on the row will show the current global dimension.';

                    trigger OnValidate()
                    begin
                        IsPrepareEnabledFlag := ChangeGlobalDimensions.IsPrepareEnabled(Rec);
                        SetStyle();
                        CurrPage.Update(true);
                    end;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Editable = IsGlobalDimCodeEnabled;
                    StyleExpr = CurrGlobalDimCodeStyle2;
                    TableRelation = Dimension;
                    ToolTip = 'Specifies another global dimension that you want to use. The second field on the row will show the current global dimension.';

                    trigger OnValidate()
                    begin
                        IsPrepareEnabledFlag := ChangeGlobalDimensions.IsPrepareEnabled(Rec);
                        SetStyle();
                        CurrPage.Update(true);
                    end;
                }
                field("Parallel Processing"; Rec."Parallel Processing")
                {
                    ApplicationArea = Dimensions;
                    Enabled = IsGlobalDimCodeEnabled and IsParallelProcessingAllowed;
                    ToolTip = 'Specifies if the change will be processed by parallel background jobs.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Old Global Dimension 1 Code"; Rec."Old Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = false;
                    ShowCaption = false;
                    StyleExpr = CurrGlobalDimCodeStyle1;
                    ToolTip = 'Specifies the dimension that is currently defined as Global Dimension 1.';
                }
                field("Old Global Dimension 2 Code"; Rec."Old Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    Enabled = false;
                    ShowCaption = false;
                    StyleExpr = CurrGlobalDimCodeStyle2;
                    ToolTip = 'Specifies the dimension that is currently defined as Global Dimension 2.';
                }
                label(Control16)
                {
                    ApplicationArea = Dimensions;
                    Enabled = false;
                    ShowCaption = false;
                    Caption = '';
                }
            }
            part(LogLines; "Change Global Dim. Log Entries")
            {
                ApplicationArea = Dimensions;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Sequential)
            {
                Caption = 'Sequential';
                action(StartSequential)
                {
                    AccessByPermission = TableData "Change Global Dim. Log Entry" = IMD;
                    ApplicationArea = Dimensions;
                    Caption = 'Start';
                    Enabled = IsPrepareEnabledFlag and not Rec."Parallel Processing";
                    Image = Start;
                    ToolTip = 'Start the process that implements the specified dimension change(s) in the affected tables within the current session. Other users cannot change the affected tables while the process is running.';

                    trigger OnAction()
                    begin
                        ChangeGlobalDimensions.StartSequential();
                    end;
                }
            }
            group(Parallel)
            {
                Caption = 'Parallel';
                action(Prepare)
                {
                    AccessByPermission = TableData "Change Global Dim. Log Entry" = IM;
                    ApplicationArea = Dimensions;
                    Caption = 'Prepare';
                    Enabled = IsPrepareEnabledFlag and Rec."Parallel Processing";
                    Image = ChangeBatch;
                    ToolTip = 'Fill the Log Entries FastTab with the list of tables that will be affected by the specified dimension change. Here you can also follow the progress of the background job that performs the change. Note: Before you can start the job, you must sign out and in to ensure that the current user cannot modify the tables that are being updated.';

                    trigger OnAction()
                    begin
                        ChangeGlobalDimensions.Prepare();
                    end;
                }
                action(Reset)
                {
                    AccessByPermission = TableData "Change Global Dim. Log Entry" = D;
                    ApplicationArea = Dimensions;
                    Caption = 'Reset';
                    Enabled = IsStartEnabled and Rec."Parallel Processing";
                    Image = Cancel;
                    ToolTip = 'Cancel the change.';

                    trigger OnAction()
                    begin
                        ChangeGlobalDimensions.ResetState();
                    end;
                }
                action(Start)
                {
                    AccessByPermission = TableData "Change Global Dim. Log Entry" = MD;
                    ApplicationArea = Dimensions;
                    Caption = 'Start';
                    Enabled = IsStartEnabled and Rec."Parallel Processing";
                    Image = Start;
                    ToolTip = 'Start a background job that implements the specified dimension change(s) in the affected tables. Other users cannot change the affected global dimensions while the job is running. Note: Before you can start the job, you must choose the Prepare action, and then sign out and in.';

                    trigger OnAction()
                    begin
                        ChangeGlobalDimensions.Start();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Sequential', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(StartSequential_Promoted; StartSequential)
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Parallel', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(Prepare_Promoted; Prepare)
                {
                }
                actionref(Reset_Promoted; Reset)
                {
                }
                actionref(Start_Promoted; Start)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.RefreshCurrentDimCodes();
        ChangeGlobalDimensions.FillBuffer();
        IsGlobalDimCodeEnabled := ChangeGlobalDimensions.IsDimCodeEnabled();
        IsPrepareEnabledFlag := ChangeGlobalDimensions.IsPrepareEnabled(Rec);
        IsStartEnabled := ChangeGlobalDimensions.IsStartEnabled();
        IsParallelProcessingAllowed := TASKSCHEDULER.CanCreateTask();
        SetStyle();
    end;

    trigger OnClosePage()
    begin
        ChangeGlobalDimensions.RemoveHeader();
    end;

    trigger OnOpenPage()
    begin
        ChangeGlobalDimensions.ResetIfAllCompleted();
    end;

    var
        ChangeGlobalDimensions: Codeunit "Change Global Dimensions";
        CurrGlobalDimCodeStyle1: Text;
        CurrGlobalDimCodeStyle2: Text;
        IsGlobalDimCodeEnabled: Boolean;
        IsPrepareEnabledFlag: Boolean;
        IsStartEnabled: Boolean;
        IsParallelProcessingAllowed: Boolean;

    local procedure SetStyle()
    begin
        SetAmbiguousStyle(CurrGlobalDimCodeStyle1, Rec."Old Global Dimension 1 Code" <> Rec."Global Dimension 1 Code");
        SetAmbiguousStyle(CurrGlobalDimCodeStyle2, Rec."Old Global Dimension 2 Code" <> Rec."Global Dimension 2 Code");
    end;

    local procedure SetAmbiguousStyle(var Style: Text; Modified: Boolean)
    begin
        if Modified then
            Style := 'Ambiguous'
        else
            Style := '';
    end;
}

