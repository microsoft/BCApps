// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Configuration.SourceConfiguration;

using Microsoft.QualityManagement.Document;

/// <summary>
/// Used to visually configure in a part which source field a target field in the inspection maps to.
/// </summary>
page 20411 "Qlty. Source Config Line Part"
{
    AutoSplitKey = true;
    Caption = 'Quality Inspection Source Details';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    ShowFilter = false;
    SourceTable = "Qlty. Inspect. Src. Fld. Conf.";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            repeater(GroupLines)
            {
                ShowCaption = false;

                field("From Field No."; Rec."From Field No.")
                {
                    Visible = false;
                }
                field("From Field Name"; Rec."From Field Name")
                {
                    AssistEdit = true;
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        Rec.HandleOnLookupFromField();
                    end;
                }
                field("To Type"; Rec."To Type")
                {
                }
                field("To Field No."; Rec."To Field No.")
                {
                    Visible = false;
                }
                field("To Field Name"; Rec."To Field Name")
                {
                    AssistEdit = true;
                    ShowMandatory = true;

                    trigger OnAssistEdit()
                    begin
                        Rec.HandleOnLookupToField();
                    end;
                }
                field("Display As"; Rec."Display As")
                {
                }
                field("Priority Test"; Rec."Priority Test")
                {
                    Visible = false;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        QltyInspectSourceConfig: Record "Qlty. Inspect. Source Config.";
    begin
        if not QltyInspectSourceConfig.Get(Rec.Code) then
            exit;

        Rec."From Table No." := QltyInspectSourceConfig."From Table No.";
        Rec."To Table No." := QltyInspectSourceConfig."To Table No.";
        if QltyInspectSourceConfig."To Type" = QltyInspectSourceConfig."To Type"::Inspection then begin
            Rec."To Type" := Rec."To Type"::Inspection;
            Rec."To Table No." := Database::"Qlty. Inspection Header";
        end;
    end;
}
