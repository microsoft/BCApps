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
                  tabledata "User AI Consumption Data" = r,
                  tabledata "AI Consumption Log Entry" = r;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(ConsumptionDateTime; TempUserAIConsumptionData."Consumption DateTime")
                {
                    Caption = 'Consumption DateTime';
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
                field(ActionsField; TempUserAIConsumptionData.Actions)
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
                        DescriptionInStream: InStream;
                        FullDescription: Text;
                        TextLine: Text;
                    begin
                        if Rec.GetBillingDetails(TempUserAIConsumptionData) then begin
                            TempUserAIConsumptionData.Description.CreateInStream(DescriptionInStream, TextEncoding::UTF8);
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
                field(FeatureTrial; Rec."Is Feature Trial")
                {
                    Caption = 'Is Feature Trial';
                    ToolTip = 'Specifies whether this consumption entry was part of a feature trial.';
                }
                field(Credits; TempUserAIConsumptionData."Copilot Credits")
                {
                    Caption = 'Credits';
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the number of credits consumed by this entry.';
                }
                field(CSFeatureDisplayName; TempUserAIConsumptionData."Copilot Studio Feature Display Name")
                {
                    Caption = 'Copilot Studio Feature Display Name';
                    ToolTip = 'Specifies the display name of the Copilot Studio feature used.';
                }
                field(CSFeatureQuantity; CSFeatureQuantityTxt)
                {
                    Caption = 'Copilot Studio Feature Quantity';
                    ToolTip = 'Specifies the quantity of Copilot Studio feature units consumed.';
                }
                field(ProcessedForBilling; TempUserAIConsumptionData."Processed For Billing")
                {
                    Caption = 'Processed For Billing';
                    ToolTip = 'Specifies whether this consumption entry has been processed for billing.';
                }
                field(CompanyName; TempUserAIConsumptionData."Company Name")
                {
                    Caption = 'Company Name';
                    ToolTip = 'Specifies the company in which this consumption entry was recorded.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
    begin
        if not AIConsumptionLogEntry.ReadPermission() then
            Message(BillingDetailsUnavailableLbl);
    end;

    trigger OnAfterGetRecord()
    var
        TaskShortName: Text[30];
        TaskLongName: Text;
    begin
        Rec.GetBillingDetails(TempUserAIConsumptionData);
        CSFeatureQuantityTxt := '';
        if TempUserAIConsumptionData."Copilot Studio Feature" <> '' then
            CSFeatureQuantityTxt := Format(TempUserAIConsumptionData."Copilot Studio Feature Quantity");
        SourceDisplayTxt := '';
        Rec.GetTaskDisplayName(TempUserAIConsumptionData."Company Name", TaskShortName, TaskLongName);
        SourceDisplayTxt := TaskLongName;
    end;

    var
        TempUserAIConsumptionData: Record "User AI Consumption Data" temporary;
        ViewDescriptionLbl: Label 'View full description';
        NoDescriptionAvailableLbl: Label 'No description available.';
        BillingDetailsUnavailableLbl: Label 'Billing details are unavailable because you do not have permission to read AI consumption log entries.';
        SourceDisplayTxt: Text;
        CSFeatureQuantityTxt: Text;
}
