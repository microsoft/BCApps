// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 537 "Dimension Values"
{
    Caption = 'Dimension Values';
    DataCaptionFields = "Dimension Code";
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Dimension Value";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = NameIndent;
                IndentationControls = Name;
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    Visible = false;
                    ToolTip = 'Specifies the code for the dimension.';
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Dimensions;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the code for the dimension value.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = Dimensions;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies a descriptive name for the dimension value.';
                }
                field("Dimension Value Type"; Rec."Dimension Value Type")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the purpose of the dimension value.';

                    trigger OnValidate()
                    begin
                        FormatLine();
                    end;
                }
                field(Totaling; Rec.Totaling)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies an account interval or a list of account numbers. The entries of the account will be totaled to give a total balance. How entries are totaled depends on the value in the Account Type field.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DimVal: Record "Dimension Value";
                        DimValList: Page "Dimension Value List";
                    begin
                        DimVal := Rec;
                        DimVal.SetRange("Dimension Code", Rec."Dimension Code");
                        DimValList.SetTableView(DimVal);
                        DimValList.LookupMode := true;
                        if DimValList.RunModal() = ACTION::LookupOK then begin
                            DimValList.GetRecord(DimVal);
                            Text := DimVal.Code;
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example a customer that is declared insolvent or an item that is placed in quarantine.';
                }
                field("Map-to IC Dimension Value Code"; Rec."Map-to IC Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies which intercompany dimension value corresponds to the dimension value on the line.';
                    Visible = false;
                }
                field("Consolidation Code"; Rec."Consolidation Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code that is used for consolidation.';
                    Visible = false;
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
                action("Indent Dimension Values")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Indent Dimension Values';
                    Image = Indent;
                    RunObject = Codeunit "Dimension Value-Indent";
                    RunPageOnRec = true;
                    ToolTip = 'Indent dimension values between a Begin-Total and the matching End-Total one level to make the list easier to read.';
                }

                action("Where-Used List")
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Where-Used List';
                    Image = Indent;
                    RunObject = page "Default Dimension Where-Used";
                    RunPageLink = "Dimension Code" = field("Dimension Code"), "Dimension Value Code" = field(Code);
                    ToolTip = 'View all the records where the dimension value is used as a default dimension. Note that default dimensions can only be assigned to record types, such as item, customer, and other master data cards and to selected other records, such as salespeople and fixed assets. Default dimensions cannot be assigned to documents or journal lines.';

                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        FormatLine();
    end;

    trigger OnAfterGetRecord()
    begin
        FormatLine();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        FormatLine();
    end;

    trigger OnOpenPage()
    var
        DimensionCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnOpenPage(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec.GetFilter("Dimension Code") <> '' then
            DimensionCode := Rec.GetRangeMin("Dimension Code");
        if DimensionCode <> '' then begin
            Rec.FilterGroup(2);
            Rec.SetRange("Dimension Code", DimensionCode);
            Rec.FilterGroup(0);
        end;
    end;

    var
        Emphasize: Boolean;
        NameIndent: Integer;

    local procedure FormatLine()
    begin
        Emphasize := Rec."Dimension Value Type" <> Rec."Dimension Value Type"::Standard;
        NameIndent := Rec.Indentation;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnOpenPage(var DimensionValue: Record "Dimension Value"; var IsHandled: Boolean)
    begin
    end;
}
