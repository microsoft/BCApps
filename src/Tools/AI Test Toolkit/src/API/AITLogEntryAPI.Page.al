// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
page 149038 "AIT Log Entry API"
{
    PageType = API;
    APIPublisher = 'microsoft';
    APIGroup = 'aiTestToolkit';
    APIVersion = 'v2.0';
    Caption = 'AI Test Logs Entries';
    EntityCaption = 'AI Test Logs Entry';
    EntitySetCaption = 'AI Test Log Entries';
    EntityName = 'aiTestLogEntry';
    EntitySetName = 'aitTestLogEntries';
    SourceTable = "AIT Log Entry";
    ODataKeyFields = SystemId;
    Extensible = false;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field("aitCode"; Rec."Test Suite Code")
                {
                    Caption = 'Test Suite Code';
                    Editable = false;
                    NotBlank = true;
                    TableRelation = "AIT Test Suite";
                }
                field("lineNumber"; Rec."Test Method Line No.")
                {
                    Caption = 'Line No.';
                }
                field("tag"; Rec.Tag)
                {
                    Caption = 'Tag';
                }
                field("version"; Rec.Version)
                {
                    Caption = 'Version';
                }
                field(modelVersion; Rec."Model Version")
                {
                    Caption = 'AOAI Model Version';
                }
                field("startTime"; Rec."Start Time")
                {
                    Caption = 'Start Time';
                }
                field("endTime"; Rec."End Time")
                {
                    Caption = 'End Time';
                }
                field("codeunitID"; Rec."Codeunit ID")
                {
                    Caption = 'Codeunit ID';
                }
                field("codeunitName"; Rec."Codeunit Name")
                {
                    Caption = 'Codeunit Name';
                }
                field("procedureName"; Rec."Procedure Name")
                {
                    Caption = 'Function Name';
                }
                field("message"; MessageTxt)
                {
                    Caption = 'Message';
                }
                field("durationMs"; Rec."Duration (ms)")
                {
                    Caption = 'Duration (ms)';
                }
                field("status"; Rec.Status)
                {
                    Caption = 'Status';
                }
                field(dataset; Rec."Test Input Group Code")
                {
                    Caption = 'Dataset';
                }
                field("datasetLineNumber"; Rec."Test Input Code")
                {
                    Caption = 'Dataset Line No.';
                }
                field(sensitive; Rec.Sensitive)
                {
                    Caption = 'Sensitive';
                }
                field("inputData"; InputText)
                {
                    Caption = 'Input Data';
                }
                field("outputData"; OutputText)
                {
                    Caption = 'Output Data';
                }
                field(errorCallStack; ErrorCallStackText)
                {
                    Caption = 'Error Call Stack';
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date Time';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        InputText := Rec.GetInputBlob();
        OutputText := Rec.GetOutputBlob();
        MessageTxt := Rec.GetMessage();
        ErrorCallStackText := Rec.GetErrorCallStack();
    end;

    var
        InputText: Text;
        OutputText: Text;
        MessageTxt: Text;
        ErrorCallStackText: Text;
}