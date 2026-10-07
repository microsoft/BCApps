// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148931 "BC14 Payment Method Data"
{
    Caption = 'BC14 Payment Method buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14PaymentMethod; "BC14 Payment Method")
            {
                AutoSave = false;
                XmlName = 'BC14PaymentMethod';

                textelement(Code) { }
                textelement(Description) { }
                textelement(BalAccountType) { }
                textelement(BalAccountNo) { }
                textelement(DirectDebit) { }
                textelement(DirectDebitPmtTermsCode) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14PaymentMethod: Record "BC14 Payment Method";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14PaymentMethod.Init();
                    NewBC14PaymentMethod.Code := CopyStr(Code, 1, MaxStrLen(NewBC14PaymentMethod.Code));
                    NewBC14PaymentMethod.Description := CopyStr(Description, 1, MaxStrLen(NewBC14PaymentMethod.Description));
                    Evaluate(NewBC14PaymentMethod."Bal. Account Type", BalAccountType);
                    NewBC14PaymentMethod."Bal. Account No." := CopyStr(BalAccountNo, 1, MaxStrLen(NewBC14PaymentMethod."Bal. Account No."));
                    Evaluate(NewBC14PaymentMethod."Direct Debit", DirectDebit);
                    NewBC14PaymentMethod."Direct Debit Pmt. Terms Code" := CopyStr(DirectDebitPmtTermsCode, 1, MaxStrLen(NewBC14PaymentMethod."Direct Debit Pmt. Terms Code"));
                    NewBC14PaymentMethod.Insert();

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
