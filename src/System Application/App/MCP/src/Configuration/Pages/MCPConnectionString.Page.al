// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Utilities;

/// <summary>
/// Dialog page to display and download the MCP connection string configuration.
/// </summary>
page 8358 "MCP Connection String"
{
    PageType = Card;
    Extensible = false;
    Editable = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(ConnectionStringGroup)
            {
                ShowCaption = false;
                field(ConnectionStringField; ConnectionStringDisplay)
                {
                    ApplicationArea = All;
                    Caption = 'Connection String';
                    ToolTip = 'Specifies the MCP connection string configuration in JSON format. Copy this to your MCP client configuration file.';
                    ShowCaption = false;
                    Editable = false;
                    MultiLine = true;
                    ExtendedDatatype = RichContent;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Download)
            {
                ApplicationArea = All;
                Caption = 'Download';
                ToolTip = 'Download the connection string as a text file.';
                Image = Download;

                trigger OnAction()
                var
                    TempBlob: Codeunit "Temp Blob";
                    InStream: InStream;
                    OutStream: OutStream;
                    FileName: Text;
                begin
                    TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
                    OutStream.WriteText(ConnectionStringJson);
                    TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
                    FileName := StrSubstNo(FileNamePatternLbl, LowerCase(ConfigurationName));
                    DownloadFromStream(InStream, DownloadTitleLbl, '', TextFileFilterLbl, FileName);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Promoted_Download; Download) { }
        }
    }

    var
        ConnectionStringDisplay: Text;
        ConnectionStringJson: Text;
        ConfigurationName: Text[100];
        DownloadTitleLbl: Label 'Download MCP Connection String';
        TextFileFilterLbl: Label 'Text Files (*.txt)|*.txt';
        FileNamePatternLbl: Label 'mcp-config-%1.txt', Locked = true, Comment = '%1 = Configuration name';

    internal procedure SetConnectionString(NewConnectionString: Text; NewConfigurationName: Text[100])
    begin
        ConnectionStringJson := NewConnectionString;
        ConnectionStringDisplay := '<pre>' + NewConnectionString + '</pre>';
        ConfigurationName := NewConfigurationName;
    end;
}
