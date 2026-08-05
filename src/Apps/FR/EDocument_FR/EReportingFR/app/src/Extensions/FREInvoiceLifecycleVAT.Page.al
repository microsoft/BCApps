// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

page 10971 "FR E-Invoice Lifecycle VAT"
{
    ApplicationArea = Basic, Suite;
    Caption = 'VAT Breakdown';
    Editable = false;
    InherentPermissions = X;
    PageType = ListPart;
    SourceTable = "FR E-Invoice Lifecycle VAT";

    layout
    {
        area(Content)
        {
            repeater(VATBreakdown)
            {
                field("VAT %"; Rec."VAT %")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Reported Amount"; Rec."Reported Amount")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
    }
}