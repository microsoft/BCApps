// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.DataMigration.BC14Reimplementation;

xmlport 148951 "BC14 ReminderTerms Data"
{
    Caption = 'BC14 Reminder Terms buffer data';
    Direction = Both;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(BC14ReminderTerms; "BC14 Reminder Terms")
            {
                AutoSave = false;
                XmlName = 'BC14ReminderTerms';

                textelement(Code) { }
                textelement(Description) { }
                textelement(MaxNoOfReminders) { }
                textelement(PostInterest) { }
                textelement(PostAdditionalFee) { }
                textelement(MinimumAmountLCY) { }
                textelement(PostAddFeePerLine) { }

                trigger OnBeforeInsertRecord()
                var
                    NewBC14ReminderTerms: Record "BC14 Reminder Terms";
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    NewBC14ReminderTerms.Init();
                    NewBC14ReminderTerms.Code := CopyStr(Code, 1, MaxStrLen(NewBC14ReminderTerms.Code));
                    NewBC14ReminderTerms.Description := CopyStr(Description, 1, MaxStrLen(NewBC14ReminderTerms.Description));
                    Evaluate(NewBC14ReminderTerms."Max. No. of Reminders", MaxNoOfReminders);
                    Evaluate(NewBC14ReminderTerms."Post Interest", PostInterest);
                    Evaluate(NewBC14ReminderTerms."Post Additional Fee", PostAdditionalFee);
                    Evaluate(NewBC14ReminderTerms."Minimum Amount (LCY)", MinimumAmountLCY);
                    Evaluate(NewBC14ReminderTerms."Post Add. Fee per Line", PostAddFeePerLine);
                    NewBC14ReminderTerms.Insert();

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
