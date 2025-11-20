// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 6760 "Send Reminders Setup"
{
    PageType = Card;
    SourceTable = "Send Reminders Setup";
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field(Code; Rec.Code)
                {
                    ApplicationArea = All;
                    Caption = 'Code';
                    ToolTip = 'Specifies a code for the reminder setup';
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies a description for the reminder setup';
                }
                field(SendMultipleTimes; Rec."Send Multiple Times Per Level")
                {
                    ApplicationArea = All;
                    Caption = 'Send multiple times for a level';
                    ToolTip = 'Specifies whether to send multiple reminders to the same customer';
                }
                group(MimimumSendingInterval)
                {
                    ShowCaption = false;
                    Visible = Rec."Send Multiple Times Per Level";

                    field(MinimumTimeBetweenSending; Rec."Minimum Time Between Sending")
                    {
                        ApplicationArea = All;
                        Caption = 'Minimum time before sending again';
                        ToolTip = 'Specifies the minimum number of days between sending reminder to the same customer';
                    }
                }
            }
            group(ReportSettings)
            {
                Caption = 'Report settings';
                field(ShowAmountsNotDue; Rec."Show Amounts Not Due")
                {
                    ApplicationArea = All;
                    Caption = 'Show amounts not due';
                    ToolTip = 'Specifies whether to show amounts that are not due on the reminder';
                }
                field(ShowMultipleInterestRate; Rec."Show Multiple Interest Rates")
                {
                    ApplicationArea = All;
                    Caption = 'Show multiple interest rates';
                    ToolTip = 'Specifies whether to show multiple interest rates on the reminder';
                }
            }
            group(CommunicationSettings)
            {
                Caption = 'Communication settings';
                field(LogInteraction; Rec."Log Interaction")
                {
                    ApplicationArea = All;
                    Caption = 'Log interaction';
                    ToolTip = 'Specifies whether to log an interaction when a reminder is sent';
                }
                field(UseDocumentSendingProfile; Rec."Use Document Sending Profile")
                {
                    ApplicationArea = All;
                    Caption = 'Use document sending profile';
                    ToolTip = 'Specifies whether to use a document sending profile when sending reminders by email';
                }
                group(SendingSetupGroup)
                {
                    ShowCaption = false;
                    Visible = not Rec."Use Document Sending Profile";
                    field(Print; Rec.Print)
                    {
                        ApplicationArea = All;
                        Caption = 'Print reminders';
                        ToolTip = 'Specifies whether to print reminders';
                    }
                    field(SendByEmail; Rec."Send by Email")
                    {
                        ApplicationArea = All;
                        Caption = 'Send by email';
                        ToolTip = 'Specifies whether to send reminders by email';
                    }
                }
                field(AttachInvoiceDocuments; Rec."Attach Invoice Documents")
                {
                    ApplicationArea = All;
                    Caption = 'Attach invoice documents';
                    ToolTip = 'Specifies whether to attach all invoice documents to the reminder email';
                }
            }
            group(Filters)
            {
                Caption = 'Filters';
                field(ReminderFilter; ReminderFilterTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Reminder Filter';
                    ToolTip = 'Specifies the filter to use to select reminders that can be used by this job.';
                    Editable = false;

                    trigger OnAssistEdit()
                    begin
                        Rec.SetReminderSelectionFilter();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        ReminderFilterTxt := Rec.GetReminderSelectionDisplayText();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ReminderFilterTxt := Rec.GetReminderSelectionDisplayText();
    end;

    trigger OnOpenPage()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        SendReminderEventHandler: Codeunit "Send Reminder Event Handler";
        Handled: Boolean;
    begin
        BindSubscription(SendReminderEventHandler);
        IssuedReminderHeader.OnGetReportParameters(Rec."Log Interaction", Rec."Show Amounts Not Due", Rec."Show Multiple Interest Rates", 0, Handled);
    end;

    var
        ReminderFilterTxt: Text;
}
