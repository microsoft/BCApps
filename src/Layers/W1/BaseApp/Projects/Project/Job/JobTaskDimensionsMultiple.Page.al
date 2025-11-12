// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Finance.Dimension;

page 1006 "Job Task Dimensions Multiple"
{
    Caption = 'Project Task Dimensions Multiple';
    PageType = List;
    SourceTable = "Job Task Dimension";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension that the dimension value filter will be linked to. To select a dimension codes, which are set up in the Dimensions window, click the drop-down arrow in the field.';

                    trigger OnValidate()
                    begin
                        if (xRec."Dimension Code" <> '') and (xRec."Dimension Code" <> Rec."Dimension Code") then
                            Error(Text000, Rec.TableCaption);
                    end;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the dimension value that the dimension value filter will be linked to. To select a value code, which are set up in the Dimensions window, choose the drop-down arrow in the field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DimensionValueCodeOnFormat(Format(Rec."Dimension Value Code"));
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec."Multiple Selection Action" := Rec."Multiple Selection Action"::Delete;
        Rec.Modify();
        exit(false);
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Rec.SetRange("Dimension Code", Rec."Dimension Code");
        if not Rec.Find('-') and (Rec."Dimension Code" <> '') then begin
            Rec."Multiple Selection Action" := Rec."Multiple Selection Action"::Change;
            Rec.Insert();
        end;
        Rec.SetRange("Dimension Code");
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Rec."Multiple Selection Action" := Rec."Multiple Selection Action"::Change;
        Rec.Modify();
        exit(false);
    end;

    trigger OnOpenPage()
    begin
        GetDefaultDim();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction = ACTION::LookupOK then
            LookupOKOnPush();
    end;

    var
        TempJobTaskDim2: Record "Job Task Dimension" temporary;
        TempJobTaskDim3: Record "Job Task Dimension" temporary;
        TempJobTask: Record "Job Task" temporary;
        TotalRecNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
        Text001: Label '(Conflict)';
#pragma warning restore AA0074

    local procedure SetCommonJobTaskDim()
    var
        JobTaskDim: Record "Job Task Dimension";
    begin
        Rec.SetRange("Multiple Selection Action", Rec."Multiple Selection Action"::Delete);
        if Rec.Find('-') then
            repeat
                if TempJobTaskDim3.Find('-') then
                    repeat
                        if JobTaskDim.Get(TempJobTaskDim3."Job No.", TempJobTaskDim3."Job Task No.", Rec."Dimension Code")
                        then
                            JobTaskDim.Delete(true);
                    until TempJobTaskDim3.Next() = 0;
            until Rec.Next() = 0;
        Rec.SetRange("Multiple Selection Action", Rec."Multiple Selection Action"::Change);
        if Rec.Find('-') then
            repeat
                if TempJobTaskDim3.Find('-') then
                    repeat
                        if JobTaskDim.Get(TempJobTaskDim3."Job No.", TempJobTaskDim3."Job Task No.", Rec."Dimension Code")
                        then begin
                            JobTaskDim."Dimension Code" := Rec."Dimension Code";
                            JobTaskDim."Dimension Value Code" := Rec."Dimension Value Code";
                            JobTaskDim.Modify(true);
                        end else begin
                            JobTaskDim.Init();
                            JobTaskDim."Job No." := TempJobTaskDim3."Job No.";
                            JobTaskDim."Job Task No." := TempJobTaskDim3."Job Task No.";
                            JobTaskDim."Dimension Code" := Rec."Dimension Code";
                            JobTaskDim."Dimension Value Code" := Rec."Dimension Value Code";
                            JobTaskDim.Insert(true);
                        end;
                    until TempJobTaskDim3.Next() = 0;
            until Rec.Next() = 0;
    end;

    procedure SetMultiJobTask(var JobTask: Record "Job Task")
    begin
        TempJobTaskDim2.DeleteAll();
        TempJobTask.DeleteAll();
        if JobTask.Find('-') then
            repeat
                CopyJobTaskDimToJobTaskDim(JobTask."Job No.", JobTask."Job Task No.");
                TempJobTask.TransferFields(JobTask);
                TempJobTask.Insert();
            until JobTask.Next() = 0;
    end;

    local procedure CopyJobTaskDimToJobTaskDim(JobNo: Code[20]; JobTaskNo: Code[20])
    var
        JobTaskDim: Record "Job Task Dimension";
    begin
        TotalRecNo := TotalRecNo + 1;
        TempJobTaskDim3."Job No." := JobNo;
        TempJobTaskDim3."Job Task No." := JobTaskNo;
        TempJobTaskDim3.Insert();

        JobTaskDim.SetRange("Job No.", JobNo);
        JobTaskDim.SetRange("Job Task No.", JobTaskNo);
        if JobTaskDim.Find('-') then
            repeat
                TempJobTaskDim2 := JobTaskDim;
                TempJobTaskDim2.Insert();
            until JobTaskDim.Next() = 0;
    end;

    local procedure GetDefaultDim()
    var
        Dim: Record Dimension;
        RecNo: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if Dim.Find('-') then
            repeat
                RecNo := 0;
                TempJobTaskDim2.SetRange("Dimension Code", Dim.Code);
                Rec.SetRange("Dimension Code", Dim.Code);
                if TempJobTaskDim2.Find('-') then
                    repeat
                        if Rec.Find('-') then begin
                            if Rec."Dimension Value Code" <> TempJobTaskDim2."Dimension Value Code" then
                                if (Rec."Multiple Selection Action" <> 10) and
                                   (Rec."Multiple Selection Action" <> 21)
                                then begin
                                    Rec."Multiple Selection Action" :=
                                      Rec."Multiple Selection Action" + 10;
                                    Rec."Dimension Value Code" := '';
                                end;
                            Rec.Modify();
                            RecNo := RecNo + 1;
                        end else begin
                            Rec := TempJobTaskDim2;
                            Rec.Insert();
                            RecNo := RecNo + 1;
                        end;
                    until TempJobTaskDim2.Next() = 0;

                if Rec.Find('-') and (RecNo <> TotalRecNo) then
                    if (Rec."Multiple Selection Action" <> 10) and
                       (Rec."Multiple Selection Action" <> 21)
                    then begin
                        Rec."Multiple Selection Action" :=
                          Rec."Multiple Selection Action" + 10;
                        Rec."Dimension Value Code" := '';
                        Rec.Modify();
                    end;
            until Dim.Next() = 0;

        Rec.Reset();
        Rec.SetCurrentKey("Dimension Code");
        Rec.SetFilter("Multiple Selection Action", '<>%1', Rec."Multiple Selection Action"::Delete)
    end;

    local procedure LookupOKOnPush()
    begin
        SetCommonJobTaskDim();
    end;

    local procedure DimensionValueCodeOnFormat(Text: Text[1024])
    begin
        if Rec."Dimension Code" <> '' then
            if (Rec."Multiple Selection Action" = 10) or
               (Rec."Multiple Selection Action" = 21)
            then
                Text := Text001;
    end;
}

