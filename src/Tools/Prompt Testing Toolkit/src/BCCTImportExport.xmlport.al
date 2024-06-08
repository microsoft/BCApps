// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

xmlport 149031 "BCCT Import/Export"
{
    Caption = 'BCCT Import/Export';
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(BCCTSuite; "BCCT Header")
            {
                MaxOccurs = Unbounded;
                XmlName = 'BCCTSuite';
                fieldattribute(Code; BCCTSuite.Code)
                {
                    Occurrence = Required;
                }
                fieldattribute(Description; "BCCTSuite".Description)
                {
                    Occurrence = Optional;
                }
                fieldattribute(Tag; "BCCTSuite".Tag)
                {
                    Occurrence = Optional;
                }
                fieldattribute(Duration; "BCCTSuite".Duration)
                {
                    Occurrence = Optional;
                }
                fieldattribute(DefaultMinDelay; "BCCTSuite"."Default Min. User Delay (ms)")
                {
                    Occurrence = Optional;
                }
                fieldattribute(DefaultMaxDelay; "BCCTSuite"."Default Max. User Delay (ms)")
                {
                    Occurrence = Optional;
                }
                fieldattribute(ModelVersion; "BCCTSuite"."ModelVersion")
                {
                    Occurrence = Optional;
                }
                fieldattribute(Dataset; "BCCTSuite"."Input Dataset")
                {
                    Occurrence = Required;
                }
                tableelement(BCCTSuiteLine; "BCCT Line")
                {
                    LinkFields = "BCCT Code" = field("Code");
                    LinkTable = "BCCTSuite";
                    MinOccurs = Zero;
                    XmlName = 'Line';

                    fieldattribute(CodeunitID; BCCTSuiteLine."Codeunit ID")
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(DelayBetwnItr; BCCTSuiteLine."Delay (ms btwn. iter.)")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Description; BCCTSuiteLine.Description)
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Dataset; BCCTSuiteLine."Input Dataset")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(MinDelay; BCCTSuiteLine."Min. User Delay (ms)")
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(MaxDelay; BCCTSuiteLine."Max. User Delay (ms)")
                    {
                        Occurrence = Optional;
                    }
                    trigger OnBeforeInsertRecord()
                    var
                        BCCTLine: Record "BCCT Line";
                    begin
                        BCCTLine.SetAscending("Line No.", true);
                        BCCTLine.SetRange("BCCT Code", BCCTSuite.Code);
                        if BCCTLine.FindLast() then;
                        BCCTSuiteLine."Line No." := BCCTLine."Line No." + 1000;
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

