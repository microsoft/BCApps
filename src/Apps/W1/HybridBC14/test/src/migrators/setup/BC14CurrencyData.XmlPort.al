// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148965 "BC14 Currency Data"
{
    Caption = 'BC14 Currency buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14Currency; "BC14 Currency")
            {
                AutoSave = false;
                XmlName = 'BC14Currency';

                textelement(Code) { }
                textelement(Description) { }
                textelement(UnrealizedGainsAcc) { }
                textelement(RealizedGainsAcc) { }
                textelement(UnrealizedLossesAcc) { }
                textelement(RealizedLossesAcc) { }
                textelement(InvoiceRoundingPrecision) { }
                textelement(AmountRoundingPrecision) { }
                textelement(Symbol) { }
                textelement(ISOCode) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14Currency: Record "BC14 Currency";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14Currency.Init();
                    NewBC14Currency.Code := CopyStr(Code, 1, MaxStrLen(NewBC14Currency.Code));
                    NewBC14Currency.Description := CopyStr(Description, 1, MaxStrLen(NewBC14Currency.Description));
                    NewBC14Currency."Unrealized Gains Acc." := CopyStr(UnrealizedGainsAcc, 1, MaxStrLen(NewBC14Currency."Unrealized Gains Acc."));
                    NewBC14Currency."Realized Gains Acc." := CopyStr(RealizedGainsAcc, 1, MaxStrLen(NewBC14Currency."Realized Gains Acc."));
                    NewBC14Currency."Unrealized Losses Acc." := CopyStr(UnrealizedLossesAcc, 1, MaxStrLen(NewBC14Currency."Unrealized Losses Acc."));
                    NewBC14Currency."Realized Losses Acc." := CopyStr(RealizedLossesAcc, 1, MaxStrLen(NewBC14Currency."Realized Losses Acc."));
                    Evaluate(NewBC14Currency."Invoice Rounding Precision", InvoiceRoundingPrecision);
                    Evaluate(NewBC14Currency."Amount Rounding Precision", AmountRoundingPrecision);
                    NewBC14Currency.Symbol := CopyStr(Symbol, 1, MaxStrLen(NewBC14Currency.Symbol));
                    NewBC14Currency."ISO Code" := CopyStr(ISOCode, 1, MaxStrLen(NewBC14Currency."ISO Code"));
                    // Default decimal places to a valid '2:2' format so production
                    // Currency.Validate("Amount Decimal Places") does not error on empty input.
                    NewBC14Currency."Amount Decimal Places" := '2:2';
                    NewBC14Currency."Unit-Amount Decimal Places" := '2:2';
                    NewBC14Currency.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
    end;

    var
        CaptionRow: Boolean;
}
