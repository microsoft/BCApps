// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Assembly.History;
using Microsoft.Utilities;

report 901 "Copy Assembly Document"
{
    Caption = 'Copy Assembly Document';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(DocType; DocType)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Document Type';
                        OptionCaption = 'Quote,Order,,,Blanket Order,Posted Order';
                        ToolTip = 'Specifies the type of assembly document that you want to copy.';

                        trigger OnValidate()
                        begin
                            DocNo := '';
                        end;
                    }
                    field(DocNo; DocNo)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the document that you want to copy. The contents of the Document Type field determines which document numbers you can choose from.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            LookupDocNo();
                        end;
                    }
                    field(IncludeHeader; IncludeHeader)
                    {
                        ApplicationArea = Assembly;
                        Caption = 'Include Header';
                        ToolTip = 'Specifies if you also want to copy the header information from the existing assembly document.';
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DocNo <> '' then
                case DocType of
                    DocType::Quote:
                        if FromAsmHeader.Get(FromAsmHeader."Document Type"::Quote, DocNo) then
                            ;
                    DocType::"Blanket Order":
                        if FromAsmHeader.Get(FromAsmHeader."Document Type"::"Blanket Order", DocNo) then
                            ;
                    DocType::Order:
                        if FromAsmHeader.Get(FromAsmHeader."Document Type"::Order, DocNo) then
                            ;
                    DocType::"Posted Order":
                        if FromPostedAsmHeader.Get(DocNo) then
                            ;
                end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        case DocType of
            DocType::Quote,
            DocType::Order,
            DocType::"Blanket Order":
                begin
                    FromAsmHeader.Get(DocType, DocNo);
                    CopyDocMgt.CopyAsmHeaderToAsmHeader(FromAsmHeader, ToAsmHeader, IncludeHeader);
                end;
            DocType::"Posted Order":
                begin
                    FromPostedAsmHeader.Get(DocNo);
                    CopyDocMgt.CopyPostedAsmHeaderToAsmHeader(FromPostedAsmHeader, ToAsmHeader, IncludeHeader);
                end;
        end;
    end;

    var
        FromAsmHeader: Record "Assembly Header";
        FromPostedAsmHeader: Record "Posted Assembly Header";
        ToAsmHeader: Record "Assembly Header";
        CopyDocMgt: Codeunit "Copy Document Mgt.";
        DocType: Option Quote,"Order",,,"Blanket Order","Posted Order";
        DocNo: Code[20];
        IncludeHeader: Boolean;

    local procedure LookupDocNo()
    begin
        case DocType of
            DocType::Quote,
            DocType::Order,
            DocType::"Blanket Order":
                begin
                    FromAsmHeader.Reset();
                    FromAsmHeader.SetRange("Document Type", DocType);
                    if DocType = ToAsmHeader."Document Type".AsInteger() then
                        FromAsmHeader.SetFilter("No.", '<>%1', ToAsmHeader."No.");
                    if PAGE.RunModal(PAGE::"Assembly List", FromAsmHeader) = ACTION::LookupOK then
                        DocNo := FromAsmHeader."No.";
                end;
            DocType::"Posted Order":
                if PAGE.RunModal(0, FromPostedAsmHeader) = ACTION::LookupOK then
                    DocNo := FromPostedAsmHeader."No.";
        end;
    end;

    procedure SetAssemblyHeader(AsmHeader: Record "Assembly Header")
    begin
        AsmHeader.TestField("No.");
        ToAsmHeader := AsmHeader;
    end;
}

