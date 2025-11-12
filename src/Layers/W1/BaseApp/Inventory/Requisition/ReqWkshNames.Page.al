// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

page 295 "Req. Wksh. Names"
{
    Caption = 'Req. Wksh. Names';
    DataCaptionExpression = DataCaption();
    PageType = List;
    SourceTable = "Requisition Wksh. Name";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the name of the requisition worksheet you are creating.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a brief description of the requisition worksheet name you are creating.';
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
        area(processing)
        {
            action("Edit Worksheet")
            {
                ApplicationArea = Planning;
                Caption = 'Edit Worksheet';
                Image = OpenWorksheet;
                ShortCutKey = 'Return';
                ToolTip = 'Make the worksheet lines editable.';

                trigger OnAction()
                begin
                    ReqJnlManagement.TemplateSelectionFromBatch(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Edit Worksheet_Promoted"; "Edit Worksheet")
                {
                }
            }
        }
    }

    trigger OnInit()
    begin
        Rec.SetRange("Worksheet Template Name");
    end;

    trigger OnOpenPage()
    begin
        ReqJnlManagement.OpenJnlBatch(Rec);
    end;

    var
        ReqJnlManagement: Codeunit ReqJnlManagement;

    local procedure DataCaption(): Text[250]
    var
        ReqWkshTmpl: Record "Req. Wksh. Template";
    begin
        if not CurrPage.LookupMode then
            if Rec.GetFilter("Worksheet Template Name") <> '' then
                if Rec.GetRangeMin("Worksheet Template Name") = Rec.GetRangeMax("Worksheet Template Name") then
                    if ReqWkshTmpl.Get(Rec.GetRangeMin("Worksheet Template Name")) then
                        exit(ReqWkshTmpl.Name + ' ' + ReqWkshTmpl.Description);
    end;
}

