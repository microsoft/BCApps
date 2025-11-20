// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

page 258 "Cons. for Business Units"
{
    SourceTable = "Bus. Unit In Cons. Process";
    Caption = 'Consolidations for Business Units';
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DataCaptionExpression = Caption();

    layout
    {
        area(Content)
        {
            repeater(ConsolidationProcesses)
            {
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = All;
                    Caption = 'Business Unit Code';
                    ToolTip = 'Specifies the business unit.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Consolidation Starting Date';
                    ToolTip = 'Specifies the starting date of the consolidation.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Consolidation Ending Date';
                    ToolTip = 'Specifies the ending date of the consolidation.';
                }
                field("Consolidation Run At"; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Consolidation Run At';
                    ToolTip = 'Specifies the date and time when the consolidation was run.';
                }
            }
        }
    }

    local procedure Caption(): Text;
    begin
        exit(Format(Rec."Starting Date") + ' - ' + Format(Rec."Ending Date"));
    end;

}
