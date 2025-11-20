// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

page 5993 "Troubleshooting Setup"
{
    Caption = 'Troubleshooting Setup';
    DataCaptionFields = "No.";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Troubleshooting Setup";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Type; Rec.Type)
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the type of troubleshooting issue.';
                    Visible = TypeVisible;
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                    Visible = NoVisible;
                }
                field("Troubleshooting No."; Rec."Troubleshooting No.")
                {
                    ApplicationArea = Service;
                    ToolTip = 'Specifies the number of the troubleshooting issue.';
                }
                field("Troubleshooting Description"; Rec."Troubleshooting Description")
                {
                    ApplicationArea = Service;
                    DrillDown = false;
                    ToolTip = 'Specifies a description of the troubleshooting issue.';
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
        area(navigation)
        {
            group("T&roublesh.")
            {
                Caption = 'T&roublesh.';
                Image = Setup;
                action(Card)
                {
                    ApplicationArea = Service;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the record on the document or journal line.';

                    trigger OnAction()
                    begin
                        Clear(Tblshtg);
                        if TblshtgHeader.Get(Rec."Troubleshooting No.") then
                            if Rec."No." <> '' then begin
                                if Format(Rec.Type) <> '' then
                                    Tblshtg.SetPageCaptionPrefix(Format(Rec.Type) + ' ' + Rec."No.");
                                Tblshtg.SetRecord(TblshtgHeader);
                            end;

                        Tblshtg.Run();
                    end;
                }
            }
        }
    }

    trigger OnInit()
    begin
        NoVisible := true;
        TypeVisible := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Validate(Type, RecType);
        Rec.Validate("No.", No);
    end;

    trigger OnOpenPage()
    begin
        TypeVisible := Rec.GetFilter(Type) = '';
        NoVisible := Rec.GetFilter("No.") = '';

        if (Rec.GetFilter(Type) <> '') and (Rec.GetFilter("No.") <> '') then begin
            RecType := Rec.GetRangeMin(Type);
            No := Rec.GetRangeMin("No.");
        end;
    end;

    var
        TblshtgHeader: Record "Troubleshooting Header";
        Tblshtg: Page Troubleshooting;
        TypeVisible: Boolean;
        NoVisible: Boolean;
        RecType: Enum "Troubleshooting Item Type";
        No: Code[20];
}

