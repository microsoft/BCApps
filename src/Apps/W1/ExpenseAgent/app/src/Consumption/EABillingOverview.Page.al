// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Environment.Consumption;

page 7079 "EA Billing Overview"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
#pragma warning disable AS0035
    SourceTable = "Expense Agent Env. Consumption";
#pragma warning restore AS0035
    Caption = 'Expense Agent - Billing Overview';
    Editable = false;
    Permissions = tabledata "Expense Agent Env. Consumption" = r,
                  tabledata "User AI Consumption Data" = r;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ConsumptionDateTime; Rec."Consumption DateTime")
                {
                    ToolTip = 'Specifies the date and time when the consumption occurred.';
                }
                field(ExpenseUserNo; Rec."Expense User No.")
                {
                    ToolTip = 'Specifies the expense user associated with this consumption entry.';
                }
                field(SourceType; Rec."Consumption Source Type")
                {
                    Caption = 'Source Type';
                    ToolTip = 'Specifies whether this consumption originated from an individual expense or an expense report.';
                }
                field(Source; SourceDisplayTxt)
                {
                    Caption = 'Source';
                    ToolTip = 'Specifies the expense or expense report linked to this consumption entry.';
                }
                field(SourceOperation; Rec."Consumption Source Operation")
                {
                    ToolTip = 'Specifies the operation that triggered the consumption, such as creating, updating, or processing an expense.';
                }
                field(ActionsField; Rec."Actions")
                {
                    Caption = 'Actions';
                    ToolTip = 'Specifies the actions performed during this consumption entry.';
                }
                field(Description; ViewDescriptionLbl)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the full description of the operation. Click to view details.';
                    trigger OnDrillDown()
                    var
                        UserAIConsumptionData: Record "User AI Consumption Data";
                        DescriptionInStream: InStream;
                        FullDescription: Text;
                        TextLine: Text;
                    begin
                        UserAIConsumptionData.SetCurrentKey("Unique Id");
                        UserAIConsumptionData.SetRange("Unique Id", Rec."Consumption Unique ID");
                        if UserAIConsumptionData.FindFirst() then begin
                            UserAIConsumptionData.CalcFields(Description);
                            UserAIConsumptionData.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
                            while not DescriptionInStream.EOS() do begin
                                DescriptionInStream.ReadText(TextLine);
                                if FullDescription <> '' then
                                    FullDescription += '\';
                                FullDescription += TextLine;
                            end;
                        end;
                        if FullDescription <> '' then
                            Message(FullDescription)
                        else
                            Message(NoDescriptionAvailableLbl);
                    end;
                }
                field(Credits; Rec."Copilot Credits")
                {
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the number of Copilot credits consumed by this entry.';
                }
                field(CSFeatureDisplayName; Rec."CS Feature Display Name")
                {
                    Caption = 'Copilot Studio Feature Display Name';
                    ToolTip = 'Specifies the display name of the Copilot Studio feature used.';
                }
                field(CSFeatureQuantity; Rec."CS Feature Quantity")
                {
                    Caption = 'Copilot Studio Feature Quantity';
                    ToolTip = 'Specifies the quantity of Copilot Studio feature units consumed.';
                }
                field(ProcessedForBilling; Rec."Processed For Billing")
                {
                    ToolTip = 'Specifies whether this consumption entry has been processed for billing.';
                }
                field(CompanyName; Rec."Company Name")
                {
                    ToolTip = 'Specifies the company in which this consumption entry was recorded.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        TaskShortName: Text[30];
        TaskLongName: Text;
    begin
        SourceDisplayTxt := '';
        Rec.GetTaskDisplayName(TaskShortName, TaskLongName);
        SourceDisplayTxt := TaskLongName;
    end;

    var
        ViewDescriptionLbl: Label 'View full description';
        NoDescriptionAvailableLbl: Label 'No description available.';
        SourceDisplayTxt: Text;
}
