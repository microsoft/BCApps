// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.WithholdingTax;

using Microsoft.Purchases.Vendor;
using System.IO;
using System.Utilities;

report 16632 "WHT E-Filing"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WHT E-Filing';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Integer"; "Integer")
        {
            MaxIteration = 1;

            trigger OnAfterGetRecord()
            begin
                if not FileOpened then begin
                    TestFile.Create(Path);
                    TestFile.CreateOutStream(TestStream);
                    FileOpened := true;
                end;

                FIlterVendID := Vendid;
                EFilingXMLPort.SetDestination(TestStream);
                EFilingXMLPort.InitVariables(FIlterVendID, ReturnPeriod, BranchCode, PayeeBranchCode);
                EFilingXMLPort.Export();
                TestFile.Close();

                Message(Text16508);
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ReturnPeriod; ReturnPeriod)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Return Period';
                        ToolTip = 'Specifies the period that the electronic report is for.';
                    }
                    field(BranchCode; BranchCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Branch Code';
                        ToolTip = 'Specifies a three character code.';
                    }
                    field(Vendid; Vendid)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Pay-to/buy-from Vendor';
                        TableRelation = Vendor;
                        ToolTip = 'Specifies the vendor that the transaction applies to.';
                    }
                    field(PayeeBranchCode; PayeeBranchCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Payee Branch Code';
                        ToolTip = 'Specifies a three character code.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        ToFile: Text[1024];
    begin
        ToFile := Text16524;
        Download(Path, Text16507, '', Text16523, ToFile);
    end;

    trigger OnPreReport()
    var
        RBMgt: Codeunit "File Management";
    begin
        Path := RBMgt.ServerTempFileName('xml');
    end;

    var
        EFilingXMLPort: XMLport "WHT-EFiling";
        TestFile: File;
        TestStream: OutStream;
        ReturnPeriod: Text[30];
        BranchCode: Text[3];
        PayeeBranchCode: Text[3];
        Path: Text[1024];
        Vendid: Code[20];
        FIlterVendID: Code[20];
        Text16523: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        Text16524: Label 'E-Filing.xml';
        FileOpened: Boolean;
        Text16507: Label 'Export to Xml file.';
        Text16508: Label 'WHT EFiling Export Complete.';
}

