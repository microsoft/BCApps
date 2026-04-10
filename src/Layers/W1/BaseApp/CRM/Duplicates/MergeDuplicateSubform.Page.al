// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Duplicates;

page 703 "Merge Duplicate Subform"
{
    Caption = 'Merge Duplicate Subform';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Merge Duplicates Line Buffer";
    SourceTableTemporary = true;
    SourceTableView = sorting("In Primary Key");

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Rec."In Primary Key" = Rec."In Primary Key"::Yes;
                    Visible = IsTableLine;
                }
                field("Table Name"; Rec."Table Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Style = Strong;
                    StyleExpr = Rec."In Primary Key" = Rec."In Primary Key"::Yes;
                    Visible = IsTableLine;
                }
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    StyleExpr = StyleExpr;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Field Name';
                    Editable = false;
                    StyleExpr = StyleExpr;
                }
                field("Data Type"; Rec."Data Type")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = not IsTableLine;
                }
                field("In Primary Key"; Rec."In Primary Key")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                }
                field("Current Value"; Rec."Current Value")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = not IsTableLine;
                }
                field("Current Count"; Rec."Current Count")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = IsTableLine;
                }
                field(Override; Rec.Override)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = IsOverrideEnabled;
                    ToolTip = 'Specifies if the field value of the current record should be overridden by the value of the duplicate record. ';
                    Visible = not IsTableLine;

                    trigger OnValidate()
                    begin
                        SetStyle();
                        CurrPage.Update();
                    end;
                }
                field("Duplicate Value"; Rec."Duplicate Value")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Alternate Value';
                    Editable = IsFieldEditable;
                    Style = Strong;
                    StyleExpr = Rec.Override or Rec.Modified;
                    Visible = not IsTableLine;

                    trigger OnValidate()
                    begin
                        SetStyle();
                        CurrPage.Update();
                    end;
                }
                field("Duplicate Count"; Rec."Duplicate Count")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Visible = IsTableLine;
                }
                field(Conflicts; Rec.Conflicts)
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = true;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = Rec.Conflicts > 0;
                    Visible = IsTableLine;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Can Be Renamed" then begin
            IsFieldEditable := not Rec.HasFieldToOverride();
            IsOverrideEnabled := false;
        end else begin
            IsOverrideEnabled := not Rec.HasModifiedField();
            IsFieldEditable := false;
        end;
    end;

    trigger OnAfterGetRecord()
    begin
        IsTableLine := Rec.Type = Rec.Type::Table;
        SetStyle();
    end;

    var
        StyleExpr: Text;
        IsTableLine: Boolean;
        IsFieldEditable: Boolean;
        IsOverrideEnabled: Boolean;

    procedure Set(var TempMergeDuplicatesLineBuffer: Record "Merge Duplicates Line Buffer" temporary)
    begin
        Rec.Copy(TempMergeDuplicatesLineBuffer, true);
        Rec.FilterGroup(2);
        TempMergeDuplicatesLineBuffer.CopyFilter(Type, Rec.Type);
        Rec.FilterGroup(0);
        if Rec.FindFirst() then;
    end;

    local procedure SetStyle()
    begin
        if Rec.Override then
            StyleExpr := 'StrongAccent'
        else
            if Rec."In Primary Key" = Rec."In Primary Key"::Yes then
                if Rec.Modified then
                    StyleExpr := 'Attention'
                else
                    StyleExpr := 'Strong'
            else
                StyleExpr := 'Standard';
    end;
}

