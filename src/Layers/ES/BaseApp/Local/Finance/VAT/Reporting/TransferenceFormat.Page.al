// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Telemetry;

page 10704 "Transference Format"
{
    Caption = 'Transference Format';
    PageType = Worksheet;
    SourceTable = "AEAT Transference Format";

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
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line number of the XML label that will be included in the VAT statement text file.';
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the position of the XML label that will be included in the VAT statement text file.';
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field length of the XML label that will be included in the VAT statement text file.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line type of the XML label that will be included in the VAT statement text file.';
                }
                field(Subtype; Rec.Subtype)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line subtype of the XML label that will be included in the VAT statement text file.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the description of the XML label that will be included in the VAT statement text file.';
                }
                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the field value of the XML label that will be included in the VAT statement text file.';
                }
                field(Box; Rec.Box)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the box number of the XML label that will be included in the VAT statement text file.';
                }
            }
        }
    }

    actions
    {
    }

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
        FeatureTelemetry.LogUptake('1000HV7', ESTelematicVATTok, Enum::"Feature Uptake Status"::Discovered);
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
        ESTelematicVATTok: Label 'ES Create Templates for Telematic VAT Statements in Text File Format', Locked = true;
        VATStmtCode: Code[10];

    local procedure VATStmtCodeOnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

