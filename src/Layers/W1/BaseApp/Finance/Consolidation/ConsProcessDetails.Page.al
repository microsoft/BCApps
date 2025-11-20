// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

page 252 "Cons. Process Details"
{
    PageType = ListPlus;
    Caption = 'Consolidation Process Details';
    SourceTable = "Bus. Unit In Cons. Process";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    DataCaptionExpression = Caption();

    layout
    {
        area(Content)
        {
            field(StartingDate; ConsolidationProcess."Starting Date")
            {
                ApplicationArea = All;
                Caption = 'Starting Date';
                ToolTip = 'Specifies the starting date of the imported entries.';
            }
            field("Ending Date"; ConsolidationProcess."Ending Date")
            {
                ApplicationArea = All;
                Caption = 'Ending Date';
                ToolTip = 'Specifies the ending date of the imported entries.';
            }
            field(RunStatus; ConsolidationProcess.Status)
            {
                ApplicationArea = All;
                Caption = 'Status';
                ToolTip = 'Specifies the status of the consolidation process.';
            }
            field(Error; ConsolidationProcess.Error)
            {
                ApplicationArea = All;
                Caption = 'Error';
                Visible = ConsolidationProcessHasError;
                ToolTip = 'Specifies the error message if the consolidation process has failed.';
            }
            repeater(BusinessUnits)
            {
                field("Business Unit Code"; Rec."Business Unit Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the code of the business unit.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the status of the business unit in the consolidation process.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency code of the business unit.';
                }
                field("Currency Exchange Rate Table"; Rec."Currency Exchange Rate Table")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the currency exchange rate table of the business unit.';
                }
                field("Closing Exchange Rate"; Rec."Closing Exchange Rate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the closing exchange rate of the business unit.';
                }
                field("Average Exchange Rate"; Rec."Average Exchange Rate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the average exchange rate of the business unit.';
                }
                field("Last Closing Exchange Rate"; Rec."Last Closing Exchange Rate")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the last closing exchange rate considered when adjusting balances in re-runs for this business unit.';
                }
            }
        }
    }
    var
        ConsolidationProcess: Record "Consolidation Process";
        Status, Error : Text;
        ConsolidationProcessHasError: Boolean;

    trigger OnOpenPage()
    begin
        ConsolidationProcessHasError := ConsolidationProcess.Error <> '';
    end;

    internal procedure SetConsolidationProcess(Id: Integer)
    begin
        ConsolidationProcess.Get(Id);
        Rec.SetRange("Consolidation Process Id", ConsolidationProcess.Id);
    end;

    local procedure Caption(): Text
    begin
        exit(Format(ConsolidationProcess."Starting Date") + ' - ' + Format(ConsolidationProcess."Ending Date"));
    end;

}
