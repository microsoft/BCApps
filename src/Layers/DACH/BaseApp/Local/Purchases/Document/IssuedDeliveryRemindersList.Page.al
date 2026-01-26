// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Navigate;

page 5005275 "Issued Delivery Reminders List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Issued Delivery Reminder';
    CardPageID = "Issued Delivery Reminder";
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = List;
    SourceTable = "Issued Deliv. Reminder Header";
    UsageCategory = History;

    layout
    {
        area(content)
        {
            repeater(Control1140000)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                    Visible = false;
                }
                field(City; Rec.City)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the value of the same field in the original delivery reminder.';
                    Visible = false;
                }
                field("No. Printed"; Rec."No. Printed")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how many times the delivery reminder has been printed.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Navigate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Find entries...';
                Image = Navigate;
                ToolTip = 'Find all entries and documents that exist for the document number and posting date on the selected entry or document.';

                trigger OnAction()
                begin
                    OpenNavigatePage();
                end;
            }
            action(PrintReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = '&Print';
                Ellipsis = true;
                Image = Print;
                ToolTip = 'Prepare to print the document. The report request window for the document opens where you can specify what to include on the print-out.';

                trigger OnAction()
                var
                    PrintDocumentComfort: Codeunit "Print Document Comfort";
                begin
                    PrintDocumentComfort.IssuedDeliveryRemindPrint(Rec, true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Navigate_Promoted; Navigate)
                {
                }
                actionref(PrintReport_Promoted; PrintReport)
                {
                }
            }
        }
    }

    local procedure OpenNavigatePage()
    var
        NavigateForm: Page Navigate;
    begin
        NavigateForm.SetDoc(Rec."Posting Date", Rec."No.");
        NavigateForm.Run();
    end;
}

