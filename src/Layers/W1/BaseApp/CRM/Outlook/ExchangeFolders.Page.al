// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Outlook;

using System.Integration;

page 5320 "Exchange Folders"
{
    Caption = 'Exchange Folders';
    Editable = false;
    PageType = List;
    RefreshOnActivate = false;
    ShowFilter = false;
    SourceTable = "Exchange Folder";
    SourceTableTemporary = true;
    SourceTableView = sorting(FullPath)
                      order(ascending);

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                IndentationColumn = Rec.Depth;
                IndentationControls = Name;
                //The GridLayout property is only supported on controls of type Grid
                //GridLayout = Columns;
                ShowAsTree = true;
                ShowCaption = false;
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Folder Name';
                    ToolTip = 'Specifies the name of the public folder that is specified for use with email logging.';
                }
                field(FullPath; Rec.FullPath)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Folder Path';
                    ToolTip = 'Specifies the complete path to the public folder that is specified for use with email logging.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(GetChildren)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Get subfolders';
                Image = Find;
                ToolTip = 'Access the subfolder. Repeat as many times as you need to access the path that you want.';

                trigger OnAction()
                var
                    SelectedExchangeFolder: Record "Exchange Folder";
                    HasChildren: Boolean;
                begin
                    if not Rec.Cached then begin
                        SelectedExchangeFolder := Rec;
                        HasChildren := ExchangeWebServicesClient.GetPublicFolders(Rec);
                        CurrPage.SetRecord(SelectedExchangeFolder);
                        if HasChildren then
                            Rec.Next();
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(GetChildren_Promoted; GetChildren)
                {
                }
            }
        }
    }

    trigger OnClosePage()
    begin
        // This has to be called before GETRECORD that copies the content
        Rec.CalcFields("Unique ID");
    end;

    trigger OnOpenPage()
    begin
        if not ExchangeWebServicesClient.ReadBuffer(Rec) then
            ExchangeWebServicesClient.GetPublicFolders(Rec);
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;

    var
        ExchangeWebServicesClient: Codeunit "Exchange Web Services Client";

    procedure Initialize(ExchWebServicesClient: Codeunit "Exchange Web Services Client"; Caption: Text)
    begin
        ExchangeWebServicesClient := ExchWebServicesClient;
        CurrPage.Caption := Caption;
    end;
}

