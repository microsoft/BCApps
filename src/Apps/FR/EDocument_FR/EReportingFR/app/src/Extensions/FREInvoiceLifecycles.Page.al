// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

page 10970 "FR E-Invoice Lifecycles"
{
    ApplicationArea = Basic, Suite;
    Caption = 'E-Invoice Lifecycles';
    Editable = false;
    InherentPermissions = X;
    PageType = List;
    SourceTable = "FR E-Invoice Lifecycle";
    UsageCategory = History;

    layout
    {
        area(Content)
        {
            repeater(Lifecycles)
            {
                field("E-Document Entry No."; Rec."E-Document Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Lifecycle Status"; Rec."Lifecycle Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reported Amount"; Rec."Reported Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Event Date"; Rec."Event Date")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Processing Status"; Rec."Processing Status")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("E-Document Message Entry No."; Rec."E-Document Message Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RetryMessageCreation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Retry Message Creation';
                Enabled = Rec."Processing Status" = Rec."Processing Status"::Failed;
                Image = Reopen;
                ToolTip = 'Schedules another attempt to create the lifecycle message.';

                trigger OnAction()
                var
                    FREInvoiceLifecycleMgt: Codeunit "FR E-Invoice Lifecycle Mgt.";
                begin
                    FREInvoiceLifecycleMgt.RetryLifecycleMessage(Rec);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            actionref(RetryMessageCreationPromoted; RetryMessageCreation)
            {
            }
        }
    }
}