// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Projects.Resources.Resource;

page 376 "Job Journal Reconcile"
{
    Caption = 'Project Journal Reconcile';
    DataCaptionExpression = Caption();
    Editable = false;
    PageType = List;
    SourceTable = "Job Journal Quantity";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Work Type Code"; Rec."Work Type Code")
                {
                    ApplicationArea = Jobs;
                    ToolTip = 'Specifies which work type the resource applies to. Prices are updated based on this entry.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Jobs;
                    Style = Strong;
                    StyleExpr = Emphasize;
                    ToolTip = 'Specifies the project quantity to be reconciled.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FormatLine(Format(Rec."Unit of Measure Code"));
    end;

    trigger OnOpenPage()
    begin
        JobJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", Type, "No.", "Unit of Measure Code", "Work Type Code");
        if JobJnlLine.Find('-') then begin
            OldUnitOfMeasureCode := JobJnlLine."Unit of Measure Code";
            OldWorkTypeCode := JobJnlLine."Work Type Code";
            repeat
                if OldUnitOfMeasureCode <> JobJnlLine."Unit of Measure Code" then begin
                    InsertUnitOfMeasureQty();
                    InsertWorkTypeQty();
                end else
                    if OldWorkTypeCode <> JobJnlLine."Work Type Code" then
                        InsertWorkTypeQty();

                OldUnitOfMeasureCode := JobJnlLine."Unit of Measure Code";
                OldWorkTypeCode := JobJnlLine."Work Type Code";

                UnitOfMeasureQty := UnitOfMeasureQty + JobJnlLine.Quantity;
                WorkTypeQty := WorkTypeQty + JobJnlLine.Quantity;
                TotalQty := TotalQty + JobJnlLine.Quantity;
            until (JobJnlLine.Next() = 0);

            InsertUnitOfMeasureQty();
            InsertWorkTypeQty();
            Rec.Init();
            Rec."Is Total" := true;
            Rec."Unit of Measure Code" := '';
            Rec."Line Type" := Rec."Line Type"::Total;
            Rec."Work Type Code" := '';
            Rec.Quantity := TotalQty;
            Rec.Insert();

            TotalQty := 0;
        end;
    end;

    var
        JobJnlLine: Record "Job Journal Line";
        UnitOfMeasureQty: Decimal;
        WorkTypeQty: Decimal;
        TotalQty: Decimal;
        OldUnitOfMeasureCode: Text[10];
        OldWorkTypeCode: Code[10];
        Emphasize: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Total %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetJobJnlLine(var JobJnlLine2: Record "Job Journal Line")
    begin
        JobJnlLine2.TestField(Type, JobJnlLine2.Type::Resource);
        JobJnlLine.CopyFilters(JobJnlLine2);
        JobJnlLine.SetRange(Type, JobJnlLine2.Type::Resource);
        JobJnlLine.SetRange("No.", JobJnlLine2."No.");
    end;

    local procedure InsertUnitOfMeasureQty()
    begin
        Rec.Init();
        Rec."Is Total" := false;
        Rec."Unit of Measure Code" := OldUnitOfMeasureCode;
        Rec."Line Type" := Rec."Line Type"::Total;
        Rec."Work Type Code" := '';
        Rec.Quantity := UnitOfMeasureQty;
        Rec.Insert();
        UnitOfMeasureQty := 0;
    end;

    local procedure InsertWorkTypeQty()
    begin
        Rec.Init();
        Rec."Is Total" := false;
        Rec."Unit of Measure Code" := OldUnitOfMeasureCode;
        Rec."Line Type" := 0;
        Rec."Work Type Code" := OldWorkTypeCode;
        Rec.Quantity := WorkTypeQty;
        Rec.Insert();
        WorkTypeQty := 0;
    end;

    procedure Caption(): Text
    var
        Res: Record Resource;
    begin
        Res.Get(JobJnlLine.GetRangeMin("No."));
        exit(Res."No." + ' ' + Res.Name);
    end;

    local procedure FormatLine(Text: Text[1024])
    begin
        if Rec."Line Type" = Rec."Line Type"::Total then begin
            Emphasize := true;
            Text := StrSubstNo(Text000, Text);
        end;
    end;
}

