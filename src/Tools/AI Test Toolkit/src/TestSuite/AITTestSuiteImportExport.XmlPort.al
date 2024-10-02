// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

xmlport 149031 "AIT Test Suite Import/Export"
{
    Caption = 'AI Import/Export';
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

                    trigger OnAfterAssignField()
                    var
                        AITTestSuiteRec: Record "AIT Test Suite";
                        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
                        CallerModuleInfo: ModuleInfo;
                        SameSuiteDifferentXMLErr: Label 'The test suite %1 is already imported with a different XML by the same app. Please delete the test suite and import again.', Comment = '%1 = Test Suite Code';
                        SameSuiteDifferentAppErr: Label 'The test suite %1 is already imported by a different app. Please rename the test suite and import again.', Comment = '%1 = Test Suite Code';
                    begin
                        // Skip if the same suite is already imported by the same app
                        // Error if the same suite is already imported with a different XML
                        // Error if the same suite is already imported by a different app
                        AITTestSuiteMgt.GetCallerModuleInfo(CallerModuleInfo);
                        AITSuite."Imported by AppId" := CallerModuleInfo.Id;

                        AITSuite."Imported XML's MD5" := MD5FileHash;

                        AITTestSuiteRec.SetLoadFields(Code, "Imported by AppId", "Imported XML's MD5");
                        AITTestSuiteRec.SetRange(Code, AITSuite.Code);

                        if AITTestSuiteRec.FindFirst() then
                            if AITTestSuiteRec."Imported by AppId" = CallerModuleInfo.Id then
                                if AITTestSuiteRec."Imported XML's MD5" = AITSuite."Imported XML's MD5" then begin
                                    SkipTestSuites.Add(AITSuite.Code);
                                    currXMLport.Skip();
                                end
                                else
                                    Error(SameSuiteDifferentXMLErr, AITSuite.Code)
                            else
                                Error(SameSuiteDifferentAppErr, AITSuite.Code);
                    end;
                }
                fieldattribute(Description; "AITSuite".Description)
                {
                    Occurrence = Optional;
                }
                fieldattribute(Tag; "AITSuite".Tag)
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
                    fieldattribute(Description; AITestMethodLine.Description)
                    {
                        Occurrence = Optional;
                    }
                    fieldattribute(Dataset; AITestMethodLine."Input Dataset")
                    {
                        Occurrence = Optional;
                    }
                    textattribute(EvaluatorText)
                    {
                        Occurrence = Optional;
                        XmlName = 'Evaluator';
                    }

                    trigger OnAfterInitRecord()
                    begin
                        if SkipTestSuites.Contains(AITSuite.Code) then
                            currXMLport.Skip();
                    end;

                    trigger OnBeforeInsertRecord()
                    var
                        AITTestMethodLine: Record "AIT Test Method Line";
                    begin
                        AITTestMethodLine.SetAscending("Line No.", true);
                        AITTestMethodLine.SetRange("Test Suite Code", AITSuite.Code);
                        if AITTestMethodLine.FindLast() then;
                        AITestMethodLine."Line No." := AITTestMethodLine."Line No." + 10000;
                    end;
                }

                trigger OnBeforeInsertRecord()
                begin
                    if SkipTestSuites.Contains(AITSuite.Code) then
                        currXMLport.Skip();
                end;
            }
        }
    }

    trigger OnInitXmlPort()
    var
        AITTestContextImpl: Codeunit "AIT Test Context Impl.";
    begin
        MD5FileHash := AITTestContextImpl.GetAndClearMD5HashForTheImportedXML();
    end;

    var
        SkipTestSuites: List of [Code[100]];
        MD5FileHash: Code[32];
}

