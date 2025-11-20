// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

page 164 "Previous Exchange Rates"
{
    PageType = List;
    SourceTable = "Bus. Unit In Cons. Process";
    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Processes)
            {
                field("Run At"; Rec.SystemCreatedAt)
                {
                    ApplicationArea = All;
                    Caption = 'Run At';
                    Tooltip = 'Specifies the date and time when the consolidation process was run.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = All;
                    Caption = 'Consolidation Starting Date';
                    Tooltip = 'Specifies the date of the consolidation process.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = All;
                    Caption = 'Consolidation Ending Date';
                    Tooltip = 'Specifies the date of the consolidation process.';
                }
                field("Average Exchange Rate"; Rec."Average Exchange Rate")
                {
                    ApplicationArea = All;
                    Tooltip = 'Specifies the average exchange rate used in the consolidation process';
                    Caption = 'Average Exchange Rate';
                }
                field("Closing Exchange Rate"; Rec."Closing Exchange Rate")
                {
                    ApplicationArea = All;
                    Caption = 'Closing Exchange Rate';
                    Tooltip = 'Specifies the closing exchange rate used in the consolidation process';
                }
                field("Last Closing Exchange Rate"; Rec."Last Closing Exchange Rate")
                {
                    ApplicationArea = All;
                    Caption = 'Last Closing Exchange Rate';
                    Tooltip = 'Specifies the last closing exchange rate used in the consolidation process';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(ShowAll)
            {
                ApplicationArea = All;
                Caption = 'Show All';
                ToolTip = 'Shows all the consolidation processes, not only the ones before the current consolidation process'' ending date.';
                Image = ShowList;

                trigger OnAction()
                begin
                    Rec.SetRange("Ending Date");
                end;
            }
        }
        area(Promoted)
        {
            actionref(ShowAll_Promoted; ShowAll)
            {
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetRange("Business Unit Code", BusinessUnitCode);
        Rec.SetRange(Status, Rec.Status::Finished);
        if MaxEndingDate <> 0D then
            Rec.SetFilter("Ending Date", '<=%1', MaxEndingDate);
    end;

    var
        BusinessUnitCode: Code[20];
        MaxEndingDate: Date;

    internal procedure SetBusinessUnit(BusinessUnit: Record "Business Unit")
    begin
        BusinessUnitCode := BusinessUnit.Code;
    end;

    internal procedure SetMaxEndingDate(NewMaxEndingDate: Date)
    begin
        MaxEndingDate := NewMaxEndingDate;
    end;

}
