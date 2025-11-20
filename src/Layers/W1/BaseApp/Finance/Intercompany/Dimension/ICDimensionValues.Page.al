// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Dimension;

page 601 "IC Dimension Values"
{
    Caption = 'Intercompany Dimension Values';
    DataCaptionFields = "Dimension Code";
    PageType = List;
    SourceTable = "IC Dimension Value";
    RefreshOnActivate = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the intercompany dimension value.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the name of the intercompany dimension value.';
                }
                field("Dimension Value Type"; Rec."Dimension Value Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the intercompany dimension value type.';
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Map-to Dimension Value Code"; Rec."Map-to Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which dimension value corresponds to the intercompany dimension value on the line.';
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
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(CopyFromDimensionValues)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Copy from Dimension Values';
                    Image = CopyDimensions;
                    RunPageMode = View;
                    ToolTip = 'Creates intercompany dimension values from existing dimension values.';

                    trigger OnAction()
                    var
                        ICDimValuesSelector: Page "IC Dim Values Selector";
                    begin
                        ICDimValuesSelector.SetDimensionCode(DimensionCode);
                        ICDimValuesSelector.Run();
                    end;
                }
                action("Indent IC Dimension Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Indent IC Dimension Values';
                    Image = Indent;
                    ToolTip = 'Indent the names of all dimension values between each set of Begin-Total and End-Total dimension values. It will also enter a totaling interval for each End-Total dimension value.';

                    trigger OnAction()
                    var
                        ICDimensionValueIndent: Codeunit "IC Dimension Value-Indent";
                    begin
                        ICDimensionValueIndent.Run(Rec);
                        CurrPage.Update();
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';
                actionref(CopyFromDimensionValues_Promoted; CopyFromDimensionValues)
                {
                }
                actionref("Indent IC Dimension Values_Promoted"; "Indent IC Dimension Values")
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Dimension Code", DimensionCode);
    end;

    trigger OnAfterGetRecord()
    begin
        NameIndent := 0;
        NameIndent := Rec.Indentation;
    end;

    var
        NameIndent: Integer;
        DimensionCode: Code[20];

    procedure SetDimensionCode(DimCode: Code[20])
    begin
        DimensionCode := DimCode;
    end;
}
