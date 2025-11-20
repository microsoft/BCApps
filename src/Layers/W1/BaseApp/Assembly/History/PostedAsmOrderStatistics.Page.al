// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Assembly.Costing;

page 923 "Posted Asm. Order Statistics"
{
    Caption = 'Posted Asm. Order Statistics';
    DataCaptionFields = "No.", Description;
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "Posted Assembly Header";

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                fixed(Control1903895301)
                {
                    ShowCaption = false;
                    group("Standard Cost")
                    {
                        Caption = 'Standard Cost';
                        field(StdMatCost; Value[ColIdx::StdCost, RowIdx::MatCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Caption = 'Material Cost';
                            Editable = false;
                            ToolTip = 'Specifies the material cost amount of all assembly order lines of type Item in the assembly order.';
                        }
                        field(StdResCost; Value[ColIdx::StdCost, RowIdx::ResCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Caption = 'Resource Cost';
                            Editable = false;
                            ToolTip = 'Specifies the material cost amount of all assembly order lines of type Resource in the assembly order.';
                        }
                        field(StdResOvhd; Value[ColIdx::StdCost, RowIdx::ResOvhd])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Caption = 'Resource Overhead';
                            Editable = false;
                            ToolTip = 'Specifies the resource overhead amount of all assembly order lines of type Resource.';
                        }
                        field(StdAsmOvhd; Value[ColIdx::StdCost, RowIdx::AsmOvhd])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Caption = 'Assembly Overhead';
                            Editable = false;
                            ToolTip = 'Specifies the overhead amount of the entire posted assembly order.';
                        }
                        field(StdTotalCost; Value[ColIdx::StdCost, RowIdx::Total])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Caption = 'Total Cost';
                            Editable = false;
                            ToolTip = 'Specifies the sum of the lines in each column.';
                        }
                    }
                    group("Expected Cost")
                    {
                        Caption = 'Expected Cost';
                        field(ExpMatCost; Value[ColIdx::ExpCost, RowIdx::MatCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ExpResCost; Value[ColIdx::ExpCost, RowIdx::ResCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ExpResOvhd; Value[ColIdx::ExpCost, RowIdx::ResOvhd])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ExpAsmOvhd; Value[ColIdx::ExpCost, RowIdx::AsmOvhd])
                        {
                            ApplicationArea = Assembly;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ExpTotalCost; Value[ColIdx::ExpCost, RowIdx::Total])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group("Actual Cost")
                    {
                        Caption = 'Actual Cost';
                        field(ActMatCost; Value[ColIdx::ActCost, RowIdx::MatCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ActResCost; Value[ColIdx::ActCost, RowIdx::ResCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ActResOvhd; Value[ColIdx::ActCost, RowIdx::ResOvhd])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                            ToolTip = 'Specifies the actual overhead cost of the resource.';
                        }
                        field(ActAsmOvhd; Value[ColIdx::ActCost, RowIdx::AsmOvhd])
                        {
                            ApplicationArea = Assembly;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(ActTotalCost; Value[ColIdx::ActCost, RowIdx::Total])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group("Dev. %")
                    {
                        Caption = 'Dev. %';
                        field(DevMatCost; Value[ColIdx::Dev, RowIdx::MatCost])
                        {
                            ApplicationArea = Assembly;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(DevResCost; Value[ColIdx::Dev, RowIdx::ResCost])
                        {
                            ApplicationArea = Assembly;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(DevResOvhd; Value[ColIdx::Dev, RowIdx::ResOvhd])
                        {
                            ApplicationArea = Assembly;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(DevAsmOvhd; Value[ColIdx::Dev, RowIdx::AsmOvhd])
                        {
                            ApplicationArea = Assembly;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(DevTotalCost; Value[ColIdx::Dev, RowIdx::Total])
                        {
                            ApplicationArea = Assembly;
                            DecimalPlaces = 0 : 5;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                    group(Variance)
                    {
                        Caption = 'Variance';
                        field(VarMatCost; Value[ColIdx::"Var", RowIdx::MatCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(VarResCost; Value[ColIdx::"Var", RowIdx::ResCost])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(VarResOvhd; Value[ColIdx::"Var", RowIdx::ResOvhd])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(VarAsmOvhd; Value[ColIdx::"Var", RowIdx::AsmOvhd])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                        field(VarTotalCost; Value[ColIdx::"Var", RowIdx::Total])
                        {
                            ApplicationArea = Assembly;
                            AutoFormatType = 1;
                            Editable = false;
                            ShowCaption = false;
                        }
                    }
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        Rec.TestField("Item No.");
    end;

    trigger OnAfterGetRecord()
    var
        CalculateAssemblyCost: Codeunit "Calculate Assembly Cost";
    begin
        Clear(Value);
        CalculateAssemblyCost.CalcPostedAsmOrderStatistics(Rec, Value);
    end;

    var
        Value: array[5, 5] of Decimal;
        ColIdx: Option ,StdCost,ExpCost,ActCost,Dev,"Var";
        RowIdx: Option ,MatCost,ResCost,ResOvhd,AsmOvhd,Total;
}
