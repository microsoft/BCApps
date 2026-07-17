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
                    ToolTip = 'Specifies the related e-document entry.';
                }
                field("Lifecycle Status"; Rec."Lifecycle Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the French electronic invoice lifecycle status.';
                }
                field("Reported Amount"; Rec."Reported Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount reported for this lifecycle occurrence.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the reported amount.';
                }
                field("Event Date"; Rec."Event Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date of the lifecycle event.';
                }
                field("Processing Status"; Rec."Processing Status")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the processing status of the lifecycle occurrence.';
                }
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the lifecycle occurrence was created.';
                }
                field("Last Error"; Rec."Last Error")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the last processing error for the lifecycle occurrence.';
                }
            }
        }
    }
}