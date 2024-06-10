// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

xmlport 149031 "AIT Import/Export"
{
    Caption = 'AIT Import/Export';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(AITSuite; "AIT Header")
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
                tableelement(AITSuiteLine; "AIT Line")
                {
                    LinkFields = "AIT Code" = field("Code");
                    LinkTable = "AITSuite";
                    MinOccurs = Zero;
                    XmlName = 'Line';

                    fieldattribute(CodeunitID; AITSuiteLine."Codeunit ID")
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(DelayBetwnItr; AITSuiteLine."Delay (ms btwn. iter.)")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Description; AITSuiteLine.Description)
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Dataset; AITSuiteLine."Input Dataset")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(MinDelay; AITSuiteLine."Min. User Delay (ms)")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(MaxDelay; AITSuiteLine."Max. User Delay (ms)")
                    {
                        Occurrence = Optional;
                    }
                    trigger OnBeforeInsertRecord()
                    var
                        AITLine: Record "AIT Line";
                    begin
                        AITLine.SetAscending("Line No.", true);
                        AITLine.SetRange("AIT Code", AITSuite.Code);
                        if AITLine.FindLast() then;
                        AITSuiteLine."Line No." := AITLine."Line No." + 1000;
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

