// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Security.Encryption;

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
                        SameSuiteDifferentXMLErr: Label 'The test suite %1 is already imported with a different XML by the same app. Please delete the test suite and import again.', Comment = '%1 = Test Suite Code';
                        SameSuiteDifferentAppErr: Label 'The test suite %1 is already imported by a different app. Please rename the test suite and import again.', Comment = '%1 = Test Suite Code';
                    begin
                        // Skip if the same suite is already imported by the same app
                        // Error if the same suite is already imported with a different XML
                        // Error if the same suite is already imported by a different app
                        AITTestSuiteRec.SetLoadFields(Code, "Imported by AppId", "Imported XML's MD5");
                        AITTestSuiteRec.SetRange(Code, AITSuite.Code);

                        if AITTestSuiteRec.FindFirst() then
                            if AITTestSuiteRec."Imported by AppId" = GlobalCallerModuleInfo.Id then
                                if AITTestSuiteRec."Imported XML's MD5" = GlobalMD5FileHash then begin
                                    SkipTestSuites.Add(AITSuite.Code);
                                    currXMLport.Skip();
                                end
                                else
                                    Error(SameSuiteDifferentXMLErr, AITSuite.Code)
                            else
                                Error(SameSuiteDifferentAppErr, AITSuite.Code);

                        AITSuite."Imported by AppId" := GlobalCallerModuleInfo.Id;
                        AITSuite."Imported XML's MD5" := GlobalMD5FileHash;
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
                fieldattribute(TestRunnerId; "AITSuite"."Test Runner Id")
                {
                    Occurrence = Optional;
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

    internal procedure SetMD5HashForTheImportedXML(XMLSetupInStream: InStream)
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        MD5Hash: Text;
    begin
        MD5Hash := CryptographyManagement.GenerateHash(XMLSetupInStream, HashAlgorithmType::MD5);
        GlobalMD5FileHash := CopyStr(MD5Hash, 1, 32);
    end;

    internal procedure SetCallerModuleInfo(var CallerModuleInfo: ModuleInfo)
    begin
        GlobalCallerModuleInfo := CallerModuleInfo;
    end;

    var
        SkipTestSuites: List of [Code[100]];
        GlobalMD5FileHash: Code[32];
        GlobalCallerModuleInfo: ModuleInfo;
}

