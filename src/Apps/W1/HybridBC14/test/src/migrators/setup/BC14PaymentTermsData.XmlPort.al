// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148963 "BC14 Payment Terms Data"
{
    Caption = 'BC14 Payment Terms buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14PaymentTerms; "BC14 Pmt. Terms")
            {
                AutoSave = false;
                XmlName = 'BC14PaymentTerms';

                textelement(Code) { }
                textelement(DueDateCalculation) { }
                textelement(DiscountDateCalculation) { }
                textelement(DiscountPct) { }
                textelement(Description) { }
                textelement(CalcPmtDiscOnCrMemos) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14PaymentTerms: Record "BC14 Pmt. Terms";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14PaymentTerms.Init();
                    NewBC14PaymentTerms.Code := CopyStr(Code, 1, MaxStrLen(NewBC14PaymentTerms.Code));
                    Evaluate(NewBC14PaymentTerms."Due Date Calculation", DueDateCalculation);
                    Evaluate(NewBC14PaymentTerms."Discount Date Calculation", DiscountDateCalculation);
                    Evaluate(NewBC14PaymentTerms."Discount %", DiscountPct);
                    NewBC14PaymentTerms.Description := CopyStr(Description, 1, MaxStrLen(NewBC14PaymentTerms.Description));
                    Evaluate(NewBC14PaymentTerms."Calc. Pmt. Disc. on Cr. Memos", CalcPmtDiscOnCrMemos);
                    NewBC14PaymentTerms.Insert();

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
