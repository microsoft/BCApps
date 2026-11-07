// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Finance.Currency;

xmlport 148966 "BC14 Exp Currency"
{
    Caption = 'Expected Currency data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(Currency; Currency)
            {
                AutoSave = false;
                XmlName = 'Currency';

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
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempCurrency.Init();
                    TempCurrency.Code := CopyStr(Code, 1, MaxStrLen(TempCurrency.Code));
                    TempCurrency.Description := CopyStr(Description, 1, MaxStrLen(TempCurrency.Description));
                    TempCurrency."Unrealized Gains Acc." := CopyStr(UnrealizedGainsAcc, 1, MaxStrLen(TempCurrency."Unrealized Gains Acc."));
                    TempCurrency."Realized Gains Acc." := CopyStr(RealizedGainsAcc, 1, MaxStrLen(TempCurrency."Realized Gains Acc."));
                    TempCurrency."Unrealized Losses Acc." := CopyStr(UnrealizedLossesAcc, 1, MaxStrLen(TempCurrency."Unrealized Losses Acc."));
                    TempCurrency."Realized Losses Acc." := CopyStr(RealizedLossesAcc, 1, MaxStrLen(TempCurrency."Realized Losses Acc."));
                    Evaluate(TempCurrency."Invoice Rounding Precision", InvoiceRoundingPrecision);
                    Evaluate(TempCurrency."Amount Rounding Precision", AmountRoundingPrecision);
                    TempCurrency.Symbol := CopyStr(Symbol, 1, MaxStrLen(TempCurrency.Symbol));
                    TempCurrency."ISO Code" := CopyStr(ISOCode, 1, MaxStrLen(TempCurrency."ISO Code"));
                    TempCurrency.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempCurrency.Reset();
        TempCurrency.DeleteAll();
    end;

    procedure GetExpectedCurrencies(var DestTempCurrency: Record Currency temporary)
    begin
        DestTempCurrency.Reset();
        DestTempCurrency.DeleteAll();
        if TempCurrency.FindSet() then
            repeat
                DestTempCurrency := TempCurrency;
                DestTempCurrency.Insert();
            until TempCurrency.Next() = 0;
    end;

    var
        TempCurrency: Record Currency temporary;
        CaptionRow: Boolean;
}
