// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10073 "IRS 1099 Suppl. Boxes"
{
    PageType = List;
    SourceTable = "IRS 1099 Suppl. Box";
    ApplicationArea = BasicCA, BasicUS;
    Caption = 'IRS 1099 Supplemental Boxes';
    DelayedInsert = true;
    AnalysisModeEnabled = false;

    layout
    {
        area(Content)
        {
            repeater(Boxes)
            {
                field("Period No."; Rec."Period No.")
                {
                    ToolTip = 'Specifies the reporting period for this definition.';
                }
                field("Form No."; Rec."Form No.")
                {
                    ToolTip = 'Specifies the MISC or NEC form for this definition.';
                }
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the supplemental box number. It must differ from the form box numbers for this period and form.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description shown when selecting a supplemental box.';
                }
                field("Parent Form Box No."; Rec."Parent Form Box No.")
                {
                    ToolTip = 'Specifies the form box whose income already includes the supplemental amount.';
                }
                field("Value Type"; Rec."Value Type")
                {
                    ToolTip = 'Specifies whether the supplemental box contains an amount or up to two occupation codes.';
                }
                field("XML Element Name"; Rec."XML Element Name")
                {
                    ToolTip = 'Specifies the supported XML mapping. Leave this empty for a custom definition without a supported XML mapping.';
                }
            }
        }
    }

    var
        LookupDocumentID: Integer;

    trigger OnOpenPage()
    var
        Supplemental: Codeunit "IRS 1099 Supplemental";
    begin
        if LookupDocumentID <> 0 then begin
            CurrPage.Editable(false);
            Supplemental.FilterAvailableSupplBoxes(Rec, LookupDocumentID);
        end;
    end;

    procedure SetDocumentLookup(DocumentID: Integer)
    begin
        LookupDocumentID := DocumentID;
    end;
}
