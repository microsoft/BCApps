// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Setup;

using Microsoft.CashFlow.Forecast;
using Microsoft.Finance.Dimension;

page 857 "Cash Flow Manual Revenues"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cash Flow Manual Revenues';
    PageType = List;
    SourceTable = "Cash Flow Manual Revenue";
    SourceTableView = sorting("Starting Date")
                      order(ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1000)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the record.';
                    Visible = false;
                }
                field("Cash Flow Account No."; Rec."Cash Flow Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the cash flow account that the entry on the manual revenue line is registered to.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the cash flow forecast entry.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Date';
                    ShowMandatory = true;
                    ToolTip = 'Specifies the date of the cash flow entry.';

                    trigger OnValidate()
                    begin
                        ValidateFromDatePrecedesToDate(Rec."Starting Date", Rec."Ending Date");
                    end;
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the total amount in LCY that the manual revenue consists of. The entered amount is the amount which is registered in the given time period per recurring frequency.';
                }
                field(Recurrence; Recurrence)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Recurrence';
                    OptionCaption = ' ,Daily,Weekly,Monthly,Quarterly,Yearly';
                    ToolTip = 'Specifies a date formula for calculating the period length. The content of the field determines how often the entry on the manual revenue line is registered. For example, if the line must be registered every month, you can enter 1M.';

                    trigger OnValidate()
                    var
                        RecurringFrequency: Text;
                    begin
                        RecurringFrequency := CashFlowManagement.RecurrenceToRecurringFrequency(Recurrence);
                        Evaluate(Rec."Recurring Frequency", RecurringFrequency);
                        EnableControls();
                    end;
                }
                field("Recurring Frequency"; Rec."Recurring Frequency")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how often the entry on the manual revenue line is registered, if the journal template used is set up to be recurring';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        CashFlowManagement.RecurringFrequencyToRecurrence(Rec."Recurring Frequency", Recurrence);
                    end;
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'End By';
                    Enabled = EndingDateEnabled;
                    ToolTip = 'Specifies the last date from which manual revenues should be registered for the cash flow forecast.';

                    trigger OnValidate()
                    begin
                        ValidateFromDatePrecedesToDate(Rec."Starting Date", Rec."Ending Date");
                    end;
                }
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("&Revenues")
            {
                Caption = '&Revenues';
                Image = Dimensions;
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(849),
                                  "No." = field(Code);
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        GetRecord();
    end;

    trigger OnAfterGetRecord()
    begin
        GetRecord();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CurrPage.SaveRecord();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        EnableControls();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.InitNewRecord();
    end;

    var
        CashFlowManagement: Codeunit "Cash Flow Management";
        Recurrence: Option " ",Daily,Weekly,Monthly,Quarterly,Yearly;
        EndingDateEnabled: Boolean;
        FromDatePrecedesToDateErr: Label '"%1" must be later than "%2"', Comment = '%1 = Field name end date; %2 = Field name start date';

    local procedure GetRecord()
    begin
        EnableControls();
        CashFlowManagement.RecurringFrequencyToRecurrence(Rec."Recurring Frequency", Recurrence);
    end;

    local procedure EnableControls()
    begin
        EndingDateEnabled := (Recurrence <> Recurrence::" ");
        if not EndingDateEnabled then
            Rec."Ending Date" := 0D;
    end;

    local procedure ValidateFromDatePrecedesToDate(FromDate: Date; ToDate: Date)
    begin
        if (FromDate <> 0D) and (ToDate <> 0D) and (FromDate > ToDate) then
            Error(FromDatePrecedesToDateErr, ToDate, FromDate);
    end;
}

