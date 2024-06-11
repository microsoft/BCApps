// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

xmlport 149031 "AIT Test Suite Import/Export"
{
    Caption = 'AIT Import/Export';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(AITSuite; "AIT Test Suite")
            {
                MaxOccurs = Unbounded;
                XmlName = 'AITSuite';
                fieldattribute(Code; AITSuite.Code)
                {
                    Occurrence = Required;
                }
                fieldattribute(Description; "AITSuite".Description)
                {
                    Occurrence = Optional;
                }
                fieldattribute(Tag; "AITSuite".Tag)
                {
                    Occurrence = Optional;
                }
                fieldattribute(Duration; "AITSuite".Duration)
                {
                    Occurrence = Optional;
                }
                fieldattribute(DefaultMinDelay; "AITSuite"."Default Min. User Delay (ms)")
                {
                    Occurrence = Optional;
                }
                fieldattribute(DefaultMaxDelay; "AITSuite"."Default Max. User Delay (ms)")
                {
                    Occurrence = Optional;
                }
                fieldattribute(ModelVersion; "AITSuite"."ModelVersion")
                {
                    Occurrence = Optional;
                }
                fieldattribute(Dataset; "AITSuite"."Input Dataset")
                {
                    Occurrence = Required;
                }
                tableelement(AITestMethodLine; "AIT Test Method Line")
                {
                    LinkFields = "Test Suite Code" = field("Code");
                    LinkTable = "AITSuite";
                    MinOccurs = Zero;
                    XmlName = 'Line';

                    fieldattribute(CodeunitID; AITestMethodLine."Codeunit ID")
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(DelayBetwnItr; AITestMethodLine."Delay (ms btwn. iter.)")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Description; AITestMethodLine.Description)
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Dataset; AITestMethodLine."Input Dataset")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(MinDelay; AITestMethodLine."Min. User Delay (ms)")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(MaxDelay; AITestMethodLine."Max. User Delay (ms)")
                    {
                        Occurrence = Optional;
                    }
                    trigger OnBeforeInsertRecord()
                    var
                        AITTestMethodLine: Record "AIT Test Method Line";
                    begin
                        AITTestMethodLine.SetAscending("Line No.", true);
                        AITTestMethodLine.SetRange("Test Suite Code", AITSuite.Code);
                        if AITTestMethodLine.FindLast() then;
                        AITestMethodLine."Line No." := AITTestMethodLine."Line No." + 1000;
                    end;
                }
            }
        }
    }
    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }
}

