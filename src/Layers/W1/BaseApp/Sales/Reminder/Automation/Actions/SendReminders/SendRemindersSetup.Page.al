// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Configures the parameters for the automated send reminders action including email options and filters.
/// </summary>
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
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                }
                field(SendMultipleTimes; Rec."Send Multiple Times Per Level")
                {
                    ApplicationArea = All;
                    Caption = 'Send multiple times for a level';
                }
                group(MimimumSendingInterval)
                {
                    ShowCaption = false;
                    Visible = Rec."Send Multiple Times Per Level";

                    field(MinimumTimeBetweenSending; Rec."Minimum Time Between Sending")
                    {
                        ApplicationArea = All;
                        Caption = 'Minimum time before sending again';
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
                }
                field(ShowMultipleInterestRate; Rec."Show Multiple Interest Rates")
                {
                    ApplicationArea = All;
                    Caption = 'Show multiple interest rates';
                }
            }
            group(CommunicationSettings)
            {
                Caption = 'Communication settings';
                field(LogInteraction; Rec."Log Interaction")
                {
                    ApplicationArea = All;
                    Caption = 'Log interaction';
                }
                field(UseDocumentSendingProfile; Rec."Use Document Sending Profile")
                {
                    ApplicationArea = All;
                    Caption = 'Use document sending profile';
                }
                group(SendingSetupGroup)
                {
                    ShowCaption = false;
                    Visible = not Rec."Use Document Sending Profile";
                    field(Print; Rec.Print)
                    {
                        ApplicationArea = All;
                        Caption = 'Print reminders';
                    }
                    field(SendByEmail; Rec."Send by Email")
                    {
                        ApplicationArea = All;
                        Caption = 'Send by email';
                    }
                }
                field(AttachInvoiceDocuments; Rec."Attach Invoice Documents")
                {
                    ApplicationArea = All;
                    Caption = 'Attach invoice documents';
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
