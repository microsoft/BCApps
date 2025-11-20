// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

page 2586 "Dim Corr Find by Dimension"
{
    PageType = Worksheet;
    SourceTable = "Dimension Set Entry";
    SourceTableTemporary = true;
    Caption = 'Find by Dimension';
    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = All;
                    TableRelation = Dimension.Code;
                    Caption = 'Dimension Code';
                    ToolTip = 'Specifies the code of the dimension.';
                }

                field("Dimension Value Code"; DimensionValueCode)
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Value Code';
                    TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
                    ToolTip = 'Specifies the value code of the dimension.';

                    trigger OnValidate()
                    begin
                        Rec."Dimension Value Code" := DimensionValueCode;
                    end;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        // Don't run trigger
        Rec.Insert();
        exit(false);
    end;

    procedure GetRecords(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary)
    begin
        if not Rec.FindFirst() then
            exit;

        repeat
            TempDimensionSetEntry.TransferFields(Rec, true);
            TempDimensionSetEntry.Insert();
        until Rec.Next() = 0;
    end;

    var
        DimensionValueCode: Code[20];
}
