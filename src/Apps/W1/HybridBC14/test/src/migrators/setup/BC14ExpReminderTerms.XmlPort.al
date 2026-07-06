// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14.Tests;

using Microsoft.Sales.Reminder;

xmlport 148952 "BC14 Exp ReminderTerms"
{
    Caption = 'Expected Reminder Terms data';
    Direction = Import;
    FieldSeparator = ',';
    RecordSeparator = '<CR><LF>';
    Format = VariableText;
    FormatEvaluate = Xml;

    schema
    {
        textelement(root)
        {
            tableelement(ReminderTerms; "Reminder Terms")
            {
                AutoSave = false;
                XmlName = 'ReminderTerms';

                textelement(Code) { }
                textelement(Description) { }
                textelement(MaxNoOfReminders) { }
                textelement(PostInterest) { }
                textelement(PostAdditionalFee) { }
                textelement(MinimumAmountLCY) { }
                textelement(PostAddFeePerLine) { }

                trigger OnBeforeInsertRecord()
                begin
                    if CaptionRow then begin
                        CaptionRow := false;
                        currXMLport.Skip();
                        exit;
                    end;

                    TempReminderTerms.Init();
                    TempReminderTerms.Code := CopyStr(Code, 1, MaxStrLen(TempReminderTerms.Code));
                    TempReminderTerms.Description := CopyStr(Description, 1, MaxStrLen(TempReminderTerms.Description));
                    Evaluate(TempReminderTerms."Max. No. of Reminders", MaxNoOfReminders);
                    Evaluate(TempReminderTerms."Post Interest", PostInterest);
                    Evaluate(TempReminderTerms."Post Additional Fee", PostAdditionalFee);
                    Evaluate(TempReminderTerms."Minimum Amount (LCY)", MinimumAmountLCY);
                    Evaluate(TempReminderTerms."Post Add. Fee per Line", PostAddFeePerLine);
                    TempReminderTerms.Insert();

                    currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnPreXmlPort()
    begin
        CaptionRow := true;
        TempReminderTerms.Reset();
        TempReminderTerms.DeleteAll();
    end;

    procedure GetExpectedReminderTerms(var Dest: Record "Reminder Terms" temporary)
    begin
        Dest.Reset();
        Dest.DeleteAll();
        if TempReminderTerms.FindSet() then
            repeat
                Dest := TempReminderTerms;
                Dest.Insert();
            until TempReminderTerms.Next() = 0;
    end;

    var
        TempReminderTerms: Record "Reminder Terms" temporary;
        CaptionRow: Boolean;
}
