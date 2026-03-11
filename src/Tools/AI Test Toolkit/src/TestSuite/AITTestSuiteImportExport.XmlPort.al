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
                        SameSuiteDifferentAppErr: Label 'The eval suite %1 is already imported by a different app. Please rename the eval suite and import again.', Comment = '%1 = Eval Suite Code';
                    begin
                        // Skip if the same suite is already imported by the same app with the same XML
                        // Delete and override suite if the same suite is already imported with a different XML
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
                                    AITTestSuiteRec.Delete()
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
                fieldattribute(Capability; "AITSuite"."Copilot Capability")
                {
                    Occurrence = Optional;
                }
                fieldattribute(Frequency; "AITSuite"."Run Frequency")
                {
                    Occurrence = Optional;
                }
                fieldattribute(TestRunnerId; "AITSuite"."Test Runner Id")
                {
                    Occurrence = Optional;
                }
                fieldattribute(TestType; "AITSuite"."Test Type")
                {
                    Occurrence = Optional;
                }
                textattribute(ValidationAttr)
                {
                    XmlName = 'Validation';
                    Occurrence = Optional;

                    trigger OnBeforePassVariable()
                    begin
                        if AITSuite.Validation then
                            ValidationAttr := 'true'
                        else
                            ValidationAttr := '';
                    end;

                    trigger OnAfterAssignVariable()
                    begin
                        AITSuite.Validation := UpperCase(ValidationAttr) = 'TRUE';
                    end;
                }
                tableelement(AITLanguage; "AIT Test Suite Language")
                {
                    LinkFields = "Test Suite Code" = field("Code");
                    LinkTable = "AITSuite";
                    MinOccurs = Zero;
                    XmlName = 'Language';

                    textattribute(Tag)
                    {
                        Occurrence = Required;

                        trigger OnBeforePassVariable()
                        begin
                            AITLanguage.CalcFields("Language Tag");
                            Tag := AITLanguage."Language Tag";
                        end;

                        trigger OnAfterAssignVariable()
                        var
                            AITTestSuiteLanguage: Codeunit "AIT Test Suite Language";
                        begin
                            AITLanguage."Language ID" := AITTestSuiteLanguage.GetLanguageIDByTag(Tag);
                        end;
                    }
                    fieldattribute(Frequency; AITLanguage."Run Frequency")
                    {
                        Occurrence = Optional;
                    }
                    textattribute(LanguageValidationAttr)
                    {
                        XmlName = 'Validation';
                        Occurrence = Optional;

                        trigger OnBeforePassVariable()
                        begin
                            if AITLanguage.Validation then
                                LanguageValidationAttr := 'True'
                            else
                                LanguageValidationAttr := '';
                        end;

                        trigger OnAfterAssignVariable()
                        begin
                            AITLanguage.Validation := UpperCase(LanguageValidationAttr) = 'TRUE';
                        end;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        if SkipTestSuites.Contains(AITSuite.Code) then
                            currXMLport.Skip();
                    end;
                }
                tableelement(AITEvaluator; "AIT Evaluator")
                {
                    LinkFields = "Test Suite Code" = field("Code");
                    LinkTable = "AITSuite";
                    MinOccurs = Zero;
                    XmlName = 'Evaluator';
                    SourceTableView = where("Test Method Line" = const(0));

                    fieldattribute(Evaluator; AITEvaluator.Evaluator)
                    {
                        Occurrence = Required;
                    }
                    fieldattribute(Type; AITEvaluator."Evaluator Type")
                    {
                        Occurrence = Required;
                    }

                    trigger OnAfterInitRecord()
                    begin
                        if SkipTestSuites.Contains(AITSuite.Code) then
                            currXMLport.Skip();
                    end;
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
                    tableelement(AITLineEvaluator; "AIT Evaluator")
                    {
                        LinkFields = "Test Suite Code" = field("Test Suite Code"), "Test Method Line" = field("Line No.");
                        LinkTable = AITestMethodLine;
                        MinOccurs = Zero;
                        XmlName = 'Evaluator';

                        fieldattribute(Evaluator; AITLineEvaluator.Evaluator)
                        {
                            Occurrence = Required;
                        }
                        fieldattribute(Type; AITLineEvaluator."Evaluator Type")
                        {
                            Occurrence = Required;
                        }

                        trigger OnAfterInitRecord()
                        begin
                            if SkipTestSuites.Contains(AITSuite.Code) then
                                currXMLport.Skip();
                        end;

                        trigger OnBeforeInsertRecord()
                        begin
                            AITLineEvaluator."Test Method Line" := AITestMethodLine."Line No.";
                        end;
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

