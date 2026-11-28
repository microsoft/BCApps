// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 10074 "IRS 1099 Doc. Suppl. Lines"
{
    PageType = ListPart;
    SourceTable = "IRS 1099 Doc. Suppl. Line";
    ApplicationArea = BasicCA, BasicUS;
    Caption = 'Supplemental Lines';
    DelayedInsert = true;
    AutoSplitKey = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Supplemental Box No."; Rec."Supplemental Box No.")
                {
                    ToolTip = 'Specifies the supplemental box for this line. You can select boxes for the document year and form that have a parent document line and have not already been added.';

                    trigger OnValidate()
                    begin
                        SetSupplementalBoxDescription();
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SupplBox: Record "IRS 1099 Suppl. Box";
                        SupplBoxes: Page "IRS 1099 Suppl. Boxes";
                    begin
                        SupplBoxes.SetDocumentLookup(Rec."Document ID");
                        SupplBoxes.LookupMode(true);
                        if SupplBoxes.RunModal() = Action::LookupOK then begin
                            SupplBoxes.GetRecord(SupplBox);
                            Rec.Validate("Supplemental Box No.", SupplBox."No.");
                            SetSupplementalBoxDescription();
                            Text := SupplBox."No.";
                            exit(true);
                        end;
                        exit(false);
                    end;
                }
                field(Description; SupplementalBoxDescription)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the supplemental box for this document''s reporting period and form.';
                    Editable = false;
                }
                field("Parent Form Box No."; Rec."Parent Form Box No.")
                {
                    ToolTip = 'Specifies the form box of the parent document line. Changing setup or renumbering document lines does not change this link.';
                }
                field("Value Type"; Rec."Value Type")
                {
                    ToolTip = 'Specifies whether the selected supplemental box contains an amount or occupation codes.';
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies an amount already included in the parent document line, not an additional payment. It must not exceed the amount on that line.';
                    Editable = Rec."Value Type" = Rec."Value Type"::Amount;
                }
                field("Occupation Code 1"; Rec."Occupation Code 1")
                {
                    ToolTip = 'Specifies the first three-character Treasury tipped occupation code, including 000. Positive cash tips require one or two valid codes.';
                    Editable = Rec."Value Type" = Rec."Value Type"::"Occupation Codes";
                }
                field("Occupation Code 2"; Rec."Occupation Code 2")
                {
                    ToolTip = 'Specifies an optional second Treasury tipped occupation code. Codes are stored as text, not numbers.';
                    Editable = Rec."Value Type" = Rec."Value Type"::"Occupation Codes";
                }
                field(ReportingExplanation; ReportingExplanation)
                {
                    Caption = 'Reporting Status';
                    ToolTip = 'Specifies why the supplemental line is not currently included in 1099 reporting. Its values are kept.';
                    Editable = false;
                }
            }

        }
    }

    trigger OnAfterGetRecord()
    var
        Supplemental: Codeunit "IRS 1099 Supplemental";
    begin
        SetSupplementalBoxDescription();
        ReportingExplanation := Supplemental.GetExclusionExplanation(Rec);
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Clear(SupplementalBoxDescription);
    end;

    var
        ReportingExplanation: Text;
        SupplementalBoxDescription: Text[250];

    local procedure SetSupplementalBoxDescription()
    var
        DocHeader: Record "IRS 1099 Form Doc. Header";
        SupplBox: Record "IRS 1099 Suppl. Box";
    begin
        Clear(SupplementalBoxDescription);
        if Rec."Supplemental Box No." = '' then
            exit;
        DocHeader.Get(Rec."Document ID");
        SupplBox.Get(DocHeader."Period No.", DocHeader."Form No.", Rec."Supplemental Box No.");
        SupplementalBoxDescription := SupplBox.Description;
    end;
}
