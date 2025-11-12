// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

using Microsoft.Foundation.AuditCodes;

page 543 "Default Dimension Priorities"
{
    ApplicationArea = Dimensions;
    Caption = 'Default Dimension Priorities';
    DelayedInsert = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Default Dimension Priority";
    SourceTableView = sorting("Source Code", Priority);
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrentSourceCode; CurrentSourceCode)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Source Code';
                    Lookup = true;
                    TableRelation = "Source Code".Code;
                    ToolTip = 'Specifies the source.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        CurrPage.SaveRecord();
                        LookupSourceCode(CurrentSourceCode, Rec);
                        CurrPage.Update(false);
                    end;

                    trigger OnValidate()
                    var
                        SourceCode: Record "Source Code";
                    begin
                        SourceCode.Get(CurrentSourceCode);
                        CurrentSourceCodeOnAfterValida();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the table ID for the account type, if you want to prioritize an account type.';

                    trigger OnValidate()
                    begin
                        TableIDOnAfterValidate();
                    end;
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = Dimensions;
                    DrillDown = false;
                    ToolTip = 'Specifies the table name for the account type you wish to prioritize.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the priority of an account type, with the highest priority being 1.';

                    trigger OnValidate()
                    begin
                        PriorityOnAfterValidate();
                    end;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Initialize)
            {
                ApplicationArea = All;
                Caption = 'Initialize Dimension Priorities';
                ToolTip = 'Initialize Default Dimension Priorities for Source Code.';
                Image = SetPriorities;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Rec.InitializeDefaultDimPrioritiesForSourceCode();
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        PriorityOnFormat(Format(Rec.Priority));
    end;

    trigger OnOpenPage()
    begin
        if Rec."Source Code" <> '' then
            CurrentSourceCode := Rec."Source Code";

        OpenSourceCode(CurrentSourceCode, Rec);
    end;

    var
#pragma warning disable AA0074
        Text000: Label '<auto>';
        Text001: Label 'You need to define a source code.';
#pragma warning restore AA0074
        CurrentSourceCode: Code[20];

    local procedure OpenSourceCode(var CurrentSourceCode: Code[20]; var DefaultDimPriority: Record "Default Dimension Priority")
    begin
        CheckSourceCode(CurrentSourceCode);
        DefaultDimPriority.FilterGroup := 2;
        DefaultDimPriority.SetRange("Source Code", CurrentSourceCode);
        DefaultDimPriority.FilterGroup := 0;
    end;

    local procedure CheckSourceCode(var CurrentSourceCode: Code[20])
    var
        SourceCode: Record "Source Code";
    begin
        if not SourceCode.Get(CurrentSourceCode) then
            if SourceCode.FindFirst() then
                CurrentSourceCode := SourceCode.Code
            else
                Error(Text001);
    end;

    procedure SetSourceCode(CurrentSourceCode: Code[20]; var DefaultDimPriority: Record "Default Dimension Priority")
    begin
        DefaultDimPriority.FilterGroup := 2;
        DefaultDimPriority.SetRange("Source Code", CurrentSourceCode);
        DefaultDimPriority.FilterGroup := 0;
        if DefaultDimPriority.Find('-') then;
    end;

    local procedure LookupSourceCode(var CurrentSourceCode: Code[20]; var DefaultDimPriority: Record "Default Dimension Priority")
    var
        SourceCode: Record "Source Code";
    begin
        Commit();
        SourceCode.Code := DefaultDimPriority.GetRangeMax("Source Code");
        if PAGE.RunModal(0, SourceCode) = ACTION::LookupOK then begin
            CurrentSourceCode := SourceCode.Code;
            SetSourceCode(CurrentSourceCode, DefaultDimPriority);
        end;
    end;

    local procedure TableIDOnAfterValidate()
    begin
        Rec.CalcFields("Table Caption");
    end;

    local procedure PriorityOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure CurrentSourceCodeOnAfterValida()
    begin
        CurrPage.SaveRecord();
        SetSourceCode(CurrentSourceCode, Rec);
        CurrPage.Update(false);
    end;

    local procedure PriorityOnFormat(Text: Text[1024])
    begin
        if Rec.Priority = 0 then
            Text := Text000;
    end;
}

