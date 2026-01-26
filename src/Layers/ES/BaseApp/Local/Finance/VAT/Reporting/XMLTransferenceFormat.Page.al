// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Telemetry;

page 10710 "XML Transference Format"
{
    Caption = 'XML Transference Format';
    PageType = Worksheet;
    SourceTable = "AEAT Transference Format XML";

    layout
    {
        area(content)
        {
            field(VATStmtCode; VATStmtCode)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'VAT Stmt. Name';
                Lookup = true;
                TableRelation = "VAT Statement Name".Name;
                ToolTip = 'Specifies the name of the related VAT statement.';

                trigger OnValidate()
                begin
                    Rec.SetRange("VAT Statement Name", VATStmtCode);
                    VATStmtCodeOnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                IndentationColumn = DescriptionIndent;
                IndentationControls = Description;
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a number that identifies this row.';
                }
                field("Line Type"; Rec."Line Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the data will be shown.';
                }
                field("Indentation Level"; Rec."Indentation Level")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the level for this label.';
                }
                field("Parent Line No."; Rec."Parent Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the line.';
                }
                field("Value Type"; Rec."Value Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to review this value before creating the final XML file.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies text that will appear on the label.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that If the line is a label, the user can include a fixed value.';
                }
                field(Box; Rec.Box)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the box number to get the data from.';
                }
                field(Ask; Rec.Ask)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that if a check mark is inserted, this label will be included in the XML file, if the amount in the Box or in Value is not zero.';
                }
                field("Exists Amount"; Rec."Exists Amount")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if this XML label will be included in the VAT statement text file if the amount is different than zero.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        DescriptionIndent := 0;
        DescriptionOnFormat();
    end;

    trigger OnInit()
    begin
        CurrPage.LookupMode := true;
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."VAT Statement Name" := VATStmtCode;
    end;

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('1000HW1', ESVATXMLTok, Enum::"Feature Uptake Status"::Discovered);
        if Rec."VAT Statement Name" <> '' then
            VATStmtCode := Rec."VAT Statement Name"
        else begin
            VATSmtName.FindFirst();
            VATStmtCode := VATSmtName.Name;
        end;
    end;

    var
        VATSmtName: Record "VAT Statement Name";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ESVATXMLTok: Label 'ES Export VAT Statements in XML Format', Locked = true;
        VATStmtCode: Code[10];
        DescriptionEmphasize: Boolean;
        DescriptionIndent: Integer;

    local procedure VATStmtCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;

    local procedure DescriptionOnFormat()
    begin
        DescriptionEmphasize := Rec."Line Type" = Rec."Line Type"::Element;
        DescriptionIndent := Rec."Indentation Level";
    end;
}

