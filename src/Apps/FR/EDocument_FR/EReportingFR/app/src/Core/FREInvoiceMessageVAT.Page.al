// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

page 10971 "FR E-Invoice Message VAT"
{
    ApplicationArea = Basic, Suite;
    Caption = 'French E-Invoice Lifecycle VAT Breakdown';
    PageType = List;
    SourceTable = "FR E-Invoice Message VAT";
    SourceTableView = sorting("Message Entry No.", "Line No.");
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    UsageCategory = None;

    layout
    {
        area(content)
        {
            repeater(VATBreakdown)
            {
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT rate used to allocate the reported payment amount.';
                }
                field("VAT Category Code"; Rec."VAT Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the VAT category used to allocate the reported payment amount.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Reported Amount';
                    ToolTip = 'Specifies the portion of the collected or reversed payment reported for this VAT category.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the reported amount.';
                }
            }
        }
    }
}
