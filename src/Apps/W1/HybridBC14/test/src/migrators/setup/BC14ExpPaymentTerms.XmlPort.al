// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Foundation.PaymentTerms;

xmlport 148964 "BC14 Exp Payment Terms"
{
    Caption = 'Expected Payment Terms data for BC14 migration tests';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(PaymentTerms; "Payment Terms")
            {
                AutoSave = false;
                XmlName = 'PaymentTerms';

                textelement(Code) { }
                textelement(DueDateCalculation) { }
                textelement(DiscountDateCalculation) { }
                textelement(DiscountPct) { }
                textelement(Description) { }
                textelement(CalcPmtDiscOnCrMemos) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempPaymentTerms.Init();
                    TempPaymentTerms.Code := CopyStr(Code, 1, MaxStrLen(TempPaymentTerms.Code));
                    Evaluate(TempPaymentTerms."Due Date Calculation", DueDateCalculation);
                    Evaluate(TempPaymentTerms."Discount Date Calculation", DiscountDateCalculation);
                    Evaluate(TempPaymentTerms."Discount %", DiscountPct);
                    TempPaymentTerms.Description := CopyStr(Description, 1, MaxStrLen(TempPaymentTerms.Description));
                    Evaluate(TempPaymentTerms."Calc. Pmt. Disc. on Cr. Memos", CalcPmtDiscOnCrMemos);
                    TempPaymentTerms.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempPaymentTerms.Reset();
        TempPaymentTerms.DeleteAll();
    end;

    procedure GetExpectedPaymentTerms(var DestTempPaymentTerms: Record "Payment Terms" temporary)
    begin
        DestTempPaymentTerms.Reset();
        DestTempPaymentTerms.DeleteAll();
        if TempPaymentTerms.FindSet() then
            repeat
                DestTempPaymentTerms := TempPaymentTerms;
                DestTempPaymentTerms.Insert();
            until TempPaymentTerms.Next() = 0;
    end;

    var
        TempPaymentTerms: Record "Payment Terms" temporary;
        CaptionRow: Boolean;
}
