// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

report 5005341 "Issue Delivery Reminder"
{
    Caption = 'Issue Delivery Reminder';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Delivery Reminder Header"; "Delivery Reminder Header")
        {
            RequestFilterFields = "No.", "Vendor No.";

            trigger OnAfterGetRecord()
            begin
                IssueDeliveryReminder.Set("Delivery Reminder Header", ReplacePostingDate, PostingDateReq);

                if NoOfRecords = 1 then begin
                    IssueDeliveryReminder.Run();
                    Mark := false;
                    IssueDeliveryReminder.GetIssDelivReminHeader(IssuedDeliveryReminderHeader);
                    IssuedDeliveryReminderHeader.Mark := true;
                end else
                    if IssueDeliveryReminder.Run() then begin
                        IssueDeliveryReminder.GetIssDelivReminHeader(IssuedDeliveryReminderHeader);
                        IssuedDeliveryReminderHeader.Mark := true;
                    end else
                        Mark := true;
            end;

            trigger OnPreDataItem()
            begin
                NoOfRecords := Count;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(PrintDoc; PrintDoc)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Print';
                        ToolTip = 'Specifies that the orders will be printed after posting.';
                    }
                    field(ReplacePostingDate; ReplacePostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Replace Posting Date';
                        ToolTip = 'Specifies that the existing posting date for the delivery reminder will be replaced with the new posting date.';
                    }
                    field(PostingDateReq; PostingDateReq)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Commit();
        OnPostReportOnBeforePrintIssuedDeliveryReminder(IssuedDeliveryReminderHeader, PrintDoc);

        if PrintDoc then begin
            IssuedDeliveryReminderHeader.MarkedOnly := true;
            if IssuedDeliveryReminderHeader.Find('-') then
                repeat
                    PrintDocumentProfessional.IssuedDeliveryRemindPrint(IssuedDeliveryReminderHeader, false);
                until IssuedDeliveryReminderHeader.Next() = 0;
        end;

        Commit();

        "Delivery Reminder Header".MarkedOnly := true;
        if (NoOfRecords <> 1) and "Delivery Reminder Header".Find('-') then
            if Confirm(
                 Text1140001 +
                 Text1140002,
                 true)
            then
                PAGE.RunModal(0, "Delivery Reminder Header");
    end;

    trigger OnPreReport()
    begin
        if ReplacePostingDate and (PostingDateReq = 0D) then
            Error(Text1140000);
    end;

    var
        Text1140000: Label 'Please enter the posting date.';
        Text1140001: Label 'It wa not possible to issue some of the selected Delivery Reminders.\\';
        Text1140002: Label 'Would you like to see these Delivery Reminders?';
        IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header";
        IssueDeliveryReminder: Codeunit "Issue Delivery Reminder";
        PrintDocumentProfessional: Codeunit "Print Document Comfort";
        PostingDateReq: Date;
        ReplacePostingDate: Boolean;
        PrintDoc: Boolean;
        NoOfRecords: Integer;

    [IntegrationEvent(false, false)]
    local procedure OnPostReportOnBeforePrintIssuedDeliveryReminder(var IssuedDelivReminderHeader: Record "Issued Deliv. Reminder Header"; var PrintDoc: Boolean)
    begin
    end;
}

